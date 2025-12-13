# Requirement Template

Use this template for individual requirements in SPEC-driven development.

---

## Functional Requirement (FR) Format

```markdown
### FR-<ID>: <Title>

**Priority:** Must | Should | Could
**Status:** Draft | Approved | Implemented | Verified

**Description:**
<One sentence describing what the system must do>

**Acceptance Criteria:**
```gherkin
Given <precondition>
When <action>
Then <expected outcome>
And <additional outcome>
```

**Implementation Notes:**
- <technical consideration 1>
- <technical consideration 2>

**Traces To:**
- Implementation: `<Class.method()>`
- Test: `<TestClass.testMethod()>`
```

---

## Non-Functional Requirement (NFR) Format

```markdown
### NFR-<ID>: <Title>

**Category:** Performance | Security | Availability | Scalability | Usability
**Status:** Draft | Approved | Verified

**Requirement:**
<What the system must achieve>

**Measurement:**
<How it will be measured>

**Target:**
<Specific threshold or value>

**Verification Method:**
<How to test: load test, security scan, etc.>

**Implementation Notes:**
- <technical consideration>
```

---

## Example Requirements

### Functional Requirement Example

```markdown
### FR-01: User Login with Email

**Priority:** Must
**Status:** Draft

**Description:**
Registered users must be able to log in using their email address and password.

**Acceptance Criteria:**
```gherkin
Given a registered user with email "user@example.com"
When they submit the login form with correct password
Then they receive a valid JWT token
And they are redirected to the dashboard

Given a user with incorrect credentials
When they submit the login form
Then they receive an "Invalid credentials" error
And no token is issued
```

**Implementation Notes:**
- Use bcrypt for password hashing
- JWT expiry: 1 hour
- Refresh token: 7 days

**Traces To:**
- Implementation: `AuthService.authenticate()`
- Test: `AuthServiceTest.testSuccessfulLogin()`
```

### Non-Functional Requirement Example

```markdown
### NFR-01: Login Response Time

**Category:** Performance
**Status:** Draft

**Requirement:**
Login requests must complete within acceptable response time.

**Measurement:**
p95 latency of `/api/auth/login` endpoint

**Target:**
< 200ms under normal load (100 concurrent users)

**Verification Method:**
Load test with k6, 100 concurrent users, 5-minute duration

**Implementation Notes:**
- Index email column in users table
- Consider connection pooling for database
```

---

## Checklist Before Submitting Requirement

- [ ] ID follows naming convention (FR-XX or NFR-XX)
- [ ] Priority/Category is one of the allowed values
- [ ] Acceptance criteria are specific and testable
- [ ] No vague language ("should be fast", "user-friendly")
- [ ] Target values are measurable (numbers, not adjectives)
- [ ] Dependencies are identified
