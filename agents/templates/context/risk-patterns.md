# Risk Patterns

This file catalogs recurring risk patterns that agents should actively watch for during planning, coding, and review.

> "The memory retrieval score: Importance, Relevance. This factor assigns a higher score to memory objects that are related to the agent's current situation."

Risk patterns help agents identify high-importance situations that require extra attention.

---

## How to Use This File

1. **Planning Agent** - Check if the task involves any risk patterns
2. **Context Builder** - Include relevant risk patterns in task context
3. **Coding Agent** - Be extra careful when implementing in risky areas
4. **Code Review Agent** - Flag changes that match risk patterns
5. **Retro Agent** - Add new risk patterns when incidents occur

---

## Risk Pattern Categories

1. **Structural Risk** - Architecture and design concerns
2. **Process Risk** - Development workflow issues
3. **Integration Risk** - External system interactions
4. **Data Risk** - Data handling and integrity
5. **Security Risk** - Vulnerabilities and threats

---

## Structural Risk Patterns

### STRUCT-001: Cross-Module Feature Implementation

**Description:** Feature requires changes across multiple modules or bounded contexts.

**Signals:**
- Plan mentions 3+ different modules
- Data flows across context boundaries
- Multiple teams' code will be touched

**Why it's risky:**
- Coordination failures between changes
- Inconsistent handling across boundaries
- Increased chance of breaking changes

**Mitigation:**
- Break into smaller, module-scoped tasks
- Use interface-first design
- Coordinate with module owners
- Run integration tests after each module change

---

### STRUCT-002: Domain-Infrastructure Coupling

**Description:** Feature requires domain layer to know about infrastructure details.

**Signals:**
- Domain entity needs database-specific annotation
- Domain service needs HTTP client
- Business logic depends on specific technology

**Why it's risky:**
- Domain becomes untestable in isolation
- Technology changes ripple through business logic
- Violates core architectural principle

**Mitigation:**
- Use port/adapter pattern
- Define interface in domain, implement in infra
- Inject dependencies through constructor
- Run ArchUnit tests immediately

---

### STRUCT-003: Shared Mutable State

**Description:** Multiple components access/modify the same state without synchronization.

**Signals:**
- Static mutable fields
- Shared caches without explicit concurrency design
- Global configuration that can change at runtime

**Why it's risky:**
- Race conditions
- Hard-to-reproduce bugs
- Unpredictable behavior under load

**Mitigation:**
- Prefer immutable data structures
- Use explicit synchronization or actors
- Scope state to smallest necessary context
- Add concurrency tests

---

## Process Risk Patterns

### PROC-001: Large Multi-File Changes

**Description:** Implementation touches many files in a single commit/PR.

**Signals:**
- 10+ files changed
- Multiple features bundled
- "Just one more thing" scope additions

**Why it's risky:**
- Hard to review effectively
- Difficult to bisect for bugs
- Rollback affects unrelated changes

**Mitigation:**
- One feature = one PR
- Commit after each logical step
- If scope grows, split into multiple PRs

---

### PROC-002: Skipping Verification Steps

**Description:** Quality gates are bypassed for speed.

**Signals:**
- "We'll add tests later"
- "Skip ArchUnit, it's fine"
- "Manual testing is enough"

**Why it's risky:**
- Bugs ship to production
- Architecture erodes
- Technical debt compounds

**Mitigation:**
- Tests are not optional
- Run `./harness/run-arch-tests.sh` always
- Document any intentional skip with follow-up task

---

### PROC-003: Continuing Past Blockers

**Description:** Agent works around blockers rather than resolving them.

**Signals:**
- TODO comments for critical logic
- Mock/stub in production code
- Hardcoded values for missing config

**Why it's risky:**
- Workarounds become permanent
- Hidden dependencies on future work
- System in inconsistent state

**Mitigation:**
- Stop and document blocker
- Escalate if blocked > 30 minutes
- Never ship workarounds without tickets

---

## Integration Risk Patterns

### INTEG-001: External Service Dependencies

**Description:** Feature relies on external APIs or services.

**Signals:**
- HTTP calls to third-party APIs
- Database connections to external systems
- Message queue dependencies

**Why it's risky:**
- External service downtime affects us
- API changes can break integration
- Rate limits and quotas

**Mitigation:**
- Implement circuit breaker
- Cache where appropriate
- Have fallback behavior
- Monitor external service health

---

### INTEG-002: Synchronous External Calls in Transaction

**Description:** External service calls happen inside database transaction.

**Signals:**
- HTTP call between db.begin() and db.commit()
- External validation inside transaction
- Notification sent before commit

**Why it's risky:**
- Transaction held open for network latency
- Inconsistency if external succeeds but db fails
- Resource exhaustion under load

**Mitigation:**
- Make external calls outside transaction
- Use outbox pattern for reliable messaging
- Separate read and write paths

---

## Data Risk Patterns

### DATA-001: Schema Changes in Production

**Description:** Database schema modifications on live system.

**Signals:**
- ALTER TABLE in migration
- New NOT NULL columns
- Index creation on large tables

**Why it's risky:**
- Locks can block transactions
- Rollback may not be possible
- Data loss if migration fails

**Mitigation:**
- Use expand/contract pattern
- Test migrations on production-size data
- Have rollback script ready
- Schedule during low-traffic windows

---

### DATA-002: Bulk Data Operations

**Description:** Operations that affect large numbers of records.

**Signals:**
- UPDATE without LIMIT
- DELETE on large tables
- Mass insert operations

**Why it's risky:**
- Long-running transactions
- Replication lag
- Lock contention

**Mitigation:**
- Batch into smaller chunks
- Add delays between batches
- Run during off-peak hours
- Monitor database metrics

---

## Security Risk Patterns

### SEC-001: User Input in Sensitive Operations

**Description:** User-provided data used in queries, commands, or file operations.

**Signals:**
- String concatenation in SQL
- User input in shell commands
- File paths from request parameters

**Why it's risky:**
- SQL injection
- Command injection
- Path traversal

**Mitigation:**
- Use parameterized queries
- Never concatenate user input into commands
- Validate and sanitize all input
- Use allowlists, not denylists

---

### SEC-002: Secrets in Code or Logs

**Description:** Sensitive data exposed in source control or logs.

**Signals:**
- API keys in config files
- Passwords in log statements
- Tokens in error messages

**Why it's risky:**
- Credentials leaked to attackers
- Compliance violations
- Difficult to rotate once exposed

**Mitigation:**
- Use secret management (Vault, env vars)
- Review logs for sensitive data
- Mask secrets in output
- Scan repos for leaked secrets

---

## Adding New Risk Patterns

When a new risk pattern is identified:

1. Create entry with unique ID (CATEGORY-NNN)
2. Describe signals that indicate the pattern
3. Explain why it's risky
4. Document mitigation strategies
5. Have Retro Agent link to incidents that revealed it
