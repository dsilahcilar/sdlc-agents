# GitHub Copilot Setup

Install SDLC Agents for GitHub Copilot.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/github-copilot/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── .github/
│   └── agents/                      # Individual agent definitions
│       ├── planning-agent.agent.md
│       ├── coding-agent.agent.md
│       ├── architect-agent.agent.md
│       ├── codereview-agent.agent.md
│       ├── retro-agent.agent.md
│       ├── curator-agent.agent.md
│       └── initializer-agent.agent.md
├── .agents/                          # Symlinked from sdlc-agents/agents
└── .gitignore                        # Updated to exclude .agents/
```

## How It Works

Each `.agent.md` file in `.github/agents/` contains:
- **YAML frontmatter**: Agent name and description for GitHub Copilot
- **Instructions reference**: Points to the full agent instructions in `.agents/<agent-name>.md`
- **Context**: Explains the agent's role in the SDLC workflow

GitHub Copilot automatically discovers these agent files and makes them available in the VS Code UI.

## Manual Setup

If you prefer manual setup:

1. Copy or symlink the `agents/` directory to `.agents/` in your project
2. Create `.github/agents/` directory
3. Create individual `.agent.md` files for each agent (see the install script for templates)
4. Add `.agents/` to your `.gitignore`

## Usage

**In VS Code with GitHub Copilot:**

1. Open GitHub Copilot Chat panel
2. Click the **agent picker** (@ icon in the chat input)
3. Select the agent you want to use from the dropdown
4. Type your request

**Example workflow:**

1. Select **initializer-agent** → "Set up project structure"
2. Select **planning-agent** → "Create a feature for user authentication"
3. Select **architect-agent** → "Review the feature plan in agent-context/features/FEAT-001/feature.md"
4. Select **coding-agent** → "Implement task T01 from FEAT-001"
5. Select **codereview-agent** → "Review my changes before creating a PR"
6. Select **retro-agent** → "Extract lessons from completing this feature"

**Note**: Agents are selected via the UI picker, not by typing `@agent-name` in the chat.


---

## Workflow Examples

### Complete Feature Implementation

```
1. @planning-agent Create a feature plan for adding user preferences
2. @architect-agent Review the feature plan in agent-context/features/FEAT-XXX/feature.md
3. @coding-agent Implement task T01 from the approved plan
4. @codereview-agent Review my changes before creating a PR
5. @retro-agent Extract lessons from completing this feature
```

### Quick Code Review

```
@codereview-agent Review the changes in src/auth/login.ts
```

### Architecture Validation

```
@architect-agent Check if adding a new service layer violates our boundaries
```

### Multi-Agent Retrospective

```
@retro-agent I completed the payment integration feature. 
Key observations:
- API rate limiting wasn't documented
- Test mocks were complex to set up
Please extract lessons for the playbook.
```

