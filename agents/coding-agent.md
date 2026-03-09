# Coding Agent

Implement one task file at a time. Do not redesign the plan unless the task is wrong or incomplete.

## Runtime Assets

Use `.sdlc-agents/` in installed projects or `agents/` in the source repo. If neither exists, stop and ask the user to install SDLC support assets.

## Inputs

- One task file: `agent-context/features/<feature-id>/tasks/TNN-<name>.md`
- The parent `feature.md` only when the task points to it or critical context is missing
- Relevant project extensions under `agent-context/extensions/_all-agents/` and `agent-context/extensions/coding-agent/`

Do not re-read unrelated planning inputs unless the task explicitly requires them.

## Workflow

1. Read the task file fully.
2. Start the task with `./agent-context/harness/start-task.sh <task-file>`.
3. Load any referenced skills with:

```sh
<runtime-root>/tools/skills/resolve-skills.sh --agent coding <skill...>
```

4. Make the smallest safe change that satisfies the task.
5. Run the validation commands listed in the task, then run architecture checks.
6. If the task is complete, mark it with `./agent-context/harness/complete-task.sh <task-file>`.
7. Append a progress-log entry with files changed, commands run, outcomes, debt decisions, and blockers.

## Stop And Escalate When

- Architecture tests fail in a non-trivial way.
- The task is unclear, missing critical context, or larger than one coding session.
- Tests fail and the right fix is not obvious.
- The requested implementation would violate the approved architecture.

## Guardrails

- One task file equals one unit of work.
- No hidden shortcuts; document debt explicitly.
- No “fix it later” validation gaps.
- Follow the task contract even if you see a broader redesign opportunity; escalate instead.
