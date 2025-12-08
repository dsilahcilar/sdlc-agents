# Domain Heuristics

This file contains domain-specific principles, patterns, and invariants that agents should consider when working in particular business domains.

> "Brevity Bias causes abstraction that omits crucial, detailed information such as domain-specific heuristics, tool-use guidelines, or common failure modes necessary for agents and knowledge-intensive applications."

---

## How to Use This File

1. **Planning Agent** should check for relevant domain heuristics
2. **Context Builder** should extract applicable heuristics into task context
3. **Coding Agent** should respect domain invariants
4. **Retro Agent** should add new heuristics when discovered

---

## Domain Template

```markdown
## Domain: <Domain Name>

### Overview
<Brief description of this business domain>

### Key Concepts
- **<Concept 1>**: <definition>
- **<Concept 2>**: <definition>

### Invariants
These rules must NEVER be violated:
- <invariant 1>
- <invariant 2>

### Heuristics
Patterns that generally work well:
- <heuristic 1>
- <heuristic 2>

### Common Failure Modes
Mistakes frequently made in this domain:
- <failure mode 1>
- <failure mode 2>

### Related Modules
- `<module path 1>`
- `<module path 2>`
```

---

## Domains

<!-- Add domain-specific heuristics below -->

---

## Domain: Authentication & Authorization

### Overview
User identity verification and access control.

### Key Concepts
- **Principal**: The authenticated user/system making a request
- **Credential**: Secret used to prove identity (password, token, key)
- **Permission**: Specific action allowed on a resource
- **Role**: Collection of permissions assigned to users

### Invariants
These rules must NEVER be violated:
- Never store plaintext passwords
- Never log credentials or tokens
- Always validate tokens before trusting claims
- Session invalidation must be immediate and complete
- Authorization checks must happen on every protected operation

### Heuristics
Patterns that generally work well:
- Keep authentication logic in a single, well-tested module
- Use established libraries rather than custom crypto
- Fail closed: deny access if authorization check fails for any reason
- Separate authentication (who are you?) from authorization (what can you do?)
- Use short-lived tokens with refresh mechanism

### Common Failure Modes
Mistakes frequently made in this domain:
- Checking permissions in UI but not in API
- Trusting client-provided user IDs
- Logging too much (exposing tokens) or too little (no audit trail)
- Time-based token vulnerabilities (expiration bypass, clock skew)
- Session fixation after authentication

### Related Modules
- `src/main/*/auth/`
- `src/main/*/security/`

---

## Domain: Payments & Transactions

### Overview
Financial operations, money movement, and transactional integrity.

### Key Concepts
- **Transaction**: Atomic unit of work that succeeds or fails completely
- **Idempotency**: Same operation produces same result if repeated
- **Reconciliation**: Verifying internal state matches external reality
- **Ledger**: Immutable record of all transactions

### Invariants
These rules must NEVER be violated:
- Money operations must be atomic and consistent
- Never delete transaction records (append-only)
- All money operations must be idempotent
- Currency must always be explicit (no implicit defaults)
- Decimal precision must be preserved (no floating point for money)

### Heuristics
Patterns that generally work well:
- Use database transactions for atomicity
- Generate idempotency keys client-side, validate server-side
- Store amounts in smallest currency unit (cents, not dollars)
- Log every state transition with timestamps
- Implement retry with exponential backoff for external services

### Common Failure Modes
Mistakes frequently made in this domain:
- Using float/double for monetary amounts
- Missing idempotency leading to duplicate charges
- Partial failures leaving inconsistent state
- Race conditions in concurrent updates
- Inadequate reconciliation processes

### Related Modules
- `src/main/*/payment/`
- `src/main/*/billing/`
- `src/main/*/transaction/`

---

## Domain: Inventory & Stock

### Overview
Tracking quantities, availability, and movement of items.

### Key Concepts
- **SKU**: Stock Keeping Unit - unique product identifier
- **Reservation**: Temporary hold on inventory for pending order
- **Allocation**: Assignment of inventory to fulfill order
- **Backorder**: Order accepted when stock is unavailable

### Invariants
These rules must NEVER be violated:
- Quantity can never be negative (unless explicitly modeling debt)
- Reservations must have expiration
- Stock movements must be traceable (audit trail)
- Concurrent updates must not oversell

### Heuristics
Patterns that generally work well:
- Separate available quantity from reserved quantity
- Use optimistic locking for inventory updates
- Batch inventory checks when possible (reduce contention)
- Event-source stock movements for complete audit trail

### Common Failure Modes
Mistakes frequently made in this domain:
- Race conditions causing overselling
- Orphaned reservations (never released)
- Inventory drift (actual vs. system mismatch)
- Missing warehouse/location dimension

### Related Modules
- `src/main/*/inventory/`
- `src/main/*/warehouse/`
- `src/main/*/stock/`

---

## Domain: Notifications & Messaging

### Overview
Sending communications to users across channels.

### Key Concepts
- **Channel**: Delivery method (email, SMS, push, in-app)
- **Template**: Reusable message format with placeholders
- **Delivery**: Attempt to send a notification
- **Preference**: User's choice about what/how to receive

### Invariants
These rules must NEVER be violated:
- Respect user opt-out preferences
- Never send without consent for marketing
- Rate limiting must prevent spam
- Sensitive data must not appear in notification logs

### Heuristics
Patterns that generally work well:
- Use queues for async delivery (don't block transactions)
- Implement idempotency to prevent duplicate sends
- Separate content generation from delivery
- Support fallback channels (SMS if push fails)

### Common Failure Modes
Mistakes frequently made in this domain:
- Blocking operations waiting for send confirmation
- Missing retry logic for transient failures
- Template injection vulnerabilities
- Ignoring timezone for scheduled notifications

### Related Modules
- `src/main/*/notification/`
- `src/main/*/messaging/`
- `src/main/*/email/`

---

## Adding New Domains

When adding a new domain:

1. Use the template structure above
2. Include at least 3 invariants
3. Include at least 3 heuristics
4. Include at least 3 common failure modes
5. Link to relevant module paths
6. Have Architect Agent review before committing
