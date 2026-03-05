---
name: sdlc-codereview-agent
description: SDLC code-review skill for validating correctness, architecture compliance, debt impact, and test quality across completed feature tasks. Use after implementation and before merge/finalization.
---

# SDLC Code Review Agent

1. Read the runtime instruction file:
   - Prefer `.sdlc-agents/codereview-agent.md` in installed projects.
   - Use `agents/codereview-agent.md` when working in this repository.
2. Execute that file as the source of truth for review behavior.
3. Keep this skill as the packaging entry point for environments that discover `SKILL.md`-based skills.
