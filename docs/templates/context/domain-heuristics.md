# Domain Heuristics

> "Brevity Bias causes abstraction that omits crucial, detailed information such as domain-specific heuristics, tool-use guidelines, or common failure modes necessary for agents and knowledge-intensive applications."

**Template Location:** [`agents/templates/context/domain-heuristics.md`](../../../agents/templates/context/domain-heuristics.md)

---

## Purpose

This file contains domain-specific principles, patterns, and invariants that help agents avoid common mistakes in specific business domains.

---

## How Agents Use This File

| Agent | Role |
|-------|------|
| **Planning Agent** | Reads this file and extracts relevant heuristics into the context file (`<issue-id>.context.md`) |
| **Architect Agent** | Reads this file to validate domain invariants are respected in plans |
| **Coding Agent** | Receives curated heuristics via the context file (does NOT read this file directly) |
| **Retro Agent** | Appends new heuristics discovered during implementation |

---

## Structure

Each domain entry follows this template:

```markdown
## Domain: <Domain Name>

### Overview
<Brief description of this business domain>

### Key Concepts
- **<Concept 1>**: <definition>

### Invariants
These rules must NEVER be violated:
- <invariant>

### Heuristics
Patterns that generally work well:
- <heuristic>

### Common Failure Modes
Mistakes frequently made in this domain:
- <failure mode>

### Related Modules
- `<module path>`
```

---

## Pre-configured Domains

The template includes these common business domains:

| Domain | Key Invariants |
|--------|----------------|
| **Authentication & Authorization** | Never store plaintext passwords, always validate tokens |
| **Payments & Transactions** | Atomic operations, idempotency, no floating point for money |
| **Inventory & Stock** | No negative quantities, reservations expire, concurrent update safety |
| **Notifications & Messaging** | Respect opt-out, rate limiting, no sensitive data in logs |

---

## Customization

After the Initializer Agent copies this file to `<project-root>/agent-context/context/domain-heuristics.md`:

1. **Add your domains** - Use the template structure
2. **Include at least 3 invariants** - Rules that must never be violated
3. **Include at least 3 heuristics** - Patterns that work well
4. **Include at least 3 failure modes** - Common mistakes
5. **Link to relevant modules** - File paths in your codebase

---

## Why This Matters

Without domain heuristics, agents may:
- Use floating point for currency calculations
- Store plaintext passwords
- Create race conditions in inventory updates
- Ignore user notification preferences

These are domain-specific knowledge that can't be inferred from code structure alone.
