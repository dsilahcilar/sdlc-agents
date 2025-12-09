# Features Templates Documentation

> Documentation for `agents/templates/features/`

The features directory contains **task-based planning templates** that implement a self-contained context architecture. Each feature has its own directory with context and isolated task files.

---

## Purpose

The features structure provides self-contained, task-based planning:

| Benefit | Description |
|---------|-------------|
| **Task isolation** | Each task file is self-contained |
| **Simple discovery** | `next-task.sh` returns task file path |
| **File-based state** | Status in frontmatter, no JSON parsing |
| **Clear organization** | One feature.md per feature |

---

## Structure

### In Templates

```
agents/templates/features/
├── README.md                    # Usage guide
├── feature-template.md          # Template for new features
└── tasks/
    └── task-template.md         # Template for new tasks
```

### In Your Project

```
<project-root>/agent-context/features/
├── FEAT-001/
│   ├── feature.md               # Feature context and metadata
│   └── tasks/
│       ├── T01-create-user-entity.md
│       ├── T02-add-repository.md
│       └── T03-add-service.md
├── FEAT-002/
│   ├── feature.md
│   └── tasks/
│       └── T01-initial-task.md
└── ...
```

---

## Feature File (`feature.md`)

Contains feature-level context shared across all tasks:

### Frontmatter

```yaml
---
id: FEAT-001
title: User Authentication
status: pending  # pending | in_progress | passing | blocked
module: auth
risk_level: high  # low | medium | high
created_at: 2024-01-15T10:00:00Z
updated_at: 2024-01-15T10:00:00Z
---
```

### Sections

| Section | Purpose |
|---------|---------|
| Description | What the feature does |
| Acceptance Criteria | What must be true when complete |
| Technology Stack | Stack, build system, validation commands |
| Architectural Constraints | Rules from architecture tests |
| Relevant Lessons | Curated from learning-playbook.md |
| Risk Patterns | From risk-patterns.md |
| Tasks | Summary table linking to task files |

---

## Task File (`T<NN>-<name>.md`)

Self-contained unit of work for the Coding Agent:

### Frontmatter

```yaml
---
id: T01
feature: FEAT-001
title: Create User Domain Entity
status: pending  # pending | in_progress | done | blocked
priority: 1
module: auth/domain
estimated_complexity: low  # low | medium | high
---
```

### Sections

| Section | Purpose |
|---------|---------|
| Objective | 1-2 sentences on what to accomplish |
| What to Do | Numbered steps |
| Files to Create/Modify | Table of files and actions |
| Architectural Rules | Specific rules for this task |
| Validation | Commands to verify completion |
| Done Criteria | Checkboxes that must all pass |
| Debt Checklist | Items from generative-debt-checklist.md |
| Notes | Additional context from feature.md |

---

## Workflow

### Planning Agent

1. Creates `features/<feature-id>/` directory
2. Creates `feature.md` from template with full context
3. Creates task files `tasks/T<NN>-<name>.md` for each step
4. All tasks start with `status: pending`

### Coding Agent

1. Receives task file path (single file)
2. Runs `start-task.sh` to mark as `in_progress`
3. Reads task file (self-contained context)
4. Optionally reads `feature.md` for broader context
5. Implements according to "What to Do"
6. Runs validation commands
7. Runs `complete-task.sh` to mark as `done`
8. Moves to next task or hands off

---

## Status Values

### Feature Status

| Status | Meaning | Transitions To |
|--------|---------|----------------|
| `pending` | Not started | `in_progress` |
| `in_progress` | At least one task started | `passing`, `blocked` |
| `passing` | All tasks done, all tests pass | - |
| `blocked` | External dependency blocking | `in_progress` |

### Task Status

| Status | Meaning | Transitions To |
|--------|---------|----------------|
| `pending` | Not started | `in_progress` |
| `in_progress` | Currently being worked on | `done`, `blocked` |
| `done` | Completed and verified | - |
| `blocked` | Cannot proceed | `in_progress`, `pending` |

---

## Design Benefits

This architecture provides:

- **Task isolation** — Each task is self-contained, no need to parse large plans
- **Minimal context** — Coding Agent reads one file per task
- **File-based state** — Status tracked in frontmatter, no JSON parsing
- **Clear boundaries** — One folder per feature
- **Parallelization** — Multiple sessions can work on different tasks simultaneously
