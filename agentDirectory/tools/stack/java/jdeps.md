# Java JDeps

**Category:** stack  
**Stack:** Java/Kotlin

## Purpose

Analyzes JVM class dependencies using the `jdeps` tool to understand module structure.

## When to Use

- Understanding dependency structure
- Finding JDK internal API usage
- Preparing for modularization
- Visualizing package dependencies

## Usage

```bash
.github/tools/stack/java/jdeps.sh [target] [options]
```

**Arguments:**
- `target` - Optional. Path to analyze (default: `target/classes`)
- `options` - Optional. Additional jdeps options

## Output Format

```
[jdeps] Analyzing dependencies...
package -> dependency
package -> dependency
...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Analysis complete |
| 1 | Error or issues found |

## Prerequisites

- Java JDK installed (jdeps is included)
- Compiled classes available (`mvn compile` or `gradle build`)

## Related Tools

- `archunit` - Architecture rule validation
- `check-circular` - Circular dependency check

## Example

```bash
$ .github/tools/stack/java/jdeps.sh target/classes
[jdeps] Analyzing dependencies...
[jdeps] Target: target/classes

com.example.controller
   -> com.example.service
   -> java.lang
   -> org.springframework.web.bind.annotation

com.example.service
   -> com.example.domain
   -> java.util
```
