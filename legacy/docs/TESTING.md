# Testing and Validation

This document provides checklists for validating SDLC Agents installation and functionality.

---

## Install Script Validation

### Quick Validation

After running `./install.sh`, verify these items:

```bash
# 1. Check agents/ exists and is accessible
ls -la your-project/agents/

# 2. Verify agent files are present
ls your-project/agents/*.md

# 3. Check tool-specific config was created (example: GitHub Copilot)
cat your-project/.github/copilot-instructions.md
```

### Tool-Specific Checks

| Tool | Config File | Validation Command |
|------|-------------|-------------------|
| GitHub Copilot | `.github/copilot-instructions.md` | `cat .github/copilot-instructions.md` |
| Claude | `CLAUDE.md`, `.claude/settings.local.json` | `cat CLAUDE.md` |
| Cursor | `.cursor/rules/sdlc-agents.mdc` | `cat .cursor/rules/sdlc-agents.mdc` |
| Windsurf | `.windsurf/rules/sdlc-agents.md` | `cat .windsurf/rules/sdlc-agents.md` |
| Aider | `.aider.conf.yml` | `cat .aider.conf.yml` |

---

## Symlink vs Copy Mode Validation

### Symlink Mode (Default)

```bash
# Should show symlink pointing to sdlc-agents/agents
ls -la your-project/agents
# Output should include: agents -> /path/to/sdlc-agents/agents
```

### Copy Mode (`--copy`)

```bash
# Should show directory, not symlink
ls -la your-project/agents
# Output should show: drwxr-xr-x ... agents

# Verify files are actual copies
file your-project/agents/planning-agent.md
# Output: ASCII text
```

---

## Agent Functionality Checklist

### Planning Agent

- [ ] Can read `agents/planning-agent.md`
- [ ] Creates feature files in `agent-context/features/`
- [ ] Generates task breakdown in `tasks/` subdirectory
- [ ] Includes technology stack section

### Architect Agent

- [ ] Can read `agents/architect-agent.md`
- [ ] Reviews feature.md files
- [ ] References architecture tests if present
- [ ] Provides approval/rejection with rationale

### Coding Agent

- [ ] Can read `agents/coding-agent.md`
- [ ] Follows task files for implementation
- [ ] Updates progress log
- [ ] Runs architecture tests after changes

### Code Review Agent

- [ ] Can read `agents/codereview-agent.md`
- [ ] Identifies debt patterns
- [ ] Checks against guardrails
- [ ] Provides structured feedback

### Retro Agent

- [ ] Can read `agents/retro-agent.md`
- [ ] Extracts lessons from completed work
- [ ] Updates learning playbook

---

## Common Issues

### Symlink Not Working

**Symptom**: `agents/` shows as broken link or doesn't exist

**Fix**:
```bash
# Re-run with copy mode
./install.sh --ghcp --target ./your-project --copy
```

### Permission Denied

**Symptom**: Can't read agent files

**Fix**:
```bash
chmod -R 644 your-project/agents/*.md
```

### Config File Not Created

**Symptom**: Tool doesn't recognize SDLC Agents

**Fix**:
```bash
# Re-run installer for that tool
./install.sh --ghcp --target ./your-project
```

---

## Full Validation Script

```bash
#!/bin/bash
# validate-install.sh

TARGET=${1:-.}
ERRORS=0

echo "Validating SDLC Agents installation in $TARGET..."

# Check agents directory
if [ -d "$TARGET/agents" ] || [ -L "$TARGET/agents" ]; then
    echo "✅ agents/ directory exists"
else
    echo "❌ agents/ directory missing"
    ((ERRORS++))
fi

# Check for at least one agent file
if ls "$TARGET/agents/"*.md 1> /dev/null 2>&1; then
    echo "✅ Agent files present"
else
    echo "❌ No agent .md files found"
    ((ERRORS++))
fi

# Summary
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed"
else
    echo "❌ $ERRORS check(s) failed"
fi

exit $ERRORS
```
