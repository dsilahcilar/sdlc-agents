# Pre-Commit Checklist

**Before committing the template → generated scripts refactoring**

---

## 🔴 CRITICAL (Must Fix)

### 1. Fix Broken File References

```bash
# Find all broken references
grep -r "quality-gate-spec\|arch-test-spec\|feature-runner-spec\|init-project-spec" \
  agents/templates/harness/ docs/ --include="*.sh" --include="*.md"
```

**Fix in:**
- [ ] `agents/templates/harness/run-quality-gates.sh:8`
- [ ] `agents/templates/harness/run-arch-tests.sh` (if exists)
- [ ] `agents/templates/harness/run-feature.sh` (if exists)
- [ ] `agents/templates/harness/init-project.sh` (if exists)
- [ ] Any other template files

**Change:**
```diff
- # See: $SDLC_AGENTS/skills/quality-gate-spec.md
+ # See: $SDLC_AGENTS/skills/harness-spec.md
```

### 2. Fix MIGRATION_GUIDE.md

- [ ] Update lines 171-173 in `docs/MIGRATION_GUIDE.md`

**Change:**
```diff
- - [Quality Gate Specification](../agents/skills/quality-gate-spec.md)
- - [Architecture Test Specification](../agents/skills/arch-test-spec.md)
- - [Feature Runner Specification](../agents/skills/feature-runner-spec.md)
- - [Project Init Specification](../agents/skills/init-project-spec.md)
+ - [Harness Specification](../agents/skills/harness-spec.md)
+ - [Stack Detection](../agents/skills/stack-detection.md)
```

---

## 🟡 HIGH PRIORITY (Should Fix)

### 3. Create CHANGELOG Entry

- [ ] Create or update `CHANGELOG.md` with:
  - Breaking changes section
  - New features (Kotlin, skill directives)
  - Migration instructions link
  - Code reduction metrics

### 4. Verify Template Placeholders

- [ ] Check all templates fail gracefully with helpful error messages
- [ ] Ensure error messages reference correct documentation

```bash
# Test each template
./agents/templates/harness/run-quality-gates.sh
./agents/templates/harness/run-arch-tests.sh
./agents/templates/harness/run-feature.sh
./agents/templates/harness/init-project.sh

# Should all exit with code 1 and clear error message
```

---

## ⚠️ MEDIUM PRIORITY (Recommended)

### 5. Test Initializer Agent (Sample)

Test at least 3 different stacks:

- [ ] Java (Maven) - `pom.xml`
- [ ] TypeScript - `package.json`
- [ ] Python - `pyproject.toml`

**Verify:**
- Scripts are generated (not placeholders)
- Scripts are executable (`chmod +x`)
- Commands match stack specification
- Scripts fail gracefully if tools not installed

### 6. Review Cross-References

- [ ] Check `agents/initializer-agent.md` references are valid
- [ ] Check `agents/skills/stack-detection.md` paths correct
- [ ] Verify `docs/skills/SKILL_DIRECTIVE_WORKFLOW.md` references exist

---

## 📝 DOCUMENTATION

### 7. Educational Content Decision

Choose one:

- [ ] **Option A:** Extract old content to `docs/guides/`
- [ ] **Option B:** Add external resource links to stack files
- [ ] **Option C:** Accept minimal specs (document decision)

### 8. Update README (if needed)

- [ ] Check if README mentions stack file format
- [ ] Update if it references old template approach
- [ ] Add note about Kotlin support

---

## ✅ FINAL VERIFICATION

Before committing, run:

```bash
# 1. Check for broken references
echo "=== Checking for broken spec references ==="
grep -r "quality-gate-spec\|arch-test-spec\|feature-runner-spec\|init-project-spec" \
  agents/ docs/ --include="*.md" --include="*.sh" && \
  echo "❌ Found broken references" || \
  echo "✅ No broken references"

# 2. Verify harness-spec.md exists
echo "=== Verifying harness-spec.md exists ==="
[ -f "agents/skills/harness-spec.md" ] && \
  echo "✅ harness-spec.md exists" || \
  echo "❌ harness-spec.md missing"

# 3. Check Kotlin stack file
echo "=== Verifying Kotlin stack file ==="
[ -f "agents/skills/stacks/kotlin.md" ] && \
  echo "✅ kotlin.md exists" || \
  echo "❌ kotlin.md missing"

# 4. Verify skill directive scripts
echo "=== Verifying skill directive scripts ==="
[ -f "agents/tools/skills/parse-skill-directives.sh" ] && \
  echo "✅ parse-skill-directives.sh exists" || \
  echo "❌ parse-skill-directives.sh missing"
[ -f "agents/tools/skills/resolve-skills.sh" ] && \
  echo "✅ resolve-skills.sh exists" || \
  echo "❌ resolve-skills.sh missing"

# 5. Check MIGRATION_GUIDE
echo "=== Verifying MIGRATION_GUIDE ==="
[ -f "docs/MIGRATION_GUIDE.md" ] && \
  echo "✅ MIGRATION_GUIDE.md exists" || \
  echo "❌ MIGRATION_GUIDE.md missing"

# 6. Verify all stack files exist
echo "=== Verifying all stack files ==="
for stack in dotnet go java kotlin php python ruby rust typescript; do
  [ -f "agents/skills/stacks/${stack}.md" ] && \
    echo "  ✅ ${stack}.md exists" || \
    echo "  ❌ ${stack}.md missing"
done

echo ""
echo "=== Summary ==="
echo "Run the checklist items above, then run this script again."
echo "When all checks pass, you're ready to commit."
```

---

## 📋 COMMIT MESSAGE TEMPLATE

When ready to commit:

```
refactor: transform stack files from docs to specs, add Kotlin support

BREAKING CHANGE: Stack files and harness templates refactored for LLM generation

Stack files in agents/skills/stacks/ simplified from verbose documentation
to concise command specifications. Harness templates are now placeholders
requiring initializer agent generation.

New features:
- Kotlin stack support with Gradle/Maven detection
- Skill directive syntax (#SkillName, !ExcludeName, #only:List)
- Harness specification defining output contract

Breaking changes:
- Stack files reduced ~55% (removed setup guides, examples)
- Harness templates are placeholders (must run initializer)
- Kotlin projects now detected separately from Java

See docs/MIGRATION_GUIDE.md for migration instructions.

Files changed: 18 files, +741/-1883 lines
```

---

## 🎯 QUICK STATUS

Check off as completed:

**Critical:**
- [ ] Fixed template file references
- [ ] Fixed MIGRATION_GUIDE.md references

**High Priority:**
- [ ] Created/updated CHANGELOG.md
- [ ] Verified templates fail gracefully

**Medium Priority:**
- [ ] Tested initializer on 3+ stacks
- [ ] Reviewed cross-references

**Documentation:**
- [ ] Decided on educational content
- [ ] Updated README if needed

**Final:**
- [ ] Ran verification script above
- [ ] All checks passed
- [ ] Ready to commit

---

## 🚀 AFTER COMMIT

Don't forget:

- [ ] Tag release if using semantic versioning
- [ ] Update external documentation
- [ ] Notify users of breaking changes
- [ ] Monitor for issues in first few days
- [ ] Create follow-up tasks for P3 items
