# GitHub Copilot Setup

Install SDLC Agents for GitHub Copilot.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/github-copilot/install.sh --target /path/to/your/project
```

## What Gets Created

```text
your-project/
├── .github/skills/
├── .claude/skills/
├── .agents/skills/
└── .sdlc-agents/                  # Symlink or copy of support assets
```

## How It Works

- Copilot can discover project skills from `.github/skills/`.
- SDLC Agents mirrors the same role skills into `.claude/skills/` and `.agents/skills/` for cross-tool compatibility.
- `.sdlc-agents/` remains the support bundle for templates, harness tooling, guardrails, and capability skills.

## Usage

1. Open GitHub Copilot Chat.
2. Use an installed SDLC skill such as `planning-agent` or `coding-agent`.
3. Prompt it with a task.

Example flow:

1. Select `initializer-agent` and initialize project scaffolding.
2. Select `planning-agent` and create feature/task artifacts.
3. Select `architect-agent` and review structural integrity.
4. Select `coding-agent` and implement a task.
5. Select `codereview-agent` and review changes.
6. Select `retro-agent` to capture learnings.
