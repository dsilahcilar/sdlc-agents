# Architecture Rules

This document describes the architecture rules that enforce guardrails.
Each rule has a clear purpose and is linked to the principles in `architecture-as-guardrail.md`.

For language-specific enforcement tools and commands, see `skills/stacks/<stack>.md`.

---

## Overview

Architecture rules are **language-agnostic concepts** enforced by **language-specific tools**:

| Stack | Primary Tool | Config File |
|-------|--------------|-------------|
| Java/Kotlin | ArchUnit | `*ArchitectureTest.java` |
| TypeScript/JS | Dependency Cruiser | `.dependency-cruiser.js` |
| Python | Import Linter | `.importlinter` |
| Go | go-arch-lint | `.go-arch-lint.yaml` |
| Rust | cargo-modules | `Cargo.toml` |
| C#/.NET | ArchUnitNET / NsDepCop | `config.nsdepcop` |
| Ruby | Packwerk | `packwerk.yml` |
| PHP | Deptrac | `deptrac.yaml` |

---

## Rule Categories

### 1. Layer Rules

**Purpose:** Enforce layer separation and dependency direction.

```java
// Rule: Domain cannot depend on infrastructure
@ArchTest
static final ArchRule domain_should_not_depend_on_infrastructure =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAPackage("..infrastructure..");

// Rule: Layered architecture
@ArchTest
static final ArchRule layered_architecture =
    layeredArchitecture()
        .consideringAllDependencies()
        .layer("Presentation").definedBy("..presentation..", "..controller..", "..api..")
        .layer("Application").definedBy("..application..", "..service..", "..usecase..")
        .layer("Domain").definedBy("..domain..", "..model..", "..entity..")
        .layer("Infrastructure").definedBy("..infrastructure..", "..repository..", "..adapter..")

        .whereLayer("Presentation").mayNotBeAccessedByAnyLayer()
        .whereLayer("Application").mayOnlyBeAccessedByLayers("Presentation")
        .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Infrastructure")
        .whereLayer("Infrastructure").mayOnlyBeAccessedByLayers("Application");
```

**Violations to catch:**
- Controller importing Repository directly
- Domain class importing HTTP client
- Service layer bypassed

---

### 2. Domain Purity Rules

**Purpose:** Keep domain free of technical concerns.

```java
// Rule: Domain should not use framework annotations
@ArchTest
static final ArchRule domain_should_not_use_spring_annotations =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().beAnnotatedWith("org.springframework..");

// Rule: Domain should not depend on specific technologies
@ArchTest
static final ArchRule domain_should_be_technology_agnostic =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAnyPackage(
            "org.springframework..",
            "jakarta.servlet..",
            "java.sql..",
            "org.hibernate.."
        );
```

**Violations to catch:**
- Domain entity with @RestController
- Domain service with @Transactional
- Domain using JDBC directly

---

### 3. Cycle Rules

**Purpose:** Prevent circular dependencies.

```java
// Rule: No package cycles
@ArchTest
static final ArchRule no_package_cycles =
    slices().matching("com.example.(*)..")
        .should().beFreeOfCycles();

// Rule: No cycles between modules
@ArchTest
static final ArchRule no_module_cycles =
    slices().matching("com.example.(*)..").namingSlices("$1")
        .should().beFreeOfCycles();
```

**Violations to catch:**
- Package A imports B, B imports A
- Module cycles through transitive dependencies

---

### 4. Naming Convention Rules

**Purpose:** Enforce consistent naming for discoverability.

```java
// Rule: Controllers should be named *Controller
@ArchTest
static final ArchRule controllers_should_be_suffixed =
    classes()
        .that().resideInAPackage("..controller..")
        .should().haveSimpleNameEndingWith("Controller");

// Rule: Services should be named *Service
@ArchTest
static final ArchRule services_should_be_suffixed =
    classes()
        .that().resideInAPackage("..service..")
        .and().areNotInterfaces()
        .should().haveSimpleNameEndingWith("Service")
        .orShould().haveSimpleNameEndingWith("ServiceImpl");

// Rule: Repositories should be named *Repository
@ArchTest
static final ArchRule repositories_should_be_suffixed =
    classes()
        .that().resideInAPackage("..repository..")
        .should().haveSimpleNameEndingWith("Repository");
```

---

### 5. Dependency Inversion Rules

**Purpose:** Ensure interfaces in domain, implementations in infrastructure.

```java
// Rule: Domain should only depend on interfaces from infrastructure
@ArchTest
static final ArchRule domain_depends_only_on_interfaces =
    classes()
        .that().resideInAPackage("..domain..")
        .should().onlyDependOnClassesThat(
            resideOutsideOfPackage("..infrastructure..")
                .or(areInterfaces())
        );

// Rule: No concrete infrastructure classes in domain
@ArchTest
static final ArchRule no_infrastructure_impl_in_domain =
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAPackage("..infrastructure.impl..");
```

---

### 6. Bounded Context Rules

**Purpose:** Enforce context isolation (if using DDD).

```java
// Rule: Contexts should not directly share entities
@ArchTest
static final ArchRule contexts_should_be_isolated =
    noClasses()
        .that().resideInAPackage("..context.order..")
        .should().dependOnClassesThat()
        .resideInAPackage("..context.customer..entity..");

// Rule: Cross-context communication through interfaces only
@ArchTest
static final ArchRule cross_context_via_interface =
    classes()
        .that().resideInAPackage("..context.order..")
        .and().dependOnClassesThat().resideInAPackage("..context.customer..")
        .should().onlyDependOnClassesThat().areInterfaces();
```

---

## Adding New Rules

When a new architectural pattern is adopted:

1. **Define the rule** in code (see examples above)
2. **Document the rule** in this file
3. **Link to principle** in `architecture-as-guardrail.md`
4. **Run on existing code** to find violations
5. **Fix or suppress** existing violations before merging

---

## Handling Violations

When ArchUnit tests fail:

### 1. Simple Fix
Violation can be fixed by moving code or changing imports.
→ Fix immediately, no exception needed.

### 2. Design Flaw
Violation indicates the plan is architecturally unsound.
→ Stop coding, escalate to Architect Agent.

### 3. Legitimate Exception
Violation is intentional and justified.
→ Document in plan, add suppression with comment, create follow-up task.

```java
// Suppression example (use sparingly!)
@ArchIgnore(reason = "Legacy code, tracked in TECH-123 for refactoring")
public class LegacyAdapter { ... }
```

---

## Test Location

ArchUnit tests should be placed in:

```
src/test/java/com/example/architecture/
  ├── LayerArchitectureTest.java
  ├── DomainPurityTest.java
  ├── CycleDetectionTest.java
  ├── NamingConventionsTest.java
  └── BoundedContextTest.java
```

Or as a single comprehensive test:

```
src/test/java/com/example/ArchitectureTest.java
```

---

## Running Architecture Tests

```bash
# Via harness script (recommended)
./harness/run-arch-tests.sh

# Via Maven
mvn test -Dtest="*Architecture*,*ArchTest*"

# Via Gradle
./gradlew test --tests "*Architecture*"
```

---

## Metrics

Track these ArchUnit-related metrics:

| Metric | Description | Target |
|--------|-------------|--------|
| **AVR (Architectural Violation Rate)** | Violations per feature | 0 for new code |
| **Suppression count** | Number of @ArchIgnore | < 10 total |
| **Rule coverage** | Principles with tests | 100% |
| **Test execution time** | Time to run arch tests | < 30 seconds |
