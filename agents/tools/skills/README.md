# Skills Tools

Tools for parsing and resolving skill directives from user prompts.

---

## Available Tools

| Tool | Purpose |
|------|---------|
| `parse-skill-directives.sh` | Extract `#includes` and `!excludes` from prompt |
| `resolve-skills.sh` | Map skill names to file paths |

---

## parse-skill-directives.sh

Extracts skill directives from a user prompt and outputs JSON.

### Usage

```bash
./parse-skill-directives.sh "<prompt>"
```

### Output

```json
{
  "includes": ["tdd", "security"],
  "excludes": ["kafka"],
  "only_mode": false
}
```

### Examples

```bash
# Standard includes and excludes
./parse-skill-directives.sh "Implement auth #TDD,Security !Kafka"
# → {"includes": ["security", "tdd"], "excludes": ["kafka"], "only_mode": false}

# Only mode (disables auto-detection)
./parse-skill-directives.sh "Write tests #only:TDD"
# → {"includes": ["tdd"], "excludes": [], "only_mode": true}
```

### Dependencies

- `jq` (for JSON output)

---

## resolve-skills.sh

Resolves skill names to file paths using `skill-index.yaml`.

### Usage

```bash
./resolve-skills.sh [--agent <role>] <skill-name> [<skill-name>...]
```

### Options

| Option | Description |
|--------|-------------|
| `--agent <role>` | Load only files for specified agent role |

**Valid roles:** `planning`, `architect`, `coding`, `review`

### Output

Skill file paths (one per line). Warnings for unknown skills go to stderr.

### Examples

```bash
# Resolve single-file skill
./resolve-skills.sh java
# → /path/to/agents/skills/stacks/java.md

# Resolve multi-file skill (all files)
./resolve-skills.sh spec-driven
# → /path/to/agents/skills/patterns/spec-driven/_index.md
# → /path/to/agents/skills/patterns/spec-driven/planning.md
# → /path/to/agents/skills/patterns/spec-driven/architect.md
# → /path/to/agents/skills/patterns/spec-driven/coding.md
# → /path/to/agents/skills/patterns/spec-driven/review.md

# Agent-specific loading (progressive disclosure)
./resolve-skills.sh --agent planning spec-driven
# → /path/to/agents/skills/patterns/spec-driven/_index.md
# → /path/to/agents/skills/patterns/spec-driven/planning.md

# Resolve alias
./resolve-skills.sh kotlin
# → /path/to/agents/skills/stacks/java.md

# Unknown skill (warns but continues)
./resolve-skills.sh unknown-skill
# → WARNING: Skill 'unknown-skill' not found in skill-index.yaml
```

### Multi-File Skills

Some skills are directories containing role-specific files:

```
patterns/spec-driven/
├── _index.md      # Core concepts (always loaded)
├── planning.md    # Planning Agent specific
├── architect.md   # Architect Agent specific
├── coding.md      # Coding Agent specific
└── review.md      # Code Review Agent specific
```

- **Without `--agent`:** Returns `_index.md` + all role files
- **With `--agent <role>`:** Returns `_index.md` + only that role's file

### Resolution Order

1. Check custom index: `$PROJECT_ROOT/agent-context/extensions/skills/skill-index.yaml`
2. Check core index: `$SDLC_AGENTS/skills/skill-index.yaml`
3. Match by canonical name or aliases (case-insensitive)

### Dependencies

- None (uses pure bash for portability)

