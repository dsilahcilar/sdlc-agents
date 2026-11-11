# Learnings

A team that repeats a mistake has not learned from it. Version 1 answered that with a shared playbook, a Retro agent that appended to it, and a Curator agent that sorted lessons into a file per role. The idea of a lesson per role was right. The storage did not hold up:

- The files only grew. Every role read more text on every run, and old cautions started to read as absolute rules.
- The lessons that mattered turned into tests and lint rules over time, and the prose copy stayed behind.
- Lessons went to the roles that write instructions. The reviewer, the role that catches mistakes, got none.

Version 2 keeps lessons per role and changes their form.

## The ladder

Every lesson takes the strongest form it can:

1. **A check in code**: a test, an architecture rule, a lint rule, a hook. It cannot be forgotten and costs no context.
2. **A gate rule**: a path rule or a judge question in `rules.json`, with a measured threshold.
3. **One or two lines in one role's lessons file.**
4. **Nothing.** Most observations are not lessons.

Only what cannot be a check or a gate rule stays as prose. If a lesson can move up the ladder later, move it and delete the prose.

## Lessons files

`.sdlc/lessons/<role>.md`, one per role that reviews:

| File | Holds | Fed by |
|---|---|---|
| `reviewer.md` | What past reviews missed | Every bug that got past a review, unless it became a check |
| `architect.md` | Decisions and their reasons, in short | Retros and decision records |
| `security.md` | Traps this repository has fallen into | Security findings and incidents |

The author has no lessons file. What the author needs to know about the repository belongs in `CLAUDE.md`, which should stay short for the same reasons.

Rules for every file:

- **One entry is one or two lines**: the date, the pull request or incident it came from, and what to look for.
- **At most 40 lines of entries.** To add one when the file is full, take one out.
- **Entries expire.** A role names the entries it used in its verdict (`lessons_used`). Count those in `uses`. An entry leaves when a check covers it, or after 90 days without a use.
- **Entries are reviewed like code.** They arrive in their own pull request, never inside a change they would judge. A person sees every lesson before it sticks.
- **Lessons about one project stay in that project.** Never add them to a shared template or a public repository. Never write a secret or a working exploit into one.

```markdown
- 2026-01-31 (#123): The nightly job and the API both write the order status. A fix in one was missing in the other. Check both writers. uses: 3
```

## When a retro runs

Not after every change. A retro runs on a signal:

- a second fix for the same kind of bug within a month,
- an incident in production,
- a bug that a review approved.

Its output is one step on the ladder: a check, a gate rule, or one entry in one role's file. A retro that produces only prose has not finished. There is no retro agent in version 2. Whoever fixes the bug runs it, with this page as the contract.

It helps to keep a short ledger of bug classes: one section per class, one row per fix. The second row is the signal. A class is settled when an enforced rule exists, and a later fix of a settled class means the rule has a hole.

## Why not the tool's built-in memory

Claude Code can give a subagent its own memory folder: `memory: project` in the agent file creates `.claude/agent-memory/<name>/` and loads the start of its `MEMORY.md` into the agent. That would replace the lessons files with one line of configuration.

Version 2 does not use it yet, for one reason: turning it on also gives the agent write access to that folder, and the reviewer is meant to change nothing. A lessons file that the role only reads, and that changes through pull requests, keeps the reviewer read-only and works the same in every tool. If you try the built-in memory, keep the rules above: short, dated, expiring, and reviewed.
