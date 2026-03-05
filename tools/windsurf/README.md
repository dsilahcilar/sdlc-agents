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
│       └── sdlc-agents.md        # References .sdlc-agents/
└── .sdlc-agents/                 # Symlinked/copied runtime prompts
```

## Manual Setup

1. Copy or symlink the repository `agents/` directory to `.sdlc-agents/` in your project
2. Create `.windsurf/rules/sdlc-agents.md` with agent references

## Usage

In Windsurf Cascade, reference the agents:
```
Use .sdlc-agents/planning-agent.md to create a feature plan
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. Follow .sdlc-agents/planning-agent.md to plan a notification system
2. Follow .sdlc-agents/architect-agent.md to validate the design
3. Follow .sdlc-agents/coding-agent.md to implement the first task
4. Follow .sdlc-agents/codereview-agent.md to review changes
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
Using .sdlc-agents/architect-agent.md, analyze the dependency graph 
of our service layer and identify coupling issues
```
