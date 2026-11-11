"""Tests for the handover gate. Run: python3 -m unittest discover -s v2/gate -p 'test_*.py'"""
import json
import pathlib
import subprocess
import sys
import tempfile
import textwrap
import unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import handover_gate as gate  # noqa: E402

ASK = {
    "paths": ["src/**", "!**/*.test.ts"],
    "question": "Does it?",
    "true": "It does.",
    "false": "It does not.",
    "threshold": 0.3,
}


def rules(*items, **top):
    return gate.parse_rules({"items": list(items), **top})


def evidence(**over):
    item = {
        "id": "unit-test",
        "title": "Unit test",
        "kind": "evidence",
        "owed_when": {"changed": ["src/**", "!**/*.test.ts"]},
        "satisfied_by": ["**/*.test.ts"],
    }
    item.update(over)
    return item


def review(**over):
    item = {
        "id": "security-review",
        "title": "Security review",
        "kind": "review",
        "reviewer": "security-review",
        "owed_when": {"changed": ["src/auth/**"], "ask": dict(ASK)},
    }
    item.update(over)
    return item


def changes(*specs):
    return [gate.Change(s[0], s[2:]) for s in specs]


def run(r, change_list, judge=None, handover="code-to-review", **kw):
    return gate.decide(r, handover, change_list, lambda paths: "diff of " + ",".join(paths), judge, **kw)


def state(decision, item_id):
    return next(i for i in decision.items if i.id == item_id)


class Globs(unittest.TestCase):
    def test_double_star_crosses_directories_and_matches_the_root(self):
        self.assertTrue(gate.glob_to_regex("**/page.tsx").match("page.tsx"))
        self.assertTrue(gate.glob_to_regex("**/page.tsx").match("src/app/a/b/page.tsx"))
        self.assertTrue(gate.glob_to_regex("src/**").match("src/a/b.ts"))
        self.assertFalse(gate.glob_to_regex("src/**").match("lib/src/a.ts"))

    def test_single_star_stays_inside_one_segment(self):
        self.assertTrue(gate.glob_to_regex("src/*.ts").match("src/a.ts"))
        self.assertFalse(gate.glob_to_regex("src/*.ts").match("src/a/b.ts"))
        self.assertTrue(gate.glob_to_regex("**/*Test.*").match("src/test/kotlin/FooTest.kt"))

    def test_other_characters_are_literal(self):
        self.assertTrue(gate.glob_to_regex(".gitleaks.toml").match(".gitleaks.toml"))
        self.assertFalse(gate.glob_to_regex(".gitleaks.toml").match("xgitleaksxtoml"))

    def test_a_bang_pattern_takes_paths_out_again(self):
        paths = gate.PathSet(["src/**", "!**/*.test.ts"])
        self.assertTrue(paths.matches("src/a.ts"))
        self.assertFalse(paths.matches("src/a.test.ts"))
        self.assertFalse(gate.PathSet(["!src/**"]).matches("src/a.ts"))

    def test_a_rename_is_reported_under_its_new_path(self):
        parsed = gate.parse_name_status("A\tsrc/new.ts\nR087\tsrc/old.ts\tsrc/moved.ts\nD\tsrc/gone.ts\n")
        self.assertEqual([(c.status, c.path) for c in parsed],
                         [("A", "src/new.ts"), ("R", "src/moved.ts"), ("D", "src/gone.ts")])


class Evidence(unittest.TestCase):
    def test_owed_and_present(self):
        d = run(rules(evidence()), changes("M src/a.ts", "M src/a.test.ts"))
        self.assertEqual(state(d, "unit-test").state, "present")
        self.assertEqual(state(d, "unit-test").evidence, ["src/a.test.ts"])
        self.assertEqual(d.next, "review")
        self.assertEqual(d.reviewers, ["reviewer"])

    def test_owed_and_missing_sends_it_back_to_the_author(self):
        d = run(rules(evidence()), changes("M src/a.ts"))
        self.assertEqual(state(d, "unit-test").state, "missing")
        self.assertEqual(d.next, "back-to-author")

    def test_a_waiver_lets_it_through_and_keeps_the_reason_for_the_reviewer(self):
        d = run(rules(evidence()), changes("M src/a.ts"), waivers=gate.parse_waivers("- Waive unit-test: rename only"))
        self.assertEqual(state(d, "unit-test").state, "waived")
        self.assertIn("rename only", state(d, "unit-test").reason)
        self.assertEqual(d.next, "review")

    def test_a_waiver_for_another_item_does_not_count(self):
        d = run(rules(evidence()), changes("M src/a.ts"), waivers=gate.parse_waivers("Waive journey-test: no page"))
        self.assertEqual(state(d, "unit-test").state, "missing")

    def test_not_owed_when_no_path_matches(self):
        d = run(rules(evidence()), changes("M README.txt"))
        self.assertEqual(state(d, "unit-test").state, "not-owed")
        self.assertEqual(d.next, "review")

    def test_a_deleted_test_file_is_not_evidence(self):
        d = run(rules(evidence()), changes("M src/a.ts", "D src/a.test.ts"))
        self.assertEqual(state(d, "unit-test").state, "missing")

    def test_added_only_fires_for_new_files(self):
        item = evidence(id="journey", owed_when={"added": ["**/page.tsx"]}, satisfied_by=["tests/e2e/**"])
        self.assertEqual(state(run(rules(item), changes("M src/app/x/page.tsx")), "journey").state, "not-owed")
        self.assertEqual(state(run(rules(item), changes("A src/app/x/page.tsx")), "journey").state, "missing")
        both = run(rules(item), changes("A src/app/x/page.tsx", "M tests/e2e/pages.spec.ts"))
        self.assertEqual(state(both, "journey").state, "present")

    def test_ignored_files_make_nothing_owed(self):
        d = run(rules(evidence(), ignore=["src/generated/**"]), changes("M src/generated/api.ts"))
        self.assertEqual(state(d, "unit-test").state, "not-owed")


class Judge(unittest.TestCase):
    def test_the_path_rule_decides_without_asking(self):
        asked = []
        d = run(rules(review()), changes("M src/auth/login.ts"), judge=lambda q: asked.append(q) or 0.0)
        self.assertEqual(state(d, "security-review").state, "owed")
        self.assertEqual(asked, [])
        self.assertEqual(d.reviewers, ["reviewer", "security-review"])

    def test_the_judge_decides_the_unclear_rest(self):
        seen = []

        def judge(q):
            seen.append(q)
            return 0.81

        d = run(rules(review()), changes("M src/orders/export.ts", "M src/orders/export.test.ts"), judge=judge)
        item = state(d, "security-review")
        self.assertEqual((item.state, item.probability), ("owed", 0.81))
        self.assertEqual(seen[0]["id"], "security-review")
        self.assertEqual(seen[0]["criteria"], {"true": "It does.", "false": "It does not."})
        self.assertEqual(seen[0]["input"]["changed_files"], "src/orders/export.ts")
        self.assertEqual(seen[0]["input"]["diff"], "diff of src/orders/export.ts")

    def test_below_the_threshold_it_is_not_owed(self):
        d = run(rules(review()), changes("M src/orders/export.ts"), judge=lambda q: 0.1)
        self.assertEqual(state(d, "security-review").state, "not-owed")
        self.assertEqual(d.reviewers, ["reviewer"])

    def test_at_the_threshold_it_is_owed(self):
        d = run(rules(review()), changes("M src/orders/export.ts"), judge=lambda q: 0.3)
        self.assertEqual(state(d, "security-review").state, "owed")

    def test_no_answer_takes_the_stricter_route(self):
        for bad in (lambda q: None, lambda q: 1.7, lambda q: "yes", lambda q: True, lambda q: 1 / 0):
            d = run(rules(review()), changes("M src/orders/export.ts"), judge=bad)
            self.assertEqual(state(d, "security-review").state, "owed")
            self.assertIn("counts as owed", state(d, "security-review").reason)

    def test_without_a_judge_only_the_path_rules_apply(self):
        d = run(rules(review()), changes("M src/orders/export.ts"))
        self.assertEqual(state(d, "security-review").state, "not-asked")
        self.assertEqual(d.reviewers, ["reviewer"])

    def test_no_question_when_no_candidate_file_changed(self):
        asked = []
        d = run(rules(review()), changes("M src/orders/export.test.ts"), judge=lambda q: asked.append(q) or 1.0)
        self.assertEqual(state(d, "security-review").state, "not-owed")
        self.assertEqual(asked, [])

    def test_an_input_too_large_to_send_counts_as_owed(self):
        asked = []
        d = run(rules(review(), max_input_chars=10), changes("M src/orders/export.ts"),
                judge=lambda q: asked.append(q) or 0.0)
        self.assertEqual(state(d, "security-review").state, "owed")
        self.assertEqual(asked, [])

    def test_past_the_question_limit_items_count_as_owed(self):
        second = review(id="second", owed_when={"ask": dict(ASK)})
        asked = []
        d = run(rules(review(), second), changes("M src/orders/export.ts"),
                judge=lambda q: asked.append(q["id"]) or 0.0, max_questions=1)
        self.assertEqual(asked, ["security-review"])
        self.assertEqual(state(d, "security-review").state, "not-owed")
        self.assertEqual(state(d, "second").state, "owed")


class Routes(unittest.TestCase):
    def test_an_approval_item_asks_for_a_person_and_does_not_stop_the_review(self):
        item = {"id": "model-run", "title": "Live model run", "kind": "approval",
                "owed_when": {"changed": ["prompts/**"]}}
        d = run(rules(item), changes("M prompts/summary.md"))
        self.assertTrue(d.needs_human)
        self.assertEqual(d.next, "review")

    def test_the_same_reviewer_is_named_once(self):
        other = review(id="stored-data", owed_when={"changed": ["src/auth/**"]})
        d = run(rules(review(), other), changes("M src/auth/login.ts"))
        self.assertEqual(d.reviewers, ["reviewer", "security-review"])

    def test_missing_evidence_wins_over_reviewers(self):
        d = run(rules(evidence(), review()), changes("M src/auth/login.ts"))
        self.assertEqual(d.next, "back-to-author")

    def test_items_of_the_other_handover_are_left_out(self):
        brief_item = {"id": "architect-pass", "title": "Architect pass", "kind": "review", "reviewer": "architect",
                      "handover": "brief-to-code",
                      "owed_when": {"ask": {"about": "brief", "question": "q", "true": "t", "false": "f"}}}
        d = run(rules(evidence(), brief_item), changes("M src/a.ts", "M src/a.test.ts"))
        self.assertEqual([i.id for i in d.items], ["unit-test"])


class Brief(unittest.TestCase):
    ITEMS = [
        {"id": "brief-testable", "title": "A check that can be run", "kind": "evidence", "handover": "brief-to-code",
         "owed_when": {"ask": {"about": "brief", "question": "lacks a check?", "true": "t", "false": "f"}}},
        {"id": "architect-pass", "title": "Architect pass", "kind": "review", "reviewer": "architect",
         "handover": "brief-to-code",
         "owed_when": {"ask": {"about": "brief", "question": "stored data?", "true": "t", "false": "f"}}},
    ]

    def test_the_brief_is_what_the_judge_reads(self):
        seen = []
        d = run(rules(*self.ITEMS), [], judge=lambda q: seen.append(q) or 0.0, handover="brief-to-code",
                brief="Goal: x")
        self.assertEqual(seen[0]["input"], {"brief": "Goal: x"})
        self.assertEqual(d.next, "code")
        self.assertEqual(d.reviewers, [])

    def test_a_brief_without_a_check_goes_back(self):
        d = run(rules(*self.ITEMS), [], judge=lambda q: 0.9 if q["id"] == "brief-testable" else 0.0,
                handover="brief-to-code", brief="Goal: x")
        self.assertEqual(d.next, "back-to-author")

    def test_the_architect_is_named_when_the_brief_asks_for_one(self):
        d = run(rules(*self.ITEMS), [], judge=lambda q: 0.9 if q["id"] == "architect-pass" else 0.0,
                handover="brief-to-code", brief="Goal: x")
        self.assertEqual((d.next, d.reviewers), ("review", ["architect"]))

    def test_no_brief_means_nothing_to_ask(self):
        d = run(rules(*self.ITEMS), [], judge=lambda q: 1.0, handover="brief-to-code", brief="  ")
        self.assertEqual({i.state for i in d.items}, {"not-owed"})


class RulesFile(unittest.TestCase):
    def bad(self, item, message):
        with self.assertRaises(gate.RulesError) as caught:
            rules(item)
        self.assertIn(message, str(caught.exception))

    def test_a_misspelt_field_is_an_error_not_a_silent_no(self):
        self.bad(evidence(satisfiedBy=["x"]), "unknown field(s) satisfiedBy")
        self.bad(evidence(owed_when={"change": ["src/**"]}), "unknown field(s) change")

    def test_each_kind_has_its_own_fields(self):
        self.bad(evidence(kind="test"), "kind must be one of")
        self.bad(review(reviewer=None), "names its 'reviewer'")
        self.bad(evidence(reviewer="x"), "only a review item has a 'reviewer'")
        self.bad(review(satisfied_by=["x"]), "only an evidence item has 'satisfied_by'")

    def test_a_question_needs_its_criteria_and_its_paths(self):
        self.bad(review(owed_when={"ask": {"question": "q", "true": "t"}}), "'false' is required")
        self.bad(review(owed_when={"ask": {"question": "q", "true": "t", "false": "f"}}), "'paths' says which")
        self.bad(review(owed_when={"ask": dict(ASK, threshold=0)}), "threshold must be")

    def test_a_brief_rule_cannot_use_path_rules(self):
        self.bad(evidence(handover="brief-to-code"), "there is no diff yet")

    def test_duplicate_ids_are_refused(self):
        with self.assertRaises(gate.RulesError):
            rules(evidence(), evidence())

    def test_the_starter_rules_load(self):
        starter = gate.load_rules(HERE.parent / "templates" / "rules.json")
        self.assertGreaterEqual(len(starter.items), 8)
        self.assertEqual({i.handover for i in starter.items}, set(gate.HANDOVERS))


class Waivers(unittest.TestCase):
    def test_lines_are_read_with_or_without_a_bullet(self):
        text = "Some text\n- Waive unit-test: rename only\nwaive journey-test:   the page is behind a flag  \n"
        self.assertEqual(gate.parse_waivers(text),
                         {"unit-test": "rename only", "journey-test": "the page is behind a flag"})

    def test_a_waiver_needs_a_reason(self):
        self.assertEqual(gate.parse_waivers("Waive unit-test:\nWaive unit-test"), {})


class Output(unittest.TestCase):
    def test_the_block_names_what_is_missing_and_what_comes_next(self):
        d = run(rules(evidence(), review()), changes("M src/orders/export.ts"), judge=lambda q: 0.81)
        text = gate.render_markdown(d)
        self.assertIn("### Owed by this change", text)
        self.assertIn("- Unit test: **MISSING**. Path rule: src/orders/export.ts.", text)
        self.assertIn("- Security review: owed. Judge: p=0.81, at or above 0.3.", text)
        self.assertIn("**Next: back to the author** (unit-test).", text)

    def test_items_that_are_not_owed_share_one_line(self):
        d = run(rules(evidence(), review()), changes("M notes.txt"))
        text = gate.render_markdown(d)
        self.assertIn("- Not owed: Unit test, Security review", text)
        self.assertIn("**Next: review by** reviewer.", text)

    def test_json_carries_the_same_decision(self):
        d = run(rules(evidence()), changes("M src/a.ts"))
        data = json.loads(json.dumps(d.to_json()))
        self.assertEqual(data["next"], "back-to-author")
        self.assertEqual(data["items"][0]["state"], "missing")


class CommandLine(unittest.TestCase):
    """The whole path: a real git repository, the rules file, and a judge that is a separate program."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = pathlib.Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        (self.repo / "src").mkdir()
        (self.repo / "src" / "a.ts").write_text("export const a = 1;\n")
        (self.repo / "rules.json").write_text(json.dumps({"items": [evidence(), review()]}))
        self.git("add", ".")
        self.git("commit", "-q", "-m", "start")
        self.git("checkout", "-q", "-b", "change")

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True)

    def judge(self, body):
        path = self.repo / "judge.py"
        path.write_text(textwrap.dedent(body))
        return f"{sys.executable} {path}"

    def gate(self, *args):
        return subprocess.run(
            [sys.executable, str(HERE / "handover_gate.py"), "--repo", str(self.repo), "--rules",
             str(self.repo / "rules.json"), "--base", "main", *args],
            capture_output=True, text=True)

    def commit(self, name, text):
        target = self.repo / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        self.git("add", ".")
        self.git("commit", "-q", "-m", name)

    def test_a_change_with_its_test_goes_to_review(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        self.commit("src/a.test.ts", "test('a', () => {});\n")
        done = self.gate("--format", "json")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertEqual(json.loads(done.stdout)["next"], "review")

    def test_only_the_change_since_the_branch_point_counts(self):
        self.commit("src/a.test.ts", "test('a', () => {});\n")
        self.git("checkout", "-q", "main")
        self.commit("src/auth/login.ts", "export const login = 1;\n")
        self.git("checkout", "-q", "change")
        data = json.loads(self.gate("--format", "json").stdout)
        self.assertEqual({i["id"]: i["state"] for i in data["items"]},
                         {"unit-test": "not-owed", "security-review": "not-owed"})

    def test_missing_evidence_exits_zero_unless_asked_to_fail(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        self.assertEqual(self.gate().returncode, 0)
        self.assertEqual(self.gate("--fail-on-missing").returncode, 1)

    def test_the_judge_program_gets_the_question_and_the_diff(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        cmd = self.judge("""
            import json, sys
            q = json.load(sys.stdin)
            ok = q["id"] == "security-review" and "export const a = 2" in q["input"]["diff"]
            print(json.dumps({"probability": 0.9 if ok else 0.0}))
        """)
        data = json.loads(self.gate("--format", "json", "--judge-cmd", cmd).stdout)
        self.assertEqual(data["reviewers"], ["reviewer", "security-review"])

    def test_a_judge_program_that_fails_takes_the_stricter_route(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        for body in ("import sys; sys.exit(3)", "print('not json')", "print('{\"probability\": \"high\"}')"):
            data = json.loads(self.gate("--format", "json", "--judge-cmd", self.judge(body)).stdout)
            self.assertEqual(data["reviewers"], ["reviewer", "security-review"], body)

    def test_waivers_are_read_from_the_pull_request_text(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        body = self.repo / "pr.md"
        body.write_text("## Brief\n\nWaive unit-test: constant only\n")
        data = json.loads(self.gate("--format", "json", "--waivers-from", str(body)).stdout)
        self.assertEqual(data["next"], "review")

    def test_a_file_that_is_not_there_is_reported_and_exits_two(self):
        done = self.gate("--waivers-from", str(self.repo / "nowhere.md"))
        self.assertEqual(done.returncode, 2)
        self.assertIn("nowhere.md", done.stderr)

    def test_a_base_that_does_not_exist_is_reported_and_exits_two(self):
        done = subprocess.run(
            [sys.executable, str(HERE / "handover_gate.py"), "--repo", str(self.repo), "--rules",
             str(self.repo / "rules.json"), "--base", "no-such-branch"], capture_output=True, text=True)
        self.assertEqual(done.returncode, 2)
        self.assertIn("git could not compare no-such-branch and HEAD", done.stderr)

    def test_a_broken_rules_file_is_reported_and_exits_two(self):
        (self.repo / "rules.json").write_text('{"items": [{"id": "x"}]}')
        done = self.gate()
        self.assertEqual(done.returncode, 2)
        self.assertIn("'title' is required", done.stderr)


if __name__ == "__main__":
    unittest.main()
