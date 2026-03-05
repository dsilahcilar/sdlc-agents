# Skill Pattern Alignment Plan

This plan migrates SDLC Agents toward a modern `SKILL.md`-based model while preserving compatibility with existing `.sdlc-agents/*.md` workflows.

## Goals

1. Align prompt assets to standard skill packaging (`SKILL.md` per skill folder).
2. Keep existing installers and user workflows operational during migration.
3. Eliminate drift across prompts/docs/installers by defining clear source-of-truth.
4. Preserve progressive-disclosure and directive support (`#Skill`, `!Skill`, `#only`).

## Migration Principles

1. Backward compatibility first: do not break `.sdlc-agents/<agent>.md` usage.
2. Progressive migration: introduce canonical skills, then re-point docs/tooling.
3. Single source of truth per concern:
   - Runtime agent instructions: `agents/*.md` (compatibility layer during migration)
   - Skill packages: `skills/**/SKILL.md` (new standard)
   - Tool adapter behavior: `tools/*/install.sh`
4. Keep prompts explicit and deterministic over abstract references.

## Phase 1 - Foundational Consistency

### 1.1 Resolve Path and Installation Drift

- Standardize references on `.sdlc-agents/` (not `agents/` or `.agents/`).
- Update tool READMEs and setup docs to match current installers.

### 1.2 Resolve Template Provisioning Drift

- Ensure `agents/setup.sh` copies all template groups that runtime prompts expect:
  - `context/`
  - `metrics/`
- Keep current behavior idempotent.

### 1.3 Resolve Skill Registry Drift

- Add explicit `kotlin` skill index entry to match stack-detection output.
- Keep `java` aliases where appropriate but avoid ambiguous resolution.

### 1.4 Resolve Policy Drift

- Align docs around supported dual mode:
  - Planning-first workflow (recommended)
  - Direct invocation by downstream agents (supported)

## Phase 2 - Introduce Standard Skill Packages

### 2.1 Add Role Skills

Create canonical role skills under `skills/roles/`:

- `skills/roles/initializer/SKILL.md`
- `skills/roles/planning/SKILL.md`
- `skills/roles/architect/SKILL.md`
- `skills/roles/coding/SKILL.md`
- `skills/roles/codereview/SKILL.md`
- `skills/roles/retro/SKILL.md`
- `skills/roles/curator/SKILL.md`

Each skill should include:
- YAML frontmatter (`name`, `description`)
- concise trigger criteria in description
- body that references runtime prompt file until full convergence

### 2.2 Add Skill Catalog Entry Point

- Create top-level `skills/README.md` documenting:
  - available role skills
  - capability skills currently living in `agents/skills/`
  - compatibility model

## Phase 3 - Documentation and Adapter Alignment

### 3.1 Tool Docs

- Update `tools/*/README.md` and `docs/TOOL_CONFIGURATION_FORMATS.md` to match actual install outputs.

### 3.2 Responsibility and Workflow Docs

- Update `docs/AGENT_RESPONSIBILITY_ALLOCATION.md` and related docs to remove conflicting statements.

### 3.3 Tool Registry Accuracy

- Ensure `docs/tools/README.md` lists only implemented tools or clearly marks planned tools.

## Phase 4 - Validation and Follow-up

### 4.1 Validation Pass

- Run `rg` scans for stale path references and conflicting policy statements.
- Confirm no broken links to removed/non-existent files.

### 4.2 Next Iteration (Post-This Change)

- Decide canonical source for role instructions:
  - Option A: `skills/roles/*/SKILL.md` canonical, generate `agents/*.md`
  - Option B: keep `agents/*.md` canonical and generate skill wrappers
- Add generation script once decision is finalized.

## Definition of Done for This Iteration

1. Plan document committed.
2. Core drift items fixed (paths, setup copying, kotlin index, policy/docs conflicts).
3. Canonical role skill scaffolding exists with valid `SKILL.md` frontmatter.
4. All tool docs/install docs reflect current `.sdlc-agents` behavior.
5. Validation scan shows no critical stale references in active docs.
