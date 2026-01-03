# Learned Planning Patterns

Patterns extracted from retrospectives and validated learnings.

> [!NOTE]
> This file is maintained by the **Curator Agent**. Entries are extracted from `learning-playbook.md` after validation.

---

## Task Decomposition Heuristics

### Heuristic: Neo4j Repository Query Implementation Pattern

When breaking down tasks for Neo4j repository queries that return projections, always plan for custom repository fragments instead of simple `@Query` annotations.

- **Trigger**: Tasks involving Neo4j queries that return projection classes (not entity classes)
- **Rationale**: Spring Data Neo4j's automatic projection mapping with `@Query` is unreliable and often causes `MappingException` at runtime
- **Task Breakdown**:
  1. Create projection data class (if not exists)
  2. Create custom repository fragment interface
  3. Create fragment implementation with `Neo4jClient` and manual `.mappedBy()` mapping
  4. Extend main repository interface with the fragment
  5. Write integration tests
- **Evidence**: 
  - Financial metrics endpoint required refactoring from `@Query` to custom fragment (2026-01-01)
  - Executives, investors, products repositories already use this pattern successfully
  - Pattern prevents runtime failures that are hard to debug
- **Time Estimate**: Add 30% buffer for custom fragment implementation vs simple `@Query`

<!-- Curator Agent: Add validated task breakdown patterns here -->
<!-- Example:
### Heuristic: Foundation-First Ordering
Always implement foundational components (domain models, ports) before adapters.
- **Trigger**: Multi-task features with domain entities
- **Evidence**: Reduced rework in 5+ features
-->

---

## Estimation Patterns

<!-- Curator Agent: Add validated estimation learnings here -->
<!-- Example:
### Pattern: Test Task Inflation
Unit test tasks often take 1.5x estimated time when covering edge cases.
- **Trigger**: Tasks with "comprehensive unit tests"
- **Mitigation**: Add buffer for test tasks
-->

---

## Dependency Patterns

<!-- Curator Agent: Add validated dependency ordering patterns here -->
<!-- Example:
### Pattern: Authorization Before Features
Implement authorization service before feature handlers that require it.
- **Trigger**: Features with user data isolation
- **Evidence**: SEC-001 implementation order
-->

---

## Risk Patterns

<!-- Curator Agent: Add validated risk identification patterns here -->
