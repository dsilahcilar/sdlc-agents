# Planning Agent

> Transforms human requests (issues, tickets, features) into structured, architecture-aware plans.

**Agent Definition:** [`agentDirectory/agents/planning-agent.md`](../../agentDirectory/agents/planning-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Requirements → Plan |
| **Code Access** | None |
| **Runs When** | Start of each task |
| **Stack Detection** | ✅ Detects and documents in Solution Plan |

---

## Responsibilities

1. **Stack Detection** - Detects and documents in Solution Plan Section 1.1
2. **Requirements Clarification** - Functional, non-functional, constraints
3. **Structural Planning** - Modules, layers, dependencies, forbidden couplings
4. **Debt Awareness** - Identifies and documents trade-offs
5. **Context Generation** - Creates curated context for downstream agents

---

## Input Files

| File | Purpose |
|------|---------|
| Request (issue, ticket) | Human requirement |
| `<project-root>/harness/feature-requirements.json` | Feature status |
| `<project-root>/guardrails/architecture-as-guardrail.md` | Principles |
| `<project-root>/guardrails/architecture-rules.md` | Rules |
| `<project-root>/context/domain-heuristics.md` | Domain patterns |
| `<project-root>/context/risk-patterns.md` | Failure modes |
| `<project-root>/memory/learning-playbook.md` | Past lessons |
| `skills/stack-detection.md` | Stack detection rules |

---

## Output Files

| File | Purpose |
|------|---------|
| `<project-root>/plan/<issue-id>.SolutionPlan.md` | Structured plan |
| `<project-root>/context/<issue-id>.context.md` | Curated context (using `templates/context-template.md`) |
| `<project-root>/harness/progress-log.md` | Updated log |
| `<project-root>/harness/feature-requirements.json` | Updated status |

---

## Solution Plan Structure

```markdown
# Solution Plan: <title>

## 1. Context
## 1.1 Technology Stack    ← Critical for downstream agents
## 2. Requirements (FR, NFR, Constraints)
## 3. Architecture & Design (Layers, Dependencies, Forbidden Couplings)
## 4. Implementation Tasks
## 5. Structural & Generative Debt Risks
## 6. Test & Verification Strategy
## 7. Learnings Applied
## 8. Open Questions
```

---

## Workflow

1. **Detect Technology Stack** using `skills/stack-detection.md`
2. **Clarify Requirements** - Restate problem, identify FR/NFR/constraints
3. **Map to Features** - Update `feature-requirements.json`
4. **Produce Structural Plan** - Layers, dependencies, forbidden couplings
5. **Address Debt Risks** - Document trade-offs
6. **Generate Context File** - Create `<issue-id>.context.md`

---

## Constraints

- **No code generation** - Only planning and documentation
- **Rich context over brevity** - Avoid under-planning
- **Specific tasks** - Each task implementable in one Coding session
- **No ignored guardrails** - If a shortcut violates architecture, document the trade-off
- **Explicit conflicts** - If playbook entries conflict, highlight them

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Vague tasks ("Implement the feature") | Not implementable in one session |
| Missing module attribution | Coding agent doesn't know where |
| Ignored debt | Shortcuts must be documented, not hidden |
| Assumed context | Don't assume Coding agent knows what you know |
| Over-compression | A 5-line plan for a complex feature is brevity bias |

---

## Handoff

→ **[Architect Agent](./architect-agent.md)** review before Coding begins
