# SPEC-Driven: Planning Agent

## Phase 1: Specification

When creating a feature.md with `#spec-driven`:

1. Add spec metadata to frontmatter:
   ```yaml
   spec_status: draft  # ENUM: draft | review | approved | superseded
   spec_version: "1.0"
   approved_by: ""
   ```

2. Create Requirements Specification section with FR/NFR tables:
   ```markdown
   ## Requirements Specification

   ### Functional Requirements

   | ID | Requirement | Acceptance Criteria | Priority |
   |----|-------------|---------------------|----------|
   | FR-001 | ... | ... | MUST |

   ### Non-Functional Requirements

   | ID | Requirement | Metric | Target |
   |----|-------------|--------|--------|
   | NFR-001 | ... | ... | ... |
   ```

3. Document assumptions and out-of-scope explicitly

**Template:** [requirement-template.md](requirement-template.md)

---

## Workflow Integration

After spec creation:
1. Set `spec_status: review`
2. Request Architect Agent validation
3. Wait for approval before creating tasks
