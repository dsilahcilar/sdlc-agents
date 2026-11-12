# Modular Monolith Skill

Skill for modular monolith architecture. Enforces strong module boundaries within a single deployable unit, enabling future decomposition.

---

## When to Use

| Scenario | Why Modular Monolith |
|----------|----------------------|
| Uncertain domain boundaries | Refine boundaries before committing to services |
| Need deployment simplicity | Single artifact, simple operations |
| Small team (< 10 devs) | Avoid distributed systems complexity |
| Brownfield modernization | Incremental modularization of legacy |
| Fast iteration phase | Quick changes without inter-service coordination |

**Skip when:** Proven domain boundaries, need independent scaling, or team already experienced with microservices.

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Module** | Self-contained business capability with explicit boundaries |
| **Public API** | The only way other modules can interact with this module |
| **Internal** | Implementation details hidden from other modules |
| **Shared Kernel** | Minimal code shared across modules (use sparingly) |
| **Module Gateway** | Facade exposing module capabilities |

---

## Workflow

### Phase 1: Planning (Planning Agent)

When creating a feature with `#modular-monolith`:

1. Identify which module owns the feature
2. Define public API changes required
3. Document inter-module dependencies

### Phase 2: Design (Architect Agent)

1. Verify module boundaries are respected
2. Check for circular module dependencies
3. Review shared kernel additions (minimize)

### Phase 3: Implementation (Coding Agent)

1. Implement within owning module
2. Expose only necessary public API
3. Use events for cross-module communication

### Phase 4: Review (Code Review Agent)

1. Check imports don't violate module boundaries
2. Verify internal packages aren't exposed
3. Confirm module communication via public API

---

## Invariants

| Invariant | Action on Violation |
|-----------|---------------------|
| Modules communicate via public API only | Remove direct internal access |
| No circular module dependencies | Extract shared concept or merge modules |
| Each module has single owner | Clarify ownership or split module |
| Shared kernel is minimal (< 5% of code) | Move to owning module or extract library |
| Database tables belong to single module | Split table or designate owner |

---

## Patterns

### Package Structure

```
src/
├── modules/
│   ├── orders/
│   │   ├── api/               # Public interfaces (OrderService, OrderDTO)
│   │   ├── internal/          # Private implementation
│   │   │   ├── domain/        # Entities, value objects
│   │   │   ├── application/   # Use cases
│   │   │   └── infrastructure/# Repositories, adapters
│   │   └── events/            # Published domain events
│   │
│   ├── inventory/
│   │   ├── api/
│   │   ├── internal/
│   │   └── events/
│   │
│   └── shared/                # Shared kernel (minimal!)
│       ├── types/             # Common value objects
│       └── events/            # Cross-cutting event definitions
│
└── infrastructure/            # Application-level concerns
    ├── config/
    └── messaging/
```

### Inter-Module Communication

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Direct API call** | Synchronous, same transaction | `orderModule.api.getOrder(id)` |
| **Domain Events** | Async, eventual consistency | `OrderPlacedEvent` → Inventory |
| **Shared Query** | Read-only cross-module data | Reporting, dashboards |

### Module Boundary Enforcement

| Approach | Tool/Technique |
|----------|----------------|
| Package visibility | Java: package-private, Kotlin: internal |
| Architecture tests | ArchUnit, Dependency Cruiser |
| Build modules | Gradle subprojects, Maven modules |

---

## Migration Path to Microservices

When ready to extract a module to a service:

1. **Already done:** Module has public API ✓
2. **Already done:** Module communicates via events ✓
3. **Extract:** Move module to separate deployable
4. **Replace:** Swap in-process API with HTTP/gRPC client
5. **Split:** Migrate module's database tables

---

## Common Issues

| Issue | Resolution |
|-------|------------|
| God module with too much | Split by subdomain capability |
| Modules sharing database tables | Assign table to one module, expose via API |
| Circular dependencies | Extract shared concept, use events |
| "Internal" code used externally | Make truly internal (package-private) |
| Shared kernel growing | Move code to owning module |
