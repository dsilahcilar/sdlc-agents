# Codex Setup

Install SDLC role skills into your Codex skills home and the SDLC support bundle into the target project.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/codex/install.sh --codex-home ~/.codex/skills --target /path/to/your/project
```

## What Gets Created

```text
~/.codex/skills/
├── planning-agent/
│   ├── SKILL.md
│   └── agents/openai.yaml
├── coding-agent/
├── architect-agent/
├── codereview-agent/
├── retro-agent/
├── curator-agent/
└── initializer-agent/

/path/to/your/project/
└── .sdlc-agents/                # Support assets for templates, harness tools, guardrails
```

## Notes

- Codex skills still depend on `.sdlc-agents/` in the active project, so this installer provisions that support bundle too.
- Use `--copy` if you want the project support bundle copied instead of symlinked.
