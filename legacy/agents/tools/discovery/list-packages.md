# List Packages

**Category:** discovery  
**Stack:** Any

## Purpose

Lists all packages, modules, or directories in the codebase to understand the project structure.

## When to Use

- First time analyzing a codebase
- Understanding project organization
- Before architecture discovery
- Mapping module boundaries

## Usage

```bash
.sdlc-agents/tools/discovery/list-packages.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)

## Output Format

```
[packages] Found <count> packages/directories:
<package1>
<package2>
...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Directory not found |

## Related Tools

- `count-files` - Count files per package
- `detect-layers` - Identify architectural layers
- `find-imports` - Find imports between packages

## Example

```bash
$ .sdlc-agents/tools/discovery/list-packages.sh src/main
[packages] Found 12 packages/directories:
src/main/kotlin/com/example/controller
src/main/kotlin/com/example/service
src/main/kotlin/com/example/domain
src/main/kotlin/com/example/repository
...
```
