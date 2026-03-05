# Tool Configuration Formats

This document describes the actual configuration files created by SDLC Agents installers.

---

## Common Runtime Path

All installers link or copy runtime prompts to:

- `.sdlc-agents/`

This directory contains the executable agent prompt files:

- `.sdlc-agents/planning-agent.md`
- `.sdlc-agents/coding-agent.md`
- `.sdlc-agents/architect-agent.md`
- `.sdlc-agents/codereview-agent.md`
- `.sdlc-agents/retro-agent.md`
- `.sdlc-agents/curator-agent.md`
- `.sdlc-agents/initializer-agent.md`

---

## GitHub Copilot

**Config Location:** `.github/agents/*.agent.md`

**Format:** Markdown with YAML frontmatter

**Generated files:**
- `.github/agents/planning-agent.agent.md`
- `.github/agents/coding-agent.agent.md`
- `.github/agents/architect-agent.agent.md`
- `.github/agents/codereview-agent.agent.md`
- `.github/agents/retro-agent.agent.md`
- `.github/agents/curator-agent.agent.md`
- `.github/agents/initializer-agent.agent.md`

These files reference `.sdlc-agents/<agent>.md` as the source instructions.

---

## Claude Code

**Config Location:** `.claude/agents/*.md`

**Format:** Markdown with YAML frontmatter

**Generated files:**
- `.claude/agents/planning-agent.md`
- `.claude/agents/coding-agent.md`
- `.claude/agents/architect-agent.md`
- `.claude/agents/codereview-agent.md`
- `.claude/agents/retro-agent.md`
- `.claude/agents/curator-agent.md`
- `.claude/agents/initializer-agent.md`

These subagent files reference `.sdlc-agents/<agent>.md`.

---

## Cursor

**Config Location:** `.cursor/rules/sdlc-agents.mdc`

**Format:** MDC (Markdown + YAML frontmatter)

The rule file references `.sdlc-agents/*.md` prompts.

---

## Windsurf

**Config Location:** `.windsurf/rules/sdlc-agents.md`

**Format:** Markdown

The rule file references `.sdlc-agents/*.md` prompts.

---

## Aider

**Config Location:** `.aider.conf.yml`

**Format:** YAML

**Generated `read:` entries:**
- `.sdlc-agents/planning-agent.md`
- `.sdlc-agents/coding-agent.md`
- `.sdlc-agents/architect-agent.md`
- `.sdlc-agents/codereview-agent.md`
- `.sdlc-agents/retro-agent.md`
- `.sdlc-agents/curator-agent.md`
- `.sdlc-agents/initializer-agent.md`

---

## Comparison

| Tool | Tool-Specific Config | Runtime Prompt Source |
|------|----------------------|-----------------------|
| GitHub Copilot | `.github/agents/*.agent.md` | `.sdlc-agents/*.md` |
| Claude Code | `.claude/agents/*.md` | `.sdlc-agents/*.md` |
| Cursor | `.cursor/rules/sdlc-agents.mdc` | `.sdlc-agents/*.md` |
| Windsurf | `.windsurf/rules/sdlc-agents.md` | `.sdlc-agents/*.md` |
| Aider | `.aider.conf.yml` | `.sdlc-agents/*.md` |
