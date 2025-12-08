# Count Files

**Category:** discovery  
**Stack:** Any

## Purpose

Counts source files per package/directory to understand codebase size and distribution.

## When to Use

- Understanding codebase scale
- Identifying large modules
- Planning refactoring efforts
- Estimating complexity

## Usage

```bash
.github/tools/discovery/count-files.sh [path] [extension]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)
- `extension` - Optional. File extension filter (e.g., `java`, `ts`)

## Output Format

```
[count] File distribution:
  <count>  <path>
  ...
Total: <total> files
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Directory not found |

## Related Tools

- `list-packages` - List packages first
- `detect-layers` - Understand layer structure

## Example

```bash
$ .github/tools/discovery/count-files.sh src java
[count] File distribution:
     45  src/main/java/com/example/service
     32  src/main/java/com/example/domain
     28  src/main/java/com/example/controller
     15  src/main/java/com/example/repository
Total: 120 java files
```
