# Contamination Guidelines - Documentation

> This document provides background context and rationale for the contamination guidelines used by agents. For the agent-specific instructions, see [`guardrails/contamination-guidelines.md`](../../../agents/guardrails/contamination-guidelines.md).

## Context

> "Contamination Risk: The efficacy of context adaptation depends fundamentally on the quality of feedback signals. In the absence of reliable feedback, the process of refining knowledge can degrade the system."

---

## Purpose

The contamination guidelines exist to prevent **knowledge degradation** in the learning playbook. Without quality control, the playbook degrades over time:

- Low-quality lessons accumulate
- Contradictory advice confuses agents
- Outdated patterns persist
- One-off hacks become "best practices"
- Noise drowns out signal

---

## The Contamination Problem

### Types of Contamination

| Type | Description | Example |
|------|-------------|---------|
| **Specificity Contamination** | Lessons too specific to one case | "In UserController line 42, use X" |
| **Vagueness Contamination** | Lessons too vague to be actionable | "Be more careful" |
| **Conflicting Contamination** | Contradictory advice without resolution | Two entries with opposite guidance |
| **Stale Contamination** | Outdated patterns that no longer apply | References to deprecated libraries |
| **Unverified Contamination** | Claims without evidence | "I think this works" |

### Why This Matters

The learning playbook is retrieved and used by the Planning Agent to inform future tasks. If it contains:
- **Noise**: Retrieval becomes less effective
- **Contradictions**: Agents receive confusing guidance
- **Stale advice**: Agents repeat outdated patterns
- **Over-specific lessons**: Context matching fails

---

## Quality Control Mechanism

The Curator Agent acts as a gatekeeper by:

1. **Evaluating incoming lessons** from the Retro Agent
2. **Checking against criteria** defined in the guidelines
3. **Rejecting, editing, or accepting** entries
4. **Resolving conflicts** between existing entries
5. **Archiving stale entries** instead of deleting

---

## Design Decisions

### Why Not Per-Project?

The contamination guidelines are **static** (in `agents/guardrails/`) rather than **per-project** (in `agent-context/memory/`) because:

1. **Consistency**: Same quality bar across all projects
2. **Centralized maintenance**: Updates apply everywhere
3. **Not project-specific**: Quality criteria don't vary by project
4. **Prevents drift**: Project-local copies could diverge

### Why Separate from Curator Agent?

The guidelines are separate from the curator agent definition because:

1. **Testability**: Guidelines can be validated independently
2. **Readability**: Agent definition stays focused
3. **Reusability**: Other agents (Retro) also reference criteria

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Curator Agent](../../agents/curator-agent.md) | Agent that enforces these guidelines |
| [Retro Agent](../../agents/retro-agent.md) | Agent that produces lessons |
| [Learning Playbook Template](../memory/) | Template with playbook structure |
