# Coming from the earlier pipeline

This project started as a pipeline of seven agents, one per phase of the work. It is kept in [`legacy/`](../legacy/README.md), unchanged, and still installs with `legacy/install.sh`. It is no longer developed. This page maps each of its pieces to what replaces it, and says how to move a repository over. Nothing here removes an earlier install for you.

## What replaces what

| Earlier pipeline | Now | Why |
|---|---|---|
| Planning agent, `feature.md`, numbered task files | A one-page brief at the top of the pull request, written by whoever writes the code | Current models plan well. What they need is a stated goal, checks that can be run, and the blast radius. |
| Architect agent on every feature | `roles/architect.md`, started only when the gate names it | Most changes do not touch stored data, a contract or a new pattern. |
| Coding agent | Nothing. The session that wrote the brief writes the code. | Its rules (one task, read no other file, stop when unsure) now cost more than they prevent. |
| Code Review agent, with its checklist and report template | `roles/reviewer.md`: a fresh context, no edit tools, a JSON verdict | A checklist makes a reviewer tick boxes. Independence is what the role is for. |
| Retro agent | A retro on a signal, whose output is a check or a rule, and a `retro` role that reads the merged history every few weeks and proposes which places the reviewer reads. See [learnings.md](./learnings.md) and [risk.md](./risk.md). | A retro after every feature produced prose nobody read twice. |
| Curator agent, shared playbook, `extensions/<agent>/` folders | `.sdlc/lessons/<role>.md`: short, dated, expiring | See [learnings.md](./learnings.md). |
| Initializer agent | `install.sh` and ten minutes with `rules.json` | A one-time job. |
| Stack and pattern skills, `#skill` directives, resolve scripts | Nothing | They restate what the model knows or can read in the repository. Keep a skill only for a choice the model would not guess. |
| Harness scripts generated per project | Your own test commands, named in the brief and in `CLAUDE.md` | The repository already has a way to run its tests. |
| Progress log | The pull request | It already records what happened. |

## What carries over

- **Architecture-first.** The architect still looks before code is written. Now the gate decides when.
- **Guardrails enforced, not documented.** Still the point, and taken further: a lesson that can be a check must become one, and the gate itself holds the pull request.
- **Roles with clear handovers.** Fewer roles, and a script at each handover.

## Moving a repository over

1. Run `install.sh --target <repository>` from the root of this repository. It adds files and removes nothing.
2. Edit `.sdlc/rules.json` for your paths and paste the contract into `CLAUDE.md`.
3. Copy the workflow to `.github/workflows/`. If you want to read what the rules ask for before they hold anything, set `ENFORCE` to `"false"` in it for the first pull requests. See the [README](../README.md).
4. Go through `agent-context/extensions/` and the learning playbook once. For each lesson that is still true, take it up the ladder in [learnings.md](./learnings.md): a check if it can be one, a gate rule if not, a line in a lessons file as the last resort. Archive the rest.
5. Remove the earlier install when nothing reads it any more: the `.sdlc-agents` link or folder, the seven agent files in `.claude/agents/` (`planning-agent.md`, `architect-agent.md`, `coding-agent.md`, `codereview-agent.md`, `retro-agent.md`, `curator-agent.md`, `initializer-agent.md`), and `agent-context/` if nothing in it is still used.

One thing to check in step 5: an earlier install made without `--copy` is a link to the folder where you cloned this repository. On any other machine, in CI or in a cloud session, that link points nowhere. The seven agents still show up by name there, and their instructions cannot be read.

Such a link also breaks when that clone is updated past the move to `legacy/`: it points at an `agents/` folder that is now `legacy/agents/`. To keep the earlier pipeline working there, delete the `.sdlc-agents` link and run `legacy/install.sh` again, or stay on the commit before the move.
