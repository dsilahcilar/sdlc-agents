# Tool Configuration Formats

This document describes the configuration formats for each AI coding assistant supported by SDLC Agents.

---

## GitHub Copilot

**Config Location:** `.github/copilot-instructions.md`

**Format:** Markdown with optional YAML frontmatter

**Example:**
```markdown
---
description: Project coding conventions
---
# Project Guidelines

- Follow TypeScript best practices
- Use functional components
- Prefer named exports
```

**Agents Location:** `.github/copilot-agents/*.md` (each agent is a separate file)

**References:**
- [GitHub Docs: Custom Instructions](https://docs.github.com/en/copilot/customizing-copilot)

---

## Claude Code

**Config Location:**
- `CLAUDE.md` (project root) — instructions
- `.claude/settings.local.json` — permissions and settings

**Format:** Plain Markdown for instructions, JSON for settings

**Example CLAUDE.md:**
```markdown
# Project Context

This project uses the SDLC Agents framework for structured development.

## Agents
See the `agents/` directory for specialized agent instructions:
- `agents/planning-agent.md` — Creates structured plans
- `agents/coding-agent.md` — Implements code changes
```

**Example settings.local.json:**
```json
{
  "permissions": {
    "allow": ["Bash(tree:*)"],
    "deny": []
  }
}
```

**References:**
- [Claude Code Configuration](https://docs.anthropic.com/claude/docs/claude-code)

---

## Cursor

**Config Location:** `.cursor/rules/*.mdc`

**Format:** MDC (Markdown with YAML frontmatter containing globs and metadata)

**Example:**
```markdown
---
description: SDLC Agents integration
globs: ["**/*"]
alwaysApply: true
---
# SDLC Agents

Use the agents in the `agents/` directory:
- @planning-agent.md for creating structured plans
- @coding-agent.md for implementing code
```

**Key Fields:**
- `description` — Rule purpose
- `globs` — File patterns to apply to
- `alwaysApply` — Whether to auto-include in context

**References:**
- [Cursor Rules Documentation](https://cursor.com/docs/rules)

---

## Windsurf

**Config Location:** `.windsurf/rules/*.md`

**Format:** Plain Markdown

**Example:**
```markdown
# SDLC Agents

This project uses structured SDLC agents for development workflow.

## Available Agents
- Planning Agent: `agents/planning-agent.md`
- Coding Agent: `agents/coding-agent.md`
- Architect Agent: `agents/architect-agent.md`
```

**References:**
- [Windsurf Configuration](https://docs.codeium.com/windsurf)

---

## Aider

**Config Location:** `.aider.conf.yml`

**Format:** YAML

**Example:**
```yaml
# SDLC Agents context files
read:
  - agents/planning-agent.md
  - agents/coding-agent.md
  - agents/architect-agent.md
  - agents/codereview-agent.md
```

**Key Fields:**
- `read` — List of files to include as context

**References:**
- [Aider Configuration](https://aider.chat/docs/config.html)

---

## Configuration Comparison

| Feature | Copilot | Claude | Cursor | Windsurf | Aider |
|---------|---------|--------|--------|----------|-------|
| Format | Markdown | Markdown | MDC | Markdown | YAML |
| Frontmatter | Optional | No | Required | No | N/A |
| File Patterns | No | No | Yes | No | No |
| Include Files | No | No | Yes (@file) | No | Yes (read:) |
| JSON Config | No | Yes | No | No | No |
