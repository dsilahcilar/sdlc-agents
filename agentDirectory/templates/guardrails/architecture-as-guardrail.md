# Architecture as Guardrail

> "Architecture-as-a-Guardrail: automated validation of structural integrity is as crucial as verifying functional output."

This document defines **non-negotiable architectural principles** for this codebase.
Agents MUST treat these as hard constraints, not suggestions.

---

## Why This Matters

> "Structural Debt (Hallucinated Coupling): This occurs when the LLM generates code that runs but violates fundamental structural integrity or modularity principles, leading to code that is expensive to refactor later."

LLMs are good at functional code but weak at architectural decisions. Deterministic guardrails (ArchUnit tests) compensate for this weakness.

---

## Core Principles

### 1. Layer Separation

The codebase follows a layered architecture. Dependencies flow inward only.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (Controllers, APIs, Views, DTOs)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│              (Use Cases, Services, Orchestration)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│           (Entities, Value Objects, Domain Services)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                       │
│          (Repositories, External Services, Adapters)         │
└─────────────────────────────────────────────────────────────┘
```

**Rules:**
- Presentation → Application ✓
- Application → Domain ✓
- Domain → Infrastructure ✗ (FORBIDDEN)
- Presentation → Domain ✗ (must go through Application)
- Presentation → Infrastructure ✗ (must go through Application)

### 2. Domain Purity

The Domain layer contains business logic and MUST be free of:
- Framework annotations (except standard annotations like @Entity)
- HTTP/REST concerns
- Database specifics (SQL, ORM details)
- External service implementations
- Logging frameworks (use domain events instead)

**The domain should be testable without any infrastructure.**

### 3. Dependency Inversion

- Domain defines interfaces (ports)
- Infrastructure implements interfaces (adapters)
- Application orchestrates through interfaces
- Never depend on concrete implementations across boundaries

### 4. No Circular Dependencies

- No package-level cycles
- No module-level cycles
- If A depends on B, B cannot depend on A (directly or transitively)

### 5. Bounded Context Isolation

If the project uses DDD bounded contexts:
- Contexts communicate through defined interfaces only
- No direct entity sharing between contexts
- Shared kernel must be explicitly defined
- Anti-corruption layers at context boundaries

---

## Agent Obligations

### Planning Agent
- Design solutions that respect layer boundaries
- Identify which layers each task touches
- Document forbidden dependencies in plan

### Architect Agent
- Validate that plans don't violate principles
- Reject plans with architectural shortcuts
- Propose new ArchUnit rules when patterns recur

### Coding Agent
- Never introduce cross-layer dependencies
- Stop and escalate if implementation requires violation
- Run `./harness/run-arch-tests.sh` after significant changes

### Code Review Agent
- Check for violations even if ArchUnit passes
- Flag coupling that erodes boundaries
- Require documented debt for any exceptions

---

## Validation

Architecture is validated through:

1. **ArchUnit tests** - Deterministic, automated checks
2. **Code review** - Human/agent review for subtle violations
3. **Quality gates** - Integrated into CI/CD

**All significant changes MUST pass:**
```bash
./harness/run-arch-tests.sh
```

---

## Exceptions

Exceptions to these principles require:

1. **Explicit documentation** in the Solution Plan
2. **Architect Agent approval** with conditions
3. **Follow-up task** to remove the exception
4. **ArchUnit suppression** with comment explaining why

Exceptions are TEMPORARY. They must be tracked and resolved.

---

## Updating This Document

This document should be updated when:
- New architectural patterns are adopted
- Existing patterns prove insufficient
- Recurring violations indicate unclear rules
- New bounded contexts are added

Changes require review by Architect Agent or human architect.
