# Contamination Guidelines

> "Contamination Risk: The efficacy of context adaptation depends fundamentally on the quality of feedback signals. In the absence of reliable feedback, the process of refining knowledge can degrade the system."

This document defines what may and may NOT be stored in `learning-playbook.md` to prevent knowledge degradation.

---

## The Contamination Problem

Without quality control, the learning playbook degrades over time:
- Low-quality lessons accumulate
- Contradictory advice confuses agents
- Outdated patterns persist
- One-off hacks become "best practices"
- Noise drowns out signal

The Curator Agent uses these guidelines to maintain playbook health.

---

## DO Store

### Generalizable Patterns
- Lessons that apply to multiple features or modules
- Approaches that worked across different contexts
- Principles that can be stated as clear rules

**Good example:**
```yaml
reusable_guidelines:
  - "When adding a new REST endpoint, always define the interface in the domain layer first"
```

### Clear Failure Modes
- Mistakes that caused measurable problems
- Violations that were caught by ArchUnit
- Shortcuts that led to rework

**Good example:**
```yaml
what_failed:
  - "Directly calling repository from controller bypassed business logic validation"
```

### Architectural Lessons
- Boundary violations and how they were fixed
- Coupling patterns that caused problems
- Structural decisions that proved valuable

### Evidence-Based Guidelines
- Lessons tied to specific PRs or issues
- Guidelines validated by tests passing/failing
- Patterns confirmed across multiple instances

---

## DO NOT Store

### One-Off Hacks
- Workarounds specific to a single situation
- Fixes that won't apply elsewhere
- Context-dependent tricks

**Bad example:**
```yaml
# Too specific, not generalizable
reusable_guidelines:
  - "In UserController.java line 42, use getUserById() not findUser()"
```

### Confidential Information
- Real PII, even in examples
- API keys, passwords, secrets
- Customer-specific data
- Internal URLs or endpoints

### Contradictory Entries (Unresolved)
- If two entries conflict, they must be reconciled
- Keep both only if clearly scoped to different contexts
- Otherwise merge, archive one, or flag for human review

### Overly Generic Advice
- "Be careful" - not actionable
- "Write good tests" - too vague
- "Follow best practices" - no specifics

**Bad example:**
```yaml
reusable_guidelines:
  - "Be more careful when writing code"
```

### Stale Patterns
- Lessons that reference deprecated libraries
- Patterns superseded by newer approaches
- Advice that conflicts with current architecture

### Unverified Claims
- Lessons without supporting evidence
- "I think this works" without confirmation
- Patterns never validated by tests

---

## Conflict Resolution Protocol

When entries conflict:

### 1. Identify Conflict Type

| Type | Description | Resolution |
|------|-------------|------------|
| **Context-dependent** | Both valid in different contexts | Scope with clear triggers |
| **Superseded** | One is newer/better | Archive the older one |
| **Contradictory** | Genuinely conflicting | Investigate and pick one |
| **Unclear** | Not enough information | Flag for human review |

### 2. Resolution Actions

**Context Scoping:**
```yaml
# Entry A
triggers:
  - pattern: "When working with legacy modules"
reusable_guidelines:
  - "Use adapter pattern for legacy integration"

# Entry B
triggers:
  - pattern: "When working with new modules"
reusable_guidelines:
  - "Use direct dependency injection"
```

**Archival:**
```yaml
# Move to memory/archive/learning-playbook-archive.md
# Add reason: "Superseded by entry LEARN-042"
```

**Human Review Flag:**
```yaml
needs_review: true
review_reason: "Conflicts with entry LEARN-023, unclear which is correct"
```

---

## Quality Metrics

Track these over time to monitor playbook health:

| Metric | Target | Action if Exceeded |
|--------|--------|-------------------|
| Total entries | < 200 active | Archive low-value entries |
| Conflict rate | < 5% | Resolve conflicts immediately |
| Stale entries | < 10% | Review entries older than 6 months |
| Needs-review entries | < 3% | Resolve or delete uncertain entries |
| Application rate | > 50% | Remove entries that are never retrieved |

---

## Curator Agent Checklist

Before accepting a new entry:

- [ ] Is it generalizable beyond this specific case?
- [ ] Does it have supporting evidence (PR, tests, violations)?
- [ ] Are guidelines actionable and specific?
- [ ] Does it avoid confidential/sensitive information?
- [ ] Does it conflict with existing entries?
- [ ] Is the context clearly specified?
- [ ] Would this help a future agent make better decisions?

If any answer is "no" or "unclear," the entry should be:
- Edited to fix the issue
- Rejected with explanation
- Flagged for human review
