# Kotlin Stack

Stack: Kotlin, JVM
Build Tools: Gradle (Kotlin DSL preferred), Maven

---

## Detection

| File | Build Tool |
|------|------------|
| `build.gradle.kts` | Gradle (Kotlin DSL) |
| `build.gradle` + kotlin plugin | Gradle (Groovy) |
| `pom.xml` + kotlin-maven-plugin | Maven |

**Kotlin indicators:**
- `*.kt` files in `src/`
- `kotlin` or `org.jetbrains.kotlin` in build files

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | Gradle | `./gradlew test` | build.gradle.kts exists |
| test | Maven | `mvn test` | kotlin-maven-plugin in pom.xml |
| lint | Ktlint | `./gradlew ktlintCheck` | `ktlint` in build.gradle.kts |
| lint | Detekt | `./gradlew detekt` | `detekt` in build.gradle.kts |
| lint | Maven Ktlint | `mvn antrun:run@ktlint` | ktlint in pom.xml |
| coverage | Kover | `./gradlew koverReport` | `kover` in build.gradle.kts |
| coverage | JaCoCo | `./gradlew jacocoTestReport` | `jacoco` in build.gradle.kts |
| security | OWASP | `./gradlew dependencyCheckAnalyze` | `dependency-check` plugin |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| ArchUnit | `./gradlew test --tests "*Arch*"` | `archunit` in dependencies |
| Konsist | `./gradlew test --tests "*Konsist*"` | `konsist` in dependencies |

**Fallback:** Skip with message suggesting ArchUnit or Konsist.

### Feature Runner

```sh
# Gradle - with module specified
./gradlew ":$FEATURE_MODULE:test"

# Gradle - without module
./gradlew test

# Maven - with module
mvn test -pl "$FEATURE_MODULE" -am

# Maven - without module
mvn test
```

### Init Project

```sh
# Gradle
./gradlew assemble --quiet

# Maven
mvn -q -DskipTests compile
```

---

## Architecture Enforcement: ArchUnit + Konsist

### ArchUnit (works with Kotlin)

```kotlin
// build.gradle.kts
testImplementation("com.tngtech.archunit:archunit-junit5:1.2.1")
```

### Konsist (Kotlin-native)

```kotlin
// build.gradle.kts
testImplementation("com.lemonappdev:konsist:0.13.0")
```

---

## Rule Template (ArchUnit)

Create `src/test/kotlin/<package>/ArchitectureTest.kt`:

```kotlin
@AnalyzeClasses(packages = ["com.example"], importOptions = [ImportOption.DoNotIncludeTests::class])
class ArchitectureTest {

    @ArchTest
    val layered_architecture: ArchRule = layeredArchitecture()
        .consideringAllDependencies()
        .layer("Controller").definedBy("..controller..")
        .layer("Service").definedBy("..service..")
        .layer("Domain").definedBy("..domain..", "..entity..", "..model..")
        .layer("Repository").definedBy("..repository..")
        .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
        .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")

    @ArchTest
    val domain_independence: ArchRule = noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAnyPackage("org.springframework..", "io.ktor..")

    @ArchTest
    val no_cycles: ArchRule = slices()
        .matching("com.example.(*)..")
        .should().beFreeOfCycles()
}
```

---

## Rule Template (Konsist)

Create `src/test/kotlin/<package>/KonsistTest.kt`:

```kotlin
class KonsistTest {

    @Test
    fun `domain classes should not depend on framework`() {
        Konsist
            .scopeFromModule("domain")
            .classes()
            .assertFalse {
                it.hasImportContaining("springframework") ||
                it.hasImportContaining("ktor")
            }
    }

    @Test
    fun `use cases should have UseCase suffix`() {
        Konsist
            .scopeFromPackage("com.example.application..")
            .classes()
            .assertTrue { it.name.endsWith("UseCase") }
    }

    @Test
    fun `no package cycles`() {
        Konsist
            .scopeFromProject()
            .assertNoCyclicDependencies()
    }
}
```

---

## Linting: Detekt + Ktlint

### Detekt Setup

```kotlin
// build.gradle.kts
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.4"
}

detekt {
    config.setFrom("$projectDir/detekt.yml")
    buildUponDefaultConfig = true
}
```

### Ktlint Setup

```kotlin
// build.gradle.kts
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
}
```

---

## Common Violations

| Violation | Fix |
|-----------|-----|
| Domain imports Ktor/Spring | Use interfaces, inject implementations |
| Data class in wrong layer | Move to domain or create DTO |
| Circular dependency | Extract to shared module |
| Missing UseCase suffix | Rename application service |

---

## Existing Tests Check

```bash
find . -name "*Arch*Test*.kt" -o -name "*Konsist*.kt"
grep -r "archunit\|konsist" build.gradle* 2>/dev/null
```
