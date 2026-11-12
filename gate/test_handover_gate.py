"""Tests for the handover gate. Run: python3 -m unittest discover -s gate -p 'test_*.py'"""
import json
import os
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


def state_of(decision_json, item_id):
    return next(i for i in decision_json["items"] if i["id"] == item_id)


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

    def test_a_line_break_in_a_name_does_not_hide_the_file(self):
        # A file name may hold any character but NUL. "." and "$" stop at a line break unless told otherwise.
        self.assertTrue(gate.glob_to_regex("src/auth/**").match("src/auth/x\ny/route.ts"))
        self.assertTrue(gate.glob_to_regex("**/*.ts").match("src/x\ny/route.ts"))
        self.assertTrue(gate.glob_to_regex(".github/workflows/**").match(".github/workflows/a\nb.yml"))
        self.assertFalse(gate.glob_to_regex("src/a.ts").match("src/a.ts\n"))

    def test_a_bang_pattern_takes_paths_out_again(self):
        paths = gate.PathSet(["src/**", "!**/*.test.ts"])
        self.assertTrue(paths.matches("src/a.ts"))
        self.assertFalse(paths.matches("src/a.test.ts"))
        self.assertFalse(gate.PathSet(["!src/**"]).matches("src/a.ts"))

    def test_a_rename_is_reported_under_both_its_paths(self):
        parsed = gate.parse_name_status("A\tsrc/new.ts\nR087\tsrc/old.ts\tsrc/moved.ts\nD\tsrc/gone.ts\n")
        self.assertEqual([(c.status, c.path) for c in parsed],
                         [("A", "src/new.ts"), ("D", "src/old.ts"), ("R", "src/moved.ts"), ("D", "src/gone.ts")])

    def test_a_copy_is_reported_under_its_new_path_only(self):
        parsed = gate.parse_name_status("C075\tsrc/a.ts\tsrc/b.ts\n")
        self.assertEqual([(c.status, c.path) for c in parsed], [("C", "src/b.ts")])

    def test_the_nul_form_keeps_every_path_as_it_is(self):
        parsed = gate.parse_name_status('A\0src/auth/tok\u00e9n.ts\0R087\0src/old "a".ts\0src/new\\b.ts\0'
                                        "C075\0src/a.ts\0src/b\tc.ts\0D\0src/gone.ts\0")
        self.assertEqual([(c.status, c.path) for c in parsed],
                         [("A", "src/auth/tok\u00e9n.ts"), ("D", 'src/old "a".ts'), ("R", "src/new\\b.ts"),
                          ("C", "src/b\tc.ts"), ("D", "src/gone.ts")])
        self.assertEqual(gate.parse_name_status(""), [])


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

    def test_a_reported_run_counts_where_the_rule_allows_it(self):
        ran = gate.parse_runs("Ran unit-test: the start-up suite passes on this commit")
        d = run(rules(evidence(run_counts=True)), changes("M src/a.ts"), runs=ran)
        self.assertEqual(state(d, "unit-test").state, "ran")
        self.assertIn("the start-up suite passes on this commit", state(d, "unit-test").reason)
        self.assertEqual(d.next, "review")

    def test_a_reported_run_does_not_count_where_the_rule_is_silent(self):
        ran = gate.parse_runs("Ran unit-test: the start-up suite passes on this commit")
        d = run(rules(evidence()), changes("M src/a.ts"), runs=ran)
        self.assertEqual(state(d, "unit-test").state, "missing")
        self.assertEqual(d.next, "back-to-author")

    def test_a_changed_test_file_comes_before_a_reported_run(self):
        ran = gate.parse_runs("Ran unit-test: by hand")
        d = run(rules(evidence(run_counts=True)), changes("M src/a.ts", "M src/a.test.ts"), runs=ran)
        self.assertEqual(state(d, "unit-test").state, "present")

    def test_an_item_with_no_file_evidence_can_be_met_by_a_run_alone(self):
        item = evidence(id="script-run", owed_when={"changed": ["deploy/**"]}, run_counts=True)
        del item["satisfied_by"]
        self.assertEqual(state(run(rules(item), changes("M deploy/backup.sh")), "script-run").state, "missing")
        ran = gate.parse_runs("- Ran script-run: `backup.sh --dry-run` against staging, printed the three steps")
        self.assertEqual(state(run(rules(item), changes("M deploy/backup.sh"), runs=ran), "script-run").state, "ran")


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

    def test_a_judge_can_say_why_it_has_no_answer(self):
        def judge(q):
            raise gate.NoAnswer("the key was rejected (HTTP 401)")

        d = run(rules(review()), changes("M src/orders/export.ts"), judge=judge)
        item = state(d, "security-review")
        self.assertEqual(item.state, "owed")
        self.assertEqual(item.reason, "judge gave no answer (the key was rejected (HTTP 401)), so it counts as owed")
        self.assertIn("Judge gave no answer (the key was rejected (HTTP 401))", gate.render_markdown(d))

    def test_a_long_reason_is_cut_to_its_last_line(self):
        def judge(q):
            raise gate.NoAnswer("Traceback (most recent call last):\n  File x\nboom " + "y" * 400)

        reason = state(run(rules(review()), changes("M src/orders/export.ts"), judge=judge), "security-review").reason
        self.assertNotIn("Traceback", reason)
        self.assertIn("(boom yyy", reason)
        self.assertLess(len(reason), gate.MAX_REASON_CHARS + 60)

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

    def test_a_diff_too_large_for_one_question_is_asked_about_in_parts(self):
        asked = []
        d = run(rules(review(), max_input_chars=55), changes("M src/c.ts", "M src/a.ts", "M src/b.ts"),
                judge=lambda q: asked.append(q["input"]["changed_files"]) or 0.1)
        self.assertEqual(asked, ["src/a.ts\nsrc/b.ts", "src/c.ts"])
        item = state(d, "security-review")
        self.assertEqual((item.state, item.probability), ("not-owed", 0.1))
        self.assertIn("over 2 parts", item.reason)

    def test_one_part_at_the_threshold_makes_it_owed_and_ends_the_asking(self):
        asked = []
        d = run(rules(review(), max_input_chars=30), changes("M src/a.ts", "M src/b.ts", "M src/c.ts"),
                judge=lambda q: asked.append(q["input"]["changed_files"]) or (0.9 if "b.ts" in asked[-1] else 0.0))
        self.assertEqual(asked, ["src/a.ts", "src/b.ts"])
        self.assertEqual(state(d, "security-review").state, "owed")
        self.assertIn("part 2 of 3 (src/b.ts)", state(d, "security-review").reason)

    def test_no_answer_on_a_part_counts_as_owed(self):
        d = run(rules(review(), max_input_chars=30), changes("M src/a.ts", "M src/b.ts"), judge=lambda q: None)
        self.assertEqual(state(d, "security-review").state, "owed")
        self.assertIn("part 1 of 2", state(d, "security-review").reason)

    def test_more_parts_than_allowed_counts_as_owed_without_asking(self):
        asked = []
        many = changes(*[f"M src/{name}.ts" for name in "abcde"])
        d = run(rules(review(), max_input_chars=30), many, judge=lambda q: asked.append(q) or 0.0)
        self.assertEqual(state(d, "security-review").state, "owed")
        self.assertIn("in 4 parts", state(d, "security-review").reason)
        self.assertEqual(asked, [])

    def test_the_parts_of_one_item_count_towards_the_question_limit(self):
        asked = []
        d = run(rules(review(), max_input_chars=30), changes("M src/a.ts", "M src/b.ts"),
                judge=lambda q: asked.append(q) or 0.0, max_questions=1)
        self.assertEqual(len(asked), 1)
        self.assertEqual(state(d, "security-review").state, "owed")

    def test_past_the_question_limit_items_count_as_owed(self):
        second = review(id="second", owed_when={"ask": dict(ASK)})
        asked = []
        d = run(rules(review(), second), changes("M src/orders/export.ts"),
                judge=lambda q: asked.append(q["id"]) or 0.0, max_questions=1)
        self.assertEqual(asked, ["security-review"])
        self.assertEqual(state(d, "security-review").state, "not-owed")
        self.assertEqual(state(d, "second").state, "owed")


class UnreadableDiff(unittest.TestCase):
    def test_a_diff_that_cannot_be_read_counts_as_owed(self):
        def broken(paths):
            raise subprocess.CalledProcessError(128, ["git", "diff"])
        d = gate.decide(rules(review()), "code-to-review", changes("M src/orders/total.ts"), broken, lambda q: 0.0)
        item = state(d, "security-review")
        self.assertEqual(item.state, "owed")
        self.assertEqual(item.reason, "the diff could not be read to ask the judge, so it counts as owed")

    def test_a_changed_file_with_no_diff_counts_as_owed(self):
        # The judge would answer 0.0 about nothing at all, and the item would pass on a diff nobody read.
        d = gate.decide(rules(review()), "code-to-review", changes("M src/orders/total.ts"), lambda paths: "\n",
                        lambda q: 0.0)
        item = state(d, "security-review")
        self.assertEqual(item.state, "owed")
        self.assertEqual(item.reason, "git gave no diff for a changed file (src/orders/total.ts), so it counts as owed")

    def test_a_file_whose_name_is_not_utf8_counts_as_owed(self):
        # Its odd bytes were replaced when the name was read, so git finds no file of that name and gives no diff
        # for it. Beside a readable file the missing part would not show.
        asked = []
        d = run(rules(review()), changes("M src/orders/total.ts", "A src/orders/caf\ufffd.ts"),
                judge=lambda q: asked.append(q) or 0.0)
        item = state(d, "security-review")
        self.assertEqual(item.state, "owed")
        self.assertIn("the name of a changed file is not UTF-8 (src/orders/caf\ufffd.ts)", item.reason)
        self.assertEqual(asked, [])

    def test_a_part_that_cannot_be_read_counts_as_owed_too(self):
        # Together the two files are too large for one question, so each is read on its own.
        big = lambda paths: "" if paths == ["src/b.ts"] else "x" * 300 * len(paths)
        d = gate.decide(rules(review(), max_input_chars=400), "code-to-review",
                        changes("M src/a.ts", "M src/b.ts"), big, lambda q: 0.0)
        item = state(d, "security-review")
        self.assertEqual(item.state, "owed")
        self.assertIn("git gave no diff for a changed file (src/b.ts)", item.reason)


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


def code_review(**over):
    """The rule that names the standard reviewer: with it in the rules, it decides which changes the reviewer reads."""
    item = {
        "id": "code-review",
        "title": "Code review",
        "kind": "review",
        "reviewer": "reviewer",
        "owed_when": {"changed": ["src/billing/**", "migrations/**", "!**/*.test.ts"]},
    }
    item.update(over)
    return item


class ReviewerByRule(unittest.TestCase):
    def test_without_a_rule_for_it_the_reviewer_reads_every_change(self):
        d = run(rules(evidence()), changes("M src/a.ts", "M src/a.test.ts"))
        self.assertEqual((d.next, d.reviewers), ("review", ["reviewer"]))

    def test_its_rule_sends_a_change_in_a_listed_place_to_the_reviewer(self):
        d = run(rules(evidence(), code_review()), changes("M src/billing/invoice.ts", "M src/billing/invoice.test.ts"))
        self.assertEqual((d.next, d.reviewers), ("review", ["reviewer"]))
        self.assertIn("- Code review: owed. Path rule: src/billing/invoice.ts.", gate.render_markdown(d))

    def test_a_change_outside_the_listed_places_goes_on_as_ready(self):
        d = run(rules(evidence(), code_review()), changes("M src/ui/button.ts", "M src/ui/button.test.ts"))
        self.assertEqual((d.next, d.reviewers, d.notes), ("ready", [], []))
        text = gate.render_markdown(d)
        self.assertIn("- Not owed: Code review", text)
        self.assertIn("**Next: ready.** No reviewer is owed.", text)
        self.assertNotIn("review by", text)

    def test_another_reviewer_can_be_owed_without_the_standard_one(self):
        d = run(rules(code_review(), review()), changes("M src/auth/login.ts"))
        self.assertEqual((d.next, d.reviewers), ("review", ["security-review"]))

    def test_the_standard_reviewer_is_named_first(self):
        d = run(rules(review(), code_review(owed_when={"changed": ["src/**"]})), changes("M src/auth/login.ts"))
        self.assertEqual(d.reviewers, ["reviewer", "security-review"])

    def test_a_waiver_brings_the_reviewer_in_to_judge_it(self):
        d = run(rules(evidence(), code_review()), changes("M src/ui/button.ts"), waivers={"unit-test": "a rename"})
        self.assertEqual((d.next, d.reviewers), ("review", ["reviewer"]))
        self.assertEqual(d.notes, ["The reviewer is on the route to judge what the author wrote for unit-test."])
        self.assertIn("The reviewer is on the route to judge what the author wrote for unit-test.",
                      gate.render_markdown(d))

    def test_a_reported_run_brings_the_reviewer_in_too(self):
        script = evidence(id="script-run", title="Run of a changed script", owed_when={"changed": ["deploy/**"]},
                          run_counts=True)
        d = run(rules(script, code_review()), changes("M deploy/backup.sh"), runs={"script-run": "dry run"})
        self.assertEqual((d.next, d.reviewers), ("review", ["reviewer"]))
        self.assertIn("script-run", d.notes[0])

    def test_missing_evidence_still_goes_back_to_the_author(self):
        d = run(rules(evidence(), code_review()), changes("M src/ui/button.ts"))
        self.assertEqual((d.next, d.reviewers), ("back-to-author", []))

    def test_a_person_can_still_be_asked_for_when_no_reviewer_is(self):
        approval = {"id": "model-run", "title": "Live model run", "kind": "approval",
                    "owed_when": {"changed": ["prompts/**"]}}
        d = run(rules(approval, code_review()), changes("M prompts/summary.md"))
        self.assertEqual((d.next, d.needs_human), ("ready", True))
        self.assertIn("**Needs human approval**", gate.render_markdown(d))

    def test_a_rule_for_the_brief_handover_does_not_decide_the_code_review(self):
        brief_item = {"id": "plan-read", "title": "A read of the plan", "kind": "review", "reviewer": "reviewer",
                      "handover": "brief-to-code",
                      "owed_when": {"ask": {"about": "brief", "question": "q", "true": "t", "false": "f"}}}
        d = run(rules(evidence(), brief_item), changes("M src/a.ts", "M src/a.test.ts"))
        self.assertEqual(d.reviewers, ["reviewer"])

    def test_the_judge_can_decide_the_unclear_rest_for_the_reviewer(self):
        ask = dict(ASK, threshold=0.5)
        item = code_review(owed_when={"changed": ["src/billing/**"], "ask": ask})
        yes = run(rules(item), changes("M src/orders/total.ts"), judge=lambda q: 0.7)
        no = run(rules(item), changes("M src/orders/total.ts"), judge=lambda q: 0.2)
        down = run(rules(item), changes("M src/orders/total.ts"), judge=lambda q: None)
        self.assertEqual([d.next for d in (yes, no, down)], ["review", "ready", "review"])

    def test_json_names_the_route_and_its_notes(self):
        d = run(rules(evidence(), code_review()), changes("M src/ui/button.ts"), waivers={"unit-test": "a rename"})
        data = json.loads(json.dumps(d.to_json()))
        self.assertEqual((data["next"], data["reviewers"]), ("review", ["reviewer"]))
        self.assertEqual(len(data["notes"]), 1)


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
        self.bad(review(run_counts=True), "only an evidence item has 'run_counts'")
        self.bad(evidence(run_counts="yes"), "'run_counts' is true or false")

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

    def test_the_starter_rules_ask_for_a_person_when_the_gate_or_its_rules_change(self):
        starter = gate.load_rules(HERE.parent / "templates" / "rules.json")
        for path in (".sdlc/rules.json", ".sdlc/gate/handover_gate.py", ".sdlc/lessons/reviewer.md",
                     ".sdlc/retro/fixes.json", ".claude/settings.json", ".claude/agents/reviewer.md", "CLAUDE.md",
                     "AGENTS.md", ".github/workflows/handover-gate.yml"):
            d = run(starter, changes("M " + path))
            self.assertEqual(state(d, "rules-change").state, "owed", path)
            self.assertTrue(d.needs_human, path)
        for path in (".sdlc/templates/brief.md", ".sdlc/VERSION", "docs/notes.md", "README.md", "docs/CLAUDE.md",
                     ".github/workflows/deploy.yml"):
            self.assertFalse(run(starter, changes("M " + path)).needs_human, path)

    def test_the_templates_name_no_item_and_no_reviewer(self):
        # Their hints show the form of a Waive, Ran and Verdict line. A pull request opened from the template and
        # left as it is must not read as one that waived something or recorded a review.
        for name in ("pull_request_template.md", "brief.md", "CLAUDE.snippet.md"):
            text = (HERE.parent / "templates" / name).read_text(encoding="utf-8")
            self.assertEqual(gate.parse_waivers(text), {}, name)
            self.assertEqual(gate.parse_runs(text), {}, name)
            self.assertEqual(gate.parse_verdicts(text), {}, name)


class Verdicts(unittest.TestCase):
    """A review that ran is recorded in the pull request, and a reviewer with a verdict is not waited for."""

    def test_lines_are_read_like_waivers_by_the_name_of_the_reviewer(self):
        text = ("## Review verdict\n- Verdict reviewer: approve, two notes\n"
                "verdict security-review:   no high-severity finding  \nVerdict architect:\n")
        self.assertEqual(gate.parse_verdicts(text),
                         {"reviewer": "approve, two notes", "security-review": "no high-severity finding"})

    def test_a_verdict_the_reviewer_wrote_itself_is_not_such_a_line(self):
        pasted = '{\n  "verdict": "approve",\n  "blocking_findings": []\n}\nVerdict: no finding.\n'
        self.assertEqual(gate.parse_verdicts(pasted), {})

    def test_a_reviewer_with_a_verdict_is_not_waited_for(self):
        r = rules(code_review(owed_when={"changed": ["src/**"]}), review())
        open_ = run(r, changes("M src/auth/login.ts"))
        half = run(r, changes("M src/auth/login.ts"), verdicts={"reviewer": "approve"})
        self.assertEqual((open_.next, open_.waiting), ("review", ["reviewer", "security-review"]))
        self.assertEqual((half.next, half.reviewers, half.waiting),
                         ("review", ["reviewer", "security-review"], ["security-review"]))
        text = gate.render_markdown(half)
        self.assertIn("**Next: review by** security-review. When one has run, write "
                      "`Verdict <reviewer>: <what it said>` in the pull request", text)
        self.assertIn("Verdict in the pull request: reviewer (approve).", text)

    def test_when_every_owed_review_has_a_verdict_the_change_is_ready(self):
        r = rules(code_review(owed_when={"changed": ["src/**"]}), review())
        d = run(r, changes("M src/auth/login.ts"),
                verdicts={"security-review": "no high-severity finding.", "reviewer": "request changes, fixed in 1a2b3c4"})
        self.assertEqual((d.next, d.waiting), ("ready", []))
        self.assertIn("**Next: ready.** Each review that was owed has a verdict in the pull request: "
                      "reviewer (request changes, fixed in 1a2b3c4), security-review (no high-severity finding). "
                      "The checks and the person who merges decide.", gate.render_markdown(d))

    def test_a_verdict_for_a_reviewer_that_is_not_owed_changes_nothing(self):
        d = run(rules(code_review(), review()), changes("M src/auth/login.ts"), verdicts={"reviewer": "approve"})
        self.assertEqual((d.next, d.waiting, d.verdicts), ("review", ["security-review"], {}))

    def test_a_verdict_does_not_stand_in_for_missing_evidence(self):
        d = run(rules(evidence(), code_review(owed_when={"changed": ["src/**"]})), changes("M src/a.ts"),
                verdicts={"reviewer": "approve"})
        self.assertEqual(d.next, "back-to-author")
        self.assertIn("No reviewer starts yet.", gate.render_markdown(d))

    def test_the_reviewer_that_judges_a_waiver_is_waited_for_until_it_has_a_verdict(self):
        r = rules(evidence(), code_review())
        waived = run(r, changes("M src/ui/button.ts"), waivers={"unit-test": "a rename"})
        judged = run(r, changes("M src/ui/button.ts"), waivers={"unit-test": "a rename"},
                     verdicts={"reviewer": "approve, the waiver holds"})
        self.assertEqual((waived.next, judged.next), ("review", "ready"))

    def test_a_person_is_still_asked_for_when_every_review_has_a_verdict(self):
        approval = {"id": "billing", "title": "Approval of a sensitive change", "kind": "approval",
                    "owed_when": {"changed": ["src/billing/**"]}}
        d = run(rules(approval, code_review()), changes("M src/billing/invoice.ts"), verdicts={"reviewer": "approve"})
        self.assertEqual((d.next, d.needs_human), ("ready", True))
        self.assertIn("**Needs human approval**", gate.render_markdown(d))

    def test_a_review_of_the_brief_is_recorded_the_same_way(self):
        open_ = run(rules(*Brief.ITEMS), [], judge=lambda q: 0.9 if "stored" in q["question"] else 0.0,
                    handover="brief-to-code", brief="Goal: x")
        done = run(rules(*Brief.ITEMS), [], judge=lambda q: 0.9 if "stored" in q["question"] else 0.0,
                   handover="brief-to-code", brief="Goal: x", verdicts={"architect": "approve"})
        self.assertEqual((open_.next, open_.waiting), ("review", ["architect"]))
        self.assertEqual((done.next, done.waiting), ("code", []))
        self.assertIn("Verdict in the pull request: architect (approve).", gate.render_markdown(done))

    def test_a_long_verdict_is_cut_to_one_short_line(self):
        d = run(rules(code_review(owed_when={"changed": ["src/**"]})), changes("M src/a.ts"),
                verdicts={"reviewer": "approve " + "x" * 400})
        line = [l for l in gate.render_markdown(d).splitlines() if l.startswith("**Next: ready.**")][0]
        self.assertLess(len(line), 400)

    def test_json_names_who_is_still_waited_for(self):
        r = rules(code_review(owed_when={"changed": ["src/**"]}), review())
        data = json.loads(json.dumps(run(r, changes("M src/auth/login.ts"), verdicts={"reviewer": "approve"}).to_json()))
        self.assertEqual((data["next"], data["waiting"], data["verdicts"]),
                         ("review", ["security-review"], {"reviewer": "approve"}))


class Waivers(unittest.TestCase):
    def test_lines_are_read_with_or_without_a_bullet(self):
        text = "Some text\n- Waive unit-test: rename only\nwaive journey-test:   the page is behind a flag  \n"
        self.assertEqual(gate.parse_waivers(text),
                         {"unit-test": "rename only", "journey-test": "the page is behind a flag"})

    def test_a_waiver_needs_a_reason(self):
        self.assertEqual(gate.parse_waivers("Waive unit-test:\nWaive unit-test"), {})

    def test_reported_runs_are_read_the_same_way(self):
        text = "We ran the tests.\n- Ran script-run: dry run on staging, three steps printed\nRan unit-test:\n"
        self.assertEqual(gate.parse_runs(text), {"script-run": "dry run on staging, three steps printed"})


class Output(unittest.TestCase):
    def test_the_block_names_what_is_missing_and_what_comes_next(self):
        d = run(rules(evidence(), review()), changes("M src/orders/export.ts"), judge=lambda q: 0.81)
        text = gate.render_markdown(d)
        self.assertIn("### Owed by this change", text)
        self.assertIn("- Unit test: **MISSING**. Path rule: src/orders/export.ts.", text)
        self.assertIn("- Security review: owed. Judge: p=0.81, at or above 0.3.", text)
        self.assertIn("**Next: back to the author** (unit-test).", text)

    def test_the_block_says_where_a_run_would_count(self):
        script = evidence(id="script-run", title="Run of a changed script", owed_when={"changed": ["deploy/**"]},
                          run_counts=True)
        d = run(rules(evidence(), script), changes("M src/a.ts", "M deploy/backup.sh"))
        text = gate.render_markdown(d)
        self.assertIn("**Next: back to the author** (unit-test, script-run).", text)
        self.assertIn("For script-run, a run counts too: `Ran <item>: <what you ran and what it showed>`.", text)
        ran = run(rules(script), changes("M deploy/backup.sh"), runs={"script-run": "dry run on staging"})
        self.assertIn("- Run of a changed script: a run stands in for a changed test, and the reviewer judges it. "
                      "Path rule: deploy/backup.sh. Run reported by the author: dry run on staging.",
                      gate.render_markdown(ran))

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

    def test_enforced_missing_evidence_holds_the_change_and_says_what_is_missing(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        held = self.gate("--enforce")
        self.assertEqual(held.returncode, 1)
        self.assertIn("**Next: back to the author** (unit-test).", held.stdout)
        self.assertIn("held back, owed evidence is missing (unit-test)", held.stderr)

    def test_enforced_a_review_holds_the_change_until_its_verdict_is_in_the_pull_request(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        self.commit("src/a.test.ts", "test('a', () => {});\n")
        text = self.repo / "pull-request.md"
        text.write_text("## Brief\n\nGoal: a is two.\n")
        waiting = self.gate("--enforce", "--pull-request-from", str(text))
        self.assertEqual(waiting.returncode, 1)
        self.assertIn("held back, no verdict in the pull request text for reviewer", waiting.stderr)
        self.assertEqual(self.gate("--pull-request-from", str(text)).returncode, 0)
        self.assertEqual(self.gate("--fail-on-missing", "--pull-request-from", str(text)).returncode, 0)
        text.write_text("## Brief\n\nGoal: a is two.\n\n## Review verdict\n\nVerdict reviewer: approve\n")
        done = self.gate("--enforce", "--pull-request-from", str(text))
        self.assertEqual((done.returncode, done.stderr), (0, ""))
        self.assertIn("**Next: ready.** Each review that was owed has a verdict in the pull request: reviewer (approve).",
                      done.stdout)

    def test_enforced_a_change_that_owes_nothing_passes(self):
        (self.repo / "rules.json").write_text(json.dumps({"items": [evidence(), code_review()]}))
        self.commit("src/a.ts", "export const a = 2;\n")
        self.commit("src/a.test.ts", "test('a', () => {});\n")
        done = self.gate("--enforce")
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("**Next: ready.** No reviewer is owed.", done.stdout)

    def test_enforced_a_brief_that_owes_a_review_holds_until_the_verdict(self):
        (self.repo / "rules.json").write_text(json.dumps({"items": Brief.ITEMS}))
        brief = self.repo / "brief.md"
        brief.write_text("Goal: rewrite the stored orders.\n")
        cmd = self.judge("""
            import json, sys
            q = json.load(sys.stdin)
            print(json.dumps({"probability": 0.9 if q["id"] == "architect-pass" else 0.0}))
        """)
        args = ["--handover", "brief-to-code", "--brief-from", str(brief), "--judge-cmd", cmd, "--enforce"]
        self.assertEqual(self.gate(*args).returncode, 1)
        text = self.repo / "pull-request.md"
        text.write_text("Verdict architect: approve, with one note on the backfill order\n")
        done = self.gate(*args, "--pull-request-from", str(text))
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("**Next: write the code.**", done.stdout)

    def test_enforced_a_gate_that_cannot_run_still_exits_two(self):
        (self.repo / "rules.json").write_text("{not json")
        self.assertEqual(self.gate("--enforce").returncode, 2)

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

    def test_what_a_failing_judge_program_says_reaches_the_block(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        said = "import sys; print('starting', file=sys.stderr); print('the key was rejected', file=sys.stderr); sys.exit(1)"
        cases = (
            (said, [], "Judge gave no answer (the key was rejected)"),
            ("import sys; sys.exit(3)", [], "Judge gave no answer (exit code 3)"),
            ("print('not json')", [], "Judge gave no answer (its output was not JSON with a probability)"),
            ("import time; time.sleep(5)", ["--judge-timeout", "0.2"], "Judge gave no answer (no reply within 0.2 seconds)"),
        )
        for body, extra, expected in cases:
            done = self.gate("--judge-cmd", self.judge(body), *extra)
            self.assertEqual(done.returncode, 0, done.stderr)
            self.assertIn(f"- Security review: owed. {expected}, so it counts as owed.", done.stdout, body)

    def test_a_judge_program_that_cannot_start_is_reported_too(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        done = self.gate("--judge-cmd", str(self.repo / "no-such-judge"))
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn("Judge gave no answer (could not start: ", done.stdout)

    def test_a_file_moved_out_of_a_watched_folder_still_owes_the_review(self):
        self.commit("src/auth/login.ts", "export const login = 1;\nexport const logout = 2;\nexport const who = 3;\n")
        self.git("checkout", "-q", "main")
        self.git("merge", "-q", "change")
        self.git("checkout", "-q", "change")
        (self.repo / "lib").mkdir()
        self.git("mv", "src/auth/login.ts", "lib/login.ts")
        self.git("commit", "-q", "-m", "move")
        data = json.loads(self.gate("--format", "json").stdout)
        review_item = next(i for i in data["items"] if i["id"] == "security-review")
        self.assertEqual((review_item["state"], review_item["reason"]), ("owed", "path rule: src/auth/login.ts"))
        self.assertEqual(data["reviewers"], ["reviewer", "security-review"])

    def test_a_file_with_an_accent_or_a_quote_in_its_name_owes_what_its_folder_owes(self):
        # git prints such a path in quotes and escaped unless asked not to, and no pattern matches that.
        self.commit("src/auth/tok\u00e9n.ts", "export const t = 1;\n")
        self.commit('src/auth/to"ken.ts', "export const t = 2;\n")
        d = json.loads(self.gate("--format", "json").stdout)
        self.assertEqual(state_of(d, "security-review")["state"], "owed")
        self.assertIn("src/auth/to", state_of(d, "security-review")["reason"])
        self.assertEqual(state_of(d, "unit-test")["state"], "missing")

    def test_a_file_named_like_a_pathspec_still_reaches_the_judge_with_its_diff(self):
        (self.repo / "rules.json").write_text(json.dumps({"items": [review(owed_when={"ask": dict(ASK, paths=["**/*.sql"])})]}))
        self.commit(":wipe.sql", "delete from orders;\n")
        judge = self.judge("""
            import json, sys
            q = json.load(sys.stdin)
            print(json.dumps({"probability": 0.9 if "delete from orders" in q["input"]["diff"] else 0.0}))
        """)
        out = self.gate("--judge-cmd", judge).stdout
        self.assertIn("- Security review: owed. Judge: p=0.90, at or above 0.3.", out)

    def test_a_file_in_a_folder_named_with_a_line_break_owes_what_its_folder_owes(self):
        self.commit("src/auth/x\ny/route.ts", "export const r = 1;\n")
        d = json.loads(self.gate("--format", "json").stdout)
        self.assertEqual(state_of(d, "security-review")["state"], "owed")
        self.assertEqual(state_of(d, "unit-test")["state"], "missing")
        # The block keeps one line per item: the line break in the name is written as its escape.
        block = self.gate().stdout
        self.assertIn("- Security review: owed. Path rule: src/auth/x\\ny/route.ts.", block)

    def test_a_source_file_that_git_takes_for_binary_still_reaches_the_judge(self):
        # One NUL byte makes git print "Binary files differ" in place of the change, and so does a "-diff" line
        # in .gitattributes. Either way the judge has to see what was written.
        (self.repo / "rules.json").write_text(json.dumps({"items": [review(owed_when={"ask": dict(ASK)})]}))
        (self.repo / "src" / "nul.ts").write_bytes(b'export const first = "grant-all";\0\n')
        (self.repo / ".gitattributes").write_text("src/marked.ts -diff\n")
        self.commit("src/marked.ts", 'export const second = "skip-check";\n')
        judge = self.judge("""
            import json, sys
            diff = json.load(sys.stdin)["input"]["diff"]
            print(json.dumps({"probability": 0.9 if "grant-all" in diff and "skip-check" in diff else 0.0}))
        """)
        out = self.gate("--judge-cmd", judge).stdout
        self.assertIn("- Security review: owed. Judge: p=0.90, at or above 0.3.", out)

    def test_a_file_whose_name_is_not_utf8_counts_as_owed_and_is_not_asked_about(self):
        (self.repo / "rules.json").write_text(json.dumps({"items": [review(owed_when={"ask": dict(ASK)})]}))
        try:
            with open(os.path.join(os.fsencode(self.repo), b"src", b"caf\xe9.ts"), "wb") as f:
                f.write(b"export const c = 1;\n")
        except OSError:
            self.skipTest("this file system takes only UTF-8 names")
        self.commit("src/b.ts", "export const b = 1;\n")
        judge = self.judge("""
            import json, sys
            json.load(sys.stdin)
            print(json.dumps({"probability": 0.0}))
        """)
        out = self.gate("--judge-cmd", judge).stdout
        self.assertIn("- Security review: owed. The name of a changed file is not UTF-8", out)

    def test_a_file_that_is_not_utf8_does_not_stop_the_gate(self):
        target = self.repo / "src" / "latin1.ts"
        target.write_bytes("export const caf\u00e9 = 1;\n".encode("latin-1"))
        self.git("add", ".")
        self.git("commit", "-q", "-m", "latin1")
        judge = self.judge("""
            import json, sys
            json.load(sys.stdin)
            print(json.dumps({"probability": 0.9}))
        """)
        result = self.gate("--judge-cmd", judge)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("- Security review: owed. Judge: p=0.90", result.stdout)

    def test_waivers_are_read_from_the_pull_request_text(self):
        self.commit("src/a.ts", "export const a = 2;\n")
        body = self.repo / "pr.md"
        body.write_text("## Brief\n\nWaive unit-test: constant only\n")
        data = json.loads(self.gate("--format", "json", "--waivers-from", str(body)).stdout)
        self.assertEqual(data["next"], "review")

    def test_a_reported_run_is_read_from_the_pull_request_text(self):
        (self.repo / "rules.json").write_text(json.dumps({"items": [evidence(run_counts=True)]}))
        self.commit("src/a.ts", "export const a = 2;\n")
        body = self.repo / "pr.md"
        body.write_text("## Brief\n\nRan unit-test: the existing suite covers the constant, 41 pass\n")
        data = json.loads(self.gate("--format", "json", "--pull-request-from", str(body)).stdout)
        self.assertEqual((data["next"], data["items"][0]["state"]), ("review", "ran"))

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
