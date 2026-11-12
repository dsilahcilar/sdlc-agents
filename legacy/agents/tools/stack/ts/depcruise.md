# TypeScript Dependency Cruiser

**Category:** stack  
**Stack:** TypeScript/JavaScript

## Purpose

Runs Dependency Cruiser to validate import rules and architectural constraints in TypeScript/JavaScript projects.

## When to Use

- After code changes
- Enforcing import restrictions
- Detecting forbidden dependencies
- Validating module boundaries

## Usage

```bash
.sdlc-agents/tools/stack/ts/depcruise.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to analyze (default: `src`)

## Output Format

```
[depcruise] Running Dependency Cruiser...
[depcruise] Config: .dependency-cruiser.js

✔ no violations found (123 modules, 456 dependencies)

OR

✘ 3 violations found
  error no-circular: src/a.ts -> src/b.ts -> src/a.ts
  ...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No violations |
| 1 | Violations found or not configured |

## Prerequisites

```bash
npm install --save-dev dependency-cruiser
npx depcruise --init
```

## Configuration

Create `.dependency-cruiser.js` (see TypeScript skill file for template).

## Related Tools

- `ts/madge` - Circular dependency detection
- `check-circular` - Generic circular check
- `check-layers` - Layer validation

## Example

```bash
$ .sdlc-agents/tools/stack/ts/depcruise.sh src
[depcruise] Running Dependency Cruiser...
[depcruise] Config: .dependency-cruiser.js
[depcruise] Path: src

✔ no violations found (45 modules, 128 dependencies cruised in 234ms)

[depcruise] Architecture rules validated ✓
```
