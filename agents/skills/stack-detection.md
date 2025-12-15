# Stack Detection

Detect the technology stack to load the appropriate skill.

---

## Detection Rules

Check for these files in order. First match wins.

| File | Stack | Skill to Load |
|------|-------|---------------|
| `build.gradle.kts` + `*.kt` | Kotlin (Gradle) | `stacks/kotlin.md` |
| `pom.xml` + kotlin-maven-plugin | Kotlin (Maven) | `stacks/kotlin.md` |
| `pom.xml` | Java (Maven) | `stacks/java.md` |
| `build.gradle` | Java/Kotlin (Gradle) | `stacks/java.md` |
| `build.gradle.kts` | Kotlin (Gradle) | `stacks/kotlin.md` |
| `package.json` | TypeScript/JavaScript | `stacks/typescript.md` |
| `pyproject.toml` | Python | `stacks/python.md` |
| `setup.py` | Python | `stacks/python.md` |
| `requirements.txt` | Python | `stacks/python.md` |
| `go.mod` | Go | `stacks/go.md` |
| `Cargo.toml` | Rust | `stacks/rust.md` |
| `*.csproj` | C#/.NET | `stacks/dotnet.md` |
| `*.sln` | C#/.NET | `stacks/dotnet.md` |
| `Gemfile` | Ruby | `stacks/ruby.md` |
| `composer.json` | PHP | `stacks/php.md` |

---

## Detection Script

```bash
detect_stack() {
    # Kotlin-first detection
    # 1. Gradle Kotlin DSL with .kt files
    if [ -f "build.gradle.kts" ] && find . -name "*.kt" -type f | head -1 | grep -q .; then
        echo "kotlin"
    # 2. Maven with kotlin-maven-plugin
    elif [ -f "pom.xml" ] && grep -q "kotlin-maven-plugin" pom.xml; then
        echo "kotlin"
    # 3. Maven without Kotlin
    elif [ -f "pom.xml" ]; then
        echo "java"
    # 4. Gradle (may be Java or Kotlin)
    elif [ -f "build.gradle" ]; then
        echo "java"
    # 5. Gradle Kotlin DSL (fallback)
    elif [ -f "build.gradle.kts" ]; then
        echo "kotlin"
    elif [ -f "package.json" ]; then
        echo "typescript"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif ls ./*.csproj >/dev/null 2>&1 || ls ./*.sln >/dev/null 2>&1; then
        echo "dotnet"
    elif [ -f "Gemfile" ]; then
        echo "ruby"
    elif [ -f "composer.json" ]; then
        echo "php"
    else
        echo "unknown"
    fi
}
```

---

## After Detection

Once stack is detected:

1. Read `skills/harness-spec.md` for core concepts
2. Read `skills/stacks/<detected-stack>.md` for:
   - Harness commands (quality gates, arch tests, init, feature runner)
   - Architecture tool setup
   - Rule templates
   - Common violations

---

## Multi-Stack Projects

For monorepos with multiple stacks:

1. Detect primary stack (root level)
2. Detect per-directory stacks
3. Load skills for each detected stack
4. Apply rules per-directory

Example:
```
/
├── package.json          → TypeScript skill for frontend
├── backend/
│   └── pom.xml           → Java skill for backend
└── scripts/
    └── requirements.txt  → Python skill for scripts
```
