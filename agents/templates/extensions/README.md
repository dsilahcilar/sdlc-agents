# Custom Instructions

Extend agent behavior without modifying core agent files.

---

## How It Works

Agents read and apply instructions from this folder **in addition to** their core behavior. This allows you to customize agents for your team's conventions, domain requirements, or coding standards.

---

## Structure

```
extensions/
├── README.md              # This file
├── _all-agents/           # Applied to ALL agents
│   └── *.md
├── architect-agent/       # Applied only to Architect Agent
│   └── *.md
├── codereview-agent/      # Applied only to Code Review Agent
│   └── *.md
├── coding-agent/          # Applied only to Coding Agent
│   └── *.md
├── curator-agent/         # Applied only to Curator Agent
│   └── *.md
├── initializer-agent/     # Applied only to Initializer Agent
│   └── *.md
├── planning-agent/        # Applied only to Planning Agent
│   └── *.md
├── retro-agent/           # Applied only to Retro Agent
│   └── *.md
└── skills/                # Custom project skills
    ├── README.md          # Skill registry and format guide
    ├── domain/            # Domain-specific skills
    ├── patterns/          # Architecture patterns
    └── tools/             # Custom tools
```

---

## Custom Skills

The `skills/` subfolder contains project-specific skills that agents load on-demand using Progressive Disclosure.

| Folder | Purpose |
|--------|---------|
| `domain/` | Domain-specific knowledge (payments, compliance, etc.) |
| `patterns/` | Custom architecture patterns (CQRS, saga, etc.) |
| `tools/` | Project-specific tools and scripts |

Skills are **capabilities and knowledge**, while extensions are **behavioral rules**. Both supplement core agent behavior.

See [`skills/README.md`](./skills/README.md) for format details.

---

## Priority Order

Instructions are applied in this order (later takes precedence on conflict):

1. Core agent instructions (from `sdlc-agents/agents/`)
2. Global custom instructions (`_all-agents/*.md`)
3. Agent-specific custom instructions (`<agent-name>/*.md`)

---

## Example: Team Code Style

Create `coding-agent/style-guide.md`:

```markdown
# Team Style Guide

## Naming Conventions

- Use camelCase for variables and functions
- Use PascalCase for classes and interfaces
- Prefix interfaces with `I` (e.g., `IUserRepository`)

## Required Patterns

- All public methods must have JSDoc/KDoc
- Use dependency injection, avoid `new` in business logic
- Prefer composition over inheritance

## Banned Patterns

- No `any` type in TypeScript
- No raw SQL in service layer (use repositories)
```

---

## Example: Domain Rules

Create `_all-agents/payment-domain.md`:

```markdown
# Payment Domain Rules

## Critical Invariants

- Never log credit card numbers
- All payment operations must be idempotent
- Always use transactions for payment state changes

## Regulatory Requirements

- PCI-DSS compliance is mandatory
- Audit logging required for all payment operations
```

---

## Example: Architecture Extensions

Create `architect-agent/company-standards.md`:

```markdown
# Company Architecture Standards

## Module Dependencies

- `api` modules may only depend on `domain` and `common`
- `infrastructure` must not be imported by `domain`
- External API clients must be in `integration` module

## Technology Choices

- Use Redis for caching (not in-memory)
- Use PostgreSQL for persistence
- Use Kafka for async messaging
```

---

## Tips

1. **Keep files focused** - One concern per file
2. **Use clear names** - File name should indicate content
3. **Be specific** - Vague instructions are ignored
4. **Include examples** - Show what you mean
5. **Explain why** - Context helps agents apply rules correctly
