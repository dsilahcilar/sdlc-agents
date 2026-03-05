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
│       └── sdlc-agents.mdc       # References .sdlc-agents/
└── .sdlc-agents/                 # Symlinked/copied runtime prompts
```

## Manual Setup

1. Copy or symlink the repository `agents/` directory to `.sdlc-agents/` in your project
2. Create `.cursor/rules/sdlc-agents.mdc` with SDLC Agents instructions

## Usage

In Cursor Chat, reference an agent file:
```
@.sdlc-agents/planning-agent.md Create a feature for user authentication
```

Or ask to follow the instructions:
```
Read .sdlc-agents/planning-agent.md and follow its instructions for my request
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. @.sdlc-agents/planning-agent.md Create a plan for adding search functionality
2. @.sdlc-agents/architect-agent.md Validate the search feature architecture
3. @.sdlc-agents/coding-agent.md Implement task T01 from the plan
4. @.sdlc-agents/codereview-agent.md Review my changes
```

### Composer Mode (Multi-File)

Use Cursor's Composer for larger changes:
```
Using agents/coding-agent.md, implement the user profile feature 
across all required files
```

### Quick Refactor

```
@.sdlc-agents/architect-agent.md I want to extract a utility function 
from src/utils.ts. Does this violate any patterns?
```
