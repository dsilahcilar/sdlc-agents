# Check Layers

**Category:** validation  
**Stack:** Any

## Purpose

Validates that dependencies between architectural layers follow expected rules (e.g., domain should not import infrastructure).

## When to Use

- After code changes
- Before committing
- During architecture review
- Enforcing layer boundaries

## Usage

```bash
.sdlc-agents/tools/validation/check-layers.sh [path]
```

**Arguments:**
- `path` - Optional. Directory to scan (default: `src`)

## Output Format

```
[layers] Validating layer dependencies...

Checking: domain -> infrastructure
  Violations: <count>
  - domain/User.java imports infrastructure/Database.java

[layers] Summary:
  Checked: <rules-checked>
  Violations: <total-violations>
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No layer violations |
| 1 | Layer violations found |

## Layer Rules (Defaults)

| From | Cannot Import |
|------|---------------|
| domain | controller, infrastructure, service |
| service | controller |
| repository | controller, service |

## Related Tools

- `detect-layers` - Discover layers first
- `check-circular` - Find circular deps
- Stack-specific: `java/archunit`, `ts/depcruise`

## Example

```bash
$ .sdlc-agents/tools/validation/check-layers.sh src
[layers] Validating layer dependencies...
[layers] Stack detected: java

Checking: domain -> controller (SHOULD NOT EXIST)
  ✓ No violations

Checking: domain -> infrastructure (SHOULD NOT EXIST)
  ⚠ 2 violations found:
  - domain/UserService.java:15 imports infrastructure/EmailClient
  - domain/Order.java:8 imports infrastructure/PaymentGateway

[layers] Summary:
  Rules checked: 4
  Violations: 2

[layers] FAILED: 2 layer violations found
```
