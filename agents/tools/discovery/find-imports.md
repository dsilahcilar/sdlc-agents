# Find Imports

**Category:** discovery  
**Stack:** Any (auto-detects)

## Purpose

Finds import/include statements between modules to understand dependency relationships.

## When to Use

- Mapping dependencies between packages
- Finding coupling between modules
- Before detecting architectural violations
- Understanding code organization

## Usage

```bash
.github/tools/discovery/find-imports.sh [path] [pattern]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)
- `pattern` - Optional. Filter imports matching pattern (e.g., `com.example`)

## Output Format

```
[imports] Found <count> import statements:
<file>: <import statement>
...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Directory not found |

## Related Tools

- `list-packages` - List packages first
- `check-circular` - Find circular dependencies
- `build-dep-graph` - Visualize dependencies

## Example

```bash
$ .github/tools/discovery/find-imports.sh src com.example.domain
[imports] Found 23 imports matching 'com.example.domain':
src/service/UserService.java: import com.example.domain.User;
src/repository/UserRepo.java: import com.example.domain.User;
...
```
