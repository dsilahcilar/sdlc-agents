# Custom Skills

Project-specific skills that agents load on-demand using Progressive Disclosure.

---

## How It Works

Skills provide domain knowledge, patterns, and tools that agents can load when relevant to the current task. Unlike extensions (which are behavioral rules), skills are **capabilities and knowledge**.

---

## Structure

```
skills/
├── README.md              # This registry
├── domain/                # Domain-specific skills
│   └── *.md               # e.g., payments.md, compliance.md
├── patterns/              # Custom architecture patterns
│   └── *.md               # e.g., saga-pattern.md, cqrs.md
└── tools/                 # Custom project tools
    ├── *.md               # Tool descriptions
    └── *.sh               # Tool scripts
```

---

## Priority Order

Skills are loaded in this order (later supplements earlier):

1. Core skills (`agents/skills/`)
2. Custom skills (`extensions/skills/`)

---

## Skill Format

Each skill file should include:

```markdown
# <Skill Name>

Brief description of what this skill provides.

---

## When to Use

- <situation when this skill applies>

## Key Concepts

- **<Concept>**: <definition>

## Patterns

<patterns or approaches this skill teaches>

## Tools

| Tool | Purpose |
|------|---------|
| `path/to/tool.sh` | What it does |

## Examples

<concrete examples of applying this skill>

## Related Skills

- `<other-skill>` - <relationship>
```

---

## Example: Domain Skill

Create `domain/payments.md`:

```markdown
# Payments Domain

Knowledge for implementing payment-related features.

---

## When to Use

- Implementing payment flows
- Handling transactions
- Working with payment providers

## Key Concepts

- **Idempotency**: Every payment operation must be safely retryable
- **Audit Trail**: All state changes require logging

## Invariants

- Never log card numbers or CVV
- Always use transactions for state changes
- Validate amounts are positive before processing

## Common Patterns

- Use saga pattern for multi-step payments
- Implement compensating transactions for rollback
```

---

## Example: Pattern Skill

Create `patterns/saga-pattern.md`:

```markdown
# Saga Pattern

Skill for implementing distributed transactions using the saga pattern.

---

## When to Use

- Multi-service transactions
- Long-running business processes
- Operations requiring compensation on failure
```

---

## Example: Custom Tool

Create `tools/internal-api.md` and `tools/internal-api.sh`:

```markdown
# Internal API Client

Tool for interacting with internal company APIs.

## Usage

./agent-context/extensions/skills/tools/internal-api.sh <endpoint>

## Output

JSON response from the API.
```

---

## More Use Case Examples

### Example: Testing/QA Skill

Create `domain/bdd-testing.md`:

```markdown
# BDD Testing Skill

Knowledge for implementing Behavior-Driven Development testing patterns.

---

## When to Use

- Writing acceptance tests for new features
- Translating user stories to executable specs
- Creating end-to-end test scenarios

## Key Concepts

- **Given-When-Then**: Structure for describing behavior
- **Feature Files**: Human-readable test specifications
- **Step Definitions**: Code that executes feature steps

## Invariants

- One scenario per business rule
- Step definitions must be reusable
- Never put implementation details in feature files

## Patterns

### Scenario Outline for Data-Driven Tests

```gherkin
Scenario Outline: Validate user age
  Given a user with age <age>
  When the age is validated
  Then the result should be <result>

  Examples:
    | age | result  |
    | 17  | invalid |
    | 18  | valid   |
    | 65  | valid   |
```

## Tools

| Tool | Purpose |
|------|---------|
| `tools/generate-steps.sh` | Generate step definition stubs |
| `tools/run-bdd.sh` | Execute BDD test suite |
```

---

### Example: Security Skill

Create `domain/security-owasp.md`:

```markdown
# OWASP Security Skill

Security patterns based on OWASP Top 10 guidelines.

---

## When to Use

- Implementing authentication/authorization
- Handling user input
- Storing sensitive data
- API security

## Key Concepts

- **Input Validation**: Never trust user input
- **Output Encoding**: Prevent injection attacks
- **Least Privilege**: Minimize access rights

## Invariants

- All user input must be validated server-side
- Passwords stored using bcrypt/argon2 (never MD5/SHA1)
- SQL queries must use parameterized statements
- Secrets never committed to code

## Common Vulnerabilities & Fixes

| Vulnerability | Pattern |
|--------------|---------|
| SQL Injection | Use parameterized queries or ORM |
| XSS | Encode output, use CSP headers |
| CSRF | Use anti-CSRF tokens |
| Broken Auth | Use established auth libraries |

## Code Examples

### ❌ Vulnerable

```java
String query = "SELECT * FROM users WHERE id = " + userId;
```

### ✅ Secure

```java
PreparedStatement stmt = conn.prepareStatement(
    "SELECT * FROM users WHERE id = ?"
);
stmt.setInt(1, userId);
```
```

---

### Example: Integration Skill

Create `domain/kafka-integration.md`:

```markdown
# Kafka Integration Skill

Patterns for Apache Kafka-based event streaming.

---

## When to Use

- Implementing event-driven architecture
- Async communication between services
- Event sourcing / CQRS

## Key Concepts

- **Topics**: Named channels for messages
- **Partitions**: Parallelism within topics
- **Consumer Groups**: Scalable message processing
- **Idempotency**: Handle duplicate messages

## Invariants

- Always set `acks=all` for critical messages
- Consumer processors must be idempotent
- Dead letter queues for failed messages
- Schema registry for event contracts

## Patterns

### Transactional Outbox

```
1. Write to DB + outbox table in single transaction
2. Background process polls outbox
3. Publishes to Kafka
4. Marks outbox entry as sent
```

### Consumer Error Handling

```
1. Attempt processing
2. On failure: retry with backoff (3 attempts)
3. On exhausted retries: send to DLQ
4. Alert on DLQ threshold
```

## Tools

| Tool | Purpose |
|------|---------|
| `tools/kafka-topics.sh` | List/create topics |
| `tools/kafka-consume.sh` | Consume messages for debugging |
```

---

### Example: Legacy Migration Skill

Create `domain/legacy-migration.md`:

```markdown
# Legacy Migration Skill

Patterns for safely migrating legacy code to modern architectures.

---

## When to Use

- Replacing monolith components
- Database migrations
- API versioning
- Strangler fig pattern implementations

## Key Concepts

- **Strangler Fig**: Gradually replace legacy with new system
- **Branch by Abstraction**: Switch implementations behind interface
- **Parallel Run**: Run old and new simultaneously, compare results

## Invariants

- Never big-bang migrations
- Always have rollback plan
- Feature flags for gradual rollout
- Comprehensive logging during transition

## Patterns

### Strangler Fig Steps

```
1. Identify seam in legacy system
2. Create façade/proxy in front of legacy
3. Implement new functionality
4. Route traffic gradually (10% → 50% → 100%)
5. Decommission legacy component
```

### Database Migration Strategy

```
1. Add new columns (nullable)
2. Dual-write to old and new
3. Backfill historical data
4. Switch reads to new columns
5. Drop old columns (after verification period)
```

## Checklist

- [ ] Migration can be paused/resumed
- [ ] Rollback tested in staging
- [ ] Monitoring in place for both paths
- [ ] Runbook documented
```

---

## End-to-End Workflow: How Agents Use Custom Skills

This shows the complete flow of how an agent discovers and uses a custom skill.

### Scenario

User asks: *"Implement a payment retry mechanism for failed transactions"*

### Step 1: Agent Reads Skill Registry

The agent first reads `extensions/skills/README.md` to discover available skills:

```
Available custom skills:
├── domain/
│   ├── payments.md          ← Relevant!
│   └── kafka-integration.md
├── patterns/
│   └── saga-pattern.md      ← Relevant!
└── tools/
    └── internal-api.sh
```

### Step 2: Agent Loads Relevant Skills

Based on the task, agent loads:
- `domain/payments.md` — For payment domain knowledge
- `patterns/saga-pattern.md` — For retry/compensation patterns

### Step 3: Agent Applies Skill Knowledge

From the skills, the agent learns:
- Payments must be idempotent
- Use saga pattern for multi-step operations
- Implement compensating transactions

### Step 4: Agent References Tools

Agent sees `tools/internal-api.sh` for interacting with payment provider.

### Step 5: Implementation

Agent implements the feature applying learned patterns:

```java
@Service
public class PaymentRetryService {
    
    // From payments.md: idempotency key
    public void retryPayment(String idempotencyKey, PaymentRequest request) {
        // From saga-pattern.md: compensation logic
        try {
            processPayment(request);
        } catch (PaymentException e) {
            compensate(idempotencyKey);
            throw e;
        }
    }
}
```

### Key Takeaways

1. **Discovery**: Agent checks `README.md` first
2. **Selective Loading**: Only loads relevant skills
3. **Pattern Application**: Applies invariants and patterns from skills
4. **Tool Usage**: Uses custom tools when available

---

## Troubleshooting

### Skill Not Being Loaded

**Symptom**: Agent doesn't seem to know about your custom skill.

**Causes & Fixes**:

| Cause | Fix |
|-------|-----|
| Skill not in `extensions/skills/` | Move file to correct directory |
| Missing from README registry | Add entry to `extensions/skills/README.md` |
| "When to Use" section unclear | Add specific trigger keywords |

### Skill Conflicts with Core Skills

**Symptom**: Agent applies wrong pattern or contradictory advice.

**Fix**: Custom skills supplement (not override) core skills. To override:

```markdown
## Overrides

> [!IMPORTANT]
> This skill **overrides** the default pattern from `stacks/java.md`.

Use `@Transactional` at service layer, NOT repository layer.
```

### Agent Ignoring Skill Invariants

**Symptom**: Agent generates code that violates your skill's rules.

**Causes & Fixes**:

| Cause | Fix |
|-------|-----|
| Invariants buried in text | Move to dedicated `## Invariants` section |
| Too many invariants | Keep to 3-5 most critical rules |
| Vague invariants | Make rules specific and actionable |

**Example of improving invariants**:

```markdown
# ❌ Vague
- Handle errors properly

# ✅ Specific  
- All repository methods must throw `DomainException`, never infrastructure exceptions
```

### Tool Script Fails

**Symptom**: Custom tool script returns error.

**Checklist**:
- [ ] Script has execute permission (`chmod +x script.sh`)
- [ ] Shebang line present (`#!/bin/bash`)
- [ ] Required dependencies installed
- [ ] Paths are relative to project root

### Skill Too Large

**Symptom**: Agent responses become slow or truncated.

**Fix**: Split into focused sub-skills:

```
# Before
domain/payments.md (2000+ lines)

# After  
domain/payments-core.md      (basics)
domain/payments-providers.md (Stripe, PayPal specifics)
domain/payments-compliance.md (PCI-DSS rules)
```

---

## Tips

1. **Keep skills focused** — One domain/pattern per file
2. **Include examples** — Concrete > abstract
3. **Link to tools** — Reference executable scripts when available
4. **Explain "why"** — Context helps agents apply skills correctly
5. **Update from retros** — Add learnings from past implementations
6. **Test your skills** — Ask the agent about a scenario and verify it uses the skill correctly
7. **Version your skills** — Use git to track changes as you refine them
