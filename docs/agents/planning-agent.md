# Planning Agent

> Transforms human requests (issues, tickets, features) into structured, self-contained task specifications.

**Agent Definition:** [`agents/planning-agent.md`](../../agents/planning-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Requirements → Feature + Tasks |
| **Code Access** | None |
| **Runs When** | Start of each feature |
| **Stack Detection** | ✅ Detects and documents in feature.md |

---

## Responsibilities

1. **Stack Detection** - Detects and documents in feature.md
2. **Requirements Clarification** - Functional, non-functional, constraints
3. **Feature Planning** - Creates feature directory with context
4. **Task Decomposition** - Creates self-contained task files
5. **Debt Awareness** - Documents trade-offs in each task
6. **Context Embedding** - All relevant context IN the task files

---

## Input Files

| File | Purpose |
|------|---------|
| Request (issue, ticket) | Human requirement |
| Architecture tests (ArchUnit, etc.) | Architectural rules |
| `<project-root>/agent-context/context/domain-heuristics.md` | Domain patterns |
| `<project-root>/agent-context/context/risk-patterns.md` | Failure modes |
| `<project-root>/agent-context/memory/learning-playbook.md` | Past lessons |
| `skills/stack-detection.md` | Stack detection rules |
| `templates/features/feature-template.md` | Feature template |
| `templates/features/tasks/task-template.md` | Task template |

---

## Output Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/features/<feature-id>/feature.md` | Feature context |
| `<project-root>/agent-context/features/<feature-id>/tasks/T<NN>-<name>.md` | Task specifications |
| `<project-root>/agent-context/harness/progress-log.md` | Updated log |

---

## Feature Structure

```
<project-root>/agent-context/features/FEAT-001/
├── feature.md               # Feature-level context
└── tasks/
    ├── T01-create-entity.md
    ├── T02-add-repository.md
    └── T03-add-service.md
```

### feature.md Contains

- Feature metadata (id, title, status, risk level)
- Acceptance criteria
- Technology stack & validation commands
- Architectural constraints (from tests)
- Relevant lessons (from playbook)
- Risk patterns
- Tasks summary table

### Task Files Contain

- Task metadata (id, feature, status, priority)
- Clear objective (1-2 sentences)
- Numbered steps (what to do)
- Files to create/modify
- Architectural rules for THIS task
- Validation commands
- Done criteria checklist
- Debt checklist

---

## Workflow

1. **Detect Technology Stack** using `skills/stack-detection.md`
2. **Clarify Requirements** - Restate problem, identify FR/NFR/constraints
3. **Create Feature Directory** - `features/<feature-id>/`
4. **Create feature.md** - Full context from template
5. **Create Task Files** - One per implementation step
6. **Log Entry** - Update progress-log.md

---

## Key Principle: Self-Contained Tasks

**Each task file must be self-contained.** The Coding Agent should be able to complete the task by reading ONLY the task file (with optional reference to feature.md for broader context).

Include in each task:
- Specific architectural rules (not just "follow architecture")
- Exact file paths to create/modify
- Exact validation commands
- Clear done criteria

---

## Constraints

- **No code generation** - Only planning and documentation
- **Self-contained tasks** - Coding Agent reads ONE file
- **Rich context** - Include all needed info in task files
- **Specific tasks** - Each task implementable in one Coding session
- **No ignored guardrails** - Document trade-offs explicitly

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Vague tasks ("Implement the feature") | Not implementable in one session |
| Missing file paths | Coding agent doesn't know where |
| Assumed context | Don't assume Coding agent will read feature.md |
| Tasks too large | Should complete in one session |
| Context scattered across files | Task should be self-contained |

---

## Handoff

1. Create feature directory with all files
2. Run `./agent-context/harness/list-features.sh` to verify
3. → **[Architect Agent](./architect-agent.md)** review of feature.md
