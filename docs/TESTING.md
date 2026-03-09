# Testing and Validation

This document provides a quick checklist for validating SDLC Agents installation.

---

## Quick Validation

After running `./install.sh`, verify:

```bash
# Skill directories exist
ls -la your-project/.github/skills/
ls -la your-project/.claude/skills/
ls -la your-project/.agents/skills/

# Core skill files exist
ls your-project/.github/skills/*/SKILL.md

# Tool-specific config exists (example: GitHub Copilot)
ls your-project/.cursor/rules/sdlc-agents.mdc
```

---

## Prompt Regression Validation

Before merging prompt or harness changes in this repository:

```bash
./evals/run-deterministic-evals.sh
./evals/run-model-evals.sh
```

- Deterministic evals are required and should fail on regressions.
- Model evals are API-backed and non-blocking in v1 (warn-only) and produce report artifacts.

---

## Tool-Specific Checks

| Tool | Expected Config | Validation Command |
|------|-----------------|-------------------|
| GitHub Copilot | `.github/skills/*/SKILL.md` | `ls .github/skills/*/SKILL.md` |
| Claude Code | `.claude/skills/*/SKILL.md` | `ls .claude/skills/*/SKILL.md` |
| Cursor | `.cursor/rules/sdlc-agents.mdc` | `cat .cursor/rules/sdlc-agents.mdc` |
| Windsurf | `.windsurf/rules/sdlc-agents.md` | `cat .windsurf/rules/sdlc-agents.md` |
| Aider | `.aider.conf.yml` | `cat .aider.conf.yml` |

---

## Symlink vs Copy Mode

### Symlink Mode (Default)

```bash
ls -la your-project/.sdlc-agents
# Should show .sdlc-agents -> /path/to/sdlc-agents/agents
```

### Copy Mode (`--copy`)

```bash
ls -la your-project/.sdlc-agents
# Should show a normal directory (not a symlink)

file your-project/.github/skills/planning-agent/SKILL.md
# Should show text file output
```

---

## Skill Checklist

- [ ] `.github/skills/planning-agent/SKILL.md` is readable
- [ ] `.claude/skills/planning-agent/SKILL.md` is readable
- [ ] `.agents/skills/planning-agent/SKILL.md` is readable
- [ ] `.sdlc-agents/` support bundle is present

---

## Common Issues

### `.sdlc-agents/` missing or broken

```bash
./install.sh --ghcp --target ./your-project --copy
```

### Skill directories missing

```bash
# Re-run installer for the target tool
./install.sh --ghcp --target ./your-project
```

---

## Minimal Validation Script

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET=${1:-.}
ERRORS=0

echo "Validating SDLC Agents installation in $TARGET..."

if [ -d "$TARGET/.sdlc-agents" ] || [ -L "$TARGET/.sdlc-agents" ]; then
  echo "✅ .sdlc-agents exists"
else
  echo "❌ .sdlc-agents missing"
  ERRORS=$((ERRORS + 1))
fi

if ls "$TARGET/.github/skills/"*/SKILL.md >/dev/null 2>&1; then
  echo "✅ Skill files present"
else
  echo "❌ No skill files found"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed"
else
  echo "❌ $ERRORS check(s) failed"
fi

exit $ERRORS
```
