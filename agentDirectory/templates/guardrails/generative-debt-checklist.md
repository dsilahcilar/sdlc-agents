# Generative & Structural Debt Checklist

> "Generative debt: the implicit cost of rework caused by choosing an easy or limited solution now over a better but more time-consuming approach."

> "When developing software, rushing to a functional solution creates low-quality, highly dependent components that cost far more to fix later than if they had been properly architected initially."

This checklist helps agents identify and handle debt intentionally.

---

## What is Debt?

### Structural Debt
Code that works but violates modularity, coupling, or architectural principles.
- Cross-layer dependencies
- Tight coupling between modules
- Shared mutable state
- Implicit contracts

### Generative Debt
Shortcuts taken to ship faster that will require rework.
- Hard-coded values that should be configurable
- Missing error handling
- Skipped tests
- Duplicated code

---

## The Checklist

Use this checklist when planning, coding, or reviewing changes.

### Before Writing Code

| Question | If Yes... |
|----------|-----------|
| Am I about to bypass an abstraction layer? | Stop. Use the proper layer. |
| Am I coupling modules that were independent? | Stop. Find an interface-based approach. |
| Am I adding framework code to the domain layer? | Stop. Keep domain pure. |
| Am I skipping the plan/design phase? | Stop. Create SolutionPlan.md first. |

### While Writing Code

| Question | If Yes... |
|----------|-----------|
| Am I hard-coding something configurable? | Document as debt. Create follow-up task. |
| Am I skipping error handling for "happy path"? | Document as debt. Add error handling. |
| Am I copying code instead of abstracting? | If < 3 occurrences, maybe OK. Otherwise, abstract. |
| Am I adding a dependency without checking impact? | Check layer rules. Run ArchUnit. |
| Am I writing code without tests? | Add tests. Tests are not optional. |

### After Writing Code

| Question | If Yes... |
|----------|-----------|
| Would I be embarrassed to show this code? | Refactor before committing. |
| Am I saying "we'll fix it later"? | Document specifically what/when/how. |
| Did I skip architecture tests? | Run `./harness/run-arch-tests.sh` now. |
| Is there undocumented complexity? | Add comments or simplify. |

---

## Decision Framework

When facing a debt decision:

```
┌─────────────────────────────────────────────────────────────┐
│                   Is this a shortcut?                        │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                   YES                  NO
                    │                   │
                    ▼                   ▼
    ┌───────────────────────┐   ┌───────────────────┐
    │  Is it justified?      │   │  Proceed normally │
    │  (time, scope, risk)   │   │                   │
    └───────────────────────┘   └───────────────────┘
                    │
          ┌────────┴────────┐
          │                 │
         YES                NO
          │                 │
          ▼                 ▼
┌─────────────────┐  ┌─────────────────────────┐
│ Document debt:  │  │ Don't take the shortcut │
│ - What          │  │ Do it right             │
│ - Why           │  │                         │
│ - Follow-up     │  │                         │
└─────────────────┘  └─────────────────────────┘
```

---

## Documenting Debt

When debt is intentional and justified, document it:

### In Progress Log

```markdown
**Structural/generative debt decisions:**
- DEBT: Hard-coded timeout value (should be configurable)
  - Reason: Deadline pressure, config system not ready
  - Follow-up: TECH-456 - Add configuration support
  - Impact: Low risk, single location
```

### In Code

```kotlin
// TECH DEBT: Hard-coded timeout - see TECH-456
// Reason: Config system not ready at time of implementation
// Remove when: Config system is available
private val TIMEOUT_MS = 5000
```

### In Feature Requirements

```json
{
  "id": "FEAT-123",
  "debt_items": [
    {
      "type": "generative",
      "description": "Missing retry logic",
      "ticket": "TECH-457",
      "priority": "medium"
    }
  ]
}
```

---

## Red Flags

These patterns almost always indicate problematic debt:

| Red Flag | Why It's Bad | What to Do |
|----------|--------------|------------|
| "Just for now" | Permanent solutions in disguise | Document with deadline |
| "No time for tests" | Creates untested code | Tests are not optional |
| "Nobody will notice" | Architecture erosion | It compounds over time |
| "It's just one place" | Duplication starts with one | Abstract if pattern emerges |
| "The framework requires it" | Often an excuse | Isolate framework code |
| "Let's ship and fix later" | Later rarely comes | Document with ticket |

---

## Agent-Specific Guidance

### Planning Agent
- Identify potential debt points in the plan
- Add "Debt Risks" section to SolutionPlan.md
- Allocate tasks for known debt paydown

### Architect Agent
- Reject plans with hidden/undocumented debt
- Require compensating controls for approved debt
- Track debt trends across features

### Coding Agent
- Never take shortcuts without documenting
- If tempted to shortcut, stop and ask
- Run checklist before marking task complete

### Code Review Agent
- Flag undocumented shortcuts
- Require follow-up tasks for debt
- Check that documented debt has tickets

### Retro Agent
- Track which debt was created/paid
- Identify patterns in debt accumulation
- Update checklist when new patterns emerge

---

## Metrics

Track over time:

| Metric | Formula | Target |
|--------|---------|--------|
| **Debt Created** | New debt items per sprint | ↓ Decreasing |
| **Debt Paid** | Closed debt items per sprint | ↑ Increasing |
| **Debt Ratio** | Created / Paid | < 1.0 |
| **Avg Debt Age** | Average time to resolve | < 30 days |
| **Undocumented Debt** | Found in review vs. documented | 0 |
