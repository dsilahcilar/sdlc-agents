# Claude Code Setup

Install SDLC Agents for Claude Code with proper subagent support.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/claude/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── .claude/
│   └── agents/                      # Subagent definitions
│       ├── planning-agent.md
│       ├── coding-agent.md
│       ├── architect-agent.md
│       ├── codereview-agent.md
│       ├── retro-agent.md
│       ├── curator-agent.md
│       └── initializer-agent.md
├── .agents/                          # Symlinked from sdlc-agents/agents
└── .gitignore                        # Updated to exclude .agents/
```

## How It Works

Claude Code's subagent system allows you to create specialized AI agents with:
- **Separate context windows** for each agent
- **Specific tool permissions** per agent
- **Custom system prompts** defining agent behavior
- **Automatic or explicit invocation**

Each subagent in `.claude/agents/` references the full instructions in `.agents/<agent-name>.md`.

## Usage

### View Available Subagents

```
/agents
```

This shows all available subagents including the 7 SDLC Agents.

### Use a Subagent

**Explicit invocation:**
```
Use the initializer-agent to set up project structure

Use the planning-agent to create a plan for user authentication

Use the coding-agent to implement task T01 from FEAT-001

Use the codereview-agent to review my recent changes
```

**Automatic delegation:**
Claude can automatically invoke the appropriate subagent based on your request and the agent's description.

---

## Workflow Examples

### Complete Feature Implementation

```
1. Use the initializer-agent (first time only)
2. Use the planning-agent to create a plan for user preferences
3. Use the architect-agent to review the feature plan
4. Use the coding-agent to implement task T01
5. Use the codereview-agent to review my implementation
6. Use the retro-agent to extract lessons from this feature
```

### Proactive Code Review

The codereview-agent is configured to be used "proactively after code changes", so Claude may automatically invoke it when you make changes.

### Complex Planning

```
Use the planning-agent. I need to refactor our payment module:
- Current: Stripe-only integration
- Goal: Support Stripe, PayPal, and Apple Pay
- Constraints: Must be backward compatible
```

## Managing Subagents

### Via /agents Command

```
/agents
```

- View all subagents
- Create new custom subagents
- Edit existing subagents
- Delete custom subagents

### Direct File Management

You can also manually edit files in `.claude/agents/`:

```bash
# Edit a subagent
code .claude/agents/planning-agent.md

# Create a custom subagent
echo '---
name: my-custom-agent
description: Use for specific task
---
Custom instructions here' > .claude/agents/my-custom-agent.md
```

## Benefits of Claude Code Subagents

1. **Focused Context**: Each agent has its own context window
2. **Tool Control**: Restrict which tools each agent can use
3. **Proactive Behavior**: Agents can be invoked automatically
4. **Large Context Window**: Claude's 200K+ token window handles complex codebases
5. **Seamless Integration**: Works natively with Claude Code's `/agents` system
