# Templates Documentation

> Documentation for `agents/templates/`

This documents the templates that the Initializer Agent copies to your project workspace.

---

## Directory Structure

The templates are located at `agents/templates/`:

```
agents/templates/
├── harness/                   # Harness scripts
│   ├── init-project.sh        # Environment setup script
│   ├── run-feature.sh         # Per-feature test runner
│   ├── run-arch-tests.sh      # Architecture validation
│   ├── run-quality-gates.sh   # Full quality check
│   ├── next-task.sh           # Get next pending task
│   ├── start-task.sh          # Mark task as in_progress
│   ├── complete-task.sh       # Mark task as done
│   ├── list-features.sh       # Show feature status
│   └── progress-log.md        # Session log template
│
├── features/                  # Feature & task templates
│   ├── README.md              # Usage guide
│   ├── feature-template.md    # Template for features
│   └── tasks/
│       └── task-template.md   # Template for tasks
│
├── memory/                    # Learning & knowledge
│   └── learning-playbook.md   # Evolving knowledge base
│
└── context/                   # Context files
    ├── domain-heuristics.md   # Domain-specific patterns
    └── risk-patterns.md       # Common failure modes
```

**Note:** The `agents/guardrails/` folder contains static reference documents (not templates) that agents read directly.

---

## How Templates Work

When the **Initializer Agent** runs on your project:

1. **All template directories** are copied to `<project-root>/agent-context/`
2. Scripts are customized for your project's technology stack
3. Placeholder content is replaced with project-specific information

```
templates/harness/     →  <your-project>/agent-context/harness/
templates/memory/      →  <your-project>/agent-context/memory/
templates/context/     →  <your-project>/agent-context/context/
templates/features/    →  <your-project>/agent-context/features/
```

The **Planning Agent** creates features using the templates:
```
<your-project>/agent-context/features/FEAT-001/
├── feature.md         # From feature-template.md
├── progress-log.md    # Feature-specific progress log
└── tasks/
    ├── T01-xxx.md     # From task-template.md
    └── T02-xxx.md
```

---

## Template Categories

### Features (`features/`)

Self-contained task-based planning. See [`features/README.md`](./features/README.md).

| File | Purpose |
|------|---------|
| `feature-template.md` | Template for feature context and metadata |
| `tasks/task-template.md` | Template for self-contained task specifications |

**Key concept:** Each task file contains ALL context the Coding Agent needs. No need to read multiple files.

### Harness (`harness/`)

Scripts for running tests, quality checks, and task management. See [`harness/README.md`](./harness/README.md).

| Script | Purpose |
|--------|---------|
| `init-project.sh` | One-time environment setup |
| `run-feature.sh <id>` | Run tests for a specific feature |
| `run-arch-tests.sh` | Run architecture validation (auto-detects stack) |
| `run-quality-gates.sh` | Full quality check |
| `next-task.sh <feature>` | Get next pending task for a feature |
| `start-task.sh <task>` | Mark task as in_progress |
| `complete-task.sh <task>` | Mark task as done |
| `list-features.sh` | Show all features and status |

### Memory (`memory/`)

Knowledge management for the learning loop.

| File | Purpose |
|------|---------|
| `learning-playbook.md` | Evolving knowledge base with lessons learned |

**Note:** Quality control rules for lessons (`contamination-guidelines.md`) are a static reference in `agents/guardrails/`, not a project template.

### Guardrails (Static Reference)

Guardrails are **not templates** — they are static reference documents in `agents/guardrails/` that agents read directly. They are not copied to projects.

- [`guardrails/generative-debt-checklist.md`](../../agents/guardrails/generative-debt-checklist.md) - Debt awareness checklist
  - [Documentation](./guardrails/generative-debt-checklist.md) - Background context
- [`guardrails/contamination-guidelines.md`](../../agents/guardrails/contamination-guidelines.md) - Quality control for learnings
  - [Documentation](./guardrails/contamination-guidelines.md) - Background context

**Note:** Architectural rules come from actual tests (ArchUnit, dependency-cruiser, etc.), not documentation files.

### Context (`context/`)

Domain and risk patterns. See individual documentation:
- [`context/domain-heuristics.md`](./context/domain-heuristics.md) - Domain patterns
- [`context/risk-patterns.md`](./context/risk-patterns.md) - Risk patterns

| File | Purpose |
|------|---------|
| `domain-heuristics.md` | Domain-specific patterns and invariants |
| `risk-patterns.md` | Common failure modes to watch for |

---

## Customization

After copying to your project, customize:

1. **Domain heuristics** - Add your domain's patterns
2. **Risk patterns** - Add your project's known failure modes
3. **Harness scripts** - Match your build system and test patterns
4. **Feature templates** - Adjust to your project's needs

The templates are starting points, not final configurations.
