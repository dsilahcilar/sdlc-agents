---
name: sdlc-coding-agent
description: SDLC implementation skill for completing one self-contained task at a time with strict architecture/test validation, progress logging, and escalation on blockers. Use after architecture-approved planning artifacts exist.
---

# SDLC Coding Agent

1. Read the runtime instruction file:
   - Prefer `.sdlc-agents/coding-agent.md` in installed projects.
   - Use `agents/coding-agent.md` when working in this repository.
2. Execute that file as the source of truth for coding-task behavior.
3. Keep this skill as the packaging entry point for environments that discover `SKILL.md`-based skills.
