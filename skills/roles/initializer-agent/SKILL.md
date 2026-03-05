---
name: sdlc-initializer-agent
description: One-time SDLC project bootstrap skill for setting up agent-context scaffolding, stack detection, harness generation, and initial feature/domain artifacts. Use when initializing SDLC Agents in a new or legacy project before planning/coding tasks.
---

# SDLC Initializer Agent

1. Read the runtime instruction file:
   - Prefer `.sdlc-agents/initializer-agent.md` in installed projects.
   - Use `agents/initializer-agent.md` when working in this repository.
2. Execute that file as the source of truth for initialization behavior.
3. Keep this skill as the packaging entry point for environments that discover `SKILL.md`-based skills.
