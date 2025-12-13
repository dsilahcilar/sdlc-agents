# Skills - Progressive Disclosure System

> Documentation for `agents/skills/`

> "Progressive disclosure is the core design principle that makes Agent Skills flexible and scalable.
> Like a well-organized manual that starts with a table of contents, then specific chapters, and finally detailed appendix,
> skills let Claude load information only as needed."

This documents the **modular skills** that agents load **only when needed**.

---

## Why Skills?

Instead of front-loading all knowledge into agent prompts:

```
❌ BAD: Agent prompt contains Java + TypeScript + Python + Go + Rust + ...
   → Wastes context window
   → Dilutes LLM attention
   → Causes confusion between stacks
```

We use progressive disclosure with **clear responsibility separation**:

```
✓ GOOD: Planning Agent detects stack → includes in context → downstream agents use specific tools
   → Single point of stack detection (Planning Agent)
   → Pre-assembled context for implementation agents
   → Minimal context usage
   → Better LLM performance
```

---

## How It Works

### Level 1: Table of Contents (This File)

**Planning Agent** reads this file to understand available skills.
**Context cost: ~100 tokens**

### Level 2: Stack Detection (Planning Agent Only)

**Only the Planning Agent** reads `stack-detection.md` to identify the technology stack.
Other agents (Coding, Code Review, Architect) receive stack context embedded in feature.md and task files.
**Context cost: ~200 tokens** (one-time, during planning)

### Level 3: Skill File (Planning Agent Only)

**Planning Agent** loads the detected stack's skill file (e.g., `stacks/java.md`) and **embeds** relevant content into feature.md and task files.
Other agents consume the *embedded* content, not the raw skill files.
**Context cost: ~400 tokens**

### Level 4: Tool Execution

Agents use tools from `agents/tools/` - only reading tool description when needed.
**Context cost: ~100 tokens per tool**

**Total for typical planning session: ~800 tokens** (vs. ~4000+ if loading everything)

---

## Explicit Skill Selection

Users can explicitly control which skills are loaded using directives in their prompt.

### Syntax

| Directive | Meaning | Example |
|-----------|---------|---------|
| `#SkillName` | Force-load skill | `#TDD` |
| `#Skill1,Skill2` | Force-load multiple | `#TDD,Security` |
| `!SkillName` | Force-exclude skill | `!Kafka` |
| `#only:X,Y` | Load ONLY these skills | `#only:TDD` |

### Examples

```
# Auto-detect stack + add TDD skill
"Implement user authentication #TDD"

# Auto-detect but exclude Kafka
"Add event processing !Kafka"

# Combine includes and excludes  
"Implement payment flow #Saga,Security !Legacy"

# Disable auto-detection, use only TDD
"Write tests for UserService #only:TDD"

# Use spec-driven development pattern
"Implement new API endpoint for order processing #spec-driven"

# Spec-driven with stack and other patterns
"Add payment integration #java #spec-driven #TDD"
```

### How It Works

1. User includes directives in their prompt
2. `parse-skill-directives.sh` extracts includes/excludes as JSON
3. `resolve-skills.sh` maps skill names to file paths
4. Agent loads resolved skill files

For a detailed end-to-end workflow showing all phases from user input to agent consumption, see [Skill Directive Workflow](SKILL_DIRECTIVE_WORKFLOW.md).

### Skill Names

Skill names are case-insensitive and support aliases. See `skills/skill-index.yaml` for the full mapping.

| Canonical Name | Aliases |
|---------------|---------|
| `java` | `kotlin`, `jvm`, `maven`, `gradle` |
| `typescript` | `ts`, `javascript`, `js`, `node` |
| `hexagonal` | `ports-and-adapters`, `clean-architecture` |

---

## Default Project Skills

These skills are auto-included and scaffolded by the Initializer Agent into `extensions/skills/domain/`:

| Skill | Purpose | Directive |
|-------|---------|-----------|
| `project-domains` | Business domain invariants, heuristics | `#domains` |
| `project-risks` | Risk patterns & mitigations | `#risks` |

To exclude from a task: `!domains` or `!risks`

---

## Directory Structure

```
skills/
├── README.md              # This file (Level 1 - Table of Contents)
├── stack-detection.md     # How to detect technology stack (Level 2)
│
├── stacks/                # Stack-specific skills (Level 3)
│   ├── java.md            # Java/Kotlin with ArchUnit
│   ├── typescript.md      # TypeScript/JavaScript
│   ├── python.md          # Python with Import Linter
│   ├── go.md              # Go with go-arch-lint
│   ├── rust.md            # Rust with cargo-modules
│   ├── dotnet.md          # C#/.NET
│   ├── ruby.md            # Ruby with Packwerk
│   └── php.md             # PHP with Deptrac
│
└── patterns/              # Reusable architectural patterns
    ├── layered.md         # Layered architecture
    ├── hexagonal.md       # Hexagonal/Ports & Adapters
    ├── modular-monolith.md
    ├── microservices.md
    └── spec-driven/       # Multi-file skill (agent-role based)
        ├── _index.md      # Core concepts (always loaded)
        ├── planning.md    # Planning Agent specific
        ├── architect.md   # Architect Agent specific
        ├── coding.md      # Coding Agent specific
        └── review.md      # Code Review Agent specific

tools/                     # Executable tools (Level 4)
├── README.md              # Tool registry
├── discovery/             # Codebase analysis tools
├── validation/            # Architecture validation tools
└── stack/                 # Stack-specific tools
    ├── java/
    └── ts/
```

### Multi-File Skills

Some skills contain agent-role-specific instructions. Instead of a single `.md` file, they use a **directory structure**:

| File | Purpose |
|------|---------|
| `_index.md` | Core concepts shared across all agents |
| `planning.md` | Planning Agent specific instructions |
| `architect.md` | Architect Agent validation logic |
| `coding.md` | Coding Agent implementation rules |
| `review.md` | Code Review Agent verification |

**Loading with agent role:**
```bash
# Load only what Planning Agent needs
resolve-skills.sh --agent planning spec-driven
# → _index.md + planning.md
```

This enables **progressive disclosure** — agents only receive the instructions relevant to their role.

### When to Use Multi-File Skills

Use **multi-file skills** when:
- Different agents need different instructions (e.g., planning vs. coding vs. review)
- Skill has distinct phases (spec → validate → implement → review)
- Content would exceed ~100 lines in a single file

Use **single-file skills** when:
- All agents need the same information
- Skill is stack-specific (Java, TypeScript, etc.)
- Content is concise (<100 lines)

---

## How Agents Use Skills

### For Planning Agent (Stack Detection)

The **Planning Agent** is responsible for stack detection:

1. Read `skills/stack-detection.md`
2. Detect the technology stack
3. Document in Solution Plan (Section 1.1 Technology Stack)
4. Document in Context file (Technology Stack section)

### For Downstream Agents (Coding, Code Review, Architect)

Downstream agents **receive stack context** from the Planning Agent:

1. Read the pre-assembled context: `<project-root>/agent-context/context/<issue-id>.context.md`
2. Use the documented skill reference: `skills/stacks/<stack>.md`
3. Execute validation commands from the context file

**DO NOT detect the stack yourself.** If stack context is missing, escalate to Planning Agent.

### Using Tools (Not Scripts!)

Agent uses tools from `agents/tools/` instead of inline scripts:

```markdown
# OLD WAY (fills context):
```bash
find src/main -name "*.java" -o -name "*.kt" | xargs grep -h "^package " | sort -u
```

# NEW WAY (minimal context):
See: agents/tools/discovery/list-packages.md
Run: agents/tools/discovery/list-packages.sh src/main
```

---

## Skill File Format

Each skill file follows this structure:

```markdown
# <Stack Name> Architecture Skill

## Architecture Enforcement Tool
Primary tool and dependencies.

## Available Tools
Table linking to agents/tools/ with when to use each.

## Quick Commands
For immediate execution without reading tool docs.

## Generated Rules Template
Code template for setting up architecture rules.

## Common Violations
Typical issues and how to fix them.

## Existing Tests Check
How to detect if rules already exist.
```

---

## Tools vs. Embedded Scripts

### Before (Embedded Scripts)

```markdown
## Discovery Commands

\`\`\`bash
# List all packages
find src/main -name "*.java" -o -name "*.kt" | xargs grep -h "^package " | sort -u

# Find imports between packages
grep -r "^import com.example" src/main --include="*.java" --include="*.kt"

# Count files per package
find src/main -name "*.java" -o -name "*.kt" | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
\`\`\`
```

**Problem:** Every time agent loads this skill, these 10+ lines fill the context window.

### After (Tool References)

```markdown
## Available Tools

| Tool | Purpose |
|------|---------|
| `agents/tools/discovery/list-packages.sh` | List all packages |
| `agents/tools/discovery/find-imports.sh` | Find import relationships |
| `agents/tools/discovery/count-files.sh` | Count files per package |
```

**Benefit:** Agent only loads tool description when it needs to use that specific tool.

---

## Adding New Skills

1. Create `skills/stacks/<stack>.md`
2. Follow the standard skill format
3. Create tools in `agents/tools/stack/<stack>/`
4. Update `stack-detection.md` with detection rules
5. Update `harness/run-arch-tests.sh` if needed
6. Test with a sample project

---

## Loading Skills Programmatically

Agents should:

### Bootstrap Agent (Initializer)
- Does **NOT** load skills
- Creates directory structure only

### Context Producer (Planning Agent)
1. Read this README (table of contents)
2. Read `stack-detection.md` (to detect stack)
3. Read the detected stack's skill file
4. Read custom skills from `extensions/skills/` if relevant
5. **Embed** relevant skill content into feature.md and task files

### Context Consumers (All Other Agents)
1. **First**: Read the feature.md and/or task files with embedded context
2. **Then**: Read tool descriptions only when ready to execute
3. **Never**: Load skills directly (only Planning Agent does this)
4. **Never**: Read `stack-detection.md` (that's Planning Agent's job)
5. **Never**: Read all stack skills at once

This keeps context usage minimal and focused, with clear responsibility separation.

---

## Context Budget

| Document | Tokens (approx) | When to Load |
|----------|-----------------|--------------|
| skills/README.md | 100 | Always (table of contents) |
| skills/stack-detection.md | 200 | First time setup |
| skills/stacks/<stack>.md | 400 | After stack detection |
| tools/<category>/<tool>.md | 100 | Before executing tool |
| tools/<category>/<tool>.sh | 0 | Never (just execute) |

**Typical session: 800 tokens** for all skill/tool knowledge.

---

## Custom Skills

For project-specific skills, consumers can add skills to `agent-context/extensions/skills/`:

| Location | Purpose |
|----------|---------|
| `agents/skills/` | Core skills (stack-specific, provided by SDLC Agents) |
| `extensions/skills/` | Custom project skills (added by consumers) |

Custom skills follow the same format as core skills and are loaded on-demand using Progressive Disclosure. Agents always check `extensions/skills/README.md` for available custom skills.

### Use Case Examples

The [`extensions/skills/README.md`](../../agents/templates/extensions/skills/README.md) includes comprehensive examples for:

| Category | Example | Description |
|----------|---------|-------------|
| **Testing** | `domain/bdd-testing.md` | BDD patterns with Gherkin/Cucumber |
| **Security** | `domain/security-owasp.md` | OWASP Top 10 guidelines |
| **Integrations** | `domain/kafka-integration.md` | Event streaming patterns |
| **Legacy** | `domain/legacy-migration.md` | Strangler fig, database migrations |
| **Domain** | `domain/payments.md` | Payment processing invariants |
| **Patterns** | `patterns/saga-pattern.md` | Distributed transaction patterns |
| **Tools** | `tools/internal-api.sh` | Custom project tooling |

### End-to-End Workflow

See the [How Agents Use Custom Skills](../../agents/templates/extensions/skills/README.md#end-to-end-workflow-how-agents-use-custom-skills) section for a complete walkthrough showing:

1. Agent discovers skills via README registry
2. Agent selectively loads relevant skills
3. Agent applies invariants and patterns
4. Agent uses custom tools

### Troubleshooting

See the [Troubleshooting](../../agents/templates/extensions/skills/README.md#troubleshooting) section for solutions to common issues:

- Skill not being loaded
- Skill conflicts with core skills
- Agent ignoring invariants
- Tool script failures
- Skills too large

