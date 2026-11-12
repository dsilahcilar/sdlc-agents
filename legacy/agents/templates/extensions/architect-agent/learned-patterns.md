# Learned Architectural Patterns

Patterns extracted from retrospectives and validated learnings.

> [!NOTE]
> This file is maintained by the **Curator Agent**. Entries are extracted from `learning-playbook.md` after validation.

---

## Structural Patterns

<!-- Curator Agent: Add validated structural patterns here -->
<!-- Example:
### Pattern: Centralized Authorization Guard
When implementing data access, use a centralized authorization service rather than inline checks.
- **Trigger**: Any feature accessing user-owned data
- **Evidence**: SEC-001 retrofit, 100% endpoint coverage
-->

---

## Anti-Patterns

<!-- Curator Agent: Add validated anti-patterns here -->
<!-- Example:
### Anti-Pattern: Cross-Layer Reach-Through
Direct controller-to-repository calls bypass business rules.
- **Detection**: Architecture tests for layer violations
- **Fix**: Route through service layer
-->

---

## Boundary Rules

<!-- Curator Agent: Add validated boundary rules here -->
<!-- Example:
### Rule: Domain Independence
Domain layer must not depend on infrastructure types.
- **Enforcement**: ArchUnit tests
-->

---

## Debt Patterns

<!-- Curator Agent: Add validated debt patterns here -->
