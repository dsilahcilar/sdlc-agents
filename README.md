# SDLC Agents

**Stop AI from generating technical debt. Build software that stays maintainable.**

[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-Agent%20Mode-blue?logo=github)](https://github.com/features/copilot)
[![Multi-Agent](https://img.shields.io/badge/Architecture-Multi--Agent-green)](./docs/AGENT_ARCHITECTURE.md)

---

## The Problem

LLMs write code fast—but they also generate **hidden costs**:

| 🚨 Problem | What Happens |
|-----------|--------------|
| **Structural Debt** | Code violates architectural boundaries. Coupling creeps in unnoticed. |
| **Generative Debt** | Quick fixes today become expensive rewrites tomorrow. |
| **Amnesia** | The same mistakes repeat across tasks—agents don't learn. |
| **Brevity Bias** | Limited context windows mean missed patterns and inconsistencies. |

**Result**: Your codebase degrades faster than you can refactor.

---

## The Solution

**SDLC Agents** bring engineering discipline to AI-assisted development:

```
Planning → Architect → Coding → Code Review → Retro
```

Each phase has a **specialized agent** that does one thing well:

| Agent | What It Does |
|-------|--------------|
| 🏗️ [Initializer](./docs/agents/initializer-agent.md) | Sets up project structure and discovers existing architecture |
| 📋 [Planning](./docs/agents/planning-agent.md) | Converts requirements into structured, implementable plans |
| 🧭 [Architect](./docs/agents/architect-agent.md) | Validates plans against architectural rules *before* coding |
| 💻 [Coding](./docs/agents/coding-agent.md) | Implements incrementally, following the approved plan |
| 🔍 [Code Review](./docs/agents/codereview-agent.md) | Catches debt, security issues, and architectural violations |
| 📖 [Retro](./docs/agents/retro-agent.md) | Extracts lessons to prevent future mistakes |
| 🗃️ [Curator](./docs/agents/curator-agent.md) | Maintains knowledge quality over time |

### Key Principles

- **Architecture-First**: Structure is validated *before* code is written
- **Continual Learning**: Lessons from past work inform future decisions
- **Progressive Disclosure**: Agents load only what they need, staying focused
- **Automated Guardrails**: Rules are enforced, not just documented

---

## Quick Start

**1.** Add `sdlc-agents` to your GitHub Copilot context  
**2.** Invoke the **Initializer Agent**:

```
Initialize this project. SDLC templates are at /path/to/sdlc-agents
```

**3.** The agent detects your stack, copies templates, and runs a health check

You're ready. Start with the **Planning Agent** for your first task.

---

## Documentation

| 📄 Document | Description |
|------------|-------------|
| [Agent Architecture](./docs/AGENT_ARCHITECTURE.md) | System design, file lifecycle, data flow |
| [Agent Responsibilities](./docs/AGENT_RESPONSIBILITY_ALLOCATION.md) | Context providers vs. consumers |
| [Individual Agents](./docs/agents/README.md) | Detailed specs for each agent |

---

<p align="center">
  <i>Designed for GitHub Copilot Agent Mode</i>
</p>
