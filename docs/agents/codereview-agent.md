# Code Review Agent

> Reviews code changes with equal focus on functional correctness, structural integrity, and debt awareness.

**Agent Definition:** [`agentDirectory/agents/codereview-agent.md`](../../agentDirectory/agents/codereview-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Change evaluation |
| **Code Access** | Read-only |
| **Runs When** | After coding |
| **Stack Detection** | ❌ Receives from Solution Plan + Context file |

---

## Why This Agent Exists

> "Code is generated and works fine and covers functional requirements. But introduces new tech debt."

Functional correctness is table stakes. The hard part is catching structural and generative debt that will cost more to fix later.

---

## Responsibilities

1. **Stack Context** - Uses pre-assembled context (does NOT detect stack)
2. **Plan Alignment** - All tasks implemented, no unplanned scope
3. **Architecture Validation** - Layer violations, coupling issues
4. **Debt Assessment** - Structural and generative debt introduced
5. **Test Coverage** - Gaps identified and documented

---

## Input Files

| File | Purpose |
|------|---------|
| Changed files (diff) | Code to review |
| `<project-root>/plan/<issue-id>.SolutionPlan.md` | Approved plan |
| `<project-root>/harness/progress-log.md` | Implementation logs |
| `<project-root>/guardrails/*` | All guardrail files |
| `<project-root>/context/<issue-id>.context.md` | Task context |
| Validation output | Test/Architecture results |

---

## Output Files

| File | Purpose |
|------|---------|
| Code Review document | Review findings |
| `<project-root>/harness/progress-log.md` | Review summary |

---

## Review Checklist

### 1. Plan Alignment
- [ ] All plan tasks are implemented
- [ ] No unplanned scope was added
- [ ] No plan tasks were skipped
- [ ] Implementation matches intended design

### 2. Architecture-as-Guardrail
- [ ] No layer violations (even if architecture tests pass)
- [ ] No new cross-module dependencies without justification
- [ ] No domain logic polluted with infrastructure concerns
- [ ] No implicit contracts between modules
- [ ] Existing boundaries are respected

### 3. Structural & Generative Debt
- [ ] No "quick hack" without documented follow-up
- [ ] No duplicated logic that should be shared
- [ ] No shared logic that should be isolated
- [ ] No premature abstractions
- [ ] No missing abstractions

### 4. Tests & Verification
- [ ] Tests exist for new functionality
- [ ] Tests cover edge cases
- [ ] Architecture tests pass
- [ ] Quality gates pass
- [ ] Manual verification steps completed

### 5. Code Quality
- [ ] Code is readable and self-documenting
- [ ] No dead code or commented-out blocks
- [ ] Error handling is appropriate
- [ ] No security vulnerabilities introduced

---

## Severity Definitions

| Severity | Definition | Action |
|----------|------------|--------|
| **High** | Architectural violation, security issue, production problems | Block merge |
| **Medium** | Technical debt, maintainability concern, missing tests | Require follow-up task |
| **Low** | Style, naming, minor improvements | Suggest, don't block |

---

## Decisions

| Decision | Meaning |
|----------|---------|
| **Approve** | Ready to merge |
| **Approve with changes** | Minor fixes, no re-review |
| **Request changes** | Must fix and re-review |

---

## Constraints

- **No implementation** - Review only, unless asked for minimal patches
- **Equal weight to function and structure** - Working code with bad architecture is not acceptable
- **Documented debt** - All identified debt must have follow-up tasks
- **Deterministic validation** - Reference architecture rules (stack-specific tool) where applicable

---

## Anti-Patterns to Flag

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| "It works" | Not sufficient justification |
| "We needed it quickly" | Debt must be documented |
| "It's just a small exception" | Exceptions must be explicit |
| "No one will notice" | Architecture erosion is cumulative |
| "We'll refactor later" | Where's the task? |

---

## Handoff

- If approved → Merge, then **[Retro Agent](./retro-agent.md)**
- If rejected → **[Coding Agent](./coding-agent.md)** (fix issues)
