# Architect Agent

> Evaluates proposed plans from the perspective of structural integrity, modularity, and long-term maintainability.

**Agent Definition:** [`agents/architect-agent.md`](../../agents/architect-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Structural review |
| **Code Access** | None |
| **Runs When** | After planning |
| **Stack Detection** | ❌ Receives from Solution Plan Section 1.1 |

---

## Why This Agent Exists

> "Structural Debt (Hallucinated Coupling): This occurs when the LLM generates code that runs but violates fundamental structural integrity or modularity principles, leading to code that is expensive to refactor later."

LLMs are notoriously weak at architectural decisions. This agent provides a dedicated architectural review step backed by deterministic validation.

---

## Responsibilities

1. **Stack Context** - Uses pre-assembled context from Solution Plan (does NOT detect stack)
2. **Structural Validation** - Detects hallucinated coupling, layer violations
3. **Generative Debt Prevention** - Requires explicit documentation of shortcuts
4. **Guardrail Updates** - Suggests new architecture rules

---

## Input Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/plan/<issue-id>.SolutionPlan.md` | Plan to review (includes Technology Stack section) |
| `<project-root>/agent-context/guardrails/architecture-as-guardrail.md` | Principles |
| `<project-root>/agent-context/guardrails/architecture-rules.md` | Rules |
| `<project-root>/agent-context/guardrails/generative-debt-checklist.md` | Debt checklist |
| `<project-root>/agent-context/context/domain-heuristics.md` | Domain patterns |
| `<project-root>/agent-context/context/risk-patterns.md` | Failure modes |
| `<project-root>/agent-context/memory/learning-playbook.md` | Past lessons |
| `skills/stacks/<stack>.md` | Stack-specific tool (from Solution Plan) |

---

## Output Files

| File | Action |
|------|--------|
| `<project-root>/agent-context/plan/<issue-id>.SolutionPlan.md` | Append Section 9: Architecture Review |
| `<project-root>/agent-context/harness/progress-log.md` | Updated with review summary |
| `<project-root>/agent-context/context/<issue-id>.context.md` | Updated with architectural constraints |

---

## Review Checklist

From `guardrails/generative-debt-checklist.md`:

- [ ] Am I introducing a shortcut that will be hard to undo later?
- [ ] Am I coupling modules that were previously independent?
- [ ] Am I bypassing an abstraction layer for convenience?
- [ ] Am I skipping or weakening tests to save time?
- [ ] Am I adding tech-specific details into domain logic?
- [ ] Am I creating implicit contracts between modules?
- [ ] Am I duplicating logic that should be shared?
- [ ] Am I sharing logic that should be isolated?

---

## Decisions

| Decision | Meaning |
|----------|---------|
| **Approved** | Plan is structurally sound, Coding Agent can proceed |
| **Approved with conditions** | Must address findings before coding |
| **Rejected** | Planning Agent must revise |

---

## Escalation Criteria

Escalate to human architect when:

1. **Fundamental boundary changes** - Plan requires redefining module boundaries
2. **New architectural patterns** - Plan introduces patterns not in existing guardrails
3. **Conflicting requirements** - Architectural purity vs performance optimization trade-off
4. **Missing context** - Not enough information to assess structural impact
5. **Historical debt** - Plan depends on paying down existing debt first

---

## Constraints

- **No code editing** - Only review and documentation
- **Conservative by default** - Prefer long-term maintainability over short-term speed
- **Mandatory debt tracking** - Approved shortcuts must have follow-up tasks
- **Deterministic validation** - All assessments should map to testable architecture rules

---

## Anti-Patterns to Reject

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| "It works, so it's fine" | Functional correctness is not architectural soundness |
| "We'll refactor later" | Without a concrete task, this is never |
| "It's just a small exception" | Exceptions compound into architectural erosion |
| "The framework requires it" | Framework constraints should be isolated, not spread |
| "It's how we've always done it" | Past mistakes are not justification |

---

## Handoff

- If approved → **[Coding Agent](./coding-agent.md)**
- If rejected → **[Planning Agent](./planning-agent.md)** (revise plan)
