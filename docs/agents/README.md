# Agent Documentation

This directory contains detailed documentation for each agent in the SDLC multi-agent system.

## Agents

| Agent | Description | Code Access |
|-------|-------------|-------------|
| [Initializer Agent](./initializer-agent.md) | Project setup + architecture discovery | Read-only |
| [Planning Agent](./planning-agent.md) | Requirements → structured plan | None |
| [Architect Agent](./architect-agent.md) | Structural review & validation | None |
| [Coding Agent](./coding-agent.md) | Incremental implementation | Read/Write |
| [Code Review Agent](./codereview-agent.md) | Debt-aware code review | Read-only |
| [Retro Agent](./retro-agent.md) | Learning extraction | None |
| [Curator Agent](./curator-agent.md) | Knowledge quality control | None |

## Workflow

```
┌──────────────────┐
│  Initializer     │  (once per project)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│    Planning      │───▶│    Architect     │───▶│     Coding       │
└──────────────────┘    └──────────────────┘    └──────────────────┘
         │                       │                       │
         │              (rejected → revise)              ▼
         │                                      ┌──────────────────┐
         │                                      │   Code Review    │
         │                                      └──────────────────┘
         │                                               │
         ▼                                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                          Retro Agent                                │
└────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────────┐
│                         Curator Agent                               │
└────────────────────────────────────────────────────────────────────┘
```

## Stack Detection Responsibility

| Agent | Detects Stack? | Notes |
|-------|----------------|-------|
| Initializer | ✅ Yes | Detects and documents in artifacts |
| Planning | ✅ Yes | Detects and documents in Solution Plan |
| Architect | ❌ No | Receives from Solution Plan Section 1.1 |
| Coding | ❌ No | Receives from Context file |
| Code Review | ❌ No | Receives from Solution Plan + Context |
| Retro | N/A | Not relevant |
| Curator | N/A | Not relevant |

## Related Documentation

- [Agent Architecture Overview](../AGENT_ARCHITECTURE.md)
- [Agent Responsibility Allocation](../AGENT_RESPONSIBILITY_ALLOCATION.md)
- [Progressive Disclosure](../PROGRESSIVE_DISCLOSURE.md)
