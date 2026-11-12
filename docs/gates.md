# Handover gates

A handover is the point where work moves from one role to the next: from the brief to the code, from the code to the review. A gate sits at the handover and decides the route.

Its purpose is narrow. **The agent that did the work must not be the one that decides how much checking the work gets.**

## How one gate decides

1. **Code decides what it can decide exactly.** Changed paths, a new file, a migration, a contract file. If a path rule says an item is owed, it is owed, and nothing is asked.
2. **A judge decides the unclear rest.** For the changes that paths cannot settle, the rule carries one factual yes/no question. It goes to a judge, which returns a probability. At or above the rule's threshold, the item is owed.
3. **No answer means the stricter route.** If the judge is down, slow, over its budget, or the diff is too large to send or cannot be read, the item counts as owed. A failed call never lowers the scrutiny.
4. **No judge means path rules only.** The gate then reports the question as "not decided" and moves on. This is the right way to start.

## What "owed" means

A change **owes** something when it has to be there before the change moves on. Each rule is one item of one of three kinds:

| Kind | Owed means | If it is not there |
|---|---|---|
| `evidence` | A kind of test, a contract file, a runnable check in the brief | Back to the author. No reviewer starts. |
| `review` | A reviewer looks at it: `security-review`, `architect`, or the standard `reviewer` | That reviewer is on the route until its verdict is in the pull request. |
| `approval` | A person decides: a paid model run, a change to payment or personal data | The block says "Needs human approval". |

For an `evidence` item the gate looks in the diff for a changed file where such evidence lives (`satisfied_by`). It does not judge whether the test is any good. That stays with the reviewer, who reads each owed test and asks whether it would fail if the behaviour broke.

### Who gets the standard reviewer

The standard reviewer reads every change until a rule names it (`"reviewer": "reviewer"`). From then on that rule decides which changes it reads, like any other review item, and a change that owes no reviewer ends in "Next: ready". A waiver or a reported run still brings the reviewer in, because someone other than the author has to judge that line. [risk.md](./risk.md) says how to choose the places and how to keep the list current.

### Waivers

A gate that demands tests invites tests written only to satisfy it. So the author may answer an owed item with one line in the pull request:

```text
Waive journey-test: the page is behind a flag and has no steps yet
```

The gate then lets the change through and passes the reason to the reviewer, who judges it. A wrong answer from the judge costs the author a sentence, not a hollow test.

### A run in place of a test

Some changes are proved by running something, not by a new test file: a change in wiring that an existing start-up test already covers, or a script that has no test at all. A rule can say so with `"run_counts": true`. The author then answers the item with one line in the pull request:

```text
Ran integration-test: the start-up suite, 212 passed, and it loads the changed wiring
```

The gate shows the item as "a run stands in for a changed test" and passes the line to the reviewer, who judges whether that run would fail if the behaviour broke. A changed test file still wins over a reported run. Without `run_counts`, a `Ran` line is ignored and only a changed file or a waiver answers the item.

### Verdicts

The gate cannot see a review happen. So the author records each one that ran with one line in the pull request, above the verdict as the reviewer returned it:

```text
Verdict reviewer: approve, two notes fixed here
Verdict security-review: no finding above low
```

The name is the reviewer's, as the "Next" line shows it. A reviewer with such a line is no longer waited for, and the "Next" line names only the ones that are left. When none is left, the change is "ready".

Write the line when the review is settled: the reviewer approved, or a person decided what stays open. A line for a reviewer the change does not owe changes nothing, and a verdict never stands in for missing evidence.

## Enforcing

By default the gate exits 0 whatever it decides, because the decision is the output. With `--enforce` it exits 1 while something owed is not there:

| "Next" line | Exit code with `--enforce` |
|---|---|
| back to the author: owed evidence is missing, with no waiver | 1 |
| review by ...: an owed review has no `Verdict` line yet | 1 |
| ready, or "write the code" at the brief handover | 0 |

"Needs human approval" does not change the exit code. A script cannot give that approval, so it stays a line for the person who merges.

When it holds a change, the gate says why on standard error. If an item is owed only because its question got no answer, it says that too. A judge that is down makes every question count as owed, and the right answer to an outage is to run the gate again, not to add tests and reviews the change never owed.

The workflow in `ci/handover-gate.yml` runs the gate this way on every pull request. Three things about it:

- **It runs again when the pull request text is edited**, so a `Waive`, `Ran` or `Verdict` line turns the job green without a new commit.
- **A branch that left the base branch before the gate was installed is reported and not held.** Its author never had the contract. Merging the base branch into it brings it under the gate.
- **`ENFORCE: "false"` makes it report only.** Use that to read what new rules ask for on real pull requests before they hold anything.

A red job holds a merge only where the check is required. Set that in branch protection or a ruleset.

## Testing and security: who needs what

Two questions are easy to mix up. Which existing tests must **run** is a cost question, and CI answers it. Which tests a change must **add** is a coverage question, and this gate answers it.

The starter rules in `templates/rules.json` cover:

| Item | Owed when the change | Decided by |
|---|---|---|
| Unit test | touches source code | paths |
| Database or integration test (a run counts) | touches queries, migrations or wiring | paths, then the judge |
| API contract | changes what callers send or receive | the judge, asked only when API code changed |
| User journey test | adds a page, or changes steps a user takes | paths for a new page, then the judge |
| Run of a changed script (a run counts) | touches a deploy or operations script | paths |
| Language check | changes text in the base language | paths |
| Code review | touches a place your rule lists. Without such a rule: every change | paths ([risk.md](./risk.md)) |
| Security review | touches sign-in, access, limits, webhooks or scan settings, or changes who can reach what | paths, then the judge |
| Architect review | alters or deletes data that is already stored | the judge, asked only when a migration changed |
| Live model run | changes a prompt | paths. A person decides, because a run costs money. |
| Approval of a sensitive change | touches payment code | paths |
| Approval of a change to the gate | touches the gate, its rules, its workflow, the lessons, the fixes file or the files that instruct the agents | paths |

Security has three levels, and most changes stop at the first:

1. **Scans** for secrets, known-bad patterns and vulnerable packages. They are cheap, so they run on every change in CI. The gate does not decide them.
2. **Access tests**: tests that walk every endpoint and check who can reach it. Write them so that a new endpoint is covered without touching the test. They run with your integration tests.
3. **A security review** in a fresh context. Only this level is decided per change, by the `security-review` item. In Claude Code, run the built-in `/security-review`. Hand it `.sdlc/lessons/security.md` if you keep one.

## Rules reference

`rules.json` is one object:

```json
{
  "version": 1,
  "ignore": ["docs/**", "**/*.md"],
  "max_input_chars": 40000,
  "items": [ ... ]
}
```

`ignore` lists files that never make anything owed. Keep the gate, the rules, the lessons and the files that instruct your agents (`CLAUDE.md`, `.claude/`) out of it: a change to them is exactly what a person should see. The starter list ignores every `.md` file and then takes those back out. `max_input_chars` caps what one question sends to the judge. A larger diff is asked about in parts: the files in path order, in groups that each fit, with the same question for each group. The item is owed as soon as one part says so. If it would take more than four parts, or one file alone does not fit, the item counts as owed without asking. A brief that is too large counts as owed too.

One item:

```json
{
  "id": "journey-test",
  "title": "User journey test",
  "kind": "evidence",
  "handover": "code-to-review",
  "owed_when": {
    "changed": ["src/checkout/**"],
    "added": ["**/page.tsx"],
    "ask": {
      "about": "diff",
      "paths": ["src/**/*.tsx", "!**/*.test.*"],
      "question": "Does this diff add or change a sequence of two or more actions that a user performs ...?",
      "true": "A multi-step user flow is added or changed.",
      "false": "The change is presentational.",
      "threshold": 0.4
    }
  },
  "satisfied_by": ["tests/e2e/**"]
}
```

| Field | Meaning |
|---|---|
| `id`, `title` | The id is what a `Waive` or `Ran` line names. The title is what the block shows. |
| `kind` | `evidence`, `review` or `approval`. |
| `handover` | `code-to-review` (the default) or `brief-to-code`. |
| `owed_when.changed` | Owed for certain when any changed file matches. A deleted file counts, and a renamed file counts under its old path and its new one, so a file moved out of a watched folder still owes what the folder owes. |
| `owed_when.added` | Owed for certain when any new file matches. |
| `owed_when.ask` | The question for the rest. `paths` says which changed files it is about: the question is asked only when one of them changed, and their diff is what the judge reads. With `"about": "brief"` the judge reads the brief instead, and `paths` is left out. |
| `threshold` | Owed at or above this probability. Default 0.5. Set it low where a miss costs more than an extra look. |
| `satisfied_by` | `evidence` only: where the evidence lives. Leave it out when nothing in the diff can satisfy the item, as for a brief. |
| `run_counts` | `evidence` only, `true` or `false` (the default): whether a `Ran <item>: ...` line in the pull request answers the item when no such file changed. |
| `reviewer` | `review` only: who is added to the route. A rule that names `reviewer` decides who gets the standard reviewer. |
| `note` | Free text for whoever edits the rules. |

Path patterns: `**` crosses directories, `*` and `?` stay inside one path segment, and a pattern that starts with `!` takes paths out again, from the whole list. So `!**/*.test.*` at the end of a list also takes out a workflow named `deploy.test.yml`. Where a list mixes source folders with files that must never drop out, write the exclusion with its folder: `!src/**/*.test.*`.

The gate refuses a rules file with a field it does not know. A misspelt field would otherwise switch a rule off without a word.

## Writing a question

- Ask about a fact in the diff, never for a judgement. "Does this diff change the type of a field an endpoint returns?" works. "Is this change risky?" does not.
- One question per rule. Give both criteria, `true` and `false`, in plain words.
- Let code narrow the cases first. A question that is asked on every change is a path rule you have not written yet.
- A threshold means nothing until it is measured. Label a sample of past pull requests by hand, run the question on them, and set the threshold from the result.
- Expect to move the starter thresholds. In a trial on 15 merged pull requests, with a small model as the judge, the security question at 0.3 asked for a review on six changes. Two of those were warranted, with answers of 0.80 and 0.95. The other four answered between 0.30 and 0.60. The journey question at 0.4 missed a renamed button that broke an end-to-end test, with an answer of 0.25.
- Name source files in `paths`, not whole folders, where a folder also holds pictures or other binary files. Every file under `paths` is sent as text, so a large binary file pushes the diff over the size limit and the item counts as owed.
- A question is only asked on the paths its rule names. The starter `stored-data` rule names migration files and a few file names. Code that merges, repairs or backfills stored records when it runs changes stored data too, so add the folders where yours lives.

## The judge protocol

A judge is any program. The gate starts it once per question with JSON on standard input:

```json
{
  "id": "security-review",
  "question": "Does this diff change who can read or change which user's data ...?",
  "criteria": {"true": "...", "false": "..."},
  "input": {"changed_files": "src/a.ts\nsrc/b.ts", "diff": "..."}
}
```

It answers on standard output:

```json
{"probability": 0.81}
```

A non-zero exit, a timeout or any other output means "no answer", and the item counts as owed. The block then shows why: the last line the program wrote to standard error, cut to 160 characters, or the exit code. So write one plain line there, such as "the key was rejected (HTTP 401)", and keep keys out of it. The gate asks at most eight questions per run (`--max-questions`), and each part of a large diff is one question. Past that, the remaining items count as owed. Keep caching, spend limits and keys inside your judge.

```bash
python3 .sdlc/gate/handover_gate.py --base origin/main --judge-cmd "python3 tools/my_judge.py"
```

Any model that gives a calibrated probability for a yes/no question will do: a small classifier or a small language model. Whether a judge earns its place over path rules alone is worth measuring. Build the path rules first, add a question only where they are too coarse, and compare.

## The command

```text
handover_gate.py --base <ref> [--head HEAD] [--rules .sdlc/rules.json] [--repo .]
                 [--pull-request-from FILE] [--judge-cmd "<command>"] [--format markdown|json] [--enforce]
handover_gate.py --handover brief-to-code --brief-from FILE [--pull-request-from FILE]
                 [--judge-cmd "<command>"] [--enforce]
```

It compares `--head` with the point where it branched off `--base`. File names are read exactly as git stores them, so a name with a space, a quote, an accent or a line break is matched like any other. The judge gets every changed file as text, also one that git would call binary because of a stray NUL byte or a line in `.gitattributes`. Where a changed file has no diff to show, or a name that is not UTF-8, the item counts as owed without asking. `--pull-request-from` names a file with the pull request text, which the gate reads for `Waive`, `Ran` and `Verdict` lines (`--waivers-from` is the older name for the same flag). At the brief handover the brief itself is read for them too. It exits 0 whatever it decides, unless `--enforce` is given (see [Enforcing](#enforcing)). `--fail-on-missing` is the narrower, older switch: only missing evidence exits 1. A rules file it cannot use, or a git error, exits 2 in every mode.

`--format json` gives the same decision for scripts: `next` (`back-to-author`, `review`, `ready` or `code`), `reviewers` (every reviewer the change owes), `waiting` (the ones with no verdict yet), `verdicts`, `needs_human`, `notes`, and one entry per item with its `state`, `reason`, `probability` and `evidence`. The states are `not-owed`, `not-asked`, `present`, `ran`, `missing`, `waived` and `owed`.

## Limits worth holding to

- **The gate routes, it does not judge.** "Is this plan good?" stays with a reviewer.
- **It can add checking and never remove a human approval.** Whatever a person must approve today stays theirs.
- **Missing evidence holds back the reviewer first.** A review of a change that lacks its tests is a review to repeat.
- **A person can always overrule it.** A `Waive` line, with a reason the reviewer judges, is the way through for an item that does not fit the change. The person who merges has the last word.
- **A `Verdict` line is the author's record.** The gate checks that it is there, not that a review ran. The verdict pasted under it, and the person who merges, are the check on that.
- **Measure a rule before you lean on it.** The starter patterns and thresholds are guesses. Read what they ask for on a few real pull requests, with `ENFORCE: "false"` if you want nothing held meanwhile.
- **The rules are reviewed like code.** Do not change `rules.json` in the same pull request as a change it would judge. Two things back that up. In CI the workflow runs the gate and the rules from the tip of the base branch, so a pull request cannot loosen the rules that judge it. And the starter rules ask for a person's approval when the gate, the rules, the gate's workflow, the lessons, the fixes file or the files that instruct the agents change.
- **A pull request that edits the gate's workflow runs its own copy.** GitHub runs a workflow file as the pull request has it. So the line above holds only while that file is untouched. The starter rules ask for a person's approval of such a change, and that person should not trust the job's result on it. Put the rest of your workflow folder on the `security-review` path list. To close the gap fully, run the gate as a required workflow from a repository ruleset, which a pull request cannot edit.
- **The judge can be talked to.** It reads text the author wrote. Where a miss would be expensive, use a path rule: it cannot be argued with.
