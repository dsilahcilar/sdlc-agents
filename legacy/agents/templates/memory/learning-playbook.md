# Learning Playbook

This file stores reusable lessons derived from past work.
It is an **evolving playbook** - not a static prompt, but accumulated wisdom that grows with each completed feature.

> "The second pattern involves agentic engineering frameworks like ACE, which treat an agent's context not as a static prompt but as an 'evolving playbook.'"

---

## How This File Works

1. **Retro Agent** analyzes completed work and adds new entries
2. **Curator Agent** maintains quality and resolves conflicts
3. **Planning/Coding Agents** query this file via curated entries in feature/task files
4. Entries are structured for machine retrieval using importance, relevance, and recency scoring

**IMPORTANT:** Coding Agent should NOT read this file directly. Instead, Planning Agent curates relevant entries into feature.md and task files.

---

## Entry Format

```yaml
---
- id: <unique-id>
  date: <ISO8601>
  source: <issue-id or PR number>
  importance: <1-10>  # Higher = more critical to apply

  context:
    language: <java|kotlin|typescript|go|rust|python|etc>
    framework: <spring|quarkus|react|express|etc>
    module: <module name>
    domain: <business domain>
    risk_level: <low|medium|high>

  triggers:
    - pattern: "When <specific situation>"
      files: ["example/paths/here.kt"]

  what_worked:
    - "<specific technique that succeeded>"

  what_failed:
    - "<approach that caused problems>"

  architecture_violations:
    - rule_id: "<ArchUnit rule name>"
      description: "<what happened>"
      fix: "<how it was resolved>"

  reusable_guidelines:
    - "When <situation>, do <action> instead of <anti-pattern>."

  debt:
    structural:
      - "<structural debt created or paid down>"
    generative:
      - "<quick fixes and their consequences>"

  related_entries:
    - <id of related learning>

  needs_review: false  # Set to true if uncertain about quality
---
```

---

## Entries

<!-- New entries are appended below this line -->
<!-- Format: YAML blocks separated by --- -->

---
- id: TEMPLATE-001
  date: "2024-01-01T00:00:00Z"
  source: "initial-setup"
  importance: 5

  context:
    language: any
    framework: any
    module: core
    domain: general
    risk_level: low

  triggers:
    - pattern: "When setting up a new SDLC agent workflow"
      files: []

  what_worked:
    - "Using structured feature and task files prevents scope creep"
    - "Running architecture tests after every significant change catches violations early"
    - "Logging progress in progress-log.md enables session continuity"

  what_failed:
    - "Passing entire learning playbook to Coding Agent overloads context"
    - "Vague task definitions lead to architectural shortcuts"
    - "Skipping Architect Agent review causes structural debt"

  architecture_violations: []

  reusable_guidelines:
    - "When starting a new feature, always create features/<id>/feature.md and task files first"
    - "When coding, use only the task file, not the full playbook"
    - "When in doubt about architecture, stop and escalate rather than guess"

  debt:
    structural: []
    generative: []

  related_entries: []

  needs_review: false
---
