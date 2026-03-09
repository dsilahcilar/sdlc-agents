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
| [Codex](#codex) | ✅ Full | `./install.sh --codex --codex-home ~/.codex/skills --target ./your-project` |

## Quick Start

```bash
# Clone sdlc-agents
git clone https://github.com/dsilahcilar/sdlc-agents.git
cd sdlc-agents

# Install for your tool (replace --ghcp with your tool)
./install.sh --ghcp --target /path/to/your/project

# Or install for multiple tools at once
./install.sh --ghcp --claude --target /path/to/your/project

# Or install for all project-local tools
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
1. Installs the canonical role skills into `.github/skills/`, `.claude/skills/`, and `.agents/skills/`
2. Links (or copies) the `agents/` directory into your project as `.sdlc-agents/` support assets
3. Creates any tool-specific rules or config needed by the selected tool

## Tool-Specific Setup

### GitHub Copilot

**Creates:**
- `.github/skills/*/SKILL.md`
- `.claude/skills/*/SKILL.md`
- `.agents/skills/*/SKILL.md`
- `.sdlc-agents/` → symlink or copy of support assets

**Usage:**
Open GitHub Copilot Chat and use the installed SDLC skills:
- Use **initializer-agent** to bootstrap a project
- Use **planning-agent** to create feature plans
- Use **coding-agent** to execute an approved task

See [tools/github-copilot/README.md](../tools/github-copilot/README.md)


---

### Claude Code

**Creates:**
- `.claude/skills/*/SKILL.md`
- `.github/skills/*/SKILL.md`
- `.agents/skills/*/SKILL.md`
- `.sdlc-agents/` → symlink or copy of support assets

**Usage:**
Use the installed SDLC skills:
```
Use the initializer-agent skill to bootstrap this project
Use the planning-agent skill to create a plan for user authentication
Use the coding-agent skill to implement task T01
Use the codereview-agent skill to review my changes
```

See [tools/claude/README.md](../tools/claude/README.md)

---

### Cursor

**Creates:**
- `.cursor/rules/sdlc-agents.mdc`
- `.agents/skills/*/SKILL.md`
- `.sdlc-agents/` → symlink or copy of support assets

**Usage:**
```
@.agents/skills/planning-agent/SKILL.md Create a feature for user authentication
```

See [tools/cursor/README.md](../tools/cursor/README.md)

---

### Windsurf

**Creates:**
- `.windsurf/rules/sdlc-agents.md`
- `.agents/skills/*/SKILL.md`
- `.sdlc-agents/` → symlink or copy of support assets

**Usage:**
```
Use .agents/skills/planning-agent/SKILL.md to create a feature plan
```

See [tools/windsurf/README.md](../tools/windsurf/README.md)

---

### Aider

**Creates:**
- `.aider.conf.yml`
- `.agents/skills/*/SKILL.md`
- `.sdlc-agents/` → symlink or copy of support assets

**Usage:**
```
Use the planning-agent skill to create a feature plan
```

See [tools/aider/README.md](../tools/aider/README.md)

---

### Codex

**Creates:**
- `<codex-home>/*/SKILL.md`
- `.sdlc-agents/` in the target project

**Usage:**
Install the SDLC role skills into your Codex skill home and the support bundle into the target project:
```bash
./install.sh --codex --codex-home ~/.codex/skills --target ./your-project
```

See [tools/codex/README.md](../tools/codex/README.md)

---

## Install Options

```bash
# Symlink mode (default) - agents stay in sync with sdlc-agents updates
./install.sh --ghcp --target ./your-project

# Copy mode - agents are copied (works better on Windows, self-contained)
./install.sh --ghcp --target ./your-project --copy
```

## Updating

If you used **symlink mode**, updates to `.sdlc-agents/` flow through automatically after `git pull`, but you should still re-run the installer when the skill directory layout changes.

If you used **copy mode**, re-run the install to refresh both the skill directories and the support bundle:
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

You can install SDLC Agents for multiple project-local tools on the same project:

```bash
# Install all tools at once
./install.sh --all --target ./your-project

# Or pick specific tools
./install.sh --ghcp --claude --target ./your-project
```

### How Multi-Tool Works

- **Shared support bundle**: Project installers reuse the same `.sdlc-agents/` assets
- **Shared skill catalog**: Project installers mirror role skills into `.github/skills/`, `.claude/skills/`, and `.agents/skills/`
- **Separate configs**: Cursor, Windsurf, and Aider still get their own config files
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

Ensure the `.sdlc-agents/` symlink is valid:
```bash
ls -la ./your-project/.sdlc-agents/
```

### Multiple tools conflict

Installing multiple tools is safe—each creates its own configuration files without conflict.

---

## Tool-Specific Issues

### GitHub Copilot

**Skills not discovered:**
- Ensure `.github/skills/*/SKILL.md` files exist
- Verify `.sdlc-agents/` directory symlink is valid: `ls -la .sdlc-agents/`
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
