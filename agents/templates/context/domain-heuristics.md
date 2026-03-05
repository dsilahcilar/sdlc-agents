# Domain Heuristics

Project-specific domain principles, invariants, and implementation heuristics.

---

## How to Use

- Planning Agent: extract relevant heuristics into feature/task artifacts.
- Architect Agent: verify planned changes do not violate invariants.
- Coding Agent: apply heuristics from feature/task context.
- Retro Agent: append proven heuristics discovered during delivery.

---

## Domain Template

Use this structure for each business domain:

```markdown
## Domain: <Domain Name>

### Overview
<Brief description of the domain>

### Key Concepts
- **<Concept>**: <Definition>

### Invariants
- <Rule that must never be violated>

### Heuristics
- <Pattern that usually works well>

### Common Failure Modes
- <Frequent mistake to avoid>

### Related Modules
- `path/to/module`
```

---

## Starter Example (Replace)

## Domain: Example Domain

### Overview
Placeholder domain description.

### Key Concepts
- **Example Concept**: Replace with real concept definitions.

### Invariants
- Replace with mandatory domain rules.

### Heuristics
- Replace with proven implementation patterns.

### Common Failure Modes
- Replace with frequent domain mistakes.

### Related Modules
- `src/example/`
