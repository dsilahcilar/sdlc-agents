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
│   └── copilot-instructions.md    # References agents/
└── agents/                         # Symlinked from sdlc-agents
```

## Manual Setup

If you prefer manual setup:

1. Copy or symlink the `agents/` directory to your project
2. Create `.github/copilot-instructions.md`:

```markdown
# SDLC Agents

This project uses SDLC Agents for structured development.

## Available Agents

Invoke agents using GitHub Copilot Chat:
- `@planning-agent` — Create structured plans
- `@coding-agent` — Implement changes
- `@architect-agent` — Validate architecture
- `@codereview-agent` — Review code
- `@retro-agent` — Extract lessons learned
```

## Usage

In GitHub Copilot Chat:
```
@planning-agent Create a feature for user authentication
```

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

