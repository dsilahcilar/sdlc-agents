# Harness Templates Documentation

> Documentation for `agentDirectory/templates/harness/`

These are **template scripts** that the Initializer Agent copies to your project's `<project-root>/harness/` directory.

---

## Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `init-project.sh` | One-time environment setup | Once, at project initialization |
| `run-feature.sh <id>` | Run tests for a specific feature | During development, per feature |
| `run-arch-tests.sh` | Run architecture validation | After every significant change |
| `run-quality-gates.sh` | Full quality check | Before code review |

---

## Stack Detection

All scripts automatically detect your technology stack:

| Detection File | Stack | Architecture Tool |
|----------------|-------|-------------------|
| `pom.xml`, `build.gradle(.kts)` | Java/Kotlin | ArchUnit |
| `package.json` | TypeScript/JS | Dependency Cruiser, Madge |
| `pyproject.toml`, `setup.py` | Python | Import Linter |
| `go.mod` | Go | go-arch-lint |
| `Cargo.toml` | Rust | cargo-modules |
| `*.csproj`, `*.sln` | C#/.NET | ArchUnitNET |
| `Gemfile` | Ruby | Packwerk |
| `composer.json` | PHP | Deptrac |

---

## Files

### `init-project.sh`

Initializes the development environment:
- Installs dependencies
- Sets up pre-commit hooks
- Verifies toolchain

### `run-feature.sh`

Runs tests for a specific feature:
```bash
./harness/run-feature.sh FEAT-001
```

### `run-arch-tests.sh`

Runs architecture validation using stack-appropriate tools:
- Java: ArchUnit tests (`*Arch*`)
- TypeScript: Dependency Cruiser + Madge circular check
- Python: Import Linter
- Go: go-arch-lint + import cycle check
- Rust: cargo check + clippy
- .NET: ArchUnitNET
- Ruby: Packwerk
- PHP: Deptrac

### `run-quality-gates.sh`

Full quality check including:
- Unit tests
- Architecture tests
- Code coverage
- Static analysis

---

## Data Files

### `feature-requirements.json`

Tracks all features and their status:
```json
{
  "features": [
    {
      "id": "FEAT-001",
      "title": "User Authentication",
      "status": "failing|in_progress|passing",
      "module": "auth",
      "risk_level": "high"
    }
  ]
}
```

### `progress-log.md`

Session-by-session progress log updated by all agents.

---

## Customization

After copying to your project, you may need to customize:

1. **Build commands** - Match your project's build system
2. **Test patterns** - Match your test naming conventions
3. **Tool paths** - Match your installed tools

The templates are designed to work out-of-the-box for common setups.
