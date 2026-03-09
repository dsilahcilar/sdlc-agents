# Aider Setup

Install SDLC Agents for Aider.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/aider/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── .aider.conf.yml               # Context files configuration
├── .agents/skills/
└── .sdlc-agents/                 # Symlinked/copied support assets
```

## Manual Setup

1. Install SDLC role skills into `.agents/skills/`
2. Create `.aider.conf.yml`:

```yaml
read:
  - .agents/skills/planning-agent/SKILL.md
  - .agents/skills/coding-agent/SKILL.md
  - .agents/skills/architect-agent/SKILL.md
```

## Usage

Aider will automatically load the agent files as context. Reference them in your prompts:
```
Follow the planning agent instructions to create a feature plan
```

---

## Workflow Examples

### Complete Feature Implementation

```bash
# Start aider with agent context
aider --read .agents/skills/planning-agent/SKILL.md

# In aider:
> Create a plan for adding API rate limiting
> /add agent-context/features/FEAT-XXX/feature.md
> Now follow coding-agent.md to implement task T01
```

### Git-Aware Development

Aider's git integration makes incremental commits easy:
```bash
aider --read .agents/skills/coding-agent/SKILL.md src/auth/*.ts
> Implement the login validation following the coding agent guidelines
# Aider auto-commits with meaningful messages
```

### Pipeline Integration

```bash
# In CI/CD script
aider --read .agents/skills/codereview-agent/SKILL.md \
      --message "Review the changes in this PR" \
      --no-auto-commits \
      $(git diff --name-only origin/main)
```

### Batch Processing

```bash
# Process multiple files
aider --read .agents/skills/coding-agent/SKILL.md \
      --message "Add error handling to all service methods" \
      src/services/*.ts
```
