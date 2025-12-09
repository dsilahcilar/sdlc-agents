# Generative & Structural Debt Checklist - Documentation

> This document provides background context and rationale for the debt checklist used by agents. For the agent-specific instructions, see [`guardrails/generative-debt-checklist.md`](../../../agents/guardrails/generative-debt-checklist.md).

## Context

> "Generative debt: the implicit cost of rework caused by choosing an easy or limited solution now over a better but more time-consuming approach."

> "When developing software, rushing to a functional solution creates low-quality, highly dependent components that cost far more to fix later than if they had been properly architected initially."

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

## Documenting Debt Examples

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

## Metrics

Track over time:

| Metric | Formula | Target |
|--------|---------|--------|
| **Debt Created** | New debt items per sprint | ↓ Decreasing |
| **Debt Paid** | Closed debt items per sprint | ↑ Increasing |
| **Debt Ratio** | Created / Paid | < 1.0 |
| **Avg Debt Age** | Average time to resolve | < 30 days |
| **Undocumented Debt** | Found in review vs. documented | 0 |
