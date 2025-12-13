# Skill Directive Workflow

## Overview

This document describes the complete end-to-end flow of skill directives from user input through to agent consumption. Understanding this workflow is critical for troubleshooting skill loading issues and extending the skill system.

## Architecture Context

The skill directive system follows a **Context Provider/Consumer** pattern:

- **Planning Agent**: The sole context provider - detects stack, parses directives, resolves skills, and embeds content
- **Downstream Agents** (Architect, Coding, Code Review): Context consumers - receive pre-assembled skill content via feature.md and task files

This separation ensures:
- Single source of truth for skill resolution
- Minimal context window usage downstream
- No redundant skill processing

---

## Phase 1: User Input

The user includes skill directives in their prompt to the Planning Agent:

```
Implement payment retry logic with saga pattern #Saga,Payments !Legacy
```

### Directive Syntax

| Directive | Meaning | Example |
|-----------|---------|---------|
| `#SkillName` | Force-load skill | `#TDD` |
| `#Skill1,Skill2` | Force-load multiple | `#TDD,Security` |
| `!SkillName` | Force-exclude skill | `!Kafka` |
| `#only:X,Y` | Load ONLY these skills | `#only:TDD` |

### User Intent

- `#Saga,Payments`: "I want saga pattern and payment domain skills loaded"
- `!Legacy`: "Exclude any legacy migration patterns"

---

## Phase 2: Directive Parsing (Planning Agent)

The Planning Agent (Section 1.5 - Parse Skill Directives) processes the user prompt:

### Step 2.1: Extract Directives

```bash
parse-skill-directives.sh "$USER_PROMPT"
```

### Step 2.2: Receive JSON Output

```json
{
  "includes": ["saga", "payments"],
  "excludes": ["legacy"],
  "only_mode": false
}
```

### Parsing Logic

- Case-insensitive matching: `#SAGA` → `saga`
- Comma-separated lists: `#A,B,C` → `["a", "b", "c"]`
- `#only:X` sets `only_mode: true` and ignores auto-detection
- Invalid directives → parse error → ask user for clarification

---

## Phase 3: Skill Resolution (Planning Agent)

The Planning Agent (Section 1.5 - Parse Skill Directives) resolves skill names to file paths.

### Step 3.1: Combine with Stack Skills

If `only_mode: false`, combine explicit directives with auto-detected stack:

```bash
# Auto-detected: java
# Explicit includes: saga, payments
# Final skill set: java, saga, payments (minus excludes)
```

### Step 3.2: Resolve Names to Paths

```bash
resolve-skills.sh saga payments
```

**Output:**
```
agents/skills/patterns/saga-pattern.md
agent-context/extensions/skills/domain/payments.md
```

### Step 3.3: Handle Unknown Skills

If a skill is not found:

```
Warning: Skill 'xyz' not found in skill-index.yaml
```

- Warning logged to stderr
- Processing continues with successfully resolved skills
- Unknown skills documented in feature.md

### Skill Index Lookup

The `skill-index.yaml` maps canonical names and aliases to file paths:

```yaml
skills:
  - name: saga
    aliases: [saga-pattern, distributed-transactions]
    path: agents/skills/patterns/saga-pattern.md
```

Supports:
- Canonical names: `saga`
- Aliases: `saga-pattern`, `distributed-transactions`
- Custom skills: `agent-context/extensions/skills/domain/payments.md`

---

## Phase 4: Skill Loading (Planning Agent)

The Planning Agent reads resolved skill files and embeds content.

### Step 4.1: Read Skill Files

```bash
# For each resolved path:
cat agents/skills/patterns/saga-pattern.md
cat agent-context/extensions/skills/domain/payments.md
```

### Step 4.2: Extract Relevant Content

From each skill file:
- **Patterns**: Architectural patterns to follow
- **Invariants**: Domain rules and constraints
- **Tools**: Custom scripts or commands
- **Examples**: Template code

### Step 4.3: Embed in Feature File

The Planning Agent updates the feature file:

**`agent-context/features/<issue-id>.feature.md`**

```markdown
## Technology Stack

**Detected Stack:** java (auto-detected via build.gradle)  
**Stack Skill:** agents/skills/stacks/java.md

**Loaded Custom Skills:**
- `agents/skills/patterns/saga-pattern.md` (via #Saga)
- `agent-context/extensions/skills/domain/payments.md` (via #Payments)

**Excluded Skills:**
- `legacy` (via !Legacy)

**Skill Directives Applied:**
- Includes: saga, payments
- Excludes: legacy

### Skill Content - Saga Pattern

[Embedded patterns and invariants from saga-pattern.md]

### Skill Content - Payments

[Embedded domain rules from payments.md]
```

### Step 4.4: Embed in Task Files

Task files also receive relevant skill content:

**`agent-context/tasks/<task-id>.task.md`**

```markdown
## Context

**Relevant Skills:**
- Saga Pattern: [key points from saga-pattern.md]
- Payments Domain: [invariants from payments.md]
```

---

## Phase 5: Consumption (Downstream Agents)

Architect, Coding, and Code Review Agents consume the pre-assembled context.

### Step 5.1: Read Feature File

```markdown
Architect/Coding/Code Review Agent first reads:
agent-context/features/<issue-id>.feature.md
```

They see:
- Technology Stack section with loaded skills
- Embedded skill content they need to apply
- No need to re-parse directives or re-resolve skills

### Step 5.2: Read Task Files

```markdown
agent-context/tasks/<task-id>.task.md
```

Task-specific skill content is already embedded.

### Step 5.3: Apply Without Re-Loading

Downstream agents:
- ✅ Read embedded skill content from feature.md and task files
- ✅ Apply patterns, invariants, and constraints as documented
- ❌ **Never** run `parse-skill-directives.sh` themselves
- ❌ **Never** run `resolve-skills.sh` themselves
- ❌ **Never** read skill files directly from `agents/skills/`

### Progressive Disclosure

Agents only load tool descriptions when they need to execute them:

```markdown
# Skill references tool:
See: agents/tools/discovery/list-packages.md
Run: agents/tools/discovery/list-packages.sh src/main
```

Agent:
1. Sees tool reference in embedded content
2. Reads tool description file (100 tokens)
3. Executes tool script
4. Continues with minimal context usage

---

## Error Handling

### Unknown Skill

**Scenario:** User specifies `#XYZ` but skill not found in `skill-index.yaml`

**Behavior:**
1. `resolve-skills.sh` outputs warning to stderr:
   ```
   Warning: Skill 'xyz' not found in skill-index.yaml
   ```
2. Planning Agent logs warning
3. Processing continues with known skills
4. Feature.md documents:
   ```markdown
   **Unknown Skills (not loaded):**
   - `xyz` - not found in skill registry
   ```

**User Action:** Check spelling or add custom skill to `extensions/skills/README.md` and `skill-index.yaml`

---

### Malformed Directive

**Scenario:** User inputs invalid directive syntax like `##Skill` or `#only:`

**Behavior:**
1. `parse-skill-directives.sh` returns parse error
2. Planning Agent receives malformed JSON or error code
3. Agent asks user:
   ```
   Unable to parse skill directives. Please check syntax:
   - Use #SkillName for includes
   - Use !SkillName for excludes
   - Use #only:Skill1,Skill2 for exclusive mode
   ```

**User Action:** Correct directive syntax and retry

---

### Conflicting Directives

**Scenario:** User specifies both include and exclude for same skill: `#TDD !TDD`

**Behavior:**
1. Exclude takes precedence (safer default)
2. Warning logged:
   ```
   Warning: Skill 'TDD' both included and excluded. Excluding.
   ```
3. Feature.md documents the conflict and resolution

---

### Missing Skill File

**Scenario:** `skill-index.yaml` references a file that doesn't exist

**Behavior:**
1. `resolve-skills.sh` attempts to read file
2. File not found error
3. Warning logged, skill skipped
4. Processing continues

**Developer Action:** Fix `skill-index.yaml` or add missing skill file

---

## Execution Flow Diagram

```
User Prompt
    ↓
┌─────────────────────────────────────────┐
│ Planning Agent (Context Provider)       │
├─────────────────────────────────────────┤
│ 1. Parse directives (Phase 2)           │
│    → parse-skill-directives.sh          │
│    → JSON: {includes, excludes, only}   │
│                                         │
│ 2. Resolve skills (Phase 3)             │
│    → resolve-skills.sh                  │
│    → File paths or warnings             │
│                                         │
│ 3. Load skills (Phase 4)                │
│    → Read skill files                   │
│    → Extract patterns/invariants        │
│                                         │
│ 4. Embed content (Phase 4)              │
│    → Update feature.md                  │
│    → Update task files                  │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Downstream Agents (Context Consumers)   │
├─────────────────────────────────────────┤
│ 1. Read feature.md (Phase 5)            │
│    → See Technology Stack section       │
│    → See embedded skill content         │
│                                         │
│ 2. Read task files (Phase 5)            │
│    → Task-specific skill content        │
│                                         │
│ 3. Apply patterns (Phase 5)             │
│    → Use embedded knowledge             │
│    → Load tool descriptions as needed   │
│    → **Never** re-parse or re-resolve   │
└─────────────────────────────────────────┘
```

---

## Key Principles

1. **Single Point of Resolution**: Only Planning Agent parses and resolves skills
2. **Context Provider/Consumer**: Planning Agent produces, downstream agents consume
3. **Progressive Disclosure**: Load skills on-demand, embed only what's needed
4. **Fail Gracefully**: Unknown skills → warning, continue with known skills
5. **Explicit Over Implicit**: User directives override auto-detection
6. **Exclude Wins**: If skill both included and excluded, exclude it

---

## Related Documentation

- [Skills README](README.md) - Overview of skill system and progressive disclosure
- [Planning Agent](../../agents/planning-agent.md) - Section 1.5: Parse Skill Directives
- [Custom Skills](../../agents/templates/extensions/skills/README.md) - Adding project-specific skills
- [Stack Detection](../agents/skills/stack-detection.md) - How stacks are auto-detected

---

## Troubleshooting

### Skill Not Loading

**Symptom:** Expected skill not appearing in feature.md

**Check:**
1. Directive syntax: `#SkillName` (not `##` or `#skill name`)
2. Spelling: Check against `skill-index.yaml`
3. Skill registry: Ensure skill exists in index
4. Logs: Check for warnings from `resolve-skills.sh`

### Directive Ignored

**Symptom:** Directive present but skill not loaded

**Check:**
1. `only_mode`: If using `#only:X`, other skills excluded
2. Conflicts: Check if skill also in exclude list
3. Parse errors: Check for malformed directive syntax

### Wrong Skills Loaded

**Symptom:** Unexpected skills in feature.md

**Check:**
1. Auto-detection: Stack detection may have loaded stack-specific skills
2. Default skills: `project-domains` and `project-risks` auto-loaded unless excluded
3. Aliases: Skill name may match multiple aliases

---

## Summary

This workflow ensures:
- ✅ Clear separation between context provider (Planning) and consumers (Architect, Coding, Review)
- ✅ Minimal redundant processing (skills resolved once)
- ✅ Minimal context window usage (embedded content, not full skill files)
- ✅ Graceful degradation (unknown skills → warnings, not failures)
- ✅ User control (explicit directives override auto-detection)
