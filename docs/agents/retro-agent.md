# Retro Agent

> Analyzes completed work (progress logs, test results, review findings) and distills reusable lessons into the evolving playbook.

**Agent Definition:** [`agents/retro-agent.md`](../../agents/retro-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Learning extraction |
| **Code Access** | None |
| **Runs When** | After completion |
| **Stack Detection** | N/A |

---

## Why This Agent Exists

> "Many AI agents lack the capacity for continual learning."

The Retro Agent closes the learning loop. Without it, agents make the same mistakes repeatedly. With it, lessons compound over time.

---

## Responsibilities

1. **Pattern Identification** - Structural debt, generative debt, success patterns
2. **Lesson Distillation** - Convert observations to reusable guidelines
3. **Guardrail Updates** - Propose changes when patterns repeat

---

## Input Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/harness/progress-log.md` | Implementation history |
| Code Review findings | Review observations |
| Test results | Unit, integration, architecture |
| Post-merge outcomes | Bug reports, incidents |
| `<project-root>/agent-context/memory/learning-playbook.md` | Current knowledge base |
| `<project-root>/agent-context/guardrails/*` | Current guardrails |
| `<project-root>/agent-context/context/*` | Context files |

---

## Output Files

| File | Action |
|------|--------|
| `<project-root>/agent-context/memory/learning-playbook.md` | New entries appended |
| Guardrail update proposals | Recommended changes |
| `<project-root>/agent-context/harness/progress-log.md` | Retro summary |

---

## Learning Entry Format (YAML)

```yaml
- id: <unique-id>
  date: <ISO8601>
  source: <issue-id>
  context:
    language: <java|kotlin|typescript|etc>
    framework: <spring|quarkus|react|etc>
    module: <module name>
    domain: <business domain>
    risk_level: <low|medium|high>
  triggers:
    - pattern: "When <situation>"
  what_worked:
    - "<technique that succeeded>"
  what_failed:
    - "<approach that caused problems>"
  architecture_violations:
    - rule_id: "<rule name>"
      description: "<what happened>"
      fix: "<resolution>"
  reusable_guidelines:
    - "When <situation>, do <action> instead of <anti-pattern>."
```

---

## Analysis Framework

### For Each Completed Feature/Issue:

1. **Timeline Review**
   - What was planned?
   - What actually happened?
   - Where were the deviations?

2. **Architecture Impact**
   - Were boundaries respected?
   - Were new dependencies introduced?
   - Did architecture tests catch issues or miss them?

3. **Debt Accounting**
   - What debt was introduced?
   - What debt was paid down?
   - What's the net position?

4. **Root Cause Analysis**
   - If problems occurred, why?
   - Could earlier agents have prevented them?
   - What signals were missed?

5. **Generalization**
   - Is this specific to this task or a broader pattern?
   - Will other features face similar situations?
   - What's the generalizable lesson?

---

## Quality Criteria for Lessons

A good learning entry:

- [ ] **Is specific** - Not "be careful" but "when X, do Y"
- [ ] **Is generalizable** - Applies beyond single instance
- [ ] **Has context** - Clear triggers for when to apply
- [ ] **Is actionable** - Agents can act on it
- [ ] **Is verifiable** - Can be validated via tests

---

## Constraints

- **No code changes** - Only learning documentation
- **Generalize, don't memorize** - Lessons should apply broadly
- **Avoid contamination** - Don't store low-quality or one-off lessons
- **Maintain structure** - Use the standard YAML format
- **Link evidence** - Every lesson should trace to real incidents

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Storing everything | Not all observations are lessons |
| Too specific ("In file X, line 42...") | Not reusable |
| Too vague ("Be more careful") | Not actionable |
| Contradictory entries | Conflicting entries confuse agents |
| Stale lessons | Lessons that no longer apply should be archived |

---

## Handoff

→ **[Curator Agent](./curator-agent.md)** (for quality review)
