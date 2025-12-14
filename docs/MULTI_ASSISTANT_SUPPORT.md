# Multi-Assistant Support

SDLC Agents works with multiple AI coding assistants. This guide explains how to install and use SDLC Agents with your preferred tool.

## Supported Tools

| Tool | Status | Install Command |
|------|--------|-----------------|
| [GitHub Copilot](#github-copilot) | ✅ Full | `./install.sh --ghcp --target ./your-project` |
| [Claude Code](#claude-code) | ✅ Full | `./install.sh --claude --target ./your-project` |
| [Cursor](#cursor) | ✅ Full | `./install.sh --cursor --target ./your-project` |
| [Windsurf](#windsurf) | ✅ Full | `./install.sh --windsurf --target ./your-project` |
| [Aider](#aider) | ✅ Full | `./install.sh --aider --target ./your-project` |

## Quick Start

```bash
# Clone sdlc-agents
git clone https://github.com/dsilahcilar/sdlc-agents.git
cd sdlc-agents

# Install for your tool (replace --ghcp with your tool)
./install.sh --ghcp --target /path/to/your/project

# Or install for multiple tools at once
./install.sh --ghcp --claude --target /path/to/your/project

# Or install for all supported tools
./install.sh --all --target /path/to/your/project
```

## How It Works

SDLC Agents uses an **adapter pattern**:

```
sdlc-agents/
├── agents/                 # Generic agent instructions (tool-agnostic)
│   ├── planning-agent.md
│   ├── coding-agent.md
│   └── ...
│
└── tools/                  # Tool-specific adapters
    ├── github-copilot/
    ├── claude/
    ├── cursor/
    ├── windsurf/
    └── aider/
```

The install script:
1. Symlinks (or copies) the `agents/` directory to your project
2. Creates tool-specific configuration referencing the agents

## Tool-Specific Setup

### GitHub Copilot

**Creates:**
- `.github/agents/*.agent.md` — Individual agent definitions
- `.sdlc-agents/` → symlink to sdlc-agents/agents
- `.gitignore` — Updated to exclude `.sdlc-agents/`

**Usage:**
Open GitHub Copilot Chat in VS Code, click the agent picker (@ icon), and select an agent:
- Select **planning-agent** → "Create a feature for user authentication"
- Select **architect-agent** → "Review the feature plan in agent-context/features/FEAT-001/feature.md"
- Select **coding-agent** → "Implement task T01 from FEAT-001"

See [tools/github-copilot/README.md](../tools/github-copilot/README.md)


---

### Claude Code

**Creates:**
- `.claude/agents/*.md` — Individual subagent definitions
- `.sdlc-agents/` → symlink to sdlc-agents/agents
- `.gitignore` — Updated to exclude `.sdlc-agents/`

**Usage:**
Use Claude Code's subagent system:
```
/agents                    # View all available subagents
Use the planning-agent to create a plan for user authentication
Use the coding-agent to implement task T01
Use the codereview-agent to review my changes
```

See [tools/claude/README.md](../tools/claude/README.md)

---

### Cursor

**Creates:**
- `.cursor/rules/sdlc-agents.mdc`
- `agents/` → symlink to sdlc-agents/agents

**Usage:**
```
@agents/planning-agent.md Create a feature for user authentication
```

See [tools/cursor/README.md](../tools/cursor/README.md)

---

### Windsurf

**Creates:**
- `.windsurf/rules/sdlc-agents.md`
- `agents/` → symlink to sdlc-agents/agents

**Usage:**
```
Use agents/planning-agent.md to create a feature plan
```

See [tools/windsurf/README.md](../tools/windsurf/README.md)

---

### Aider

**Creates:**
- `.aider.conf.yml`
- `agents/` → symlink to sdlc-agents/agents

**Usage:**
```
Follow the planning agent instructions to create a feature plan
```

See [tools/aider/README.md](../tools/aider/README.md)

---

## Install Options

```bash
# Symlink mode (default) - agents stay in sync with sdlc-agents updates
./install.sh --ghcp --target ./your-project

# Copy mode - agents are copied (works better on Windows, self-contained)
./install.sh --ghcp --target ./your-project --copy
```

## Updating

If you used **symlink mode**, updating is automatic—just `git pull` in the sdlc-agents repo.

If you used **copy mode**, re-run the install with `--copy` to update:
```bash
./install.sh --ghcp --target ./your-project --copy
```

## Choosing a Tool

Not sure which tool to use? Here's a quick guide:

| Use Case | Recommended Tool | Why |
|----------|------------------|-----|
| **IDE-first workflow** | GitHub Copilot, Cursor | Deep IDE integration, inline suggestions |
| **Larger context needs** | Claude Code | Larger context window for complex codebases |
| **Maximum flexibility** | Cursor, Windsurf | Supports multiple models and providers |
| **Terminal-based workflow** | Aider | CLI-native, git-aware, scriptable |
| **Enterprise/compliance** | GitHub Copilot | Enterprise policies, SSO, audit logs |

### Tool Strengths

| Tool | Best For |
|------|----------|
| **GitHub Copilot** | Native VS Code/JetBrains integration, enterprise features |
| **Claude Code** | Long context, complex reasoning, documentation-heavy tasks |
| **Cursor** | AI-native IDE, composer mode, multi-file edits |
| **Windsurf** | Flows for complex tasks, cascade chat, deep codebase understanding |
| **Aider** | Git integration, terminal users, scripting pipelines |

---

## Using Multiple Tools

You can install SDLC Agents for multiple tools on the same project:

```bash
# Install all tools at once
./install.sh --all --target ./your-project

# Or pick specific tools
./install.sh --ghcp --claude --target ./your-project
```

### How Multi-Tool Works

- **Shared `agents/` directory**: All tools use the same agent instructions
- **Separate configs**: Each tool gets its own configuration file
- **No conflicts**: Tool configs are independent (`.github/`, `.claude/`, `.cursor`, etc.)

### When to Use Multiple Tools

| Scenario | Recommendation |
|----------|----------------|
| Team with different preferences | Install all, let each dev use their choice |
| Different tasks need different tools | Use Copilot for quick edits, Claude for complex planning |
| Comparing tool effectiveness | Install both, A/B test on same tasks |
| CI/CD integration | Use Aider in pipelines, IDE tools for development |

---

## Troubleshooting

### Symlinks not working (Windows)

Use copy mode instead:
```bash
./install.sh --ghcp --target ./your-project --copy
```

### Agent files not found

Ensure the `agents/` symlink is valid:
```bash
ls -la ./your-project/agents/
```

### Multiple tools conflict

Installing multiple tools is safe—each creates its own configuration files without conflict.

---

## Tool-Specific Issues

### GitHub Copilot

**Agents not discovered:**
- Ensure `.github/agents/*.agent.md` files exist
- Verify `.sdlc-agents/` directory symlink is valid: `ls -la .sdlc-agents/`
- Check `.sdlc-agents/` is excluded in `.gitignore`
- Restart VS Code

### Claude Code

**Permission errors with settings.local.json:**
```bash
chmod 644 .claude/settings.local.json
```

**CLAUDE.md not being read:**
- Ensure file is in project root
- Check file isn't empty

### Cursor

**Rules not loading:**
- Verify `.cursor/rules/sdlc-agents.mdc` exists
- Check MDC frontmatter is valid YAML
- Restart Cursor

### Windsurf

**Rules directory issues:**
- Ensure `.windsurf/rules/` directory exists
- Check file permissions
- Verify rules file has `.md` extension

### Aider

**Context size limitations:**
- Use `--map-tokens` to limit context
- Consider excluding large files in `.aider.conf.yml`
- Use `--no-auto-commits` if git issues occur

---

## Tool Comparison Guide

### Context and Performance

| Tool | Context Window | Speed | Offline |
|------|----------------|-------|---------|
| **GitHub Copilot** | ~8K tokens | Fast | ❌ Cloud |
| **Claude Code** | ~200K tokens | Medium | ❌ Cloud |
| **Cursor** | Varies by model | Fast | ❌ Cloud |
| **Windsurf** | Large | Medium | ❌ Cloud |
| **Aider** | Varies by model | Varies | Model-dependent |

### Feature Support

| Feature | Copilot | Claude | Cursor | Windsurf | Aider |
|---------|---------|--------|--------|----------|-------|
| **Inline suggestions** | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Chat interface** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Multi-file edits** | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| **Git integration** | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ✅ |
| **Custom models** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **VS Code support** | ✅ | ✅ | N/A | N/A | ✅ |
| **JetBrains support** | ✅ | ⚠️ | N/A | N/A | ✅ |

### Platform Availability

| Tool | IDE/Editor | CLI | Web |
|------|------------|-----|-----|
| **GitHub Copilot** | VS Code, JetBrains, Vim, etc. | ❌ | ❌ |
| **Claude Code** | VS Code, JetBrains | ✅ | ✅ |
| **Cursor** | Cursor (dedicated IDE) | ❌ | ❌ |
| **Windsurf** | Windsurf (dedicated IDE) | ❌ | ❌ |
| **Aider** | Any (via terminal) | ✅ | ❌ |

### Pricing Models

| Tool | Free Tier | Paid | Enterprise |
|------|-----------|------|------------|
| **GitHub Copilot** | Limited | $10/mo | ✅ |
| **Claude Code** | Limited | Usage-based | ✅ |
| **Cursor** | Limited | $20/mo | ⚠️ |
| **Windsurf** | Limited | $15/mo | ⚠️ |
| **Aider** | Open source | BYOK | N/A |

*BYOK = Bring Your Own Key (API costs only)*

### Best Use Cases Summary

| Tool | Best For |
|------|----------|
| **GitHub Copilot** | Day-to-day coding, enterprise teams, IDE integration |
| **Claude Code** | Complex reasoning, large codebase analysis, documentation |
| **Cursor** | Rapid prototyping, multi-file refactoring, flexibility |
| **Windsurf** | Flow-based workflows, deep codebase understanding |
| **Aider** | CI/CD pipelines, terminal workflows, git automation |
