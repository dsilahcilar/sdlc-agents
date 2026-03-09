# Cursor Setup

Install SDLC Agents for Cursor IDE.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/cursor/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── .cursor/
│   └── rules/
│       └── sdlc-agents.mdc       # References .agents/skills/
├── .agents/skills/
└── .sdlc-agents/                 # Symlinked/copied support assets
```

## Manual Setup

1. Install SDLC role skills into `.agents/skills/`
2. Create `.cursor/rules/sdlc-agents.mdc` with SDLC Agents instructions

## Usage

In Cursor Chat, reference an agent file:
```
@.agents/skills/planning-agent/SKILL.md Create a feature for user authentication
```

Or ask to follow the instructions:
```
Read .agents/skills/planning-agent/SKILL.md and follow its instructions for my request
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. @.agents/skills/planning-agent/SKILL.md Create a plan for adding search functionality
2. @.agents/skills/architect-agent/SKILL.md Validate the search feature architecture
3. @.agents/skills/coding-agent/SKILL.md Implement task T01 from the plan
4. @.agents/skills/codereview-agent/SKILL.md Review my changes
```

### Composer Mode (Multi-File)

Use Cursor's Composer for larger changes:
```
Using .agents/skills/coding-agent/SKILL.md, implement the user profile feature 
across all required files
```

### Quick Refactor

```
@.agents/skills/architect-agent/SKILL.md I want to extract a utility function 
from src/utils.ts. Does this violate any patterns?
```
