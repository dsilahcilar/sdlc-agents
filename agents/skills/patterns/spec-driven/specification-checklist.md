# Specification Checklist

Use this checklist to validate specifications before approval. All items must be checked before moving `spec_status` from `review` to `approved`.

---

## Completeness Checks

### Requirements Coverage

- [ ] All known user stories are captured as requirements
- [ ] Both functional (FR) and non-functional (NFR) requirements present
- [ ] Each requirement has a unique ID
- [ ] Requirements are grouped logically by feature area

### Acceptance Criteria

- [ ] Every FR has at least one acceptance criterion
- [ ] Criteria are written in testable format (Given/When/Then or equivalent)
- [ ] No criteria use vague terms ("fast", "secure", "user-friendly")
- [ ] Edge cases and error conditions are specified

### Non-Functional Requirements

- [ ] Performance requirements have measurable targets
- [ ] Security requirements specify threat model or compliance standard
- [ ] Availability requirements have uptime percentage
- [ ] Scalability requirements have growth projections

---

## Clarity Checks

### Language Quality

- [ ] No ambiguous pronouns ("it", "this", "that" without clear referent)
- [ ] No undefined acronyms or jargon
- [ ] "Must" vs "Should" vs "Could" used consistently (MoSCoW)
- [ ] Passive voice replaced with specific actors

### Specificity

- [ ] Numbers have units (ms, %, users/second)
- [ ] Date/time formats are specified (ISO8601, local timezone)
- [ ] API response formats are defined (JSON schema or example)
- [ ] Error messages have specific codes/formats

---

## Testability Checks

### Verification Method

- [ ] Each FR maps to a test type (unit, integration, e2e)
- [ ] Each NFR has a measurement method
- [ ] Test data requirements are documented
- [ ] Environment requirements for testing are specified

### Traceability

- [ ] Traceability matrix is prepared (requirement → test)
- [ ] Each requirement is independently testable
- [ ] Test coverage target is defined

---

## Consistency Checks

### Internal Consistency

- [ ] No contradictory requirements
- [ ] Terminology is consistent across spec
- [ ] Priority levels are balanced (not all "Must")
- [ ] Dependencies between requirements are documented

### External Consistency

- [ ] Aligns with existing system architecture
- [ ] Compatible with documented constraints
- [ ] No conflicts with other feature specs
- [ ] References to external systems are validated

---

## Scope Checks

### Boundaries

- [ ] "Out of Scope" section is present and explicit
- [ ] Assumptions are documented and validated
- [ ] Dependencies on other teams/systems are identified
- [ ] Future considerations are noted but clearly marked

### Risk Assessment

- [ ] High-risk requirements are flagged
- [ ] Mitigation strategies are proposed
- [ ] Fallback behavior is specified for risky features
- [ ] Performance bottlenecks are anticipated

---

## Approval Criteria

| Criterion | Status |
|-----------|--------|
| All completeness checks pass | ☐ |
| All clarity checks pass | ☐ |
| All testability checks pass | ☐ |
| All consistency checks pass | ☐ |
| All scope checks pass | ☐ |
| Stakeholder sign-off obtained | ☐ |

---

## Approval Record

| Role | Name | Date | Comments |
|------|------|------|----------|
| Author | | | |
| Reviewer | | | |
| Approver | | | |

---

## Post-Approval Changes

If changes are needed after approval:

1. Create a new version (increment `spec_version`)
2. Document change in Change Log section
3. Re-run this checklist
4. Obtain re-approval before implementation continues
