# SPEC-Driven: Code Review Agent

## Phase 4: Verification

### Traceability Check

1. Trace each change to a requirement ID
2. Flag orphan implementations (code without requirement backing)
3. Verify all acceptance criteria have corresponding tests

### Spec Drift Detection

Signs of spec drift:
- Implementation deviates from spec without update
- New features not documented in requirements
- Changed behavior without version increment

**Action on drift:** Block merge, request spec update first.

### Verification Checklist

- [ ] All modified files trace to requirements
- [ ] Acceptance criteria have test coverage
- [ ] No undocumented behavior changes
- [ ] Comment links match implementation
