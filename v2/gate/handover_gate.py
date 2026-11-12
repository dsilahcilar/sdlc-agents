#!/usr/bin/env python3
"""Handover gate: works out what a change owes before it moves on, and where it goes next.

The agent that did the work must not be the one that decides how much checking the work gets. This script
makes that decision instead, from rules kept as data (rules.json). For every item in the rules it answers:

  1. Is it owed?   Path rules decide what they can decide exactly. For the unclear rest, one factual yes/no
                   question goes to a judge: any program that returns a probability. When the judge gives no
                   answer the item counts as owed, so a failed call never lowers the scrutiny. With no judge
                   configured, only the path rules apply and the question is reported as not asked.
  2. Is it there?  For an "evidence" item (a kind of test, a contract file): did the change touch a file in
                   the place such evidence lives? If not, the author adds it, reports a run where the rule
                   lets a run count, or waives it in one line, and the reviewer judges that line.

The output is the list "Owed by this change" and the next step: back to the author while evidence is missing,
otherwise on to the reviewers the list names, plus a human approval when a rule asks for one.

The standard reviewer reads every change, until a rule of yours names it. From then on that rule decides which
changes it reads, like any other review item, and a change that no reviewer is owed goes on as ready. A waiver
or a reported run still brings the reviewer in, because someone other than the author has to judge that line.

The gate routes. It does not judge quality, and it can add checking but never remove a human approval.
See ../docs/gates.md for the design, the rules reference and the judge protocol.

Usage:
  handover_gate.py --base <ref> --head <ref> [--rules .sdlc/rules.json] [--judge-cmd "<command>"]
                   [--pull-request-from FILE] [--format markdown|json]
  handover_gate.py --handover brief-to-code --brief-from FILE [--judge-cmd "<command>"]

Exits 0 whatever it decides: the decision is the output. --fail-on-missing makes missing evidence exit 1.
Python 3.8+, standard library only.
"""
from __future__ import annotations

import argparse
import dataclasses
import json
import pathlib
import re
import shlex
import subprocess
import sys
from typing import Callable, Dict, List, Optional, Sequence, Tuple

HANDOVERS = ("brief-to-code", "code-to-review")
KINDS = ("evidence", "review", "approval")
ABOUT = ("diff", "brief")
DEFAULT_THRESHOLD = 0.5
DEFAULT_MAX_INPUT_CHARS = 40_000
DEFAULT_MAX_QUESTIONS = 8
# The reviewer that reads every change unless a review item names it. Then that item decides.
STANDARD_REVIEWER = "reviewer"
# A diff too large for one question is asked about in parts, up to this many. Past it the item counts as owed.
MAX_PARTS = 4
# Spaces and tabs only between the parts: \s would run on into the next line and take it for the reason.
WAIVER_RE = re.compile(r"^[ \t]*(?:[-*][ \t]*)?waive[ \t]+([A-Za-z0-9_.-]+)[ \t]*:[ \t]*(\S.*)$",
                       re.IGNORECASE | re.MULTILINE)

RAN_RE = re.compile(r"^[ \t]*(?:[-*][ \t]*)?ran[ \t]+([A-Za-z0-9_.-]+)[ \t]*:[ \t]*(\S.*)$",
                    re.IGNORECASE | re.MULTILINE)

ITEM_KEYS = {"id", "title", "kind", "handover", "owed_when", "satisfied_by", "run_counts", "reviewer", "note"}
OWED_KEYS = {"changed", "added", "ask"}
ASK_KEYS = {"about", "paths", "question", "true", "false", "threshold"}

# A judge takes {"id", "question", "criteria": {"true", "false"}, "input": {...}} and returns the probability
# that the answer is yes, or None when it cannot answer. To say why it cannot, it raises NoAnswer.
Judge = Callable[[dict], Optional[float]]
# The longest reason of a judge that is shown in the block.
MAX_REASON_CHARS = 160
# What a byte that is not UTF-8 becomes when git's output is read (errors="replace").
NOT_DECODED = "\ufffd"


class NoAnswer(Exception):
    """Raised by a judge that cannot answer, with the reason in a few words. The item counts as owed, and the
    reason is shown beside it, so a rejected key can be told from an outage."""


class Unreadable(Exception):
    """The diff of a changed file cannot be put to the judge. The message says why, for the block."""


class RulesError(ValueError):
    """The rules file is not usable. The message names the item and the field."""


# ---------------------------------------------------------------------------------------------------------
# Paths


def glob_to_regex(pattern: str) -> "re.Pattern[str]":
    """`**` crosses directories, `*` and `?` stay inside one path segment. `**/x` also matches `x` at the root.

    A file name may hold any character but NUL, a line break included, so `.` matches those too and the end is
    the end of the string. Otherwise a folder named with a line break would hide its files from every rule."""
    out, i = [], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return re.compile("^" + "".join(out) + r"\Z", re.DOTALL)


class PathSet:
    """A list of globs. A pattern that starts with `!` takes paths out again, wherever it stands in the list."""

    def __init__(self, patterns: Sequence[str]):
        self.patterns = list(patterns)
        self._yes = [glob_to_regex(p) for p in patterns if not p.startswith("!")]
        self._no = [glob_to_regex(p[1:]) for p in patterns if p.startswith("!")]

    def __bool__(self) -> bool:
        return bool(self._yes)

    def matches(self, path: str) -> bool:
        return any(r.match(path) for r in self._yes) and not any(r.match(path) for r in self._no)

    def of(self, paths: Sequence[str]) -> List[str]:
        return [p for p in paths if self.matches(p)]


@dataclasses.dataclass(frozen=True)
class Change:
    status: str  # A added, M modified, D deleted, R renamed (path is the new name), C copied
    path: str


def parse_name_status(text: str) -> List[Change]:
    """The output of `git diff --name-status -z`: a status, then one path, or two for a rename or a copy, each
    ended by a NUL.

    Without -z git puts a path that holds a quote, a backslash or a byte outside ASCII in quotes and escapes it,
    and no pattern would match the result: a file with an accent in its name would owe nothing. The line form
    (status, tab, path) is still read, for callers that have it.

    A rename is two changes: its old path as deleted and its new path as renamed. Reported under the new path
    alone, a file moved out of a folder that a rule watches would owe nothing. A copy leaves its source as it
    was, so it is reported under its new path only."""
    changes = []
    if "\0" in text:
        fields = text.split("\0")
        i = 0
        while i < len(fields) and fields[i]:
            status = fields[i][0]
            if status in "RC" and i + 2 < len(fields):
                if status == "R":
                    changes.append(Change("D", fields[i + 1]))
                changes.append(Change(status, fields[i + 2]))
                i += 3
            elif i + 1 < len(fields):
                changes.append(Change(status, fields[i + 1]))
                i += 2
            else:
                break
        return changes
    for line in text.splitlines():
        parts = line.split("\t")
        if len(parts) < 2 or not parts[0]:
            continue
        status = parts[0][0]
        if status == "R" and len(parts) >= 3:
            changes.append(Change("D", parts[1]))
        changes.append(Change(status, parts[-1]))
    return changes


# ---------------------------------------------------------------------------------------------------------
# Rules


@dataclasses.dataclass
class Ask:
    about: str
    paths: PathSet
    question: str
    true: str
    false: str
    threshold: float


@dataclasses.dataclass
class Item:
    id: str
    title: str
    kind: str
    handover: str
    changed: PathSet
    added: PathSet
    ask: Optional[Ask]
    satisfied_by: PathSet
    reviewer: Optional[str]
    run_counts: bool = False


@dataclasses.dataclass
class Rules:
    ignore: PathSet
    items: List[Item]
    max_input_chars: int = DEFAULT_MAX_INPUT_CHARS


def _strings(value, where: str) -> List[str]:
    if value is None:
        return []
    if not isinstance(value, list) or not all(isinstance(v, str) and v for v in value):
        raise RulesError(f"{where}: expected a list of path patterns")
    return value


def _unknown(obj: dict, allowed: set, where: str) -> None:
    extra = sorted(set(obj) - allowed)
    if extra:
        raise RulesError(f"{where}: unknown field(s) {', '.join(extra)}")


def parse_rules(data: dict) -> Rules:
    """Strict on purpose: a misspelt field in a rule would otherwise switch that rule off without a word."""
    if not isinstance(data, dict) or not isinstance(data.get("items"), list):
        raise RulesError("rules: expected an object with an 'items' list")
    _unknown(data, {"version", "ignore", "items", "max_input_chars", "note"}, "rules")
    items, seen = [], set()
    for n, raw in enumerate(data["items"]):
        where = f"item {raw.get('id', n) if isinstance(raw, dict) else n}"
        if not isinstance(raw, dict):
            raise RulesError(f"{where}: expected an object")
        _unknown(raw, ITEM_KEYS, where)
        for key in ("id", "title", "kind"):
            if not isinstance(raw.get(key), str) or not raw[key]:
                raise RulesError(f"{where}: '{key}' is required")
        if raw["id"] in seen:
            raise RulesError(f"{where}: duplicate id")
        seen.add(raw["id"])
        if raw["kind"] not in KINDS:
            raise RulesError(f"{where}: kind must be one of {', '.join(KINDS)}")
        handover = raw.get("handover", "code-to-review")
        if handover not in HANDOVERS:
            raise RulesError(f"{where}: handover must be one of {', '.join(HANDOVERS)}")
        owed = raw.get("owed_when")
        if not isinstance(owed, dict) or not owed:
            raise RulesError(f"{where}: 'owed_when' needs 'changed', 'added' or 'ask'")
        _unknown(owed, OWED_KEYS, f"{where}.owed_when")
        ask = None
        if "ask" in owed:
            a = owed["ask"]
            if not isinstance(a, dict):
                raise RulesError(f"{where}.owed_when.ask: expected an object")
            _unknown(a, ASK_KEYS, f"{where}.owed_when.ask")
            for key in ("question", "true", "false"):
                if not isinstance(a.get(key), str) or not a[key].strip():
                    raise RulesError(f"{where}.owed_when.ask: '{key}' is required")
            about = a.get("about", "diff")
            if about not in ABOUT:
                raise RulesError(f"{where}.owed_when.ask: about must be one of {', '.join(ABOUT)}")
            threshold = a.get("threshold", DEFAULT_THRESHOLD)
            if isinstance(threshold, bool) or not isinstance(threshold, (int, float)) or not 0 < threshold <= 1:
                raise RulesError(f"{where}.owed_when.ask: threshold must be a number above 0 and at most 1")
            paths = _strings(a.get("paths"), f"{where}.owed_when.ask.paths")
            if about == "diff" and not paths:
                raise RulesError(f"{where}.owed_when.ask: 'paths' says which changed files the question is about")
            ask = Ask(about, PathSet(paths), a["question"].strip(), a["true"].strip(), a["false"].strip(),
                      float(threshold))
        changed = PathSet(_strings(owed.get("changed"), f"{where}.owed_when.changed"))
        added = PathSet(_strings(owed.get("added"), f"{where}.owed_when.added"))
        if not (changed or added or ask):
            raise RulesError(f"{where}: 'owed_when' needs 'changed', 'added' or 'ask'")
        if handover == "brief-to-code" and (changed or added or (ask and ask.about != "brief")):
            raise RulesError(f"{where}: at brief-to-code there is no diff yet, so only an 'ask' about the brief works")
        satisfied = PathSet(_strings(raw.get("satisfied_by"), f"{where}.satisfied_by"))
        if raw["kind"] != "evidence" and satisfied:
            raise RulesError(f"{where}: only an evidence item has 'satisfied_by'")
        run_counts = raw.get("run_counts", False)
        if not isinstance(run_counts, bool):
            raise RulesError(f"{where}: 'run_counts' is true or false")
        if raw["kind"] != "evidence" and run_counts:
            raise RulesError(f"{where}: only an evidence item has 'run_counts'")
        reviewer = raw.get("reviewer")
        if raw["kind"] == "review" and not (isinstance(reviewer, str) and reviewer):
            raise RulesError(f"{where}: a review item names its 'reviewer'")
        if raw["kind"] != "review" and reviewer is not None:
            raise RulesError(f"{where}: only a review item has a 'reviewer'")
        items.append(Item(raw["id"], raw["title"], raw["kind"], handover, changed, added, ask, satisfied, reviewer,
                          run_counts))
    max_chars = data.get("max_input_chars", DEFAULT_MAX_INPUT_CHARS)
    if isinstance(max_chars, bool) or not isinstance(max_chars, int) or max_chars <= 0:
        raise RulesError("rules: max_input_chars must be a positive whole number")
    return Rules(PathSet(_strings(data.get("ignore"), "rules.ignore")), items, max_chars)


def load_rules(path: pathlib.Path) -> Rules:
    try:
        return parse_rules(json.loads(path.read_text()))
    except json.JSONDecodeError as e:
        raise RulesError(f"{path}: not valid JSON ({e})") from e


def parse_waivers(text: str) -> Dict[str, str]:
    """Lines of the form `Waive <item id>: <reason>`, as the author writes them in the pull request."""
    return {m.group(1): m.group(2).strip() for m in WAIVER_RE.finditer(text or "")}


def parse_runs(text: str) -> Dict[str, str]:
    """Lines of the form `Ran <item id>: <what was run and what it showed>`, for items that let a run count."""
    return {m.group(1): m.group(2).strip() for m in RAN_RE.finditer(text or "")}


# ---------------------------------------------------------------------------------------------------------
# Deciding


@dataclasses.dataclass
class ItemResult:
    id: str
    title: str
    kind: str
    # not-owed | not-asked | present | ran | missing | waived | owed
    state: str
    reason: str
    probability: Optional[float] = None
    evidence: List[str] = dataclasses.field(default_factory=list)
    reviewer: Optional[str] = None
    run_counts: bool = False

    @property
    def is_owed(self) -> bool:
        return self.state in ("present", "ran", "missing", "waived", "owed")


@dataclasses.dataclass
class Decision:
    handover: str
    # back-to-author | review | ready | code
    next: str
    reviewers: List[str]
    needs_human: bool
    items: List[ItemResult]
    # Why the route is what it is, where the items alone do not say it.
    notes: List[str] = dataclasses.field(default_factory=list)

    def to_json(self) -> dict:
        return {
            "handover": self.handover,
            "next": self.next,
            "reviewers": self.reviewers,
            "needs_human": self.needs_human,
            "notes": self.notes,
            "items": [dataclasses.asdict(i) for i in self.items],
        }


def _one_line(text: str) -> str:
    """The last line of what a judge said, short enough for one line of the block."""
    lines = [" ".join(line.split()) for line in text.splitlines() if line.strip()]
    last = lines[-1] if lines else ""
    return last if len(last) <= MAX_REASON_CHARS else last[:MAX_REASON_CHARS - 1].rstrip() + "…"


def _shown(path: str) -> str:
    """A path on one line: a line break or another control character in a name is written as its escape."""
    return "".join(ch if ch.isprintable() else ch.encode("unicode_escape").decode("ascii") for ch in path)


def _first(paths: Sequence[str]) -> str:
    return _shown(paths[0]) + (f" (+{len(paths) - 1} more)" if len(paths) > 1 else "")


class _Asker:
    """Counts the questions of one run, so a rules file with many of them cannot run up a bill unnoticed."""

    def __init__(self, judge: Optional[Judge], max_questions: int):
        self.judge, self.left = judge, max_questions

    def ask(self, item: Item, payload_input: dict) -> Tuple[Optional[float], str]:
        """(probability, why there is none)."""
        assert self.judge is not None and item.ask is not None
        if self.left <= 0:
            return None, "question limit of this run reached"
        self.left -= 1
        try:
            p = self.judge({
                "id": item.id,
                "question": item.ask.question,
                "criteria": {"true": item.ask.true, "false": item.ask.false},
                "input": payload_input,
            })
        except NoAnswer as e:
            why = _one_line(str(e))
            return None, f"judge gave no answer ({why})" if why else "judge gave no answer"
        except Exception as e:  # a judge that throws has not answered; the stricter route applies
            return None, f"judge failed ({type(e).__name__})"
        if p is None or isinstance(p, bool) or not isinstance(p, (int, float)) or not 0 <= p <= 1:
            return None, "judge gave no answer"
        return float(p), ""


def _owed(item: Item, changes: Sequence[Change], diff_for: Callable[[List[str]], str], brief: Optional[str],
          asker: _Asker, max_chars: int) -> Tuple[str, str, Optional[float]]:
    """('yes' | 'no' | 'not-asked', reason, probability)."""
    paths = [c.path for c in changes]
    sure = item.changed.of(paths) or item.added.of([c.path for c in changes if c.status == "A"])
    if sure:
        return "yes", f"path rule: {_first(sure)}", None
    ask = item.ask
    if ask is None:
        return "no", "no path rule matched", None
    if ask.about == "brief":
        if not brief or not brief.strip():
            return "no", "no brief to ask about", None
        subject, payload = "the brief", {"brief": brief}
    else:
        candidates = ask.paths.of(paths)
        if not candidates:
            return "no", "no path rule matched", None
        subject, payload = _first(candidates), None
    if asker.judge is None:
        return "not-asked", f"no judge configured, so only the path rules apply ({subject})", None
    try:
        if payload is None:
            payload = _diff_payload(candidates, diff_for)
        size = _size(payload)
        if size > max_chars:
            if ask.about == "brief":
                return "yes", f"too large to ask the judge ({size} characters), so it counts as owed", None
            return _owed_in_parts(item, candidates, diff_for, asker, max_chars, size)
    except Unreadable as e:
        return "yes", f"{e}, so it counts as owed", None
    except (OSError, subprocess.CalledProcessError):
        # A question that cannot be put is a question without an answer.
        return "yes", "the diff could not be read to ask the judge, so it counts as owed", None
    p, why = asker.ask(item, payload)
    if p is None:
        return "yes", f"{why}, so it counts as owed", None
    if p >= ask.threshold:
        return "yes", f"judge: p={p:.2f}, at or above {ask.threshold:g}", p
    return "no", f"judge: p={p:.2f}, below {ask.threshold:g}", p


def _diff_payload(paths: Sequence[str], diff_for: Callable[[List[str]], str]) -> dict:
    """What the judge reads about these files. A file whose change cannot be shown is not left out quietly:
    the judge would answer about the rest and the item would pass on a diff nobody read."""
    odd = [p for p in paths if NOT_DECODED in p]
    if odd:
        # Its bytes were replaced when the name was read, so git cannot be asked for it by that name.
        raise Unreadable(f"the name of a changed file is not UTF-8 ({_first(odd)}), and its diff cannot be read")
    diff = diff_for(list(paths))
    if not diff.strip():
        raise Unreadable(f"git gave no diff for a changed file ({_first(list(paths))})")
    return {"changed_files": "\n".join(_shown(p) for p in paths), "diff": diff}


def _size(payload: dict) -> int:
    return sum(len(v) for v in payload.values())


def _parts(candidates: Sequence[str], diff_for: Callable[[List[str]], str], max_chars: int) -> Optional[List[List[str]]]:
    """The files in path order, cut into groups that each fit one question. None when one file alone does not fit."""
    parts: List[List[str]] = []
    current: List[str] = []
    used = 0
    for path in sorted(candidates):
        one = _size(_diff_payload([path], diff_for)) + 1
        if one > max_chars:
            return None
        if current and used + one > max_chars:
            parts.append(current)
            current, used = [], 0
        current.append(path)
        used += one
    if current:
        parts.append(current)
    return parts


def _owed_in_parts(item: Item, candidates: Sequence[str], diff_for: Callable[[List[str]], str], asker: _Asker,
                   max_chars: int, size: int) -> Tuple[str, str, Optional[float]]:
    """A diff too large for one question: the same question per group of files. Owed as soon as one part says so."""
    assert item.ask is not None
    parts = _parts(candidates, diff_for, max_chars)
    if parts is None:
        return "yes", "one file is too large to ask the judge about, so it counts as owed", None
    if len(parts) > MAX_PARTS:
        return "yes", f"too large to ask the judge in {MAX_PARTS} parts ({size} characters), so it counts as owed", None
    highest = 0.0
    for n, part in enumerate(parts, 1):
        where = f"part {n} of {len(parts)}"
        p, why = asker.ask(item, _diff_payload(part, diff_for))
        if p is None:
            return "yes", f"{why} ({where}), so it counts as owed", None
        if p >= item.ask.threshold:
            return "yes", f"judge: p={p:.2f} on {where} ({_first(part)}), at or above {item.ask.threshold:g}", p
        highest = max(highest, p)
    return "no", f"judge: p={highest:.2f} at most over {len(parts)} parts, below {item.ask.threshold:g}", highest


def decide(rules: Rules, handover: str, changes: Sequence[Change], diff_for: Callable[[List[str]], str],
           judge: Optional[Judge] = None, brief: Optional[str] = None, waivers: Optional[Dict[str, str]] = None,
           max_questions: int = DEFAULT_MAX_QUESTIONS, runs: Optional[Dict[str, str]] = None) -> Decision:
    """changes: the changed files. diff_for(paths) -> the unified diff of those files. judge: None when none is set up.
    waivers and runs: what the author wrote in the pull request, by item id."""
    waivers = waivers or {}
    runs = runs or {}
    changes = [c for c in changes if not rules.ignore.matches(c.path)]
    paths = [c.path for c in changes if c.status != "D"]
    asker = _Asker(judge, max_questions)
    results: List[ItemResult] = []
    for item in rules.items:
        if item.handover != handover:
            continue
        owed, reason, p = _owed(item, changes, diff_for, brief, asker, rules.max_input_chars)
        if owed != "yes":
            results.append(ItemResult(item.id, item.title, item.kind, "not-owed" if owed == "no" else "not-asked",
                                      reason, p))
            continue
        if item.kind != "evidence":
            results.append(ItemResult(item.id, item.title, item.kind, "owed", reason, p, reviewer=item.reviewer))
            continue
        evidence = item.satisfied_by.of(paths)
        if evidence:
            results.append(ItemResult(item.id, item.title, item.kind, "present", reason, p, evidence))
        elif item.run_counts and item.id in runs:
            results.append(ItemResult(item.id, item.title, item.kind, "ran",
                                      f"{reason}. Run reported by the author: {runs[item.id]}", p, run_counts=True))
        elif item.id in waivers:
            results.append(ItemResult(item.id, item.title, item.kind, "waived",
                                      f"{reason}. Waived by the author: {waivers[item.id]}", p))
        else:
            results.append(ItemResult(item.id, item.title, item.kind, "missing", reason, p,
                                      run_counts=item.run_counts))
    missing = any(r.state == "missing" for r in results)
    extra = []
    for r in results:
        if r.kind == "review" and r.state == "owed" and r.reviewer not in extra:
            extra.append(r.reviewer)
    needs_human = any(r.kind == "approval" and r.state == "owed" for r in results)
    if handover != "code-to-review":
        step = "back-to-author" if missing else ("review" if extra else "code")
        return Decision(handover, step, extra, needs_human, results)
    notes: List[str] = []
    by_rule = any(i.handover == handover and i.kind == "review" and i.reviewer == STANDARD_REVIEWER for i in rules.items)
    others = [r for r in extra if r != STANDARD_REVIEWER]
    claims = [r.id for r in results if r.state in ("waived", "ran")]
    if not by_rule or STANDARD_REVIEWER in extra:
        reviewers = [STANDARD_REVIEWER] + others
    elif claims:
        # The author answered an owed item with a sentence. Someone other than the author has to judge it.
        reviewers = [STANDARD_REVIEWER] + others
        notes.append(f"The reviewer is on the route to judge what the author wrote for {', '.join(claims)}.")
    else:
        reviewers = others
    step = "back-to-author" if missing else ("review" if reviewers else "ready")
    return Decision(handover, step, reviewers, needs_human, results, notes)


# ---------------------------------------------------------------------------------------------------------
# Output


def _sentence(text: str) -> str:
    text = text[:1].upper() + text[1:]
    return text if text.endswith((".", "?", "!")) else text + "."


def render_markdown(d: Decision) -> str:
    lines = ["### Owed by this change" if d.handover == "code-to-review" else "### Owed by this brief", ""]
    quiet = []
    for r in d.items:
        why = _sentence(r.reason)
        if r.state == "not-owed":
            quiet.append(r.title)
        elif r.state == "not-asked":
            lines.append(f"- {r.title}: not decided. {why}")
        elif r.state == "present":
            lines.append(f"- {r.title}: present ({_first(r.evidence)}). {why}")
        elif r.state == "ran":
            lines.append(f"- {r.title}: a run stands in for a changed test, and the reviewer judges it. {why}")
        elif r.state == "missing":
            lines.append(f"- {r.title}: **MISSING**. {why}")
        elif r.state == "waived":
            lines.append(f"- {r.title}: waived, and the reviewer judges the reason. {why}")
        elif r.kind == "review":
            lines.append(f"- {r.title}: owed. {why}")
        else:
            lines.append(f"- {r.title}: owed, and a person decides. {why}")
    if quiet:
        lines.append(f"- Not owed: {', '.join(quiet)}")
    if not d.items:
        lines.append("- No rule applies at this handover.")
    lines.append("")
    if d.next == "back-to-author":
        ids = ", ".join(r.id for r in d.items if r.state == "missing")
        by_run = ", ".join(r.id for r in d.items if r.state == "missing" and r.run_counts)
        run_hint = f" For {by_run}, a run counts too: `Ran <item>: <what you ran and what it showed>`." if by_run else ""
        lines.append(f"**Next: back to the author** ({ids}). Add what is missing, or write "
                     f"`Waive <item>: <reason>` in the pull request.{run_hint} No reviewer starts yet.")
    elif d.next == "review":
        lines.append(f"**Next: review by** {', '.join(d.reviewers)}.")
    elif d.next == "ready":
        lines.append("**Next: ready.** No reviewer is owed. The checks and the person who merges decide.")
    else:
        lines.append("**Next: write the code.**")
    lines.extend(d.notes)
    if d.needs_human:
        lines.append("**Needs human approval** before it is merged or released, whatever the reviewers say.")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------------------------------------
# Command line


def command_judge(command: str, timeout: float = 60.0) -> Judge:
    """A judge that is a program: the question goes in as JSON on stdin, {"probability": 0.0-1.0} comes back
    on stdout. Anything else (a non-zero exit, a timeout, other output) means it gave no answer. The last line
    a failing program writes to standard error is the reason shown in the block."""
    argv = shlex.split(command)

    def judge(payload: dict) -> Optional[float]:
        try:
            done = subprocess.run(argv, input=json.dumps(payload), capture_output=True, text=True, timeout=timeout)
        except subprocess.TimeoutExpired:
            raise NoAnswer(f"no reply within {timeout:g} seconds")
        except OSError as e:
            raise NoAnswer(f"could not start: {e.strerror or type(e).__name__}")
        if done.returncode != 0:
            raise NoAnswer(_one_line(done.stderr) or f"exit code {done.returncode}")
        try:
            p = json.loads(done.stdout).get("probability")
        except (ValueError, AttributeError):
            raise NoAnswer("its output was not JSON with a probability")
        return p if isinstance(p, (int, float)) and not isinstance(p, bool) else None

    return judge


def _git(repo: pathlib.Path, *args: str) -> str:
    # A file in another encoding is still a changed file: its odd bytes are replaced, not fatal.
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, encoding="utf-8", errors="replace",
                          check=True).stdout


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Works out what a change owes before it moves on, and where it goes next.")
    ap.add_argument("--handover", choices=HANDOVERS, default="code-to-review")
    ap.add_argument("--rules", default=".sdlc/rules.json", help="the rules file (default: .sdlc/rules.json)")
    ap.add_argument("--repo", default=".", help="the repository to read the diff from (default: here)")
    ap.add_argument("--base", help="the ref the change started from, for example origin/main")
    ap.add_argument("--head", default="HEAD", help="the ref with the change (default: HEAD)")
    ap.add_argument("--brief-from", help="a file with the brief, for rules that ask about it")
    ap.add_argument("--pull-request-from", "--waivers-from", dest="pull_request_from",
                    help="a file with the pull request text, read for 'Waive <item>: <reason>' and "
                         "'Ran <item>: <what was run>' lines")
    ap.add_argument("--judge-cmd", help="a program that answers one question: JSON in on stdin, {\"probability\": p} out")
    ap.add_argument("--judge-timeout", type=float, default=60.0)
    ap.add_argument("--max-questions", type=int, default=DEFAULT_MAX_QUESTIONS)
    ap.add_argument("--format", choices=("markdown", "json"), default="markdown")
    ap.add_argument("--fail-on-missing", action="store_true", help="exit 1 when owed evidence is missing")
    args = ap.parse_args(argv)

    repo = pathlib.Path(args.repo)
    try:
        rules = load_rules(pathlib.Path(args.rules))
    except (OSError, RulesError) as e:
        print(f"handover gate: {e}", file=sys.stderr)
        return 2
    try:
        brief = pathlib.Path(args.brief_from).read_text() if args.brief_from else None
        pr_text = pathlib.Path(args.pull_request_from).read_text() if args.pull_request_from else ""
    except OSError as e:
        print(f"handover gate: {e}", file=sys.stderr)
        return 2
    author_text = pr_text + "\n" + (brief or "")
    waivers, runs = parse_waivers(author_text), parse_runs(author_text)

    changes: List[Change] = []
    diff_for: Callable[[List[str]], str] = lambda paths: ""
    if args.handover == "code-to-review":
        if not args.base:
            ap.error("--base is required at code-to-review")
        try:
            span = f"{_git(repo, 'merge-base', args.base, args.head).strip()}..{args.head}"
            changes = parse_name_status(_git(repo, "diff", "--name-status", "-z", "-M", span))
        except subprocess.CalledProcessError as e:
            why = e.stderr.strip() or "no common commit found (a shallow clone needs more history)"
            print(f"handover gate: git could not compare {args.base} and {args.head}: {why}", file=sys.stderr)
            return 2
        # Literal: a file may be named like a pathspec with magic, such as ":x.sql", and still has to be found.
        # --text: a NUL byte in a source file, or a "-diff" line in .gitattributes, makes git print "Binary files
        # differ" in place of the change, and the judge would be asked about a diff it cannot see.
        # No textconv and no external diff: the judge reads what is in the commit, not what a filter makes of it.
        diff_for = lambda paths: _git(repo, "--literal-pathspecs", "diff", "--text", "--no-textconv", "--no-ext-diff",
                                      "-M", span, "--", *paths)

    judge = command_judge(args.judge_cmd, args.judge_timeout) if args.judge_cmd else None
    decision = decide(rules, args.handover, changes, diff_for, judge, brief, waivers, args.max_questions, runs)
    if args.format == "json":
        print(json.dumps(decision.to_json(), indent=2))
    else:
        print(render_markdown(decision), end="")
    return 1 if args.fail_on_missing and decision.next == "back-to-author" else 0


if __name__ == "__main__":
    sys.exit(main())
