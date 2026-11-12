# Which changes the reviewer reads

A reviewer on every change is the safe start, and it is what the gate does until you say otherwise. It is also the largest running cost of the workflow: every review is a fresh context that reads the diff and the code around it and runs checks.

Most changes do not need it. Which ones do is a question the merged history can answer, and this page is about asking it.

## What one project's history said

A trial on one project read about 1,000 merged pull requests from five weeks, 700 in a backend and 330 in a web app. For each later fix it found the earlier pull request the fix repaired.

- **Place beat size.** In the backend, 32 changes went wrong in use. The folders that hold calculations, stored data, scheduled jobs, calls to outside services and deploy scripts held most of them. A list of such folders chosen from the earlier half of the period sent 66% of the later half's changes to the reviewer and had 16 of the 20 that went wrong among them: 7.0% went wrong inside the list and 3.4% outside it.
- **Small changes went wrong less often, and size alone was still a poor rule.** The small changes that went wrong were deploy scripts and configuration. A path rule catches those and a size rule lets them through.
- **Hotspots helped less than folders.** Ranking files by how often they change times how large they are, the hottest half of the changes held 63% of the failures. The folder list held 85% for about the same number of reviews.
- **The web app was a different case.** 4 of 328 changes went wrong in use, and no folder, size or hotspot rule set them apart. All but one of its later fixes repaired something a check in code catches: a failing test, a type error, a broken page. There the reviewer was taken off by default.
- **The first count was too low.** Those figures come from pairs found by hand. The report's reading list, described below, then found eight more backend changes that had gone wrong and one more in the web app, mostly fixes that named the earlier pull request in other words than "fix". On the fuller count of 40, a list chosen from the earlier half by the report's fixed rule sent 58% of the later half's changes to the reviewer and had 19 of the 27 that went wrong among them: 9.4% inside and 5.5% outside. The lift is real and smaller than a first look suggests.

Your history will say something else. Measure it before you cut.

## The rule

The standard reviewer reads every change until a rule names it. From then on that rule decides, like any other review item:

```json
{
  "id": "code-review",
  "title": "Code review",
  "kind": "review",
  "reviewer": "reviewer",
  "note": "The places where a change went wrong in use more often than elsewhere. Kept current by the retro, see docs/risk.md.",
  "owed_when": {
    "changed": ["src/billing/**", "src/jobs/**", "**/migrations/**", "deploy/**", "!**/*.test.*"]
  }
}
```

With this rule in place:

- A change that touches a listed place shows "Code review: owed" with the path that made it so, and goes to the reviewer.
- A change that touches none of them, and owes no other reviewer, ends in "Next: ready". The checks in CI and the person who merges decide.
- **A waiver or a reported run still brings the reviewer in.** The author answered an owed item with a sentence, and someone other than the author has to judge it. Otherwise the cheap way out of every owed test would be a line nobody reads.
- Missing evidence still goes back to the author first.
- Security review, architect review and human approval are decided by their own rules, as before.

The rule can carry a question for the judge as well, for changes outside the listed places. Start without one. A list of paths is free, exact and easy to argue about.

## Three sources for the list

1. **Where changes went wrong.** The folders where merged changes later needed a fix more often than changes do overall. The risk report finds them.
2. **Hotspots.** Files that change often and are large. They are a second opinion: add one when changes to it also went wrong more often than changes overall.
3. **What you know.** Money, access, anything a mistake in would be expensive. Add those by hand and say why in the rule's `note`. History cannot see a failure that has not happened yet.

## The risk report

```bash
python3 .sdlc/retro/risk_report.py --since "60 days ago"
```

It reads the merged pull requests on the main branch and prints:

- **To read**: sentences in which a pull request names an earlier one next to a word such as "fix", "broke" or "regression". These are guesses from the wording. A pair counts only once someone has read both pull requests and written it into `.sdlc/retro/fixes.json`, under `fixes` with its kind or under `not_fixes`.
- **The reviewer's rule today**: how many changes it sends to the reviewer, how many of the ones that went wrong are among them, and each one it let through.
- **By folder** and **by size**: how often changes went wrong.
- **A list from this history**: the folders where changes went wrong at least 1.5 times as often as changes overall, on at least 15 changes and two failures. It is chosen twice: from the whole period, and from the earlier half alone and then checked on the later half. Trust the second figure. A list always looks good on the changes it was chosen from.
- **Hotspots**: the files with the most changes times lines, and whether the rule names them.

Where merges are merge commits, the description of a pull request is not in the history. Write the texts to a file and pass it:

```bash
gh pr list --state merged --limit 1000 --json number,title,body > /tmp/pull-requests.json
python3 .sdlc/retro/risk_report.py --since "60 days ago" --pull-requests /tmp/pull-requests.json
```

A fix has one of three kinds. `wrong-in-use`: a user or a job in production got a wrong result or a failure. `red-main`: the main branch was left with a failing test, lint or build. `other`: anything else worth keeping. Only `wrong-in-use` judges the reviewer's rule. A red main branch is a job for a check on the pull request, not for a reader.

## The retro

The `retro` role runs the report, reads the pairs, and proposes changes to the rule and to the lessons files in a pull request of its own. Run it every few weeks, and after a bad week. It proposes and a person merges: the rules are reviewed like code, and never in the same pull request as a change they would judge.

What it may propose is one step on the ladder in [learnings.md](./learnings.md): a check in code, a gate rule, or one or two lines in one role's lessons file.

## Limits

- **The figures are floors.** A failure counts only when somebody fixed it and the fix names what it repaired. A bug nobody has noticed yet is in no report.
- **What a reviewer would have caught outside the list is not measured.** The "let through" lines are the only signal. Read them at every retro.
- **Small numbers.** With fewer than ten known failures the report chooses no folders, and it is right not to.
- **Recent changes look better than they are.** A change merged last week has had a week to go wrong.
- **A list is not a verdict on the code.** A folder is on it because changes there went wrong, which also happens to code that is simply worked on the most.
