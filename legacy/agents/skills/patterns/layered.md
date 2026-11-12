# Layered Architecture Skill

Skill for traditional N-tier/layered architecture. Enforces strict layer separation and dependency direction.

---

## When to Use

| Scenario | Why Layered |
|----------|-------------|
| CRUD-heavy applications | Simple request/response flow |
| Small-to-medium codebases | Easy to understand and onboard |
| Teams new to architecture patterns | Well-documented, industry standard |
| Tight deadlines with known requirements | Quick to implement correctly |
| Monolithic deployments | Single deployable unit |

**Skip when:** Complex domain logic, need for high testability, or anticipating significant change in persistence/UI.

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Layer** | A horizontal slice of functionality with a specific responsibility |
| **Dependency Direction** | Upper layers depend on lower layers, never reverse |
| **Strict Mode** | Each layer only accesses the layer immediately below |
| **Relaxed Mode** | Layers can skip intermediate layers (e.g., Controller → Repository) |

### Standard Layers

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| **Presentation** | UI rendering, HTTP handling, input validation | Controllers, Views, DTOs |
| **Application** | Use cases, orchestration, transaction boundaries | Services, Facades |
| **Domain** | Business logic, entities, domain rules | Models, Value Objects |
| **Infrastructure** | External concerns, data access, integrations | Repositories, API clients |

---

## Workflow

### Phase 1: Planning (Planning Agent)

When creating a feature with `#layered`:

1. Identify which layers the feature touches
2. Document layer responsibilities in Solution Plan
3. Define interfaces at layer boundaries

### Phase 2: Design (Architect Agent)

1. Verify changes respect dependency direction
2. Ensure no layer-skipping violations (if strict mode)
3. Review cross-cutting concerns (logging, security)

### Phase 3: Implementation (Coding Agent)

1. Create components in appropriate layer directories
2. Define DTOs at layer boundaries
3. Implement dependency injection for layer access

### Phase 4: Review (Code Review Agent)

1. Check import statements for layer violations
2. Verify business logic is in Domain, not Presentation
3. Confirm infrastructure concerns are isolated

---

## Invariants

| Invariant | Action on Violation |
|-----------|---------------------|
| No upward dependencies (Infra → Domain) | Refactor to use interfaces/abstractions |
| No layer skipping (strict mode) | Add intermediary service/facade |
| Business logic in Domain layer only | Move logic from Controllers/Repositories |
| Presentation layer never accesses DB directly | Route through Application/Domain layers |
| Each layer has its own DTOs | Create mapping at boundaries |

---

## Patterns

### Package Structure

```
src/
├── presentation/     # Controllers, API endpoints
├── application/      # Application services
├── domain/           # Business entities, domain services
└── infrastructure/   # Repositories, external integrations
```

### Boundary DTOs

```
Presentation: UserRequest, UserResponse
Application:  UserCommand, UserResult
Domain:       User (entity)
```

---

## Common Issues

| Issue | Resolution |
|-------|------------|
| "Fat controllers" with business logic | Extract to Application/Domain services |
| Anemic domain model | Move behavior from services into entities |
| Circular dependencies between layers | Introduce interfaces, apply Dependency Inversion |
| Inconsistent layer naming | Standardize: `controller`, `service`, `repository` |
| Testing requires database | Mock repository interface in Domain tests |
