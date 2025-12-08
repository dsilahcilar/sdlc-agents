# Templates Documentation

> Documentation for `agents/templates/`

This documents the templates that the Initializer Agent copies to your project workspace.

---

## Directory Structure

The templates are located at `agents/templates/`:

```
agents/templates/
├── context-template.md        # Template for task-specific context files
│
├── harness/                   # Harness scripts
│   ├── init-project.sh        # Environment setup script
│   ├── run-feature.sh         # Per-feature test runner
│   ├── run-arch-tests.sh      # Architecture validation
│   ├── run-quality-gates.sh   # Full quality check
│   ├── feature-requirements.json  # Feature registry
│   └── progress-log.md        # Session log template
│
├── memory/                    # Learning & knowledge
│   ├── learning-playbook.md   # Evolving knowledge base
│   ├── retrieval-config.json  # Retrieval scoring weights
│   └── contamination-guidelines.md  # Quality control for learnings
│
├── guardrails/                # Architecture guardrails
│   ├── architecture-as-guardrail.md  # Non-negotiable principles
│   ├── architecture-rules.md  # Deterministic rule descriptions
│   └── generative-debt-checklist.md  # Debt awareness checklist
│
└── context/                   # Context files
    ├── domain-heuristics.md   # Domain-specific patterns
    └── risk-patterns.md       # Common failure modes
```

---

## How Templates Work

When the **Initializer Agent** runs on your project:

1. **All template directories** are copied to `<project-root>/agent-context/`
2. Scripts are customized for your project's technology stack
3. Placeholder content is replaced with project-specific information

```
templates/harness/     →  <your-project>/agent-context/harness/
templates/memory/      →  <your-project>/agent-context/memory/
templates/guardrails/  →  <your-project>/agent-context/guardrails/
templates/context/     →  <your-project>/agent-context/context/
```

The `context-template.md` is used by the **Planning Agent** to generate:
```
<your-project>/agent-context/context/<issue-id>.context.md
```

---

## Template Categories

### Harness (`harness/`)

Scripts for running tests and quality checks. See [`harness/README.md`](./harness/README.md).

| Script | Purpose |
|--------|---------|
| `init-project.sh` | One-time environment setup |
| `run-feature.sh <id>` | Run tests for a specific feature |
| `run-arch-tests.sh` | Run architecture validation (auto-detects stack) |
| `run-quality-gates.sh` | Full quality check |

### Memory (`memory/`)

Knowledge management for the learning loop.

| File | Purpose |
|------|---------|
| `learning-playbook.md` | Evolving knowledge base with lessons learned |
| `retrieval-config.json` | Scoring weights for context selection |
| `contamination-guidelines.md` | Quality control rules for lessons |

### Guardrails (`guardrails/`)

Architecture enforcement.

| File | Purpose |
|------|---------|
| `architecture-as-guardrail.md` | Human-readable architectural principles |
| `architecture-rules.md` | Deterministic rules (language-agnostic) |
| `generative-debt-checklist.md` | Checklist for avoiding generative debt |

### Context (`context/`)

Domain and risk patterns.

| File | Purpose |
|------|---------|
| `domain-heuristics.md` | Domain-specific patterns and invariants |
| `risk-patterns.md` | Common failure modes to watch for |

---

## Customization

After copying to your project, customize:

1. **Guardrails** - Add your project's architectural principles
2. **Domain heuristics** - Add your domain's patterns
3. **Risk patterns** - Add your project's known failure modes
4. **Harness scripts** - Match your build system and test patterns

The templates are starting points, not final configurations.
