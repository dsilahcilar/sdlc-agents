# Curator Agent

> Maintains the quality of the learning playbook by preventing contamination, resolving conflicts, and ensuring high signal-to-noise ratio.

**Agent Definition:** [`agents/curator-agent.md`](../../agents/curator-agent.md)

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Role** | Knowledge quality control |
| **Code Access** | None |
| **Runs When** | Periodically |
| **Stack Detection** | N/A |

---

## Why This Agent Exists

> "Contamination Risk: The efficacy of context adaptation depends fundamentally on the quality of feedback signals. In the absence of reliable feedback, the process of refining knowledge can degrade the system."

Without curation, the learning playbook degrades over time:
- Low-quality lessons accumulate
- Contradictory advice confuses agents
- Outdated patterns persist
- Noise drowns out signal

---

## Responsibilities

1. **Entry Evaluation** - Quality criteria, generalizability, conflicts
2. **Playbook Maintenance** - Merge similar, resolve contradictions, archive stale
3. **Contamination Prevention** - Reject low-quality entries

---

## Input Files

| File | Purpose |
|------|---------|
| `<project-root>/agent-context/memory/learning-playbook.md` | Current knowledge base |
| New entries from Retro Agent | Incoming lessons |
| `$SDLC_AGENTS/agents/guardrails/contamination-guidelines.md` | Quality criteria |
| `<project-root>/agent-context/guardrails/*` | Current guardrails |
| `<project-root>/agent-context/harness/progress-log.md` | Historical context |

---

## Output Files

| File | Action |
|------|--------|
| `<project-root>/agent-context/memory/learning-playbook.md` | Updated |
| `<project-root>/agent-context/memory/archive/` | Archived entries |
| `<project-root>/agent-context/harness/progress-log.md` | Curation log |

---

## Curation Actions

| Action | When | Output |
|--------|------|--------|
| **Accept** | Meets quality, adds value | Entry added |
| **Merge** | Overlaps with existing | Entries combined |
| **Edit** | Has value but needs refinement | Entry improved |
| **Reject** | Doesn't meet criteria | Entry discarded |
| **Archive** | Valid but outdated | Moved to archive |

---

## Conflict Resolution

When entries conflict:

1. **Identify the conflict**
   - Are they truly contradictory?
   - Or are they context-dependent?

2. **Attempt context scoping**
   - Entry A applies to context X
   - Entry B applies to context Y
   - Add clear triggers to distinguish

3. **If irreconcilable**
   - Determine which has more evidence
   - Archive the weaker entry
   - Document the decision

4. **If unclear**
   - Flag for human review
   - Add `needs_review: true` to both entries

---

## Quality Metrics Tracked

| Metric | Description |
|--------|-------------|
| **Total entries** | Count of active lessons |
| **Entries per module** | Distribution across codebase |
| **Conflict rate** | Contradictory entries detected |
| **Application rate** | How often entries are retrieved and used |
| **Decay rate** | Entries archived as stale |

---

## Playbook Health Checks

Periodically verify:

- [ ] No orphaned entries (all have valid context tags)
- [ ] No circular contradictions
- [ ] Reasonable entry count per module (not too few, not too many)
- [ ] Recent entries exist (playbook is actively growing)
- [ ] Old entries are still relevant (no stale patterns)

---

## Constraints

- **No code changes** - Knowledge curation only
- **Preserve history** - Archive, don't delete
- **Evidence-based** - Decisions should cite reasons
- **Conservative merging** - When in doubt, keep separate
- **Explicit conflicts** - Never hide contradictions

---

## Anti-Patterns to Prevent

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Accumulation without curation | Playbook grows unbounded |
| Silent contradictions | Conflicting entries confuse agents |
| Stale advice | Outdated patterns cause errors |
| Over-curation | Valuable lessons rejected too aggressively |
| Under-curation | Low-quality entries pollute retrieval |

---

## Handoff

→ Curated playbook available for **[Planning Agent](./planning-agent.md)** (via retrieval)
