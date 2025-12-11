# Java/Kotlin Architecture Skill

Stack: Java, Kotlin, Scala (JVM)
Tool: **ArchUnit**

---

## Architecture Enforcement Tool

**ArchUnit** - Unit tests for architecture rules over JVM bytecode.

**Setup:**
1. Add `com.tngtech.archunit:archunit-junit5` as a test dependency
2. Find the latest version:
   ```bash
   mvn versions:display-dependency-updates -Dincludes=com.tngtech.archunit:archunit-junit5
   ```
3. For Gradle projects: use `testImplementation` dependency configuration

---

## Available Tools

> **Progressive Disclosure:** Use these tools instead of embedding scripts.
> See each tool's `.md` file for detailed usage before executing.

### Discovery Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `.github/tools/discovery/list-packages.sh` | List all packages | Initial codebase analysis |
| `.github/tools/discovery/find-imports.sh` | Find import relationships | Mapping dependencies |
| `.github/tools/discovery/detect-layers.sh` | Identify architecture layers | Before rule generation |
| `.github/tools/discovery/count-files.sh` | Count files per package | Understanding scale |

### Validation Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `.github/tools/stack/java/archunit.sh` | Run ArchUnit tests | After code changes |
| `.github/tools/stack/java/jdeps.sh` | Analyze JVM dependencies | Understanding structure |
| `.github/tools/validation/check-layers.sh` | Quick layer validation | Before running full tests |
| `.github/tools/validation/check-circular.sh` | Find circular deps | Debugging coupling issues |

---

## Quick Commands

For immediate execution without reading tool docs:

```bash
# Run architecture tests
.github/tools/stack/java/archunit.sh

# Analyze dependencies
.github/tools/stack/java/jdeps.sh target/classes
```

---

## Generated Rules Template

Create `src/test/java/<package>/ArchitectureTest.java`:

```java
package com.example.architecture;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.*;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

@AnalyzeClasses(packages = "com.example", importOptions = ImportOption.DoNotIncludeTests.class)
public class ArchitectureTest {

    // Layer rules
    @ArchTest
    static final ArchRule layered_architecture =
        layeredArchitecture()
            .consideringAllDependencies()
            .layer("Controller").definedBy("..controller..")
            .layer("Service").definedBy("..service..")
            .layer("Domain").definedBy("..domain..", "..entity..", "..model..")
            .layer("Repository").definedBy("..repository..")
            .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
            .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
            .whereLayer("Domain").mayOnlyBeAccessedByLayers("Service", "Repository");

    // Domain purity
    @ArchTest
    static final ArchRule domain_should_not_depend_on_spring =
        noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAPackage("org.springframework..");

    // No cycles
    @ArchTest
    static final ArchRule no_package_cycles =
        slices().matching("com.example.(*)..")
            .should().beFreeOfCycles();

    // Naming conventions
    @ArchTest
    static final ArchRule controllers_should_be_suffixed =
        classes()
            .that().resideInAPackage("..controller..")
            .should().haveSimpleNameEndingWith("Controller");
}
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain imports Spring | Move to infrastructure, inject via interface |
| Controller calls Repository | Add Service layer |
| Circular dependency | Extract shared code to common package |
| Missing suffix | Rename class to follow convention |

---

## Existing Tests Check

```bash
# Use the discovery tools
.github/tools/discovery/find-imports.sh src archunit

# Or check directly
find . -name "*Arch*Test*.java" -o -name "*Architecture*Test*.java"
```
