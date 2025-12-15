# Java ArchUnit

**Category:** stack  
**Stack:** Java/Kotlin

## Purpose

Runs ArchUnit architecture tests to validate JVM codebase structure and dependencies.

## When to Use

- After code changes in Java/Kotlin projects
- Enforcing layer boundaries
- Checking naming conventions
- Validating package dependencies

## Usage

```bash
.sdlc-agents/tools/stack/java/archunit.sh [test-pattern]
```

**Arguments:**
- `test-pattern` - Optional. Test class pattern (default: `*Arch*,*Architecture*`)

## Output Format

```
[archunit] Running ArchUnit tests...
[archunit] Build tool: Maven/Gradle
...
[archunit] Tests PASSED/FAILED
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All architecture tests pass |
| 1 | Tests failed or not found |

## Prerequisites

Add to your project:

**Maven (pom.xml):**
```xml
<dependency>
    <groupId>com.tngtech.archunit</groupId>
    <artifactId>archunit-junit5</artifactId>
    <version>1.2.1</version>
    <scope>test</scope>
</dependency>
```

**Gradle (build.gradle.kts):**
```kotlin
testImplementation("com.tngtech.archunit:archunit-junit5:1.2.1")
```

## Related Tools

- `check-layers` - Quick layer validation
- `check-circular` - Circular dependency check
- `java/jdeps` - JVM dependency analysis

## Example

```bash
$ .sdlc-agents/tools/stack/java/archunit.sh
[archunit] Running ArchUnit tests...
[archunit] Build tool: Maven
[archunit] Pattern: *Arch*,*Architecture*

Running tests...
Tests run: 12, Failures: 0, Errors: 0

[archunit] All architecture tests passed ✓
```
