---
id: T01
feature: INFRA-001
title: Add skill directive support and LLM-generated harness scripts
status: in_progress
priority: 1
module: agents/
estimated_complexity: high
skill_reference: N/A (meta-work on SDLC agents system)
---

# Task: Add skill directive support and LLM-generated harness scripts

## Objective

Enable all agents to parse skill directives from user prompts (supporting both planning-first and direct invocation workflows), and transition from static template scripts to LLM-generated, stack-specific harness scripts based on project configuration analysis.

## What Was Done

1. ✅ Added "Skill Directives" sections to all downstream agents:
   - `agents/architect-agent.md:44-66`
   - `agents/codereview-agent.md:43-65`
   - `agents/coding-agent.md:55-77`
   - Documents directive syntax (`#SkillName`, `!SkillName`, `#only:Skills`)
   - Shows how to parse and resolve skills with `--agent <role>` flag

2. ✅ Enhanced skill directive workflow documentation:
   - `docs/skills/SKILL_DIRECTIVE_WORKFLOW.md`
   - Added Pattern 2: Direct Agent Invocation
   - Documented dual workflow support (planning-first vs direct)
   - Updated Phase 5 with Option A (from feature files) and Option B (direct loading)
   - Revised key principles to emphasize flexibility

3. ✅ Updated Initializer Agent workflow:
   - `agents/initializer-agent.md:34-54`
   - Changed from "Customize for Stack" to "Generate Stack-Specific Scripts"
   - Lists 7 scripts to generate with LLM-based analysis
   - Documents generation workflow: read spec → analyze config → generate → chmod +x

4. ✅ Converted quality gates script to template placeholder:
   - `agents/templates/harness/run-quality-gates.sh`
   - Reduced from 293 lines to 29 lines
   - Now errors with clear message directing users to run initializer
   - Prevents use of generic script on real projects

5. ✅ Created quality gate specification for LLM generation:
   - `agents/skills/quality-gate-spec.md` (new, untracked)
   - Defines 6 phases: test, lint, arch, coverage, security, metrics
   - Specifies failure modes (hard fail vs soft warn)
   - Includes generation process and stack-specific examples
   - Documents metrics collection, comparison, and archival

## What Remains To Do

### High Priority

- [x] **Create specification documents for remaining harness scripts:**
  - [x] `agents/skills/arch-test-spec.md` - How to generate `run-arch-tests.sh`
  - [x] `agents/skills/feature-runner-spec.md` - How to generate `run-feature.sh`
  - [x] `agents/skills/init-project-spec.md` - How to generate `init-project.sh`

- [x] **Convert remaining template scripts to placeholders:**
  - [x] `agents/templates/harness/run-arch-tests.sh` → placeholder (133→29 lines)
  - [x] `agents/templates/harness/run-feature.sh` → placeholder (87→32 lines)
  - [x] `agents/templates/harness/init-project.sh` → placeholder (113→29 lines)

- [ ] **Test the generation workflow:**
  - [ ] Test initializer agent with Java/Maven project
  - [ ] Test initializer agent with TypeScript/npm project
  - [ ] Test initializer agent with Python/pytest project
  - [ ] Verify generated scripts have same quality as old templates

### Medium Priority

- [x] **Enhance quality-gate-spec.md:**
  - [x] Add Rust (Cargo) examples
  - [x] Add Go (go.mod) examples
  - [ ] Expand arch/lint phase details for config file detection

- [x] **Document migration path:**
  - [x] Write guide for migrating existing projects from old templates (`docs/MIGRATION_GUIDE.md`)
  - [ ] Consider version detection (old vs new template structure)
  - [x] Add migration script or checklist

- [ ] **Validate agent skill directive implementation:**
  - [ ] Test Architect Agent with `#hexagonal` directive
  - [ ] Test Coding Agent with `#TDD !Kafka` directives
  - [ ] Test Code Review Agent with `#Security,TDD` directives
  - [ ] Verify progressive disclosure works correctly

### Low Priority

- [ ] **Consider DRY for agent skill directive sections:**
  - Current: Identical sections in architect, codereview, coding agent files
  - Option: Reference shared documentation instead
  - Decision: Is repetition intentional for standalone agent files?

- [ ] **Add metrics scripts to spec:**
  - `collect-metrics.sh` partially covered in quality-gate-spec
  - `compare-metrics.sh` partially covered in quality-gate-spec
  - `archive-metrics.sh` partially covered in quality-gate-spec
  - Consider: Should these have their own dedicated spec?

## Files Modified

| File | Lines Changed | Type |
|------|---------------|------|
| `agents/architect-agent.md` | +21 | Modified |
| `agents/codereview-agent.md` | +19 | Modified |
| `agents/coding-agent.md` | +21 | Modified |
| `agents/initializer-agent.md` | ~27 (refactored) | Modified |
| `agents/templates/harness/run-quality-gates.sh` | -264 (template conversion) | Modified |
| `agents/templates/harness/run-arch-tests.sh` | -104 (template conversion) | Modified |
| `agents/templates/harness/run-feature.sh` | -55 (template conversion) | Modified |
| `agents/templates/harness/init-project.sh` | -84 (template conversion) | Modified |
| `docs/skills/SKILL_DIRECTIVE_WORKFLOW.md` | +28 | Modified |
| `agents/skills/quality-gate-spec.md` | +163 | Created |
| `agents/skills/arch-test-spec.md` | +178 | Created |
| `agents/skills/feature-runner-spec.md` | +157 | Created |
| `agents/skills/init-project-spec.md` | +186 | Created |
| `docs/MIGRATION_GUIDE.md` | +149 | Created |

## Architectural Impact

### Breaking Changes

⚠️ **Template Script Conversion:**
- Old `run-quality-gates.sh` had 293 lines of implementation
- New version is a 29-line placeholder that errors out
- **Impact:** Existing projects using old template must re-run initializer
- **Migration:** Documented in `docs/MIGRATION_GUIDE.md`

### New Capabilities

✅ **Dual Workflow Pattern:**
- Planning-first workflow (existing)
- Direct agent invocation (new)
- Enables quick ad-hoc tasks without full planning cycle

✅ **LLM-Driven Script Generation:**
- Scripts tailored to actual project configuration
- No more maintaining templates for every stack combination
- Reduces maintenance burden on SDLC agents project

## Validation

### Manual Testing Required

```bash
# 1. Test skill directive parsing
echo "Implement auth #TDD #Security !Legacy" | .sdlc-agents/tools/skills/parse-skill-directives.sh

# 2. Test skill resolution for different agents
.sdlc-agents/tools/skills/resolve-skills.sh --agent coding tdd security
.sdlc-agents/tools/skills/resolve-skills.sh --agent architect hexagonal

# 3. Test initializer script generation (on test project)
# Create test Java/Maven project
# Run initializer agent
# Verify generated run-quality-gates.sh matches spec
# Verify all 7 scripts are generated and executable

# 4. Test generated quality gates
cd <test-project>
./agent-context/harness/run-quality-gates.sh
# Verify output format matches specification
```

### Integration Testing

- [ ] Full workflow test: User prompt with directives → Planning → Coding → Review
- [ ] Direct invocation test: User prompt with directives → Coding Agent only
- [ ] Generation test: Initializer creates all harness scripts for various stacks

## Done Criteria

All must be checked before marking task as `done`:

- [ ] Specifications created for all 7 harness scripts (4 remaining)
- [ ] All template scripts converted to placeholders or removed
- [ ] Initializer agent tested on at least 3 different stacks (Java, TS, Python)
- [ ] Generated scripts match or exceed quality of old template scripts
- [ ] Migration guide documented for existing projects
- [ ] All agent skill directive sections tested with real examples
- [ ] Dual workflow pattern validated (planning-first + direct invocation)
- [ ] No hardcoded assumptions about tools (all based on config analysis)

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Generated scripts lower quality than templates | High | Test extensively; ensure spec captures all edge cases from old implementation |
| Breaking change disrupts existing projects | Medium | Document migration path; consider version detection |
| LLM fails to detect tools correctly | Medium | Provide clear spec with config file patterns to look for |
| Inconsistent script generation across stacks | Medium | Create comprehensive test suite with multiple project types |
| Skill directive parsing inconsistent | Low | Use shared parsing script; test with various directive combinations |

## Notes

### Design Decisions

1. **Why template → placeholder?**
   - Forces proper initialization per project
   - Avoids one-size-fits-all anti-pattern
   - Ensures scripts match actual project tooling

2. **Why dual workflow?**
   - Planning-first: Structured, complete feature work
   - Direct invocation: Quick fixes, ad-hoc tasks
   - Flexibility for different user needs

3. **Why LLM-generated scripts?**
   - Each project has different tools configured
   - Impossible to maintain templates for all combinations
   - LLM can analyze actual config and generate appropriate commands

### Technical Debt

- Repetitive "Skill Directives" sections across agent files (consider DRY)
- Missing specs for 4 out of 7 harness scripts
- No automated tests for script generation
- Migration path not yet documented

### Future Enhancements

- Consider caching generated scripts (regenerate only on config changes)
- Add `--dry-run` flag to initializer to preview generated scripts
- Support custom script templates in project `.sdlc-agents/` directory
- Add validation that generated scripts are syntactically correct (shellcheck)

---

**Last Updated:** 2025-12-14
**Assignee:** System Enhancement
**Epic:** SDLC Agents v2.0 - Skill System & Generated Workflows
