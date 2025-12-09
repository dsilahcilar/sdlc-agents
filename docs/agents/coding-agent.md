# Coding Agent

> Implements ONE task at a time from a self-contained task file, while strictly respecting architecture guardrails.

**Agent Definition:** [`agents/coding-agent.md`](../../agents/coding-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Implementation |
| **Code Access** | Read/Write |
| **Runs When** | After approval |
| **Stack Detection** | ❌ Receives from task/feature file |

---

## Core Principles

1. **One task at a time** - Complete before starting another
2. **Smallest safe change** - Prefer small, verifiable changes
3. **Architecture is non-negotiable** - Never bypass guardrails
4. **Log everything** - Every action in `progress-log.md`
5. **Fail fast** - Stop and document blockers

---

## Responsibilities

1. **Task Execution** - Implements what the task file specifies
2. **Stack Context** - Uses pre-assembled context (does NOT detect stack)
3. **Architecture Compliance** - Architecture test failures are HARD ERRORS
4. **Progress Logging** - Every action documented

---

## Input Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/features/<feature-id>/tasks/T<NN>-<name>.md` | **Primary input** - self-contained task |
| `<project-root>/agent-context/features/<feature-id>/feature.md` | Optional broader context |
| `<project-root>/agent-context/harness/progress-log.md` | Previous progress |

**Key insight:** The task file contains ALL context needed:
- What to do (numbered steps)
- Files to create/modify
- Architectural rules
- Validation commands
- Done criteria

**Does NOT read** the full `learning-playbook.md` directly. Relevant entries are curated in task/feature files.

---

## Output Files

| File | Action |
|------|--------|
| Source code files | Created/Modified |
| Test files | Created/Modified |
| Task file (frontmatter) | Status updated to `done` |
| `<project-root>/agent-context/harness/progress-log.md` | Session entry appended |

---

## Workflow Per Task

```
1. RECEIVE TASK FILE
   - Receive path: features/<feature-id>/tasks/T01-xxx.md
   - Read the task file completely
           │
           ▼
2. START TASK
   - Run: ./harness/start-task.sh <task-file>
   - Log: "Starting task T<n>: <title>"
           │
           ▼
3. GATHER CONTEXT
   - Review "What to Do" section
   - Review "Files to Create/Modify" section
   - Review "Architectural Rules" section
   - (Optional) Read feature.md for broader context
           │
           ▼
4. IMPLEMENT CHANGE
   - Follow the numbered steps exactly
   - Respect layer boundaries
   - No changes outside task scope
           │
           ▼
5. RUN CHECKS
   - Run validation commands from task file
   - ./harness/run-arch-tests.sh
           │
           ▼
6. EVALUATE RESULTS
   - Tests pass? → Continue
   - Tests fail? → Fix or stop
   - Architecture tests fail? → HARD STOP
           │
           ▼
7. COMPLETE TASK
   - Verify all Done Criteria met
   - Run: ./harness/complete-task.sh <task-file>
   - Append to progress-log.md
   - Commit with descriptive message
           │
           ▼
   [Get next task or handoff]
```

---

## Getting Next Task

After completing a task:

```bash
./agent-context/harness/next-task.sh <feature-id>
# Returns: features/<feature-id>/tasks/T02-xxx.md
```

If no pending tasks remain:
```
[next-task] All 5 tasks are done for FEAT-001
```

---

## Architecture Violation Protocol

**Architecture test failures are HARD ERRORS.**

When `harness/run-arch-tests.sh` fails:

1. **DO NOT proceed** with more coding
2. **Analyze the violation**:
   - Simple fix (move import, change package)?
   - Fundamental design flaw?
3. **If simple fix**: Fix and re-run
4. **If design flaw**:
   - Stop coding
   - Log violation in `progress-log.md`
   - Escalate to Architect Agent or human
5. **Never suppress or ignore architecture test failures**

---

## When to Stop

Stop and escalate when:

- [ ] Architecture test fails with non-trivial violation
- [ ] Task specification is incorrect or unclear
- [ ] Required context is missing from task file
- [ ] Tests fail and fix is non-obvious
- [ ] Scope creep: task is larger than described
- [ ] Conflicting requirements discovered

**Stopping is not failure. Unlogged problems are failure.**

---

## Constraints

- **One task file = one unit of work** - Don't mix tasks
- **No task changes** - If task is wrong, stop and escalate
- **No architecture violations** - Architecture test failures block progress
- **No hidden shortcuts** - Use Debt Checklist in task file
- **No context exploring** - Use only task file + optional feature.md

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| "I'll fix the tests later" | Tests must pass before proceeding |
| "It's just a small violation" | Violations compound |
| "The task didn't mention this" | Stop and ask, don't assume |
| "I know a better way" | Follow the task specification |
| "I'll document it later" | Log as you go, not after |
| Reading files not in task | Stay focused on task scope |

---

## Handoff

After completing all tasks:

1. Verify: `./harness/list-features.sh` shows feature as `passing`
2. → **[Code Review Agent](./codereview-agent.md)** with feature directory path
