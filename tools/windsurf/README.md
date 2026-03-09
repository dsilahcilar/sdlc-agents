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
│       └── sdlc-agents.md        # References .agents/skills/
├── .agents/skills/
└── .sdlc-agents/                 # Symlinked/copied support assets
```

## Manual Setup

1. Install SDLC role skills into `.agents/skills/`
2. Create `.windsurf/rules/sdlc-agents.md` with agent references

## Usage

In Windsurf Cascade, reference the agents:
```
Use .agents/skills/planning-agent/SKILL.md to create a feature plan
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. Follow .agents/skills/planning-agent/SKILL.md to plan a notification system
2. Follow .agents/skills/architect-agent/SKILL.md to validate the design
3. Follow .agents/skills/coding-agent/SKILL.md to implement the first task
4. Follow .agents/skills/codereview-agent/SKILL.md to review changes
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
Using .agents/skills/architect-agent/SKILL.md, analyze the dependency graph 
of our service layer and identify coupling issues
```
