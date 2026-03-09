# Tool Configuration Formats

This document describes the actual configuration files created by SDLC Agents installers.

---

## Common Skill Paths

Project-local installers install the canonical role skills into all of these directories:

- `.github/skills/`
- `.claude/skills/`
- `.agents/skills/`

Each role skill is a folder with at least:

- `SKILL.md`
- `agents/openai.yaml`

## Common Support Bundle

Project-local installers also link or copy:

- `.sdlc-agents/`

This support bundle contains templates, harness tooling, guardrails, and capability skills.

---

## GitHub Copilot

**Primary Skill Location:** `.github/skills/<skill-name>/SKILL.md`

**Mirrors also installed:**
- `.claude/skills/<skill-name>/SKILL.md`
- `.agents/skills/<skill-name>/SKILL.md`

---

## Claude Code

**Primary Skill Location:** `.claude/skills/<skill-name>/SKILL.md`

**Mirrors also installed:**
- `.github/skills/<skill-name>/SKILL.md`
- `.agents/skills/<skill-name>/SKILL.md`

---

## Cursor

**Config Location:** `.cursor/rules/sdlc-agents.mdc`

**Format:** MDC (Markdown + YAML frontmatter)

The rule file references `.agents/skills/*/SKILL.md`.

---

## Windsurf

**Config Location:** `.windsurf/rules/sdlc-agents.md`

**Format:** Markdown

The rule file references `.agents/skills/*/SKILL.md`.

---

## Aider

**Config Location:** `.aider.conf.yml`

**Format:** YAML

**Generated `read:` entries:**
- `.agents/skills/planning-agent/SKILL.md`
- `.agents/skills/coding-agent/SKILL.md`
- `.agents/skills/architect-agent/SKILL.md`
- `.agents/skills/codereview-agent/SKILL.md`
- `.agents/skills/retro-agent/SKILL.md`
- `.agents/skills/curator-agent/SKILL.md`
- `.agents/skills/initializer-agent/SKILL.md`

---

## Codex

**Install Locations:**
- `<codex-home>/<skill-name>/SKILL.md`
- `<project-root>/.sdlc-agents/`

The Codex installer copies the canonical role skills into the configured Codex skills home and provisions the project support bundle in the target repository.

---

## Comparison

| Tool | Primary Skill Location | Extra Config |
|------|------------------------|-------------|
| GitHub Copilot | `.github/skills/` | `.sdlc-agents/` support bundle |
| Claude Code | `.claude/skills/` | `.sdlc-agents/` support bundle |
| Cursor | `.agents/skills/` | `.cursor/rules/sdlc-agents.mdc` |
| Windsurf | `.agents/skills/` | `.windsurf/rules/sdlc-agents.md` |
| Aider | `.agents/skills/` | `.aider.conf.yml` |
| Codex | `<codex-home>/` | `.sdlc-agents/` support bundle in target project |
