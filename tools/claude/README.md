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
├── .claude/skills/
├── .github/skills/
├── .agents/skills/
└── .sdlc-agents/                    # Symlinked or copied support assets
```

## How It Works

Claude can load SDLC role skills from `.claude/skills/`.
The installer also mirrors the same skills to `.github/skills/` and `.agents/skills/` so the project stays compatible across tools.

## Usage

### Use a Skill

```
Use the initializer-agent skill to set up project structure
Use the planning-agent skill to create a plan for user authentication
Use the coding-agent skill to implement task T01 from FEAT-001
Use the codereview-agent skill to review my recent changes
```

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

You can inspect or edit installed SDLC skill packages under `.claude/skills/`.

## Benefits of Claude Code Subagents

1. **Focused Context**: Each agent has its own context window
2. **Tool Control**: Restrict which tools each agent can use
3. **Proactive Behavior**: Agents can be invoked automatically
4. **Large Context Window**: Claude's 200K+ token window handles complex codebases
5. **Seamless Integration**: Works natively with Claude Code's `/agents` system
