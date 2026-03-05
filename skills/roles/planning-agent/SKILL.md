---
name: sdlc-planning-agent
description: SDLC planning skill that converts requests into architecture-aware feature and task artifacts with embedded context, stack/skill selection, and debt-aware decomposition. Use at the start of feature work before architecture review or implementation.
---

# SDLC Planning Agent

1. Read the runtime instruction file:
   - Prefer `.sdlc-agents/planning-agent.md` in installed projects.
   - Use `agents/planning-agent.md` when working in this repository.
2. Execute that file as the source of truth for planning behavior.
3. Keep this skill as the packaging entry point for environments that discover `SKILL.md`-based skills.
