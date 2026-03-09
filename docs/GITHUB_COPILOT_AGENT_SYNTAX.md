# GitHub Copilot Skill Support

This document explains how SDLC Agents installs project skills for GitHub Copilot.

## Overview

GitHub Copilot can discover project skills from skill directories rather than legacy agent-wrapper files.

- Primary location: `.github/skills/`
- Mirrored for compatibility: `.agents/skills/` and `.claude/skills/`
- Skill format: `<skill-name>/SKILL.md`
- Optional UI metadata: `<skill-name>/agents/openai.yaml`

SDLC Agents also installs `.sdlc-agents/` as a support bundle for templates, harness tooling, guardrails, and capability skills.

## Installed Structure

```text
your-project/
├── .github/skills/
│   ├── planning-agent/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   └── ...
├── .agents/skills/
├── .claude/skills/
└── .sdlc-agents/
```

## How It Works

1. GitHub Copilot discovers SDLC role skills from `.github/skills/`.
2. Each skill contains the role instructions in `SKILL.md`.
3. The skill instructions use `.sdlc-agents/` support assets when they need templates, harness generators, guardrails, or capability-skill resolution.

## Usage

Typical SDLC flow:

```text
Use the initializer-agent skill to bootstrap this project
Use the planning-agent skill to create a feature plan
Use the architect-agent skill to review the plan
Use the coding-agent skill to implement task T01
Use the codereview-agent skill to review the changes
Use the retro-agent skill to extract lessons learned
```

## Migration From Legacy `.github/agents`

Older SDLC Agents installs created `.github/agents/*.agent.md` wrappers. Current installs are skill-first:

1. Re-run the installer:

```bash
./install.sh --ghcp --target /path/to/your/project
```

2. Confirm `.github/skills/*/SKILL.md` exists.
3. Keep `.sdlc-agents/` because the skills still rely on the support bundle.
4. Remove old `.github/agents/` wrappers after you verify the new skill-based setup works for your workflow.
