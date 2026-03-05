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
├── .github/
│   └── agents/
│       ├── planning-agent.agent.md
│       ├── coding-agent.agent.md
│       ├── architect-agent.agent.md
│       ├── codereview-agent.agent.md
│       ├── retro-agent.agent.md
│       ├── curator-agent.agent.md
│       └── initializer-agent.agent.md
├── .sdlc-agents/                  # Symlink or copy of runtime prompts
└── .gitignore                     # Updated to exclude .sdlc-agents/
```

## How It Works

- Copilot discovers `.github/agents/*.agent.md` files in VS Code.
- Each `.agent.md` file references `.sdlc-agents/<agent>.md` as the source instructions.
- You select agents via the Copilot Chat agent picker UI.

## Usage

1. Open GitHub Copilot Chat.
2. Choose an agent from the picker.
3. Prompt it with a task.

Example flow:

1. Select `initializer-agent` and initialize project scaffolding.
2. Select `planning-agent` and create feature/task artifacts.
3. Select `architect-agent` and review structural integrity.
4. Select `coding-agent` and implement a task.
5. Select `codereview-agent` and review changes.
6. Select `retro-agent` to capture learnings.
