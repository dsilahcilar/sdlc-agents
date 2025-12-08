# Coding Agent

> Implements the approved plan incrementally, one task at a time, while strictly respecting architecture guardrails.

**Agent Definition:** [`agentDirectory/agents/coding-agent.md`](../../agentDirectory/agents/coding-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Implementation |
| **Code Access** | Read/Write |
| **Runs When** | After approval |
| **Stack Detection** | ❌ Receives from Context file |

---

## Core Principles

1. **One task at a time** - Complete before starting another
2. **Smallest safe change** - Prefer small, verifiable changes
3. **Architecture is non-negotiable** - Never bypass guardrails
4. **Log everything** - Every action in `progress-log.md`
5. **Fail fast** - Stop and document blockers

---

## Responsibilities

1. **Stack Context** - Uses pre-assembled context (does NOT detect stack)
2. **Incremental Implementation** - One task, one commit, one log entry
3. **Architecture Compliance** - Architecture test failures are HARD ERRORS
4. **Progress Logging** - Every action documented

---

## Input Files

| File | Purpose |
|------|---------|
| `<project-root>/plan/<issue-id>.SolutionPlan.md` | Approved plan |
| `<project-root>/context/<issue-id>.context.md` | Curated context (includes stack) |
| `<project-root>/harness/feature-requirements.json` | Feature registry |
| `<project-root>/harness/progress-log.md` | Previous progress |

**Important:** Does NOT read the full `learning-playbook.md` directly. Relevant entries are curated in `context.md`.

---

## Output Files

| File | Action |
|------|--------|
| Source code files | Created/Modified |
| Test files | Created/Modified |
| `<project-root>/harness/progress-log.md` | Session entry appended |
| `<project-root>/harness/feature-requirements.json` | Status updated |

---

## Workflow Per Task

```
1. SELECT TASK
   - Choose next incomplete task from plan
   - Identify corresponding feature ID
   - Log: "Starting task T<n>: <description>"
          │
          ▼
2. GATHER CONTEXT
   - Open relevant source files
   - Review context/<issue-id>.context.md
   - Check applicable guardrails
          │
          ▼
3. IMPLEMENT CHANGE
   - Make the smallest change that works
   - Respect layer boundaries
   - No new cross-module dependencies unless explicitly allowed
          │
          ▼
4. RUN CHECKS
   - harness/run-feature.sh <feature-id>
   - harness/run-arch-tests.sh
   - harness/run-quality-gates.sh (optional)
          │
          ▼
5. EVALUATE RESULTS
   - Tests pass? → Continue
   - Tests fail? → Fix or stop
   - Architecture tests fail? → HARD STOP
          │
          ▼
6. LOG PROGRESS
   - Append to progress-log.md
   - Update feature status in JSON
   - Commit with descriptive message
          │
          ▼
   [Next task or done]
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
- [ ] Implementation reveals plan is incorrect
- [ ] Required context is missing
- [ ] Tests fail and fix is non-obvious
- [ ] Scope creep: task is larger than expected
- [ ] Conflicting requirements discovered

**Stopping is not failure. Unlogged problems are failure.**

---

## Constraints

- **No plan changes** - If the plan is wrong, stop and escalate
- **No architecture violations** - Architecture test failures block progress
- **No hidden shortcuts** - All debt must be logged
- **No context overload** - Use only `context/<issue-id>.context.md`, not full playbook
- **No multi-task batching** - One task, one commit, one log entry

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| "I'll fix the tests later" | Tests must pass before proceeding |
| "It's just a small violation" | Violations compound |
| "The plan didn't mention this" | Stop and ask, don't assume |
| "I know a better way" | Follow the approved plan |
| "I'll document it later" | Log as you go, not after |

---

## Handoff

→ **[Code Review Agent](./codereview-agent.md)**
