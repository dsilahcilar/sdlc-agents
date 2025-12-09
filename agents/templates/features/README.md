# Features Directory

This directory contains feature specifications and their tasks.

## Structure

```
features/
├── README.md                    # This file
├── feature-template.md          # Template for new features
└── tasks/
    └── task-template.md         # Template for new tasks
```

## In Your Project

When copied to your project, the structure becomes:

```
<project-root>/agent-context/features/
├── FEAT-001/
│   ├── feature.md               # Feature context and metadata
│   └── tasks/
│       ├── T01-create-entity.md
│       ├── T02-add-repository.md
│       └── T03-add-service.md
├── FEAT-002/
│   ├── feature.md
│   └── tasks/
│       └── T01-initial-task.md
└── ...
```

## Workflow

### Planning Agent

1. Creates `features/<feature-id>/feature.md` from `feature-template.md`
2. Creates `features/<feature-id>/tasks/T<NN>-<name>.md` for each task
3. Sets all task statuses to `pending`

### Coding Agent

1. Receives a specific task file path (e.g., `features/FEAT-001/tasks/T01-create-entity.md`)
2. Reads the task file (self-contained context)
3. Optionally reads `features/FEAT-001/feature.md` for broader context
4. Implements the task
5. Updates task status to `done` (or `blocked` if stuck)

### Task Selection

Use `./agent-context/harness/next-task.sh` to find next pending task:

```bash
./agent-context/harness/next-task.sh FEAT-001
# Output: features/FEAT-001/tasks/T02-add-repository.md
```

## Status Values

### Feature Status

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `in_progress` | At least one task in progress |
| `passing` | All tasks done, all tests passing |
| `blocked` | Cannot proceed due to external dependency |

### Task Status

| Status | Meaning |
|--------|---------|
| `pending` | Not started |
| `in_progress` | Currently being worked on |
| `done` | Completed and verified |
| `blocked` | Cannot proceed, needs escalation |

## Design Benefits

This architecture provides:

- **Task isolation** — Each task is self-contained
- **Minimal context** — Coding Agent reads one file per task
- **File-based state** — Status tracked in frontmatter
- **Clear boundaries** — One folder per feature
- **Parallelization** — Multiple sessions can work different tasks
