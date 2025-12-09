# Risk Patterns

> "The memory retrieval score: Importance, Relevance. This factor assigns a higher score to memory objects that are related to the agent's current situation."

Risk patterns help agents identify high-importance situations that require extra attention.

**Template Location:** [`agents/templates/context/risk-patterns.md`](../../../agents/templates/context/risk-patterns.md)

---

## Purpose

This file catalogs recurring risk patterns that agents should actively watch for during planning, coding, and review. It helps agents identify situations that historically lead to problems.

---

## How Agents Use This File

| Agent | Role |
|-------|------|
| **Planning Agent** | Reads this file and includes relevant risks in the context file |
| **Architect Agent** | Reads this file to evaluate risk exposure in plans |
| **Coding Agent** | Receives curated risks via the context file |
| **Code Review Agent** | Flags changes that match risk patterns |
| **Retro Agent** | Adds new risk patterns when incidents occur |

---

## Risk Categories

| Category | ID Prefix | Focus |
|----------|-----------|-------|
| **Structural Risk** | `STRUCT-` | Architecture and design concerns |
| **Process Risk** | `PROC-` | Development workflow issues |
| **Integration Risk** | `INTEG-` | External system interactions |
| **Data Risk** | `DATA-` | Data handling and integrity |
| **Security Risk** | `SEC-` | Vulnerabilities and threats |

---

## Pattern Structure

Each risk pattern follows this template:

```markdown
### <CATEGORY>-NNN: <Pattern Name>

**Description:** <What this risk pattern is>

**Signals:**
- <indicator that this pattern is present>

**Why it's risky:**
- <consequence of ignoring this>

**Mitigation:**
- <action to reduce risk>
```

---

## Common Risk Patterns Reference

These are common patterns the Initializer Agent should look for:

### Structural Risks
| ID | Pattern | Signals |
|----|---------|---------|
| STRUCT-001 | Cross-Module Feature | Changes across 3+ modules |
| STRUCT-002 | Domain-Infrastructure Coupling | Domain using DB/HTTP directly |
| STRUCT-003 | Shared Mutable State | Static mutable fields, global caches |

### Process Risks
| ID | Pattern | Signals |
|----|---------|---------|
| PROC-001 | Large Multi-File Changes | 10+ files changed |
| PROC-002 | Skipping Verification | Tests/quality gates bypassed |
| PROC-003 | Continuing Past Blockers | TODOs for critical logic |

### Integration Risks
| ID | Pattern | Signals |
|----|---------|---------|
| INTEG-001 | External Service Deps | Third-party API calls |
| INTEG-002 | Sync Calls in Transaction | HTTP inside DB transaction |

### Data Risks
| ID | Pattern | Signals |
|----|---------|---------|
| DATA-001 | Schema Changes | ALTER TABLE, migrations |
| DATA-002 | Bulk Operations | UPDATE/DELETE without LIMIT |

### Security Risks
| ID | Pattern | Signals |
|----|---------|---------|
| SEC-001 | User Input in Sensitive Ops | String concat in SQL/commands |
| SEC-002 | Secrets in Code/Logs | API keys, passwords in source |

---

## Customization

After the Initializer Agent copies this file to `<project-root>/agent-context/context/risk-patterns.md`:

1. **Analyze project structure** for risk indicators
2. **Add project-specific patterns** based on:
   - Technology stack (e.g., specific framework risks)
   - Business domain (e.g., compliance requirements)
   - Past incidents (via Retro Agent)
3. **Remove the placeholder example**
4. **Link to relevant modules** where risks are likely

---

## Why This Matters

Without risk patterns, agents may:
- Underestimate complexity of cross-module changes
- Not recognize when they're touching sensitive areas
- Miss common pitfalls for the technology stack
- Repeat mistakes from past incidents

These are situational awareness signals that help agents be appropriately cautious.
