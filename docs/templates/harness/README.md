# Harness Templates Documentation

> Documentation for `agents/templates/harness/`

These are **template scripts** that the Initializer Agent copies to your project's `<project-root>/agent-context/harness/` directory.

---

## Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `init-project.sh` | One-time environment setup | Once, at project initialization |
| `run-feature.sh <id>` | Run tests for a specific feature | During development, per feature |
| `run-arch-tests.sh` | Run architecture validation | After every significant change |
| `run-quality-gates.sh` | Full quality check (6 phases) | Before code review |

### Metrics Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `collect-metrics.sh` | Collect architectural metrics | Automatically via quality gates |
| `compare-metrics.sh` | Compare against thresholds | Automatically via quality gates |
| `archive-metrics.sh` | Archive historical snapshots | Automatically via quality gates |

### Task Management Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `next-task.sh <feature-id>` | Get next pending task | Before starting work |
| `start-task.sh <task-file>` | Mark task as in_progress | When starting a task |
| `complete-task.sh <task-file>` | Mark task as done | After completing a task |
| `list-features.sh` | Show all features and status | For progress overview |

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

## Core Scripts

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
1. Unit tests
2. Architecture tests
3. Static analysis
4. Code coverage
5. Security checks
6. Metrics validation (collect, compare, archive)

---

## Task Management Scripts

### `next-task.sh`

Finds the next pending task for a feature:

```bash
./harness/next-task.sh FEAT-001
# Output: features/FEAT-001/tasks/T02-add-repository.md
```

Looks for tasks with `status: pending` in frontmatter, sorted by filename.

### `start-task.sh`

Marks a task as `in_progress`:

```bash
./harness/start-task.sh features/FEAT-001/tasks/T01-create-entity.md
```

Also updates the feature status to `in_progress` if it was `pending`.

### `complete-task.sh`

Marks a task as `done`:

```bash
./harness/complete-task.sh features/FEAT-001/tasks/T01-create-entity.md
```

When all tasks are complete, automatically updates the feature status to `passing`.

### `list-features.sh`

Shows all features and their progress:

```bash
./harness/list-features.sh
```

Output:
```
=== Feature Status ===

🔄 FEAT-001: User Authentication
   Status: in_progress | Risk: 🔴 high
   Tasks: 2/5 done | 1 pending | 2 in progress | 0 blocked

⏳ FEAT-002: User Profile
   Status: pending | Risk: 🟢 low
   Tasks: 0/3 done | 3 pending | 0 in progress | 0 blocked

=== Summary ===
Total: 2 features
  ⏳ Pending: 1
  🔄 In Progress: 1
  ✅ Passing: 0
  🚫 Blocked: 0
```

---

## Data Files

### `progress-log.md`

Session-by-session progress log updated by all agents.

---

## Customization

After copying to your project, you may need to customize:

1. **Build commands** - Match your project's build system
2. **Test patterns** - Match your test naming conventions
3. **Tool paths** - Match your installed tools

The templates are designed to work out-of-the-box for common setups.
