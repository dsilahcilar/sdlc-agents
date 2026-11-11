# Coming from version 1

Version 1 stays in this repository, unchanged: `agents/`, `tools/`, `docs/` and the root `install.sh`. Version 2 lives in `v2/` and installs beside it. Nothing here removes a version 1 install for you.

## What replaces what

| Version 1 | Version 2 | Why |
|---|---|---|
| Planning agent, `feature.md`, numbered task files | A one-page brief at the top of the pull request, written by whoever writes the code | Current models plan well. What they need is a stated goal, checks that can be run, and the blast radius. |
| Architect agent on every feature | `roles/architect.md`, started only when the gate names it | Most changes do not touch stored data, a contract or a new pattern. |
| Coding agent | Nothing. The session that wrote the brief writes the code. | Its rules (one task, read no other file, stop when unsure) now cost more than they prevent. |
| Code Review agent, with its checklist and report template | `roles/reviewer.md`: a fresh context, no edit tools, a JSON verdict | A checklist makes a reviewer tick boxes. Independence is what the role is for. |
| Retro agent | A retro on a signal, whose output is a check or a rule. See [learnings.md](./learnings.md). | A retro after every feature produced prose nobody read twice. |
| Curator agent, shared playbook, `extensions/<agent>/` folders | `.sdlc/lessons/<role>.md`: short, dated, expiring | See [learnings.md](./learnings.md). |
| Initializer agent | `v2/install.sh` and ten minutes with `rules.json` | A one-time job. |
| Stack and pattern skills, `#skill` directives, resolve scripts | Nothing | They restate what the model knows or can read in the repository. Keep a skill only for a choice the model would not guess. |
| Harness scripts generated per project | Your own test commands, named in the brief and in `CLAUDE.md` | The repository already has a way to run its tests. |
| Progress log | The pull request | It already records what happened. |

## What carries over

- **Architecture-first.** The architect still looks before code is written. Now the gate decides when.
- **Guardrails enforced, not documented.** Still the point. Version 2 goes further: a lesson that can be a check must become one.
- **Roles with clear handovers.** Fewer roles, and a script at each handover.

## Moving a repository over

1. Run `v2/install.sh --target <repository>`. It adds files and removes nothing.
2. Edit `.sdlc/rules.json` for your paths and paste the contract into `CLAUDE.md`.
3. Run the gate in shadow for a while. See the [README](../README.md).
4. Go through `agent-context/extensions/` and the learning playbook once. For each lesson that is still true, take it up the ladder in [learnings.md](./learnings.md): a check if it can be one, a gate rule if not, a line in a lessons file as the last resort. Archive the rest.
5. Remove the version 1 install when nothing reads it any more: the `.sdlc-agents` link or folder, the seven agent files in `.claude/agents/` (`planning-agent.md`, `architect-agent.md`, `coding-agent.md`, `codereview-agent.md`, `retro-agent.md`, `curator-agent.md`, `initializer-agent.md`), and `agent-context/` if nothing in it is still used.

One thing to check in step 5: a version 1 install made without `--copy` is a link to the folder where you cloned this repository. On any other machine, in CI or in a cloud session, that link points nowhere. The seven agents still show up by name there, and their instructions cannot be read.
