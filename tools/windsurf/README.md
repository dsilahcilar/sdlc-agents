# Windsurf Setup

Install SDLC Agents for Windsurf IDE.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/windsurf/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── .windsurf/
│   └── rules/
│       └── sdlc-agents.md        # References agents/
└── agents/                        # Symlinked from sdlc-agents
```

## Manual Setup

1. Copy or symlink the `agents/` directory to your project
2. Create `.windsurf/rules/sdlc-agents.md` with agent references

## Usage

In Windsurf Cascade, reference the agents:
```
Use agents/planning-agent.md to create a feature plan
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. Follow agents/planning-agent.md to plan a notification system
2. Follow agents/architect-agent.md to validate the design
3. Follow agents/coding-agent.md to implement the first task
4. Follow agents/codereview-agent.md to review changes
```

### Using Flows

Windsurf Flows excel at multi-step tasks:
```
Create a Flow:
- Step 1: Plan with planning-agent.md
- Step 2: Validate with architect-agent.md
- Step 3: Implement with coding-agent.md
```

### Deep Codebase Understanding

```
Using agents/architect-agent.md, analyze the dependency graph 
of our service layer and identify coupling issues
```
