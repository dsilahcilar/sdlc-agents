# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

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

- **Agent files are now tool-agnostic**: Removed YAML frontmatter from all `agents/*.md` files
- **Updated documentation**: `AGENT_ARCHITECTURE.md` and `COMPARISON_WITH_SPEC_KIT.md` updated to reflect multi-tool support

### Migration Guide

If you were using SDLC Agents with GitHub Copilot before:

1. **Re-run the installer:**
   ```bash
   ./install.sh --ghcp --target /path/to/your/project
   ```

2. **Your existing `agents/` content is preserved** — the installer only updates configuration files

3. **Optional**: Install support for additional tools with `--all` or specific tool flags

---

## [1.0.0] - 2024-12-08

### Added

- Initial release with 7 specialized agents
- GitHub Copilot support
- Skills system with stack detection
- Extension system for customization
- Learning playbook and curator workflow
