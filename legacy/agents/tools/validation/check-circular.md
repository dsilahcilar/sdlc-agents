# Check Circular Dependencies

**Category:** validation  
**Stack:** Any (auto-detects)

## Purpose

Detects circular dependencies between modules that can cause maintenance issues and tight coupling.

## When to Use

- After code changes
- Before committing
- During architecture review
- Finding coupling issues

## Usage

```bash
.sdlc-agents/tools/validation/check-circular.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)

## Output Format

```
[circular] Checking for circular dependencies...
[circular] Stack detected: <stack>

Found <count> circular dependencies:
<module1> -> <module2> -> <module1>
...

OR

[circular] No circular dependencies found ✓
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No circular dependencies |
| 1 | Circular dependencies found |

## Related Tools

- `find-imports` - See all imports
- `build-dep-graph` - Visualize dependencies
- `check-layers` - Validate layer rules

## Stack-Specific Tools Used

| Stack | Tool |
|-------|------|
| TypeScript | `madge --circular` |
| Java | `jdeps` analysis |
| Python | Manual import analysis |
| Go | `go build` cycle detection |

## Example

```bash
$ .sdlc-agents/tools/validation/check-circular.sh src
[circular] Checking for circular dependencies...
[circular] Stack detected: typescript

Found 2 circular dependencies:
src/services/UserService.ts -> src/services/AuthService.ts -> src/services/UserService.ts
src/utils/helper.ts -> src/utils/formatter.ts -> src/utils/helper.ts

[circular] FAILED: 2 circular dependencies found
```
