# Custom Skills

Project-specific skills that agents load on-demand using Progressive Disclosure.

---

## How It Works

Skills provide domain knowledge, patterns, and tools that agents can load when relevant to the current task. Unlike extensions (which are behavioral rules), skills are **capabilities and knowledge**.

---

## Structure

```
skills/
├── README.md              # This registry
├── domain/                # Domain-specific skills
│   └── *.md               # e.g., payments.md, compliance.md
├── patterns/              # Custom architecture patterns
│   └── *.md               # e.g., saga-pattern.md, cqrs.md
└── tools/                 # Custom project tools
    ├── *.md               # Tool descriptions
    └── *.sh               # Tool scripts
```

---

## Priority Order

Skills are loaded in this order (later supplements earlier):

1. Core skills (`agents/skills/`)
2. Custom skills (`extensions/skills/`)

---

## Skill Format

Each skill file should include:

```markdown
# <Skill Name>

Brief description of what this skill provides.

---

## When to Use

- <situation when this skill applies>

## Key Concepts

- **<Concept>**: <definition>

## Patterns

<patterns or approaches this skill teaches>

## Tools

| Tool | Purpose |
|------|---------|
| `path/to/tool.sh` | What it does |

## Examples

<concrete examples of applying this skill>

## Related Skills

- `<other-skill>` - <relationship>
```

---

## Example: Domain Skill

Create `domain/payments.md`:

```markdown
# Payments Domain

Knowledge for implementing payment-related features.

---

## When to Use

- Implementing payment flows
- Handling transactions
- Working with payment providers

## Key Concepts

- **Idempotency**: Every payment operation must be safely retryable
- **Audit Trail**: All state changes require logging

## Invariants

- Never log card numbers or CVV
- Always use transactions for state changes
- Validate amounts are positive before processing

## Common Patterns

- Use saga pattern for multi-step payments
- Implement compensating transactions for rollback
```

---

## Example: Pattern Skill

Create `patterns/saga-pattern.md`:

```markdown
# Saga Pattern

Skill for implementing distributed transactions using the saga pattern.

---

## When to Use

- Multi-service transactions
- Long-running business processes
- Operations requiring compensation on failure
```

---

## Example: Custom Tool

Create `tools/internal-api.md` and `tools/internal-api.sh`:

```markdown
# Internal API Client

Tool for interacting with internal company APIs.

## Usage

./agent-context/extensions/skills/tools/internal-api.sh <endpoint>

## Output

JSON response from the API.
```

---

## Tips

1. **Keep skills focused** — One domain/pattern per file
2. **Include examples** — Concrete > abstract
3. **Link to tools** — Reference executable scripts when available
4. **Explain "why"** — Context helps agents apply skills correctly
5. **Update from retros** — Add learnings from past implementations
