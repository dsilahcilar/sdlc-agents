"""Tests for the risk report. Run: python3 -m unittest discover -s v2/retro -p 'test_*.py'"""
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import risk_report as rr  # noqa: E402
import handover_gate as gate  # noqa: E402

REVIEWER_RULE = {"id": "code-review", "title": "Code review", "kind": "review", "reviewer": "reviewer",
                 "owed_when": {"changed": ["src/billing/**", "deploy/**"]}}
UNIT_TEST = {"id": "unit-test", "title": "Unit test", "kind": "evidence",
             "owed_when": {"changed": ["src/**", "!**/*.test.ts"]}, "satisfied_by": ["**/*.test.ts"]}
CONTRACT = {"id": "api-contract", "title": "API contract", "kind": "evidence",
            "owed_when": {"changed": ["src/api/**"]}, "satisfied_by": ["contracts/**"]}


def scope(*items, **top):
    return rr.scope_from_rules(gate.parse_rules({"items": list(items) or [UNIT_TEST], **top}))


def merged(number, *paths, lines=10, text="", title=""):
    return rr.Merged(number, f"sha{number}", f"2026-01-{number % 28 + 1:02d}T10:00:00+00:00", title or f"Change {number}",
                     text, [rr.File(p, lines) for p in paths])


def wrong(*pairs):
    return [rr.Fix(fix, repairs, rr.WRONG_IN_USE) for fix, repairs in pairs]


class Numbers(unittest.TestCase):
    def test_a_merge_commit_and_a_squash_merge_both_name_their_pull_request(self):
        self.assertEqual(rr.pull_request_number("Merge pull request #12 from someone/branch"), 12)
        self.assertEqual(rr.pull_request_number("Give totals two decimals (#34)"), 34)

    def test_a_commit_pushed_straight_to_the_branch_has_none(self):
        self.assertIsNone(rr.pull_request_number("Fix the build, see #12 for why"))


class Candidates(unittest.TestCase):
    def history(self, text):
        return [merged(5, "src/a.ts"), merged(7, "src/b.ts"), merged(9, "src/a.ts", text=text)]

    def found(self, text, known=()):
        return [(c.fix, c.repairs) for c in rr.find_candidates(self.history(text), known)]

    def test_a_sentence_that_names_an_earlier_pull_request_next_to_a_failure_word(self):
        self.assertEqual(self.found("The total was wrong since #5. This fixes it."), [(9, 5)])
        self.assertEqual(self.found("Regression from https://example.test/o/r/pull/7 in the export."), [(9, 7)])

    def test_the_failure_word_has_to_be_in_the_same_sentence(self):
        self.assertEqual(self.found("Builds on #5. Also fixes a typo."), [])

    def test_a_number_that_is_not_an_earlier_merged_pull_request_is_left_out(self):
        self.assertEqual(self.found("Fixes #6, the issue about totals. Broken since #11."), [])

    def test_a_pair_that_was_read_before_does_not_come_back(self):
        self.assertEqual(self.found("Fixes what #5 broke.", known=[(9, 5)]), [])

    def test_each_pair_is_reported_once(self):
        self.assertEqual(self.found("Fixes what #5 broke. #5 was wrong about tax."), [(9, 5)])


class FixesFile(unittest.TestCase):
    def load(self, data):
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / "fixes.json"
            path.write_text(data if isinstance(data, str) else json.dumps(data))
            return rr.load_fixes(path)

    def test_no_file_yet_means_nothing_confirmed(self):
        self.assertEqual(rr.load_fixes(pathlib.Path("/nonexistent/fixes.json")), ([], set()))

    def test_fixes_and_dismissed_pairs_are_read(self):
        fixes, not_fixes = self.load({"fixes": [{"fix": 9, "repairs": 5, "kind": "wrong-in-use", "what": "tax"}],
                                      "not_fixes": [[9, 7]]})
        self.assertEqual((fixes[0].fix, fixes[0].repairs, fixes[0].kind), (9, 5, "wrong-in-use"))
        self.assertEqual(not_fixes, {(9, 7)})

    def test_a_misspelt_field_or_kind_is_an_error(self):
        for bad in ({"fixs": []}, {"fixes": [{"fix": 9, "repairs": 5, "kind": "bad"}]},
                    {"fixes": [{"fix": 9, "repair": 5, "kind": "other"}]}, {"not_fixes": [[9]]}, "{"):
            with self.assertRaises(rr.FixesError):
                self.load(bad)


class WhatCounts(unittest.TestCase):
    def test_without_a_rule_for_it_the_reviewer_reads_every_change(self):
        s = scope(UNIT_TEST)
        self.assertIsNone(s.reviewer)
        self.assertTrue(s.reviewed(merged(1, "src/ui/button.ts")))

    def test_its_rule_decides_which_changes_it_reads(self):
        s = scope(UNIT_TEST, REVIEWER_RULE)
        self.assertTrue(s.reviewed(merged(1, "src/ui/button.ts", "deploy/run.sh")))
        self.assertFalse(s.reviewed(merged(2, "src/ui/button.ts")))

    def test_an_ignored_file_does_not_bring_the_reviewer(self):
        s = scope(UNIT_TEST, dict(REVIEWER_RULE, owed_when={"changed": ["**/billing/**"]}), ignore=["docs/**"])
        self.assertFalse(s.reviewed(merged(1, "docs/billing/notes.txt")))

    def test_tests_and_other_evidence_are_not_the_code_under_review(self):
        s = scope(UNIT_TEST, CONTRACT, ignore=["docs/**"])
        code = [p for p in ("src/a.ts", "src/a.test.ts", "contracts/openapi.yaml", "src/test/helpers/fake.ts",
                            "docs/x.txt", "package-lock.json", "deploy/run.sh") if s.is_code(p)]
        self.assertEqual(code, ["src/a.ts", "deploy/run.sh"])

    def test_a_question_or_an_added_list_in_the_rule_is_flagged(self):
        ask = {"paths": ["src/**"], "question": "q", "true": "t", "false": "f"}
        s = scope(dict(REVIEWER_RULE, owed_when={"changed": ["src/billing/**"], "ask": ask}))
        self.assertTrue(s.reviewer_has_more)
        self.assertFalse(scope(REVIEWER_RULE).reviewer_has_more)


class Analysis(unittest.TestCase):
    def setUp(self):
        # 40 changes: 20 in billing, 20 in the screens. Every fourth billing change went wrong, and one screen did.
        self.merged, pairs = [], []
        for n in range(1, 41):
            billing = n % 2 == 1
            path = f"src/billing/invoice{n % 3}.ts" if billing else f"src/ui/screen{n % 3}.ts"
            self.merged.append(merged(n, path, f"src/x{n}.test.ts", lines=30 if billing else 200))
            if (billing and n % 8 == 1) or n == 20:
                pairs.append((100 + n, n))
        self.fixes = wrong(*pairs)
        self.lines = {"src/billing/invoice0.ts": 900, "src/billing/invoice1.ts": 100, "src/ui/screen0.ts": 50}

    def report(self, *items, fixes=None, **kw):
        return rr.analyse(self.merged, self.fixes if fixes is None else fixes, set(), scope(*items),
                          lambda p: self.lines.get(p, 10), **kw)

    def test_it_counts_the_changes_and_the_ones_that_went_wrong(self):
        r = self.report(UNIT_TEST)
        self.assertEqual(r["changes"], 40)
        self.assertEqual(r["needed_a_fix"], {"wrong-in-use": 6, "red-main": 0, "other": 0})

    def test_only_fixes_of_something_wrong_in_use_judge_the_reviewer_rule(self):
        fixes = self.fixes + [rr.Fix(150, 2, rr.RED_MAIN), rr.Fix(151, 4, rr.OTHER)]
        r = self.report(UNIT_TEST, REVIEWER_RULE, fixes=fixes)
        self.assertEqual(r["needed_a_fix"], {"wrong-in-use": 6, "red-main": 1, "other": 1})
        self.assertEqual(r["current_rule"]["failed"], 6)

    def test_a_fix_of_a_pull_request_outside_the_period_is_left_out(self):
        r = self.report(UNIT_TEST, fixes=self.fixes + wrong((200, 999)))
        self.assertEqual(r["needed_a_fix"]["wrong-in-use"], 6)

    def test_with_no_rule_everything_is_reviewed_and_nothing_is_let_through(self):
        r = self.report(UNIT_TEST)
        self.assertFalse(r["reviewer_by_rule"])
        self.assertEqual((r["current_rule"]["reviewed"], r["current_rule"]["caught"], r["let_through"]), (40, 6, []))

    def test_the_rule_is_replayed_over_the_period(self):
        r = self.report(UNIT_TEST, REVIEWER_RULE)
        c = r["current_rule"]
        self.assertEqual((c["changes"], c["reviewed"], c["failed"], c["caught"]), (40, 20, 6, 5))
        self.assertEqual((c["rate_inside"], c["rate_outside"]), (0.25, 0.05))
        self.assertEqual([(x["number"], x["files"]) for x in r["let_through"]], [(20, ["src/ui/screen2.ts"])])

    def test_folders_are_listed_with_their_rate_and_whether_the_rule_names_them(self):
        r = self.report(UNIT_TEST, REVIEWER_RULE)
        rows = {row["folder"]: row for row in r["by_folder"]}
        self.assertEqual((rows["src/billing"]["changes"], rows["src/billing"]["failed"], rows["src/billing"]["rate"]),
                         (20, 5, 0.25))
        self.assertEqual((rows["src/billing"]["on_the_list"], rows["src/ui"]["on_the_list"], rows["src"]["on_the_list"]),
                         ("all", "none", "some"))
        self.assertEqual(r["by_folder"][0]["folder"], "src/billing")

    def test_sizes_count_code_lines_without_the_tests(self):
        r = self.report(UNIT_TEST)
        self.assertEqual([(row["changes"], row["failed"]) for row in r["by_size"]], [(20, 5), (0, 0), (20, 1), (0, 0)])

    def test_too_few_failures_give_no_list(self):
        self.assertIsNone(self.report(UNIT_TEST)["suggestion"])

    def test_hotspots_are_changes_times_lines(self):
        r = self.report(UNIT_TEST, REVIEWER_RULE)
        top = r["hotspots"][0]
        self.assertEqual((top["file"], top["lines"], top["on_the_list"]), ("src/billing/invoice0.ts", 900, "all"))
        self.assertEqual(top["changes"] * top["lines"], max(h["changes"] * h["lines"] for h in r["hotspots"]))

    def test_candidates_come_from_every_merged_pull_request_and_skip_known_pairs(self):
        self.merged.append(merged(41, "docs.txt", text="Fixes the total that #3 broke. Also repairs #1."))
        r = self.report(UNIT_TEST)
        self.assertEqual([(c["fix"], c["repairs"]) for c in r["candidates"]], [(41, 3), (41, 1)])
        r = rr.analyse(self.merged, self.fixes, {(41, 3)}, scope(UNIT_TEST))
        self.assertEqual([(c["fix"], c["repairs"]) for c in r["candidates"]], [(41, 1)])


class ChosenFolders(unittest.TestCase):
    def setUp(self):
        # 120 changes in four folders of 30. The two job folders go wrong one time in five, and one form did.
        self.merged, self.failed = [], set()
        folders = ("src/jobs/sync", "src/jobs/import", "src/pages", "src/forms")
        for n in range(1, 121):
            folder = folders[n % 4]
            self.merged.append(merged(n, f"{folder}/file{n % 5}.ts"))
            if (folder.startswith("src/jobs") and n % 10 in (0, 1)) or n == 3:
                self.failed.add(n)
        for m in self.merged:
            m.code = m.files

    def test_folders_that_go_wrong_more_often_than_the_rest_are_chosen(self):
        self.assertEqual(rr.choose_folders(self.merged, self.failed, 15, 1.5), ["src/jobs"])

    def test_the_outer_folder_stands_for_the_ones_inside_it(self):
        chosen = rr.choose_folders(self.merged, self.failed, 15, 1.5)
        self.assertNotIn("src/jobs/sync", chosen)

    def test_a_folder_needs_enough_changes_and_two_failures(self):
        self.assertEqual(rr.choose_folders(self.merged, self.failed, 100, 1.5), [])
        self.assertEqual(rr.choose_folders(self.merged, {3, 6}, 15, 1.5), [])

    def test_the_list_is_also_chosen_on_the_earlier_half_and_checked_on_the_later(self):
        fixes = wrong(*[(500 + n, n) for n in self.failed])
        r = rr.analyse(self.merged, fixes, set(), scope(UNIT_TEST))
        s = r["suggestion"]
        self.assertEqual(s["folders"], ["src/jobs"])
        self.assertEqual(s["chosen_on_the_earlier_half"], ["src/jobs"])
        later = s["checked_on_the_later_half"]
        self.assertEqual((later["changes"], later["reviewed"], later["failed"], later["caught"]), (60, 30, 6, 6))
        text = rr.render_markdown(r)
        self.assertIn("Folders where changes went wrong at least 1.5 times as often as changes do overall: "
                      "`src/jobs/**`.", text)
        self.assertIn("On the later half that list sends 30 of 60 changes to the reviewer (50%) and has 6 of the 6 "
                      "that went wrong among them.", text)


class Output(unittest.TestCase):
    def test_the_report_says_what_the_rule_does_and_what_it_lets_through(self):
        changes = [merged(n, "src/billing/a.ts" if n % 2 else "src/ui/b.ts") for n in range(1, 21)]
        r = rr.analyse(changes, wrong((30, 1), (31, 2)), set(), scope(UNIT_TEST, REVIEWER_RULE))
        text = rr.render_markdown(r)
        self.assertIn("20 merged pull requests changed code between 2026-01-02 and 2026-01-21.", text)
        self.assertIn("The rule sends 10 of 20 changes to the reviewer (50%) and has 1 of the 2 that went wrong among "
                      "them. Went wrong inside: 10%. Outside: 10%.", text)
        self.assertIn("- Let through: #2 Change 2 (src/ui/b.ts)", text)
        self.assertIn("Too few changes are known to have gone wrong (2) to choose folders from them.", text)

    def test_a_repository_without_the_rule_is_told_so(self):
        r = rr.analyse([merged(1, "src/a.ts")], [], set(), scope(UNIT_TEST))
        self.assertIn("No rule names the reviewer, so it reads every change.", rr.render_markdown(r))

    def test_an_empty_period_is_one_line(self):
        r = rr.analyse([], [], set(), scope(UNIT_TEST))
        self.assertIn("No merged pull request with a code change in this period.", rr.render_markdown(r))


class CommandLine(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = pathlib.Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        (self.repo / ".sdlc").mkdir()
        (self.repo / ".sdlc/rules.json").write_text(json.dumps({"ignore": [".sdlc/**"], "items": [UNIT_TEST, REVIEWER_RULE]}))
        self.write("README.txt", "start\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "Start")
        self.merge(1, "Add invoices", {"src/billing/invoice.ts": "a\nb\nc\n", "src/billing/invoice.test.ts": "t\n"})
        self.squash(2, "Add a button", {"src/ui/button.ts": "x\n"})
        self.merge(3, "Give invoices their tax", {"src/billing/invoice.ts": "a\nb\nc\nd\n"},
                   message="The total was wrong since #1: tax was left out.")
        self.write("notes.txt", "pushed straight to main\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "A note")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True, text=True).stdout

    def write(self, path, text):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def merge(self, number, title, files, message="work"):
        self.git("checkout", "-q", "-b", f"change-{number}")
        for path, text in files.items():
            self.write(path, text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)
        self.git("checkout", "-q", "main")
        self.git("merge", "-q", "--no-ff", f"change-{number}", "-m", f"Merge pull request #{number} from someone/change-{number}",
                 "-m", title)

    def squash(self, number, title, files):
        for path, text in files.items():
            self.write(path, text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", f"{title} (#{number})")

    def run_report(self, *args):
        import contextlib
        import io
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = rr.main(["--repo", str(self.repo), "--branch", "main", "--rules", str(self.repo / ".sdlc/rules.json"),
                            "--fixes", str(self.repo / ".sdlc/retro/fixes.json"), *args])
        return code, out.getvalue(), err.getvalue()

    def test_it_reads_merge_commits_and_squash_merges(self):
        code, out, _ = self.run_report("--format", "json")
        r = json.loads(out)
        self.assertEqual(code, 0)
        self.assertEqual((r["changes"], r["commits_without_a_number"]), (3, 2))
        self.assertEqual(r["current_rule"]["reviewed"], 2)
        self.assertEqual([(c["fix"], c["repairs"]) for c in r["candidates"]], [(3, 1)])
        self.assertEqual(r["hotspots"][0], {"file": "src/billing/invoice.ts", "changes": 2, "lines": 4, "failed": 0,
                                           "on_the_list": "all"})

    def test_a_confirmed_fix_moves_from_the_reading_list_into_the_counts(self):
        self.write(".sdlc/retro/fixes.json", json.dumps({"fixes": [{"fix": 3, "repairs": 1, "kind": "wrong-in-use"}]}))
        code, out, _ = self.run_report()
        self.assertEqual(code, 0)
        self.assertIn("A later fix is on record for 1 that went wrong in use", out)
        self.assertIn("has 1 of the 1 that went wrong among them", out)
        self.assertIn("No sentence names an earlier pull request", out)
        self.assertIn("Commits on main that carry no pull request number and were left out: 2.", out)

    def test_the_text_of_the_pull_requests_can_come_from_a_file(self):
        self.write("texts.json", json.dumps([{"number": 2, "title": "Add a button", "body": "Also fixes the crash from #1."}]))
        _, out, _ = self.run_report("--format", "json", "--pull-requests", str(self.repo / "texts.json"))
        self.assertIn((2, 1), [(c["fix"], c["repairs"]) for c in json.loads(out)["candidates"]])

    def test_a_broken_fixes_file_is_reported_and_exits_two(self):
        self.write(".sdlc/retro/fixes.json", "{")
        code, _, err = self.run_report()
        self.assertEqual(code, 2)
        self.assertIn("not valid JSON", err)

    def test_a_branch_that_does_not_exist_is_reported_and_exits_two(self):
        import contextlib
        import io
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            code = rr.main(["--repo", str(self.repo), "--branch", "nope", "--rules", str(self.repo / ".sdlc/rules.json")])
        self.assertEqual(code, 2)
        self.assertIn("git could not read nope", err.getvalue())


if __name__ == "__main__":
    unittest.main()
