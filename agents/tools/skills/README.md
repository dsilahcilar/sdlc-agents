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
./resolve-skills.sh <skill-name> [<skill-name>...]
```

### Output

Skill file paths (one per line). Warnings for unknown skills go to stderr.

### Examples

```bash
# Resolve known skills
./resolve-skills.sh java typescript
# → /path/to/agents/skills/stacks/java.md
# → /path/to/agents/skills/stacks/typescript.md

# Resolve alias
./resolve-skills.sh kotlin
# → /path/to/agents/skills/stacks/java.md

# Unknown skill (warns but continues)
./resolve-skills.sh unknown-skill
# → WARNING: Skill 'unknown-skill' not found in skill-index.yaml
```

### Resolution Order

1. Check custom index: `$PROJECT_ROOT/agent-context/extensions/skills/skill-index.yaml`
2. Check core index: `$SDLC_AGENTS/skills/skill-index.yaml`
3. Match by canonical name or aliases (case-insensitive)

### Dependencies

- None (uses pure bash for portability)
