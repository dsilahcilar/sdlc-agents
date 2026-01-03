# Skills - Progressive Disclosure

Load only the skills you need for the current task.

---

## Quick Reference

For skill discovery, read **`skill-index.yaml`** to see:
- All available skills with aliases
- **`detect_hints`** - keywords to match against user requests/code

---

## Skill Categories

### 1. Stack Skills (Auto-Detected)

**Detection:** Use `stack-detection.md` to auto-detect project stack.

| Stack | File | Aliases |
|-------|------|---------|
| Java/Kotlin | `stacks/java.md` | kotlin, jvm, maven, gradle |
| TypeScript/JS | `stacks/typescript.md` | ts, javascript, js, node |
| Python | `stacks/python.md` | py |
| Go | `stacks/go.md` | golang |
| Rust | `stacks/rust.md` | cargo |
| .NET/C# | `stacks/dotnet.md` | csharp, cs |
| Ruby | `stacks/ruby.md` | rb, rails |
| PHP | `stacks/php.md` | laravel |

### 2. Pattern Skills (On-Demand)

| Pattern | Path | Aliases |
|---------|------|---------|
| Hexagonal | `patterns/hexagonal.md` | ports-and-adapters, clean-architecture, clean |
| Layered | `patterns/layered.md` | - |
| Modular Monolith | `patterns/modular-monolith.md` | modular |
| Microservices | `patterns/microservices.md` | micro |
| Spec-Driven | `patterns/spec-driven/` | spec, specification-first, sdd |

### 3. Framework Skills (On-Demand)

| Framework | Path | Aliases |
|-----------|------|---------|
| Embabel | `frameworks/embabel/` | embabel-agent, embabel-framework |

**Multi-file skills** (directories) contain:
- `_index.md` - Core concepts (always loaded)
- `planning.md` - Planning Agent specific guidance
- `architect.md` - Architect Agent specific guidance
- `coding.md` - Coding Agent specific guidance
- `review.md` - Code Review Agent specific guidance

---

## How to Discover Skills

1. **Read `skill-index.yaml`** for complete listing
2. **Match `detect_hints`** against keywords in user request or code
3. **Use aliases** for alternative names

---

## How to Load Skills

```bash
# Resolve single skill
.sdlc-agents/tools/skills/resolve-skills.sh <skill-name>

# Resolve with agent role (for multi-file skills)
.sdlc-agents/tools/skills/resolve-skills.sh --agent <role> <skill-name>

# Parse user directives
.sdlc-agents/tools/skills/parse-skill-directives.sh "$USER_PROMPT"
```

---

## User Skill Directives

Users can explicitly request skills using directives in their prompt:

| Directive | Effect |
|-----------|--------|
| `#SkillName` | Force-load skill |
| `#Skill1,Skill2` | Force-load multiple skills |
| `!SkillName` | Force-exclude a skill |
| `#only:Skills` | Disable auto-detection, use only listed |

---

## Custom Skills

Projects may have custom skills in `<project-root>/agent-context/extensions/skills/`:
- `domain/` - Domain-specific knowledge
- `patterns/` - Custom architecture patterns
- `tools/` - Project-specific tools

Check `extensions/skills/README.md` if it exists.
