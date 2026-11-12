# Initializer Agent

> Performs one-time setup for long-running, multi-session development work, including architecture discovery for legacy projects.

**Agent Definition:** [`agents/initializer-agent.md`](../../agents/initializer-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Project setup + architecture discovery |
| **Code Access** | Read-only |
| **Runs When** | Once per project |
| **Stack Detection** | ✅ Detects and documents technology stack |

---

## Responsibilities

1. **Run Setup Script** - Executes `setup.sh` to copy all templates atomically
2. **Stack Detection** - Detects and documents technology stack using `skills/stack-detection.md`
3. **Stack Customization** - Updates copied templates for detected stack
4. **Feature Creation** - Creates initial feature using `features/feature-template.md`
5. **Architecture Discovery** (legacy projects only) - Analyzes existing codebase patterns, generates rules
6. **Health Verification** - Ensures harness scripts run without error

---

## Setup Script

The Initializer Agent uses `agents/setup.sh` to copy all templates in one atomic operation:

```sh
<sdlc-agents-path>/agents/setup.sh <sdlc-agents-path> <project-root>
```

**Options:**
- `-f` — Force overwrite existing files
- `-h` — Show help

This approach increases determinism by handling all file copying in a single script, leaving only value-filling for the LLM.

---

## Output Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/harness/init-project.sh` | Environment setup script |
| `<project-root>/agent-context/harness/run-feature.sh` | Per-feature test runner |
| `<project-root>/agent-context/harness/run-arch-tests.sh` | Architecture validation |
| `<project-root>/agent-context/harness/run-quality-gates.sh` | Full quality check |
| `<project-root>/agent-context/harness/next-task.sh` | Get next pending task |
| `<project-root>/agent-context/harness/start-task.sh` | Mark task as in_progress |
| `<project-root>/agent-context/harness/complete-task.sh` | Mark task as done |
| `<project-root>/agent-context/harness/list-features.sh` | Show feature status |
| `<project-root>/agent-context/harness/progress-log.md` | Session log |
| `<project-root>/agent-context/features/` | Feature templates |
| `<project-root>/agent-context/memory/learning-playbook.md` | Knowledge base |
| `<project-root>/agent-context/context/domain-heuristics.md` | Domain patterns |
| `<project-root>/agent-context/context/risk-patterns.md` | Failure modes |
| `docs/architecture-discovery-report.md` | Analysis results (if legacy project) |

---

## Workflow

```
1. RUN SETUP SCRIPT
   setup.sh copies all templates atomically
   │
   ▼
2. DETECT STACK
   Read skills/stack-detection.md
   │
   ▼
3. CUSTOMIZE FOR STACK
   Update harness scripts with stack-specific commands
   │
   ▼
4. CREATE INITIAL FEATURE
   Copy feature-template.md to features/FEAT-001/feature.md
   │
   ▼
5. ARCHITECTURE DISCOVERY (conditional)
   │
   ├── Legacy project without tests? → Perform discovery
   │
   └── Greenfield OR tests exist? → Skip
   │
   ▼
6. VERIFY HEALTH
   Run init-project.sh, run-arch-tests.sh, run-quality-gates.sh
   │
   ▼
7. COMMIT
   "chore: initialize SDLC agent harness"
```

---

## Stack Customization

After running the setup script, customize these files for the detected stack:

| File | Customization |
|------|---------------|
| `harness/init-project.sh` | Set build commands for stack |
| `harness/run-arch-tests.sh` | Set architecture test commands |
| `harness/run-quality-gates.sh` | Set lint/format/test commands |
| `harness/run-feature.sh` | Set test runner for stack |

---

## Architecture Discovery (Conditional)

For legacy projects without existing architecture tests:

### Process

1. **Analyze Structure** - Map packages, detect layers, build dependency graph
2. **Recognize Patterns** - Identify Layered, Hexagonal, Clean Architecture, etc.
3. **Detect Violations** - Find cycles, wrong-direction dependencies
4. **Generate Report** - Create `docs/architecture-discovery-report.md`
5. **Request Team Review** - Validate inferred patterns before proceeding

### Pattern Recognition

| Pattern | Signals |
|---------|---------|
| **Layered** | controller → service → repository, unidirectional |
| **Hexagonal** | ports/adapters, domain isolated |
| **Clean Architecture** | use cases, entities, dependency rule |
| **Modular Monolith** | feature-based packages (user/, order/) |
| **MVC** | model/view/controller separation |

---

## Constraints

- **No business logic** - Only scaffolding, configuration, and discovery
- **POSIX shell scripts** - Avoid bash-isms for portability
- **Idempotent operations** - Scripts should be safe to re-run
- **Read-only analysis** - Discovery does not modify existing code
- **Non-judgmental discovery** - Document what IS, not what SHOULD BE
- **Document violations as debt** - Not as immediate blockers

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Loading all skills | Only load the detected stack's skill |
| Imposing ideal architecture | Discover what exists |
| Breaking the build | Generated rules should pass initially |
| Over-strictness | Start broad, tighten over time |
| Skipping team review | Discovery results need validation |

---

## Handoff

→ Ready for **[Planning Agent](./planning-agent.md)**
