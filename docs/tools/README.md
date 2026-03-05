# Tools Registry

Documentation for executable tools under `agents/tools/`.

---

## How to Use

1. Read this registry to find a tool.
2. Read the tool's `.md` file for usage details.
3. Execute the matching `.sh` script.

---

## Available Categories

| Category | Purpose |
|----------|---------|
| `discovery/` | Analyze structure/imports and layer hints |
| `validation/` | Validate dependency constraints |
| `skills/` | Parse and resolve skill directives |
| `stack/java/` | Java/JVM architecture tooling helpers |
| `stack/ts/` | TypeScript dependency tooling helpers |

---

## Discovery Tools

| Tool | Files | Purpose |
|------|-------|---------|
| `list-packages` | `discovery/list-packages.md/.sh` | List package/module paths |
| `find-imports` | `discovery/find-imports.md/.sh` | Find import relationships |
| `detect-layers` | `discovery/detect-layers.md/.sh` | Infer layer boundaries |
| `count-files` | `discovery/count-files.md/.sh` | Count files per directory/package |

## Validation Tools

| Tool | Files | Purpose |
|------|-------|---------|
| `check-circular` | `validation/check-circular.md/.sh` | Detect circular dependencies |
| `check-layers` | `validation/check-layers.md/.sh` | Verify layer dependency direction |

## Skill Tools

| Tool | Files | Purpose |
|------|-------|---------|
| `parse-skill-directives` | `skills/parse-skill-directives.sh` | Parse `#...`, `!...`, `#only:...` directives |
| `resolve-skills` | `skills/resolve-skills.sh` | Resolve skill names/aliases to files |

## Stack-Specific Tools

### Java/JVM

| Tool | Files | Purpose |
|------|-------|---------|
| `archunit` | `stack/java/archunit.md/.sh` | Run or assist ArchUnit checks |
| `jdeps` | `stack/java/jdeps.md/.sh` | Analyze JVM package/module dependencies |

### TypeScript

| Tool | Files | Purpose |
|------|-------|---------|
| `depcruise` | `stack/ts/depcruise.md/.sh` | Run dependency-cruiser checks |
| `madge` | `stack/ts/madge.md/.sh` | Detect circular dependencies with madge |

---

## Notes

- This registry intentionally lists only tools currently present in `agents/tools/`.
- If you add new tools, update this file in the same change.
