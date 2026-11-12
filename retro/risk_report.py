#!/usr/bin/env python3
"""Risk report: where did merged changes later need a fix, and does the reviewer's rule cover those places?

The handover gate can let a rule decide which changes the reviewer reads. That rule is a list of paths, and a
list of paths goes stale. This script reads the merged history and says what the list should have been:

  1. Which merged pull requests later needed a fix. A fix counts once a person or the retro role has confirmed
     it in the fixes file (.sdlc/retro/fixes.json). The script only proposes candidates: sentences in which a
     later pull request names an earlier one next to a word such as "fix", "broke" or "regression".
  2. How often that happened, by folder and by size of the change.
  3. What the reviewer's rule would have done over the same period: how many changes it sends to the reviewer,
     how many of the failed ones are among them, and which it lets through.
  4. The folders where changes went wrong clearly more often than elsewhere, chosen once from the whole period
     and once from its earlier half alone and checked on the later half. A list that only memorises the past
     shows up in that check.
  5. Hotspots: the files that changed most often, times their size.

It decides nothing. Its output is what a person, or the retro role, reads before proposing a change to the
rules in a pull request of its own.

Usage:
  risk_report.py [--repo .] [--branch origin/main] [--since "90 days ago"] [--rules .sdlc/rules.json]
                 [--fixes .sdlc/retro/fixes.json] [--pull-requests FILE] [--format markdown|json]

--pull-requests names a JSON file with a list of {"number", "title", "body"}: the text of the merged pull
requests, for example from `gh pr list --state merged --json number,title,body --limit 1000`. Without it the
script reads the commit messages on the branch, which is enough where a squash merge keeps the description.

Python 3.8+, standard library only.
"""
from __future__ import annotations

import argparse
import dataclasses
import json
import pathlib
import re
import subprocess
import sys
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "gate"))
import handover_gate as gate  # noqa: E402

# The kinds a confirmed fix can have. Only the first is what a reviewer is there to catch.
WRONG_IN_USE = "wrong-in-use"   # a user or a job in production got a wrong result or a failure
RED_MAIN = "red-main"           # the main branch was left with a failing test, lint or build
OTHER = "other"                 # anything else worth keeping, such as two migrations with one number
KINDS = (WRONG_IN_USE, RED_MAIN, OTHER)

FAILURE_WORDS = re.compile(
    r"\b(fix(?:es|ed)?|broke|broken|breaks|regress\w*|revert\w*|wrong(?:ly)?|missed|fail(?:s|ed|ing|ure)?|bug|"
    r"crash\w*|repair\w*|follow[- ]up|left out|forgot\w*|incorrect\w*)\b", re.IGNORECASE)
REFERENCE = re.compile(r"(?:(?<![\w/])#|/pull/)(\d+)\b")
MERGE_SUBJECT = re.compile(r"^Merge pull request #(\d+)\b")
SQUASH_SUBJECT = re.compile(r"\(#(\d+)\)\s*$")
# Files that are written by a tool. They are large, and nobody reviews them line by line.
NOT_CODE = ["**/package-lock.json", "**/pnpm-lock.yaml", "**/yarn.lock", "**/*.lock", "**/*.min.*", "**/*.snap"]
# Where tests usually live, for the test helpers and fixtures that no rule names as evidence.
TESTS = ["src/test/**", "test/**", "tests/**", "e2e/**", "**/__tests__/**", "**/*.test.*", "**/*.spec.*"]
SKIP_TITLES = r"^(Bump |build\(deps|chore\(deps)"
SIZES = ((50, "50 lines or fewer"), (150, "51 to 150"), (400, "151 to 400"), (None, "more than 400"))


@dataclasses.dataclass
class File:
    path: str
    lines: int   # added plus deleted


@dataclasses.dataclass
class Merged:
    number: int
    sha: str
    when: str    # ISO 8601, as git prints it
    title: str
    text: str    # everything that was written about it: commit messages, and the pull request text when given
    files: List[File]
    code: List[File] = dataclasses.field(default_factory=list)

    @property
    def code_lines(self) -> int:
        return sum(f.lines for f in self.code)


@dataclasses.dataclass
class Fix:
    fix: int
    repairs: int
    kind: str
    what: str = ""


@dataclasses.dataclass
class Candidate:
    fix: int
    repairs: int
    sentence: str


class FixesError(ValueError):
    """The fixes file is not usable."""


# ---------------------------------------------------------------------------------------------------------
# Reading


def _git(repo: pathlib.Path, *args: str) -> str:
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, encoding="utf-8", errors="replace",
                          check=True).stdout


def pull_request_number(subject: str) -> Optional[int]:
    """A merge commit says "Merge pull request #12 from ...", a squash merge ends in "(#12)"."""
    m = MERGE_SUBJECT.search(subject) or SQUASH_SUBJECT.search(subject)
    return int(m.group(1)) if m else None


def read_history(repo: pathlib.Path, branch: str, since: str, texts: Optional[Dict[int, Tuple[str, str]]] = None,
                 skip_titles: str = SKIP_TITLES) -> Tuple[List[Merged], int]:
    """The pull requests merged into the branch, oldest first, and how many commits on it carried no number."""
    texts = texts or {}
    skip = re.compile(skip_titles) if skip_titles else None
    out = _git(repo, "log", "--first-parent", f"--since={since}", "--format=%H%x1f%cI%x1f%s%x1f%b%x1e", branch)
    merged, unnumbered = [], 0
    for record in out.split("\x1e"):
        if not record.strip():
            continue
        sha, when, subject, body = record.strip("\n").split("\x1f")
        number = pull_request_number(subject)
        if number is None:
            unnumbered += 1
            continue
        is_merge = bool(MERGE_SUBJECT.search(subject))
        title = (body.strip().splitlines() or [subject])[0] if is_merge else SQUASH_SUBJECT.sub("", subject).strip()
        given_title, given_body = texts.get(number, ("", ""))
        title = given_title or title
        if skip and skip.search(title):
            continue
        try:
            # -z: without it git quotes and escapes a path that holds a quote or a byte outside ASCII.
            stat = _git(repo, "diff", "--numstat", "-z", "--no-renames", f"{sha}^1", sha)
            said = _git(repo, "log", "--format=%B", f"{sha}^1..{sha}") if is_merge else f"{subject}\n{body}"
        except subprocess.CalledProcessError:
            continue   # the first commit of the repository has nothing to compare with
        files = []
        for line in stat.split("\0"):
            parts = line.split("\t", 2)
            if len(parts) == 3:
                added, deleted = (0 if p == "-" else int(p) for p in parts[:2])
                files.append(File(parts[2], added + deleted))
        merged.append(Merged(number, sha, when, title, "\n".join(t for t in (title, given_body, said) if t), files))
    merged.reverse()
    return merged, unnumbered


def load_texts(path: pathlib.Path) -> Dict[int, Tuple[str, str]]:
    data = json.loads(path.read_text())
    if not isinstance(data, list):
        raise FixesError(f"{path}: expected a list of pull requests")
    return {int(p["number"]): (p.get("title") or "", p.get("body") or "") for p in data if "number" in p}


def load_fixes(path: pathlib.Path) -> Tuple[List[Fix], Set[Tuple[int, int]]]:
    """The confirmed fixes, and the pairs that were read and are not one."""
    if not path.exists():
        return [], set()
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        raise FixesError(f"{path}: not valid JSON ({e})") from e
    if not isinstance(data, dict):
        raise FixesError(f"{path}: expected an object with 'fixes' and 'not_fixes'")
    extra = sorted(set(data) - {"note", "fixes", "not_fixes"})
    if extra:
        raise FixesError(f"{path}: unknown field(s) {', '.join(extra)}")
    fixes = []
    for n, raw in enumerate(data.get("fixes", [])):
        if not isinstance(raw, dict) or set(raw) - {"fix", "repairs", "kind", "what"}:
            raise FixesError(f"{path}: fix {n} has fields other than fix, repairs, kind and what")
        if not isinstance(raw.get("fix"), int) or not isinstance(raw.get("repairs"), int):
            raise FixesError(f"{path}: fix {n} needs the numbers 'fix' and 'repairs'")
        if raw.get("kind") not in KINDS:
            raise FixesError(f"{path}: fix {n}: kind must be one of {', '.join(KINDS)}")
        fixes.append(Fix(raw["fix"], raw["repairs"], raw["kind"], str(raw.get("what", ""))))
    not_fixes = set()
    for pair in data.get("not_fixes", []):
        if not (isinstance(pair, list) and len(pair) == 2 and all(isinstance(v, int) for v in pair)):
            raise FixesError(f"{path}: 'not_fixes' is a list of [fix, repairs] pairs")
        not_fixes.add((pair[0], pair[1]))
    return fixes, not_fixes


@dataclasses.dataclass
class Scope:
    """What the rules say about paths: what never counts, where evidence lives, and where the reviewer is owed."""
    ignore: gate.PathSet
    # Tests, contract files, translations: what an evidence item is satisfied by is proof, not the code it proves.
    evidence: gate.PathSet
    not_code: gate.PathSet
    # The 'changed' list of the rule that names the standard reviewer. None when no rule names it: it then
    # reads every change.
    reviewer: Optional[gate.PathSet]
    # The rule also has an 'added' list or a question for the judge, which history alone cannot replay.
    reviewer_has_more: bool = False

    def is_code(self, path: str) -> bool:
        return not (self.ignore.matches(path) or self.evidence.matches(path) or self.not_code.matches(path))

    def reviewed(self, change: Merged) -> bool:
        return self.reviewer is None or bool(self.reviewer.of([f.path for f in change.files
                                                               if not self.ignore.matches(f.path)]))


def scope_from_rules(rules: gate.Rules, not_code: Sequence[str] = NOT_CODE) -> Scope:
    evidence: List[str] = list(TESTS)
    reviewer: Optional[List[str]] = None
    more = False
    for item in rules.items:
        if item.handover != "code-to-review":
            continue
        if item.kind == "evidence":
            evidence.extend(p for p in item.satisfied_by.patterns if not p.startswith("!"))
        if item.kind == "review" and item.reviewer == gate.STANDARD_REVIEWER:
            reviewer = (reviewer or []) + item.changed.patterns
            more = more or item.ask is not None or bool(item.added)
    return Scope(rules.ignore, gate.PathSet(evidence), gate.PathSet(list(not_code)),
                 None if reviewer is None else gate.PathSet(reviewer), more)


# ---------------------------------------------------------------------------------------------------------
# Working it out


def sentences(text: str) -> List[str]:
    flat = re.sub(r"[ \t]+", " ", text)
    return [s.strip(" -*\t") for s in re.split(r"(?<=[.!?])\s+|\n+", flat) if s.strip(" -*\t")]


def find_candidates(merged: Sequence[Merged], known: Iterable[Tuple[int, int]]) -> List[Candidate]:
    """Sentences in which a pull request names an earlier merged one next to a word of failure."""
    numbers = {m.number for m in merged}
    seen = set(known)
    found = []
    for m in merged:
        for sentence in sentences(m.text):
            if not FAILURE_WORDS.search(sentence):
                continue
            for ref in REFERENCE.findall(sentence):
                pair = (m.number, int(ref))
                if pair[1] < m.number and pair[1] in numbers and pair not in seen:
                    seen.add(pair)
                    found.append(Candidate(pair[0], pair[1], sentence[:300]))
    return found


def folders(path: str) -> List[str]:
    parts = path.split("/")[:-1]
    return ["/".join(parts[:n]) for n in range(1, len(parts) + 1)]


def by_folder(changes: Sequence[Merged]) -> Dict[str, Set[int]]:
    """Folder -> the pull requests that changed code somewhere under it."""
    out: Dict[str, Set[int]] = {}
    for m in changes:
        for f in m.code:
            for folder in folders(f.path):
                out.setdefault(folder, set()).add(m.number)
    return out


def _rate(part: int, whole: int) -> float:
    return part / whole if whole else 0.0


def choose_folders(changes: Sequence[Merged], failed: Set[int], min_changes: int, factor: float) -> List[str]:
    """The folders where changes went wrong clearly more often than changes do overall.

    A folder is chosen when it saw at least min_changes changes, at least two of them went wrong, and its rate is
    at least `factor` times the overall rate. Of a folder and one inside it, the outer one stands. The rule is
    plain on purpose: a search for the list that fits the past best picks narrow folders that held one bad week,
    and does worse on the weeks after."""
    everyone = {m.number for m in changes}
    failed = failed & everyone
    base = _rate(len(failed), len(everyone))
    chosen = {folder for folder, prs in by_folder(changes).items()
              if len(prs) >= min_changes and len(failed & prs) >= 2 and _rate(len(failed & prs), len(prs)) >= factor * base}
    return sorted(c for c in chosen if not any(c.startswith(o + "/") for o in chosen))


@dataclasses.dataclass
class Cut:
    """What sending some of the changes to the reviewer would have done."""
    changes: int
    reviewed: int
    failed: int
    caught: int

    @property
    def rate_inside(self) -> float:
        return _rate(self.caught, self.reviewed)

    @property
    def rate_outside(self) -> float:
        return _rate(self.failed - self.caught, self.changes - self.reviewed)

    def to_json(self) -> dict:
        return {**dataclasses.asdict(self), "rate_inside": round(self.rate_inside, 4),
                "rate_outside": round(self.rate_outside, 4)}


def cut(changes: Sequence[Merged], failed: Set[int], reviewed) -> Cut:
    inside = {m.number for m in changes if reviewed(m)}
    everyone = {m.number for m in changes}
    return Cut(len(everyone), len(inside), len(failed & everyone), len(failed & inside))


def under(paths: Sequence[str]):
    prefixes = tuple(p + "/" for p in paths)
    return lambda m: any(f.path.startswith(prefixes) for f in m.code)


def analyse(merged: Sequence[Merged], fixes: Sequence[Fix], not_fixes: Set[Tuple[int, int]], scope: Scope,
            line_count=lambda path: 0, min_changes: int = 15, factor: float = 1.5, top: int = 15) -> dict:
    for m in merged:
        m.code = [f for f in m.files if scope.is_code(f.path)]
    changes = [m for m in merged if m.code]
    numbers = {m.number for m in changes}
    by_number = {m.number: m for m in changes}
    kinds: Dict[int, Set[str]] = {}
    for f in fixes:
        if f.repairs in numbers:
            kinds.setdefault(f.repairs, set()).add(f.kind)
    failed = {n for n, k in kinds.items() if WRONG_IN_USE in k}

    sizes = []
    low = 0
    for high, name in SIZES:
        group = [m for m in changes if m.code_lines > low and (high is None or m.code_lines <= high)]
        sizes.append({"size": name, "changes": len(group), "failed": len(failed & {m.number for m in group})})
        low = high or low

    paths = sorted({f.path for m in changes for f in m.code})

    def on_the_list(files: Sequence[str]) -> str:
        """Of the files that changed here, how many the reviewer's rule names: all, some or none."""
        if scope.reviewer is None:
            return "all"
        named = len(scope.reviewer.of(files))
        return "all" if named == len(files) else ("some" if named else "none")

    touched = by_folder(changes)
    table = []
    for folder, prs in touched.items():
        if len(prs) < min_changes:
            continue
        # A folder that only passes on what its one child holds says nothing of its own.
        if any(touched[c] == prs for c in touched if c.startswith(folder + "/")):
            continue
        table.append({"folder": folder, "changes": len(prs), "failed": len(failed & prs),
                      "rate": round(_rate(len(failed & prs), len(prs)), 4),
                      "on_the_list": on_the_list([p for p in paths if p.startswith(folder + "/")])})
    table.sort(key=lambda row: (-row["rate"], -row["changes"], row["folder"]))

    current = cut(changes, failed, scope.reviewed)
    let_through = [{"number": n, "title": by_number[n].title,
                    "files": [f.path for f in by_number[n].code][:6]}
                   for n in sorted(failed) if not scope.reviewed(by_number[n])]

    suggestion = None
    if len(failed) >= 10:
        half = len(changes) // 2
        earlier, later = changes[:half], changes[half:]
        learned = choose_folders(earlier, failed, min_changes, factor)
        chosen = choose_folders(changes, failed, min_changes, factor)
        suggestion = {"folders": chosen, "over_the_period": cut(changes, failed, under(chosen)).to_json(),
                      "chosen_on_the_earlier_half": learned,
                      "checked_on_the_later_half": cut(later, failed, under(learned)).to_json()}

    counts: Dict[str, List[int]] = {}
    for m in changes:
        for f in m.code:
            counts.setdefault(f.path, []).append(m.number)
    hot = []
    for path, prs in counts.items():
        lines = line_count(path)
        if lines:
            hot.append({"file": path, "changes": len(prs), "lines": lines, "failed": len(failed & set(prs)),
                        "on_the_list": on_the_list([path])})
    hot.sort(key=lambda row: (-row["changes"] * row["lines"], row["file"]))

    known = {(f.fix, f.repairs) for f in fixes} | not_fixes
    return {
        "changes": len(changes),
        "first": changes[0].when if changes else None,
        "last": changes[-1].when if changes else None,
        "needed_a_fix": {kind: sum(1 for k in kinds.values() if kind in k) for kind in KINDS},
        "factor": factor,
        "reviewer_by_rule": scope.reviewer is not None,
        "reviewer_rule_has_more": scope.reviewer_has_more,
        "current_rule": current.to_json(),
        "let_through": let_through,
        "by_size": sizes,
        "by_folder": table,
        "suggestion": suggestion,
        "hotspots": hot[:top],
        "candidates": [dataclasses.asdict(c) for c in find_candidates(merged, known)],
    }


# ---------------------------------------------------------------------------------------------------------
# Output


def _pct(value: float) -> str:
    return f"{value * 100:.0f}%" if value >= 0.1 or value == 0 else f"{value * 100:.1f}%"


def _cut_line(c: dict) -> str:
    share = _rate(c["reviewed"], c["changes"])
    return (f"sends {c['reviewed']} of {c['changes']} changes to the reviewer ({_pct(share)}) and has "
            f"{c['caught']} of the {c['failed']} that went wrong among them. "
            f"Went wrong inside: {_pct(c['rate_inside'])}. Outside: {_pct(c['rate_outside'])}.")


def render_markdown(r: dict, top_folders: int = 20) -> str:
    fixed = r["needed_a_fix"]
    lines = ["## Risk report", ""]
    if not r["changes"]:
        return "\n".join(lines + ["No merged pull request with a code change in this period."]) + "\n"
    lines += [f"{r['changes']} merged pull requests changed code between {r['first'][:10]} and {r['last'][:10]}. "
              f"A later fix is on record for {fixed[WRONG_IN_USE]} that went wrong in use, {fixed[RED_MAIN]} that "
              f"left the main branch red and {fixed[OTHER]} other. These are floors: a fix counts only once it "
              f"is in the fixes file.", ""]
    lines.append("### The reviewer's rule today")
    lines.append("")
    if not r["reviewer_by_rule"]:
        lines.append("No rule names the reviewer, so it reads every change.")
    else:
        lines.append("The rule " + _cut_line(r["current_rule"]))
        if r["reviewer_rule_has_more"]:
            lines.append("The rule also has an `added` list or a question for the judge. Only its `changed` list "
                         "is counted here.")
        for row in r["let_through"]:
            lines.append(f"- Let through: #{row['number']} {row['title']} ({', '.join(row['files'])})")
    lines += ["", "### By folder", "",
              "| Folder | Changes | Went wrong | Rate | On the reviewer's list |", "|---|---|---|---|---|"]
    for row in r["by_folder"][:top_folders]:
        lines.append(f"| `{row['folder']}` | {row['changes']} | {row['failed']} | {_pct(row['rate'])} | "
                     f"{row['on_the_list']} |")
    lines += ["", "### By size of the change", "", "| Code lines changed | Changes | Went wrong |", "|---|---|---|"]
    for row in r["by_size"]:
        lines.append(f"| {row['size']} | {row['changes']} | {row['failed']} |")
    lines += ["", "### A list from this history", ""]
    s = r["suggestion"]
    if s is None:
        lines.append(f"Too few changes are known to have gone wrong ({fixed[WRONG_IN_USE]}) to choose folders "
                     f"from them. A list made from fewer than ten would be a guess.")
    else:
        lines.append(f"Folders where changes went wrong at least {r['factor']:g} times as often as changes do overall: "
                     + (", ".join(f"`{f}/**`" for f in s["folders"]) or "none stand out") + ".")
        lines.append("Over the whole period this list " + _cut_line(s["over_the_period"]))
        lines.append("That flatters it, because the list was chosen from the same changes. A fairer test: the same "
                     "rule on the earlier half alone picks "
                     + (", ".join(f"`{f}`" for f in s["chosen_on_the_earlier_half"]) or "nothing")
                     + ". On the later half that list " + _cut_line(s["checked_on_the_later_half"]))
    lines += ["", "### Hotspots", "", "Files by how often they changed times how large they are now.", "",
              "| File | Changes | Lines | Went wrong | On the reviewer's list |", "|---|---|---|---|---|"]
    for row in r["hotspots"]:
        lines.append(f"| `{row['file']}` | {row['changes']} | {row['lines']} | {row['failed']} | "
                     f"{'yes' if row['on_the_list'] == 'all' else 'no'} |")
    lines += ["", "### To read", ""]
    if not r["candidates"]:
        lines.append("No sentence names an earlier pull request next to a word of failure that is not in the "
                     "fixes file yet.")
    else:
        lines.append("Each line is a guess from the wording. Read both pull requests, then add the pair to the "
                     "fixes file under `fixes` with its kind, or under `not_fixes`.")
        lines.append("")
        for c in r["candidates"]:
            lines.append(f"- #{c['fix']} may fix #{c['repairs']}: \"{c['sentence']}\"")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------------------------------------
# Command line


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Where merged changes later needed a fix, against the reviewer's rule.")
    ap.add_argument("--repo", default=".")
    ap.add_argument("--branch", default="origin/main", help="the branch changes are merged into")
    ap.add_argument("--since", default="90 days ago", help="how far back to read, as git understands it")
    ap.add_argument("--rules", default=".sdlc/rules.json")
    ap.add_argument("--fixes", default=".sdlc/retro/fixes.json", help="the confirmed fixes (it may not exist yet)")
    ap.add_argument("--pull-requests", help="a JSON list of {number, title, body} with the pull request texts")
    ap.add_argument("--min-changes", type=int, default=15, help="a folder needs this many changes to be listed")
    ap.add_argument("--factor", type=float, default=1.5,
                    help="a folder is chosen when its rate is this many times the overall rate")
    ap.add_argument("--skip-titles", default=SKIP_TITLES, help="pull requests whose title matches are left out")
    ap.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = ap.parse_args(argv)

    repo = pathlib.Path(args.repo)
    try:
        rules = gate.load_rules(pathlib.Path(args.rules))
        fixes, not_fixes = load_fixes(pathlib.Path(args.fixes))
        texts = load_texts(pathlib.Path(args.pull_requests)) if args.pull_requests else {}
    except (OSError, ValueError) as e:
        print(f"risk report: {e}", file=sys.stderr)
        return 2
    try:
        merged, unnumbered = read_history(repo, args.branch, args.since, texts, args.skip_titles)
        counted = _git(repo, "grep", "-I", "-c", "-z", "", args.branch, "--")
    except subprocess.CalledProcessError as e:
        print(f"risk report: git could not read {args.branch}: {e.stderr.strip()}", file=sys.stderr)
        return 2
    # One record per text file on the branch: "<branch>:<path>", a NUL, "<lines>", a line break.
    sizes = {}
    for record in counted.split("\n"):
        name, _, count = record.partition("\0")
        if count.isdigit():
            sizes[name[len(args.branch) + 1:]] = int(count)
    line_count = lambda path: sizes.get(path, 0)

    report = analyse(merged, fixes, not_fixes, scope_from_rules(rules), line_count, args.min_changes, args.factor)
    report["commits_without_a_number"] = unnumbered
    if args.format == "json":
        print(json.dumps(report, indent=2))
    else:
        print(render_markdown(report), end="")
        if unnumbered:
            print(f"\nCommits on {args.branch} that carry no pull request number and were left out: {unnumbered}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
