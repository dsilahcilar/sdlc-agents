# Skills - Progressive Disclosure

Load only the skills you need for the current task.

---

## Available Skills

### Stack Detection
**File:** `stack-detection.md`
**Purpose:** Detect the project's technology stack

### Stack-Specific Skills

| Stack | File |
|-------|------|
| Java/Kotlin | `stacks/java.md` |
| TypeScript/JS | `stacks/typescript.md` |
| Python | `stacks/python.md` |
| Go | `stacks/go.md` |
| Rust | `stacks/rust.md` |
| .NET/C# | `stacks/dotnet.md` |
| Ruby | `stacks/ruby.md` |
| PHP | `stacks/php.md` |

---

## How to Use

**Step 1:** Read this file to see available skills
**Step 2:** If you need stack detection, read `stack-detection.md`
**Step 3:** Load only the detected stack's skill file
**Step 4:** Execute tools from that skill as needed

Do NOT load all stack skills. Only load what you need.

---

## Custom Skills

Projects may have custom skills in `<project-root>/agent-context/extensions/skills/`:
- `domain/` - Domain-specific knowledge
- `patterns/` - Custom architecture patterns
- `tools/` - Project-specific tools

Check `extensions/skills/README.md` if it exists.
