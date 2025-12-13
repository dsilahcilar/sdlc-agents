# Hexagonal Architecture Skill

Skill for hexagonal (ports & adapters) architecture. Enforces domain isolation with explicit boundaries between business logic and external systems.

---

## When to Use

| Scenario | Why Hexagonal |
|----------|---------------|
| Complex domain logic | Domain stays pure and testable |
| Multiple external integrations | Adapters isolate change impact |
| Need high testability | Domain tests without infrastructure |
| Expect UI/infrastructure changes | Swap adapters without touching core |
| Microservices preparation | Natural service boundary identification |

**Skip when:** Simple CRUD apps, tight deadlines, or teams unfamiliar with DDD concepts.

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Domain Core** | Pure business logic, no external dependencies |
| **Port** | Interface defined by the domain (what it needs/provides) |
| **Adapter** | Implementation of a port, connects to external systems |
| **Driving/Primary** | External actors that call the application (UI, APIs) |
| **Driven/Secondary** | External systems called by the application (DB, APIs) |

### The Hexagon

```
       [Driving Adapters]
              │
              ▼
    ┌────────────────────┐
    │   Driving Ports    │  ← Use Cases / Application Services
    │         │          │
    │    ┌────┴────┐     │
    │    │ DOMAIN  │     │
    │    └────┬────┘     │
    │         │          │
    │   Driven Ports     │  ← Repository / Gateway Interfaces
    └────────────────────┘
              │
              ▼
       [Driven Adapters]
```

---

## Workflow

### Phase 1: Planning (Planning Agent)

When creating a feature with `#hexagonal`:

1. Identify domain concepts and behaviors
2. Define driving ports (use cases the feature exposes)
3. Define driven ports (external dependencies required)

### Phase 2: Design (Architect Agent)

1. Verify domain has no infrastructure imports
2. Review port interfaces for domain language
3. Ensure adapters implement ports, not the reverse

### Phase 3: Implementation (Coding Agent)

1. Start with domain entities and value objects
2. Define port interfaces in domain layer
3. Create adapters in infrastructure layer
4. Wire via dependency injection

### Phase 4: Review (Code Review Agent)

1. Check domain imports (must be zero external deps)
2. Verify adapters implement port interfaces
3. Confirm tests mock ports, not concrete adapters

---

## Invariants

| Invariant | Action on Violation |
|-----------|---------------------|
| Domain has no infrastructure imports | Move dependency behind a port |
| Ports use domain language, not tech terms | Rename to business concepts |
| Adapters depend on domain, never reverse | Invert dependency via interface |
| No direct framework references in domain | Abstract behind ports |
| Domain tests run without external systems | Mock ports, not adapters |

---

## Patterns

### Package Structure

```
src/
├── domain/                    # Pure business logic
│   ├── model/                 # Entities, Value Objects
│   ├── ports/
│   │   ├── inbound/           # Driving ports (use cases)
│   │   └── outbound/          # Driven ports (repositories, gateways)
│   └── services/              # Domain services
│
├── application/               # Use case implementations
│   └── services/              # Orchestration, transactions
│
└── infrastructure/            # Adapters
    ├── inbound/               # REST controllers, CLI, GraphQL
    └── outbound/              # JPA repos, HTTP clients, message queues
```

### Port Naming Convention

| Port Type | Naming Pattern | Example |
|-----------|----------------|---------|
| Driving (use case) | `{Action}{Entity}UseCase` | `CreateOrderUseCase` |
| Driven (repository) | `{Entity}Repository` | `OrderRepository` |
| Driven (gateway) | `{Service}Gateway` | `PaymentGateway` |

---

## Common Issues

| Issue | Resolution |
|-------|------------|
| Framework annotations in domain | Move to adapter, use plain classes in domain |
| "Anemic" ports that just pass data | Add domain behavior, ports expose capabilities |
| Adapter logic leaking into domain | Move business rules to domain services |
| Too many small ports | Group related operations, avoid 1-method ports |
| Testing adapters, not ports | Test domain via port interfaces |
