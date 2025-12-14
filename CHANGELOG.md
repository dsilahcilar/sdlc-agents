# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Changed

- **Renamed `.agents/` to `.sdlc-agents/`**: More specific directory name to avoid conflicts with other tools that might use the generic `.agents` directory name. All install scripts, agent files, and documentation updated to use `.sdlc-agents/` consistently.

### Added

- **GitHub Copilot Agent Support**: Proper support for custom agents in GitHub Copilot
  - Creates `.github/agents/*.agent.md` files for each agent
  - Each agent file has YAML frontmatter for GitHub Copilot discovery
  - Agents are accessible via VS Code UI agent picker
  - Automatic `.gitignore` update to exclude `.sdlc-agents/` directory
- **Multi-Assistant Support**: SDLC Agents now works with 5 AI coding assistants
  - GitHub Copilot
  - Claude Code
  - Cursor  
  - Windsurf
  - Aider
- **Unified Install Script**: Single `./install.sh` with tool selection flags
  - `--ghcp`, `--claude`, `--cursor`, `--windsurf`, `--aider`
  - `--all` to install for all tools
  - `--copy` mode for Windows compatibility
- **Tool-Specific Adapters**: Each tool gets its own configuration
  - Tool configs in `tools/<tool>/`
  - Shared agent instructions in `agents/`
- **Multi-Assistant Documentation**: New `docs/MULTI_ASSISTANT_SUPPORT.md`
  - Tool selection guide
  - Multi-tool usage patterns
  - Tool-specific troubleshooting

### Changed

- **GitHub Copilot installation structure**: 
  - Now creates `.github/agents/` directory with individual `.agent.md` files
  - Uses `.sdlc-agents/` (hidden directory) instead of `agents/` for symlink
  - Automatically updates `.gitignore` to exclude `.sdlc-agents/`
  - Removed `copilot-instructions.md` (not needed)
- **Agent files are now tool-agnostic**: Removed YAML frontmatter from all `agents/*.md` files
- **Updated documentation**: `AGENT_ARCHITECTURE.md` and `COMPARISON_WITH_SPEC_KIT.md` updated to reflect multi-tool support
- **Simplified agent path handling**: 
  - All agent files now use hardcoded `.sdlc-agents/` path instead of dynamic `find` command
  - Replaced complex `SDLC_AGENTS=$(dirname "$(find . -name "initializer-agent.md" ...)")` with simple `SDLC_AGENTS=".sdlc-agents"`
  - Updated all `$SDLC_AGENTS` references in agent files to use `.sdlc-agents/` directly
  - More reliable and faster path resolution across all providers

### Migration Guide

If you were using SDLC Agents with GitHub Copilot before:

1. **Re-run the installer** to get the new `.github/agents/` structure:
   ```bash
   ./install.sh --ghcp --target /path/to/your/project
   ```

2. **Your existing content is preserved** — the installer only updates configuration files

3. **New usage**: In VS Code, open GitHub Copilot Chat and use the agent picker:
   - Click the **@ icon** in the chat input
   - Select an agent from the dropdown (e.g., planning-agent, coding-agent)
   - Type your request

4. **Clean up old structure** (optional):
   - Remove old `agents/` symlink if it exists: `rm agents`
   - The new `.sdlc-agents/` directory is hidden and excluded from git

5. **Optional**: Install support for additional tools with `--all` or specific tool flags

---

## [1.0.0] - 2024-12-08

### Added

- Initial release with 7 specialized agents
- GitHub Copilot support
- Skills system with stack detection
- Extension system for customization
- Learning playbook and curator workflow
