# GitHub Copilot Agent Support

This document explains how SDLC Agents implements custom agent support for GitHub Copilot.

## Overview

GitHub Copilot supports custom agents through a specific directory structure:
- **Location**: `.github/agents/`
- **File format**: `<agent-name>.agent.md`
- **Content**: YAML frontmatter + Markdown instructions
- **Usage**: Via VS Code UI agent picker (not `@syntax`)

## Why This Matters

### The Correct Approach
The installation creates individual `.agent.md` files in `.github/agents/`, which GitHub Copilot recognizes as custom agents. These agents are then accessible via the **UI agent picker** in VS Code.

### Important Note
GitHub Copilot custom agents are **not** invoked using `@agent-name` syntax in the chat. Instead, users select agents from a dropdown UI picker.

## File Structure

```
your-project/
├── .github/
│   └── agents/                          # Individual agent definitions
│       ├── planning-agent.agent.md
│       ├── coding-agent.agent.md
│       ├── architect-agent.agent.md
│       ├── codereview-agent.agent.md
│       ├── retro-agent.agent.md
│       ├── curator-agent.agent.md
│       └── initializer-agent.agent.md
├── .agents/                              # ← Hidden: Full agent instructions (symlinked)
│   ├── planning-agent.md
│   ├── coding-agent.md
│   └── ...
└── .gitignore                            # ← Updated to exclude .agents/
```

## Agent File Format

Each `.agent.md` file follows this structure:

```markdown
---
name: planning-agent
description: Transforms requests into structured, architecture-aware plans with isolated tasks
---

# Planning Agent

This agent is part of the SDLC Agents system for structured, architecture-aware development.

## Instructions

The complete instructions for this agent are located in:
`.agents/planning-agent.md`

Please read and follow those instructions carefully.

## Agent Context

This agent operates within the SDLC Agents workflow:
- **Input**: Receives context from previous agents or user requests
- **Process**: Follows the workflow defined in `.agents/planning-agent.md`
- **Output**: Produces artifacts for downstream agents or final deliverables

## Extensions

Check for project-specific customizations:
1. **Global rules**: `agent-context/extensions/_all-agents/*.md`
2. **Agent-specific**: `agent-context/extensions/planning-agent/*.md`

Custom instructions take precedence over core behavior.
```

## How It Works

1. **GitHub Copilot scans** `.github/agents/` directory on startup
2. **Discovers** all `.agent.md` files
3. **Parses** YAML frontmatter to get agent name and description
4. **Registers** each agent in the UI agent picker
5. **Loads** the full markdown content when the agent is selected
6. **References** the detailed instructions in `.agents/<agent-name>.md`

## Usage in VS Code

### Step-by-Step

1. **Open GitHub Copilot Chat** panel in VS Code
2. **Click the agent picker** (@ icon in the chat input field)
3. **Select an agent** from the dropdown menu
4. **Type your request** in the chat

### Example Workflow

```
1. Select: initializer-agent
   Type: "Set up project structure"

2. Select: planning-agent
   Type: "Create a feature for user authentication"

3. Select: architect-agent
   Type: "Review the feature plan in agent-context/features/FEAT-001/feature.md"

4. Select: coding-agent
   Type: "Implement task T01 from FEAT-001"

5. Select: codereview-agent
   Type: "Review my changes before creating a PR"

6. Select: retro-agent
   Type: "Extract lessons from completing this feature"
```

## Installation

### New Projects

```bash
./install.sh --ghcp --target /path/to/your/project
```

This creates:
- `.github/agents/*.agent.md` (7 agent files)
- `.agents/` symlink to sdlc-agents/agents (hidden directory)
- Updates `.gitignore` to exclude `.agents/`

### Existing Projects (Migration)

If you previously installed SDLC Agents, re-run the installer:

```bash
./install.sh --ghcp --target /path/to/your/project
```

The installer will:
- ✅ Create `.github/agents/` directory
- ✅ Create individual `.agent.md` files
- ✅ Create `.agents/` symlink (hidden)
- ✅ Update `.gitignore` to exclude `.agents/`
- ✅ Preserve your existing `agent-context/` directory

### Clean Up Old Installation

If you have an old `agents/` directory (not hidden):

```bash
# Remove old symlink
rm agents

# The new .agents/ directory is hidden and git-ignored
ls -la .agents/  # Verify it exists
```

## Technical Details

### YAML Frontmatter Properties

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Unique identifier for the agent (shown in UI picker) |
| `description` | Yes | Brief description of the agent's purpose (shown in UI) |
| `prompt` | No | Additional custom instructions (we use markdown body instead) |
| `tools` | No | Specific tools the agent can access (defaults to all) |
| `infer` | No | Whether Copilot can auto-invoke this agent (defaults to true) |

### Why We Use `.agents/` (Hidden Directory)

1. **Cleaner project root**: Hidden directory doesn't clutter the file explorer
2. **Git-friendly**: Automatically excluded via `.gitignore`
3. **Clear separation**: User code vs. agent configuration
4. **Symlink best practice**: Hidden directories for external dependencies

### Why We Use References

Instead of duplicating the full agent instructions in each `.agent.md` file, we:
1. **Keep the source of truth** in `.agents/<agent-name>.md`
2. **Reference it** from `.github/agents/<agent-name>.agent.md`
3. **Benefits**:
   - Single source of truth for agent instructions
   - Tool-agnostic agent definitions
   - Easier maintenance and updates
   - Consistent across all supported tools

## Troubleshooting

### Agents Not Discovered

**Symptoms**: Agent picker doesn't show custom agents

**Solutions**:
1. Verify `.github/agents/*.agent.md` files exist
2. Check YAML frontmatter is valid (no syntax errors)
3. Restart VS Code
4. Check GitHub Copilot extension is enabled and up to date

### Agent Not Loading Instructions

**Symptoms**: Agent responds but doesn't follow SDLC workflow

**Solutions**:
1. Verify `.agents/` symlink is valid: `ls -la .agents/`
2. Check that `.agents/<agent-name>.md` exists
3. Ensure the reference path in `.agent.md` is correct (`.agents/` not `agents/`)

### Symlink Issues (Windows)

**Symptoms**: `.agents/` directory not accessible

**Solutions**:
Use copy mode instead of symlink:
```bash
./install.sh --ghcp --target /path/to/your/project --copy
```

### .gitignore Not Updated

**Symptoms**: `.agents/` directory appears in git status

**Solutions**:
Manually add to `.gitignore`:
```bash
echo "" >> .gitignore
echo "# SDLC Agents (symlinked directory)" >> .gitignore
echo ".agents/" >> .gitignore
```

## References

- [GitHub Copilot Custom Agents Documentation](https://docs.github.com/en/copilot/customizing-copilot/creating-custom-agents)
- [SDLC Agents Multi-Assistant Support](./MULTI_ASSISTANT_SUPPORT.md)
- [GitHub Copilot Tool README](../tools/github-copilot/README.md)

## Changelog

- **2024-12-14**: 
  - Implemented proper custom agent support with `.github/agents/` directory structure
  - Changed to `.agents/` (hidden directory) for agent instructions
  - Added automatic `.gitignore` updates
  - Removed `copilot-instructions.md` (not needed)
  - Clarified that agents are selected via UI picker, not `@syntax`
