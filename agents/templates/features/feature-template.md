---
id: <FEATURE-ID>  <!-- REQUIRED: Unique identifier, e.g., feat-user-auth -->
title: <Feature Title>  <!-- REQUIRED: Human-readable feature name -->
status: pending  <!-- ENUM: pending | in_progress | passing | blocked -->
module: <primary-module>  <!-- REQUIRED: Main module/package this affects -->
risk_level: low  <!-- ENUM: low | medium | high -->
skill_reference: <path-to-skill>  <!-- REQUIRED: e.g., skills/stacks/kotlin.md -->
created_at: <ISO8601>  <!-- REQUIRED: Use current timestamp -->
updated_at: <ISO8601>  <!-- REQUIRED: Use current timestamp -->
---

# Feature: <FEATURE-ID> - <Feature Title>

## Description

<!-- 2-3 sentences describing what this feature accomplishes and its business value -->
<Replace with concrete description>

## Acceptance Criteria

<!-- Specific, testable criteria - not vague statements -->
- [ ] <Criterion 1 - specific and verifiable>
- [ ] <Criterion 2>
- [ ] <Criterion 3>

---

## Technology Stack

**Stack:** <detected stack>  <!-- e.g., Kotlin + Spring Boot -->
**Skill Reference:** `skills/stacks/<stack>.md`
**Build System:** <e.g., Maven, Gradle, npm>
**Architecture Tool:** <e.g., ArchUnit, dependency-cruiser>

### Validation Commands

<!-- All commands must be executable, not placeholders -->
| Check | Command |
|-------|---------|
| Build | `<build command>` |
| Unit Tests | `<test command>` |
| Architecture | `<arch check command>` |

---

## Architectural Constraints

<!-- Extracted from architecture tests (ArchUnit, dependency-cruiser, etc.) -->
<!-- Include actual rules that apply to this feature's modules -->

- <constraint 1>
- <constraint 2>

---

## Relevant Lessons

<!-- Curated from learning-playbook.md, matching this module/framework -->
<!-- If no relevant lessons, write "No relevant lessons found" -->

### Lesson: <title>

**Context:** <when this applies>

**Guidelines:**
- <guideline 1>
- <guideline 2>

---

## Risk Patterns

<!-- Extracted from risk-patterns.md, relevant to this feature -->
<!-- If no risks apply, write "No specific risk patterns identified" -->

- <risk 1>
- <risk 2>

---

## Domain Heuristics

<!-- Extracted from domain-heuristics.md, if applicable -->
<!-- If no heuristics apply, write "No domain heuristics applicable" -->

- <heuristic 1>
- <heuristic 2>

---

## Tasks

<!-- Link to all tasks created for this feature -->
| Task | Description | Status |
|------|-------------|--------|
| T01 | <description> | pending |
| T02 | <description> | pending |

See `tasks/` directory for detailed task specifications.

---

<!-- TEMPLATE COMPLETION CHECKLIST (Remove this section after filling):
Before saving this feature file, verify:
- [ ] All <angle-bracket> placeholders have been replaced with real values
- [ ] id is unique and follows naming convention (e.g., feat-xxx-yyy)
- [ ] status is one of: pending, in_progress, passing, blocked
- [ ] risk_level is one of: low, medium, high
- [ ] skill_reference points to actual skill file
- [ ] created_at/updated_at use ISO8601 format (YYYY-MM-DDTHH:MM:SSZ)
- [ ] All commands in Validation Commands table are executable
- [ ] Architectural Constraints are extracted from real tests
- [ ] Task table matches actual task files in tasks/ directory
- [ ] Sections without content say "No X found" rather than leaving placeholders
-->
