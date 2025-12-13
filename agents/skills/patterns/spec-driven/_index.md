# SPEC-Driven Development Skill

Skill for specification-first software development. Enforces "specification as contract" between planning and implementation phases.

---

## When to Use

| Scenario | Why SPEC-Driven |
|----------|-----------------|
| Complex features with multiple stakeholders | Shared understanding before code |
| Unclear or evolving requirements | Iterative refinement before commitment |
| Regulatory/compliance-sensitive implementations | Audit trail and traceability |
| Long-running projects needing traceability | Requirements-to-code mapping |
| Cross-team coordination | Explicit interface contracts |

**Skip when:** Spikes, prototypes, well-understood CRUD operations, or time-boxed experiments.

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Specification as Contract** | Spec is the agreement between planning and implementation |
| **Testable Requirements** | Every requirement maps to a verification method |
| **Progressive Refinement** | Specs evolve: Draft → Review → Approved → Superseded |

---

## Invariants

| Invariant | Action on Violation |
|-----------|---------------------|
| No implementation before approved spec | Block, request approval |
| Every requirement has acceptance criteria | Request criteria |
| Scope changes require spec updates first | Update spec, re-approve |
| Unspecified behavior is explicitly TBD | Document, escalate |

---

## Templates

| Template | Purpose |
|----------|---------|
| [requirement-template.md](requirement-template.md) | FR/NFR formats with examples |
| [specification-checklist.md](specification-checklist.md) | Validation before approval |

---

## Common Issues

| Issue | Resolution |
|-------|------------|
| Spec too vague | Add specific acceptance criteria with numbers/thresholds |
| Orphan implementation | Link to requirement or document as enhancement |
| Spec drift | Update spec first, re-approve, then continue |
| Missing NFRs | Add: response time, availability, data retention |
