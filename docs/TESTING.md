# Testing and Validation

This document provides a quick checklist for validating SDLC Agents installation.

---

## Quick Validation

After running `./install.sh`, verify:

```bash
# Runtime prompt directory exists
ls -la your-project/.sdlc-agents/

# Core prompt files exist
ls your-project/.sdlc-agents/*-agent.md

# Tool-specific config exists (example: GitHub Copilot)
ls your-project/.github/agents/*.agent.md
```

---

## Prompt Regression Validation

Before merging prompt or harness changes in this repository:

```bash
./evals/run-deterministic-evals.sh
./evals/run-model-evals.sh
```

- Deterministic evals are required and should fail on regressions.
- Model evals are scaffolded/non-blocking in v1 and produce report artifacts.

---

## Tool-Specific Checks

| Tool | Expected Config | Validation Command |
|------|-----------------|-------------------|
| GitHub Copilot | `.github/agents/*.agent.md` | `ls .github/agents/*.agent.md` |
| Claude Code | `.claude/agents/*.md` | `ls .claude/agents/*.md` |
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

file your-project/.sdlc-agents/planning-agent.md
# Should show text file output
```

---

## Runtime Prompt Checklist

- [ ] `.sdlc-agents/planning-agent.md` is readable
- [ ] `.sdlc-agents/architect-agent.md` is readable
- [ ] `.sdlc-agents/coding-agent.md` is readable
- [ ] `.sdlc-agents/codereview-agent.md` is readable
- [ ] `.sdlc-agents/retro-agent.md` is readable
- [ ] `.sdlc-agents/curator-agent.md` is readable
- [ ] `.sdlc-agents/initializer-agent.md` is readable

---

## Common Issues

### `.sdlc-agents/` missing or broken

```bash
./install.sh --ghcp --target ./your-project --copy
```

### Tool config not created

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

if ls "$TARGET/.sdlc-agents/"*-agent.md >/dev/null 2>&1; then
  echo "✅ Runtime prompt files present"
else
  echo "❌ No runtime prompt files found"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed"
else
  echo "❌ $ERRORS check(s) failed"
fi

exit $ERRORS
```
