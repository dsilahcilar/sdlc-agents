# Context Template

Template for generating task-specific context files.

---

## Output Location

`<project-root>/agent-context/context/<issue-id>.context.md`

---

## Template

```markdown
# Task Context: <issue-id>

Generated: <ISO8601 timestamp>

---

## Task Summary

<brief description of the task>

## Scope

- **Module(s):** <modules>
- **Language:** <language>
- **Framework:** <framework>
- **Risk Level:** <risk level>

---

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

---

## Architectural Constraints

<extracted from architecture-as-guardrail.md, relevant to this task>

- <constraint 1>
- <constraint 2>

---

## Relevant Lessons

### Lesson 1: <title from playbook>

**Context:** <when this applies>

**Guidelines:**
- <guideline 1>
- <guideline 2>

**What worked:**
- <success pattern>

**What failed:**
- <failure pattern>

---

## Risk Patterns to Watch

<extracted from risk-patterns.md, relevant to this task>

- <risk 1>
- <risk 2>

---

## Domain Heuristics

<extracted from domain-heuristics.md, if applicable>

- <heuristic 1>
- <heuristic 2>

---

## Debt Checklist

<most relevant items from generative-debt-checklist.md>

- [ ] <debt check 1>
- [ ] <debt check 2>

---

## Previous Session State

<summary from progress-log.md if continuing work>

- Last action: <what was done>
- Current status: <where we are>
- Open questions: <unresolved items>
```

---

## Source Materials

Gather from these sources to populate the template:

| Source | Use For |
|--------|---------|
| `agent-context/plan/<issue-id>.SolutionPlan.md` | Task summary, scope, stack |
| `agent-context/harness/progress-log.md` | Previous session state |
| `agent-context/guardrails/architecture-as-guardrail.md` | Architectural constraints |
| `agent-context/guardrails/generative-debt-checklist.md` | Debt checklist |
| `agent-context/context/domain-heuristics.md` | Domain heuristics |
| `agent-context/context/risk-patterns.md` | Risk patterns |
| `agent-context/memory/learning-playbook.md` | Relevant lessons |
| `skills/stacks/<stack>.md` | Validation commands |

---

## Playbook Entry Selection

From `memory/learning-playbook.md`, select entries using these criteria:

**Filter by context match:**
- Same module (+0.30)
- Same language (+0.20)
- Same framework (+0.25)
- Same domain (+0.15)
- Similar risk level (+0.10)

**Score remaining entries:**
- Importance weight: 0.35
- Relevance weight: 0.40
- Recency weight: 0.25

**Selection limits:**
- Maximum 8 entries
- Minimum score: 0.7

---

## Quality Criteria

Before finalizing context file:

- [ ] Technology stack is specified (stack name, skill reference)
- [ ] Validation commands are included (build, test, architecture)
- [ ] Lessons are relevant (match module/framework)
- [ ] Architectural constraints are included
- [ ] Risk patterns are included
- [ ] Previous session state is current (if applicable)
