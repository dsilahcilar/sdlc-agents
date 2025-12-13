# SPEC-Driven: Coding Agent

## Phase 3: Implementation

### Before Coding

1. Verify `spec_status: approved` in feature.md
2. Read Requirements Specification section
3. Identify requirements covered by current task

### During Implementation

1. Check spec before making assumptions
2. Spec silent on behavior? → Document as TBD, escalate
3. Link code to requirement IDs in comments:
   ```java
   // Implements FR-001: User authentication
   public void authenticate(User user) { ... }
   ```

### Discovery of Gaps

If implementation reveals spec gaps:
1. Do NOT guess the behavior
2. Document the gap with "TBD: [question]"
3. Escalate to Planning Agent for spec update
4. Wait for approval before implementing gap
