# TypeScript Madge

**Category:** stack  
**Stack:** TypeScript/JavaScript

## Purpose

Detects circular dependencies in TypeScript/JavaScript projects using Madge.

## When to Use

- Quick circular dependency check
- Before committing changes
- Debugging import issues
- Understanding module relationships

## Usage

```bash
.sdlc-agents/tools/stack/ts/madge.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to analyze (default: `src`)

## Output Format

```
[madge] Checking circular dependencies...

Circular dependencies found!
  src/a.ts -> src/b.ts -> src/a.ts

OR

[madge] No circular dependencies found ✓
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No circular dependencies |
| 1 | Circular dependencies found |

## Prerequisites

Madge is run via npx (auto-installed).

## Related Tools

- `ts/depcruise` - Full dependency validation
- `check-circular` - Generic circular check

## Example

```bash
$ .sdlc-agents/tools/stack/ts/madge.sh src
[madge] Checking circular dependencies...
[madge] Path: src
[madge] Extensions: ts,tsx,js,jsx

Circular dependencies found!

1) src/services/UserService.ts > src/services/AuthService.ts > src/services/UserService.ts

[madge] FAILED: 1 circular dependency found
```
