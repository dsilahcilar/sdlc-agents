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
│       └── sdlc-agents.mdc       # References agents/
└── agents/                        # Symlinked from sdlc-agents
```

## Manual Setup

1. Copy or symlink the `agents/` directory to your project
2. Create `.cursor/rules/sdlc-agents.mdc` with SDLC Agents instructions

## Usage

In Cursor Chat, reference an agent file:
```
@agents/planning-agent.md Create a feature for user authentication
```

Or ask to follow the instructions:
```
Read agents/planning-agent.md and follow its instructions for my request
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. @agents/planning-agent.md Create a plan for adding search functionality
2. @agents/architect-agent.md Validate the search feature architecture
3. @agents/coding-agent.md Implement task T01 from the plan
4. @agents/codereview-agent.md Review my changes
```

### Composer Mode (Multi-File)

Use Cursor's Composer for larger changes:
```
Using agents/coding-agent.md, implement the user profile feature 
across all required files
```

### Quick Refactor

```
@agents/architect-agent.md I want to extract a utility function 
from src/utils.ts. Does this violate any patterns?
```

