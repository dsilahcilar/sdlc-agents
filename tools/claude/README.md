# Claude Code Setup

Install SDLC Agents for Claude Code.

## Quick Start

```bash
# From the sdlc-agents directory
./tools/claude/install.sh --target /path/to/your/project
```

## What Gets Created

```
your-project/
├── CLAUDE.md                      # Project instructions
├── .claude/
│   └── settings.local.json        # Permissions (optional)
└── agents/                        # Symlinked from sdlc-agents
```

## Manual Setup

1. Copy or symlink the `agents/` directory to your project
2. Create `CLAUDE.md` in your project root (see template below)

## Usage

With Claude Code, simply ask to use an agent:
```
Use the planning agent to create a feature for user authentication
```

Or reference the files directly:
```
Read agents/planning-agent.md and follow its instructions
```

---

## Workflow Examples

### Complete Feature Implementation

```
1. Read agents/planning-agent.md and create a plan for user preferences
2. Read agents/architect-agent.md and review the feature plan
3. Read agents/coding-agent.md and implement task T01
4. Read agents/codereview-agent.md and review my implementation
5. Read agents/retro-agent.md and extract lessons from this feature
```

### Multi-File Analysis

Claude's large context window is great for holistic analysis:
```
Read the entire agents/ directory and explain how the agents work together
```

### Complex Planning

```
Use the planning agent. I need to refactor our payment module:
- Current: Stripe-only integration
- Goal: Support Stripe, PayPal, and Apple Pay
- Constraints: Must be backward compatible
```

