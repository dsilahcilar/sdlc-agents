# SPEC-Driven: Architect Agent

## Phase 2: Validation

Before approving a specification, verify completeness using the checklist.

### Approval Checklist

- [ ] All functional requirements have acceptance criteria
- [ ] Non-functional requirements have measurable targets
- [ ] Assumptions are explicitly documented
- [ ] Out-of-scope items are listed
- [ ] No ambiguous language ("should", "might", "etc.")
- [ ] Dependencies are identified
- [ ] Risk assessment completed

**Detailed Checklist:** [specification-checklist.md](specification-checklist.md)

---

## Approval Process

1. Review specification against checklist
2. If incomplete: request clarification, set `spec_status: draft`
3. If complete: set `spec_status: approved`, sign `approved_by`

---

## Change Management

When scope changes are requested after approval:
1. Block implementation until spec is updated
2. Require re-approval for modified sections
3. Increment `spec_version`
