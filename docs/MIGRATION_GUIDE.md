# Migration Guide: Template → Generated Scripts

This guide helps projects migrate from the old static template scripts to the new LLM-generated, stack-specific scripts.

## Overview

### What Changed

The SDLC Agents system now generates harness scripts tailored to your project instead of using generic templates.

| Script | Before | After |
|--------|--------|-------|
| `run-quality-gates.sh` | 293-line static template | Generated based on your tools |
| `run-arch-tests.sh` | 133-line static template | Generated based on your arch tools |
| `run-feature.sh` | 87-line static template | Generated based on your test framework |
| `init-project.sh` | 113-line static template | Generated based on your build system |

### Why This Change?

1. **Project-specific scripts** - Each project has different tools configured
2. **No dead code** - Scripts only include commands for tools you actually use
3. **Better maintenance** - Specs are easier to update than templates for every stack
4. **Accurate commands** - LLM analyzes your actual config files

---

## Migration Checklist

### Step 1: Verify You Need to Migrate

Check if your harness scripts are placeholders:

```bash
head -5 agent-context/harness/run-quality-gates.sh
```

If you see `This is a PLACEHOLDER`, migration is required.

If you see working script content with actual commands, you have the old templates. You can:
- **Option A**: Keep using them (they still work)
- **Option B**: Migrate to generated scripts (recommended)

### Step 2: Backup Existing Scripts (Optional)

If you've customized the old templates:

```bash
cp agent-context/harness/run-quality-gates.sh agent-context/harness/run-quality-gates.sh.bak
cp agent-context/harness/run-arch-tests.sh agent-context/harness/run-arch-tests.sh.bak
cp agent-context/harness/run-feature.sh agent-context/harness/run-feature.sh.bak
cp agent-context/harness/init-project.sh agent-context/harness/init-project.sh.bak
```

### Step 3: Run the Initializer Agent

The initializer agent will generate new scripts:

```
@initializer-agent follow the instructions
```

The agent will:
1. Detect your technology stack
2. Analyze your build configuration files
3. Generate stack-appropriate harness scripts
4. Make them executable

### Step 4: Verify Generated Scripts

After the initializer runs:

```bash
# Check scripts were generated (not placeholders)
head -5 agent-context/harness/run-quality-gates.sh

# Test execution
./agent-context/harness/init-project.sh
./agent-context/harness/run-arch-tests.sh
./agent-context/harness/run-quality-gates.sh
```

### Step 5: Merge Custom Changes (If Any)

If you had customizations in the backup files:

1. Compare old vs new scripts
2. Manually port any custom logic
3. Or request the initializer to incorporate specific requirements

---

## Troubleshooting

### Generated Script Missing a Tool

**Symptom**: A tool you use wasn't included in the generated script.

**Cause**: The tool's config file wasn't detected.

**Solution**:
1. Check if the config file exists in the project root
2. Ask the initializer to re-analyze with specific tool mention
3. Manually add the command to the generated script

### Script Fails After Migration

**Symptom**: Script errors that didn't occur with old template.

**Cause**: Generated commands may have slight differences.

**Solution**:
1. Compare with backup script
2. Adjust command flags as needed
3. Report issue for spec improvement

### Want to Keep Old Templates

**Symptom**: Prefer the static templates over generated scripts.

**Solution**:
1. Copy templates from `.sdlc-agents/templates/harness/` before running initializer
2. Or restore from backup
3. Note: Old templates will work but won't be updated

---

## Rollback Instructions

If you need to revert to old templates:

```bash
# Restore from backup
cp agent-context/harness/run-quality-gates.sh.bak agent-context/harness/run-quality-gates.sh
cp agent-context/harness/run-arch-tests.sh.bak agent-context/harness/run-arch-tests.sh
cp agent-context/harness/run-feature.sh.bak agent-context/harness/run-feature.sh
cp agent-context/harness/init-project.sh.bak agent-context/harness/init-project.sh
```

Or get old templates from git history:

```bash
git show HEAD~N:agent-context/harness/run-quality-gates.sh > agent-context/harness/run-quality-gates.sh
```

---

## FAQ

### Q: Do I have to migrate?

**A**: No. If your old scripts work, they'll continue to work. Migration is recommended for:
- New projects
- Projects wanting more accurate tool detection
- Projects with multiple stacks (e.g., frontend + backend)

### Q: What if the initializer generates wrong commands?

**A**: The generated scripts are just files - you can edit them. Report issues so specs can be improved.

### Q: How often should I regenerate scripts?

**A**: When you:
- Add new tools (linters, test frameworks, etc.)
- Change build systems
- Significantly restructure the project

---

## Related Documentation

- [Harness Specification](../agents/skills/harness-spec.md) - Output contract for generated scripts
- [Stack Detection](../agents/skills/stack-detection.md) - How stacks are detected
- [Stack Commands](../agents/skills/stacks/) - Stack-specific commands (java.md, python.md, etc.)
- [Initializer Agent](../agents/initializer-agent.md) - Generates project-specific scripts
