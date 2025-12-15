# Java Stack

Stack: Java, JVM
Build Tools: Maven, Gradle

---

## Detection

| File | Build Tool |
|------|------------|
| `pom.xml` | Maven |
| `build.gradle` | Gradle (Groovy) |
| `build.gradle.kts` | Gradle (Kotlin DSL) |

---

## Harness Commands

### Quality Gates

| Phase | Tool | Command | Config Check |
|-------|------|---------|--------------|
| test | Maven | `mvn test` | pom.xml exists |
| test | Gradle | `./gradlew test` | build.gradle exists |
| lint | Checkstyle | `mvn checkstyle:check` | `checkstyle` in pom.xml |
| lint | SpotBugs | `mvn spotbugs:check` | `spotbugs` in pom.xml |
| lint | Gradle | `./gradlew check` | checkstyle/spotbugs in build.gradle |
| coverage | JaCoCo | `mvn jacoco:report` | `jacoco-maven-plugin` in pom.xml |
| coverage | Gradle | `./gradlew jacocoTestReport` | `jacoco` in build.gradle |
| security | OWASP | `mvn dependency-check:check` | `dependency-check-maven` in pom.xml |

### Architecture Tests

| Tool | Command | Config Check |
|------|---------|--------------|
| ArchUnit (Maven) | `mvn test -Dtest="*Arch*" -DfailIfNoTests=false` | `archunit` in pom.xml dependencies |
| ArchUnit (Gradle) | `./gradlew test --tests "*Arch*"` | `archunit` in build.gradle |

**Fallback:** Skip with message suggesting ArchUnit installation.

### Feature Runner

```sh
# With module specified (from feature.md)
mvn test -pl "$FEATURE_MODULE" -am
./gradlew ":$FEATURE_MODULE:test"

# Without module (full suite)
mvn test
./gradlew test
```

### Init Project

```sh
# Maven
mvn -q -DskipTests compile

# Gradle
./gradlew assemble --quiet
```

---

## Architecture Enforcement: ArchUnit

**Setup:**
```xml
<!-- Maven pom.xml -->
<dependency>
    <groupId>com.tngtech.archunit</groupId>
    <artifactId>archunit-junit5</artifactId>
    <version>1.2.1</version>
    <scope>test</scope>
</dependency>
```

```kotlin
// Gradle build.gradle.kts
testImplementation("com.tngtech.archunit:archunit-junit5:1.2.1")
```

---

## Rule Template

Create `src/test/java/<package>/ArchitectureTest.java`:

```java
@AnalyzeClasses(packages = "com.example", importOptions = ImportOption.DoNotIncludeTests.class)
public class ArchitectureTest {

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

    @ArchTest
    static final ArchRule domain_should_not_depend_on_spring =
        noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAPackage("org.springframework..");

    @ArchTest
    static final ArchRule no_package_cycles =
        slices().matching("com.example.(*)..")
            .should().beFreeOfCycles();
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
find . -name "*Arch*Test*.java" -o -name "*Architecture*Test*.java"
grep -r "archunit" pom.xml build.gradle* 2>/dev/null
```
