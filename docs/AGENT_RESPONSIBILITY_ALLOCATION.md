# Agent Responsibility Allocation

This document clarifies the separation of concerns between agents, specifically around **context provision vs. context consumption**.

---

## The Problem

Having different agents reduces contextual load and enables well-defined roles. However, some responsibilities were incorrectly shared between agents, particularly:

- **Stack detection** was being done by downstream agents (Coding, Code Review) when it should be part of their pre-assembled context
- **Environment discovery** was being repeated per-agent instead of being done once during planning

---

## Solution: Context Providers vs. Context Consumers

### Context Providers (Detect Stack)

These agents run **before** or **at the start** of a task and are responsible for discovering the environment and providing context to downstream agents:

| Agent | When It Runs | Stack Detection Responsibility |
|-------|--------------|-------------------------------|
| **Initializer Agent** | Project setup (once) | ✅ Detect and document in harness |
| **Architecture Discovery Agent** | Legacy project analysis (once) | ✅ Detect and document in report |
| **Planning Agent** | Start of each feature | ✅ Detect and include in feature.md + task files |

### Context Consumers (Receive Stack)

These agents run **after** planning and receive context from upstream agents. They should **NOT** detect the stack themselves:

| Agent | What It Receives | Source |
|-------|------------------|--------|
| **Architect Agent** | Stack info in feature.md | Planning Agent |
| **Coding Agent** | Stack info in task file and/or feature.md | Planning Agent |
| **Code Review Agent** | Stack info in feature.md + task files | Planning Agent |
| **Retro Agent** | Raw logs (doesn't need stack) | N/A |
| **Curator Agent** | Playbook entries (doesn't need stack) | N/A |

---

## Feature File: Technology Stack Section

The Planning Agent adds a **Technology Stack** section to every `feature.md`:

```markdown
## Technology Stack

**Stack:** <detected stack, e.g., java, typescript, python>
**Build System:** <e.g., Maven, Gradle, npm>
**Skill Reference:** `skills/stacks/<stack>.md`
**Architecture Tool:** <e.g., ArchUnit, dependency-cruiser>

### Validation Commands

| Check | Command |
|-------|---------|
| Build | `<build command>` |
| Unit Tests | `<test command>` |
| Architecture | `<arch check command>` |
```

---

## Task File: Self-Contained Context

Each task file contains all context needed for implementation:

- **Objective** - What to accomplish
- **What to Do** - Numbered steps
- **Files to Create/Modify** - Exact paths
- **Architectural Rules** - Rules for THIS task
- **Validation** - Commands to run
- **Done Criteria** - Checklist for completion

The Coding Agent reads **one task file** as its primary input.

---

## Benefits

1. **Reduced contextual load** - Downstream agents don't waste cycles on environment discovery
2. **Task isolation** - Each task file is self-contained
3. **Single source of truth** - Stack is determined once, embedded in context
4. **Clear escalation path** - If context is missing, agents know to escalate to Planning Agent
5. **Better LLM performance** - Focused context improves accuracy
6. **Clearer agent boundaries** - Each agent has a well-defined role

---

## Anti-Patterns to Avoid

1. ❌ **Coding Agent detecting stack** - It should receive this in its task file
2. ❌ **Code Review Agent loading stack-detection.md** - Already in feature.md
3. ❌ **Architect Agent discovering stack** - Already provided by Planning Agent
4. ❌ **Missing stack context in features** - Planning Agent must include it

---

## Escalation Rules

| Agent | If Stack Context Missing |
|-------|-------------------------|
| Coding Agent | STOP and escalate to Planning Agent |
| Code Review Agent | STOP and escalate to Planning Agent |
| Architect Agent | REJECT feature, return to Planning Agent |

---

## Key Files

- `agents/planning-agent.md` - Creates feature.md + task files with stack context
- `agents/coding-agent.md` - Receives self-contained task files
- `agents/codereview-agent.md` - Reviews with feature/task context
- `agents/architect-agent.md` - Reviews feature.md structure
- `agents/initializer-agent.md` - Sets up features/ directory
- `templates/features/feature-template.md` - Feature template
- `templates/features/tasks/task-template.md` - Task template
