---
id: T<NN>  <!-- REQUIRED: Sequential number, format T01, T02, T03... -->
feature: <FEATURE-ID>  <!-- REQUIRED: Must match parent feature directory name -->
title: <Task Title>  <!-- REQUIRED: Concise, action-oriented title -->
status: pending  <!-- ENUM: pending | in_progress | done | blocked -->
priority: <1-N>  <!-- REQUIRED: 1 = highest priority -->
module: <target-module>  <!-- REQUIRED: Target module/package path -->
estimated_complexity: low  <!-- ENUM: low | medium | high -->
skill_reference: <path-to-skill>  <!-- REQUIRED: e.g., skills/stacks/kotlin.md -->
---

# Task: <Task Title>

## Objective

<!-- 1-2 sentences describing what this task accomplishes and WHY -->
<Replace with concrete objective>

## What to Do

<!-- Numbered steps, specific and actionable -->
1. <Step 1 - be specific, include file paths>
2. <Step 2>
3. <Step 3>

## Files to Create/Modify

<!-- All paths must be real project paths, not placeholders -->
| File | Action | Purpose |
|------|--------|---------|
| `path/to/file.kt` | Create | <purpose> |
| `path/to/other.kt` | Modify | <purpose> |

---

## Architectural Rules

<!-- Extract from architecture tests (ArchUnit, dependency-cruiser, etc.) -->
<!-- These are rules the Coding Agent MUST follow -->

- <rule 1>
- <rule 2>

---

## Validation

Run these commands to verify completion:

```bash
# Unit tests for this task
<specific test command, e.g., ./gradlew test --tests "ClassName">

# Architecture check
./agent-context/harness/run-arch-tests.sh
```

---

## Done Criteria

All must be checked before marking task as `done`:

- [ ] <Criterion 1 - specific and verifiable>
- [ ] <Criterion 2>
- [ ] Unit tests pass
- [ ] Architecture tests pass

---

## Debt Checklist

Review before completion (from guardrails/generative-debt-checklist.md):

- [ ] No hardcoded values that should be configurable
- [ ] No TODO comments without tracking issue
- [ ] No suppressed warnings without justification
- [ ] Proper error handling (not just throwing/catching everything)

---

## Notes

<!-- Any additional context, learnings from feature.md that apply specifically here -->
<Replace or remove if not needed>

---

<!-- TEMPLATE COMPLETION CHECKLIST (Remove this section after filling):
Before saving this task file, verify:
- [ ] All <angle-bracket> placeholders have been replaced with real values
- [ ] id follows format T01, T02, etc.
- [ ] feature matches the parent feature directory name exactly
- [ ] status is one of: pending, in_progress, done, blocked
- [ ] estimated_complexity is one of: low, medium, high
- [ ] skill_reference points to actual skill file
- [ ] File paths in table are real project paths
- [ ] Validation commands are executable (not placeholders)
- [ ] Done criteria are specific and testable
-->
