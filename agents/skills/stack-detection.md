# Stack Detection

Detect the technology stack to load the appropriate skill.

---

## Detection Rules

Check for these files in order. First match wins.

| File | Stack | Skill to Load |
|------|-------|---------------|
| `pom.xml` | Java (Maven) | `stacks/java.md` |
| `build.gradle` | Java/Kotlin (Gradle) | `stacks/java.md` |
| `build.gradle.kts` | Kotlin (Gradle) | `stacks/java.md` |
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
    if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "java"
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

1. Load `skills/stacks/<detected-stack>.md`
2. Follow the skill instructions for:
   - Architecture tool setup
   - Discovery commands
   - Rule generation
   - Test execution

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
