# Detect Layers

**Category:** discovery  
**Stack:** Any

## Purpose

Identifies architectural layers in the codebase by analyzing package/directory naming conventions.

## When to Use

- Understanding existing architecture
- Before generating architecture rules
- Identifying layer boundaries
- Architecture discovery for legacy projects

## Usage

```bash
.sdlc-agents/tools/discovery/detect-layers.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)

## Output Format

```
[layers] Detected architecture layers:
Layer: <layer-name>
  Packages: <count>
  Paths: <path1>, <path2>...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Directory not found |

## Related Tools

- `list-packages` - Get all packages first
- `check-layers` - Validate layer dependencies
- `find-imports` - Find cross-layer imports

## Example

```bash
$ .sdlc-agents/tools/discovery/detect-layers.sh src/main
[layers] Detected architecture layers:
Layer: Controller (Presentation)
  Packages: 3
  Paths: controller, api, rest

Layer: Service (Application)
  Packages: 5
  Paths: service, usecase, application

Layer: Domain (Core)
  Packages: 4
  Paths: domain, entity, model

Layer: Repository (Infrastructure)
  Packages: 2
  Paths: repository, persistence
```
