# SDLC Skills Catalog

This directory contains `SKILL.md`-packaged SDLC skills for runtimes that natively support skill discovery.

## Role Skills

- `roles/initializer-agent/SKILL.md`
- `roles/planning-agent/SKILL.md`
- `roles/architect-agent/SKILL.md`
- `roles/coding-agent/SKILL.md`
- `roles/codereview-agent/SKILL.md`
- `roles/retro-agent/SKILL.md`
- `roles/curator-agent/SKILL.md`

## Compatibility Model

- Canonical role instructions now live in `skills/roles/*/SKILL.md`.
- Installers now place these role skills into project-local skill directories:
  - `.github/skills/`
  - `.claude/skills/`
  - `.agents/skills/`
- Compatibility runtime prompts remain available at `agents/*-agent.md` for support-bundle and legacy workflows.
- Regenerate compatibility prompts with `./scripts/generate-role-agents.sh`.
- Installed projects still receive `.sdlc-agents/` as a support bundle for templates, harness tooling, guardrails, and capability skills.

## Existing Capability Skills

Core progressive-disclosure capability skills still live under `agents/skills/`.

- Stack detection and stack skills: `agents/skills/stacks/`
- Pattern skills: `agents/skills/patterns/`
- Framework skills: `agents/skills/frameworks/`
- Skill index: `agents/skills/skill-index.yaml`

Migration to full `SKILL.md` packaging for capability skills can happen incrementally in future iterations.
