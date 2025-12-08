# Tools Registry - Progressive Disclosure System

> Documentation for `agentDirectory/tools/`

> "Like a well-organized manual that starts with a table of contents, then specific chapters, and finally detailed appendix."

This documents the **executable tools** that agents can discover and use **only when needed**.

---

## How It Works

Instead of embedding shell scripts in prompts, agents:

```
1. READ this registry (table of contents)
2. FIND relevant tool by category/description
3. READ tool details ONLY when needed (from tool's .md file)
4. EXECUTE the tool (the .sh file)
```

---

## Tool Categories

| Category | Description | Use When |
|----------|-------------|----------|
| `discovery/` | Analyze codebase structure | First time setup, architecture analysis |
| `validation/` | Check architecture rules | After code changes, before commit |
| `stack/` | Stack-specific commands | When working with specific technology |
| `quality/` | Code quality checks | End of feature, before review |

---

## Quick Reference

### Discovery Tools
| Tool | Description | Stack |
|------|-------------|-------|
| `list-packages` | List all packages/directories in codebase | Any |
| `find-imports` | Find import statements between modules | Any |
| `detect-layers` | Identify architectural layers | Any |
| `build-dep-graph` | Generate dependency graph | Any |
| `count-files` | Count files per package/directory | Any |

### Validation Tools
| Tool | Description | Stack |
|------|-------------|-------|
| `check-circular` | Detect circular dependencies | Any |
| `check-layers` | Validate layer dependencies | Any |
| `run-arch-tests` | Run architecture tests | Auto-detect |

### Stack-Specific Tools
| Tool | Description | Stack |
|------|-------------|-------|
| `java/archunit` | Run ArchUnit tests | Java/Kotlin |
| `java/jdeps` | Visualize JVM dependencies | Java/Kotlin |
| `ts/depcruise` | Run Dependency Cruiser | TypeScript |
| `ts/madge` | Detect circular deps | TypeScript |
| `python/import-linter` | Run Import Linter | Python |
| `go/arch-lint` | Run go-arch-lint | Go |
| `rust/clippy` | Run Clippy checks | Rust |
| `dotnet/archunit` | Run ArchUnitNET | C#/.NET |
| `ruby/packwerk` | Run Packwerk | Ruby |
| `php/deptrac` | Run Deptrac | PHP |

---

## Using Tools

### From Agent Prompts

```markdown
When you need to analyze package structure:
1. See tools registry: agentDirectory/tools/README.md → "Discovery Tools"
2. Read tool details: agentDirectory/tools/discovery/list-packages.md
3. Execute: agentDirectory/tools/discovery/list-packages.sh
```

### From Shell

```bash
# Run any tool directly
./agentDirectory/tools/discovery/list-packages.sh

# With arguments (if supported)
./agentDirectory/tools/stack/java/archunit.sh --verbose
```

---

## Tool File Structure

Each tool consists of two files:

```
tools/
├── <category>/
│   ├── <tool-name>.md    # Human-readable description + usage
│   └── <tool-name>.sh    # Executable script
```

### The `.md` File (Description)

Contains:
- What the tool does
- When to use it
- Expected output
- Examples
- Related tools

### The `.sh` File (Implementation)

Contains:
- Executable POSIX shell script
- Minimal dependencies
- Clear output format
- Exit codes for success/failure

---

## Adding New Tools

1. Create `tools/<category>/<name>.md` with description
2. Create `tools/<category>/<name>.sh` with implementation
3. Add entry to this README in the Quick Reference section
4. Make script executable: `chmod +x tools/<category>/<name>.sh`

### Tool Description Template

```markdown
# <Tool Name>

**Category:** <discovery|validation|stack|quality>
**Stack:** <Any|Java|TypeScript|etc.>

## Purpose

<1-2 sentences about what this tool does>

## When to Use

- <use case 1>
- <use case 2>

## Usage

\`\`\`bash
agentDirectory/tools/<category>/<name>.sh [options]
\`\`\`

## Output Format

<describe what the tool outputs>

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure / Violations found |

## Related Tools

- `<other-tool>` - <brief relation>

## Example

\`\`\`bash
$ agentDirectory/tools/<category>/<name>.sh
<example output>
\`\`\`
```

---

## Progressive Disclosure Benefits

1. **Minimal context** - Agents read only tool descriptions, not implementations
2. **Discoverable** - Registry acts as table of contents
3. **Executable** - Scripts run independently
4. **Maintainable** - Update script without changing prompts
5. **Extensible** - Add tools without modifying agent definitions

---

## Anti-Patterns

❌ **Don't** embed full scripts in agent prompts
❌ **Don't** load all tool details at once
❌ **Don't** duplicate logic between tools
❌ **Don't** make tools that require complex setup

✓ **Do** scan registry first, load details on demand
✓ **Do** keep tools single-purpose
✓ **Do** document expected inputs/outputs
✓ **Do** use consistent naming conventions
