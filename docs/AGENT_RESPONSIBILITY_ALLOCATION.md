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
| **Planning Agent** | Start of each task | ✅ Detect and include in Solution Plan + Context file |

### Context Consumers (Receive Stack)

These agents run **after** planning and receive context from upstream agents. They should **NOT** detect the stack themselves:

| Agent | What It Receives | Source |
|-------|------------------|--------|
| **Architect Agent** | Stack info in Solution Plan Section 1.1 | Planning Agent |
| **Coding Agent** | Stack info in Context file | Planning Agent |
| **Code Review Agent** | Stack info in Solution Plan + Context file | Planning Agent |
| **Retro Agent** | Raw logs (doesn't need stack) | N/A |
| **Curator Agent** | Playbook entries (doesn't need stack) | N/A |

---

## Solution Plan: Technology Stack Section

The Planning Agent now adds a **Section 1.1: Technology Stack** to every Solution Plan:

```markdown
## 1.1 Technology Stack

**Stack:** <detected stack, e.g., java, typescript, python>
**Build System:** <e.g., Maven, Gradle, npm>
**Skill Reference:** `skills/stacks/<stack>.md`
**Architecture Tool:** <e.g., ArchUnit, dependency-cruiser>
**Validation Commands:**
- Build: `<command>`
- Test: `<command>`
- Architecture Check: `<command>`
```

---

## Context File: Technology Stack Section

The Context file (`<project-root>/agent-context/context/<issue-id>.context.md`) now includes:

```markdown
## Technology Stack

**Stack:** <detected stack>
**Skill Reference:** `skills/stacks/<stack>.md`
**Build System:** <e.g., Maven, Gradle, npm>
**Architecture Tool:** <e.g., ArchUnit, dependency-cruiser>

### Validation Commands

| Check | Command |
|-------|---------|
| Build | `<build command>` |
| Unit Tests | `<test command>` |
| Architecture | `<arch check command>` |
```

---

## Benefits

1. **Reduced contextual load** - Downstream agents don't waste cycles on environment discovery
2. **Single source of truth** - Stack is determined once, documented clearly
3. **Clear escalation path** - If context is missing, agents know to escalate to Planning Agent
4. **Better LLM performance** - Focused context improves accuracy
5. **Clearer agent boundaries** - Each agent has a well-defined role

---

## Anti-Patterns to Avoid

1. ❌ **Coding Agent detecting stack** - It should receive this in its context
2. ❌ **Code Review Agent loading stack-detection.md** - Already in Solution Plan
3. ❌ **Architect Agent discovering stack** - Already provided by Planning Agent
4. ❌ **Missing stack context in plans** - Planning Agent must include it

---

## Escalation Rules

| Agent | If Stack Context Missing |
|-------|-------------------------|
| Coding Agent | STOP and escalate to Planning Agent |
| Code Review Agent | STOP and escalate to Planning Agent |
| Architect Agent | REJECT plan, return to Planning Agent |

---

## Files Modified

- `agents/planning-agent.md` - Added stack detection responsibility and Technology Stack section
- `agents/coding-agent.md` - Changed to receive pre-assembled stack context
- `agents/codereview-agent.md` - Changed to receive pre-assembled stack context
- `agents/architect-agent.md` - Changed to receive stack from Solution Plan
- `agents/initializer-agent.md` - Clarified as context provider
- `agents/architecture-discovery-agent.md` - Clarified as context provider
- `templates/context-template.md` - Context file template (moved from context/)
- `skills/README.md` - Updated responsibility allocation documentation
