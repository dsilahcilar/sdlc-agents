# Microservices Skill

Skill for microservices architecture. Provides guidance for building and maintaining distributed, independently deployable services.

---

## When to Use

| Scenario | Why Microservices |
|----------|-------------------|
| Large organization (> 50 devs) | Team autonomy and independent deployment |
| Proven, stable domain boundaries | Bounded contexts are well understood |
| Need independent scaling | Scale services based on load |
| Polyglot requirements | Different services, different tech stacks |
| High availability requirements | Isolate failures to individual services |

**Skip when:** Small team, uncertain domain boundaries, need simple operations, or tight deadlines.

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Service** | Independently deployable unit with single responsibility |
| **Bounded Context** | DDD concept defining service scope |
| **API Contract** | Explicit interface between services |
| **Data Ownership** | Each service owns its data exclusively |
| **Eventual Consistency** | Accept data sync delays across services |

---

## Workflow

### Phase 1: Planning (Planning Agent)

When creating a feature with `#microservices`:

1. Identify owning service(s)
2. Define API contract changes
3. Document cross-service interactions
4. Plan for eventual consistency

### Phase 2: Design (Architect Agent)

1. Verify service boundaries align with bounded contexts
2. Review API contract for backward compatibility
3. Assess failure scenarios and resilience

### Phase 3: Implementation (Coding Agent)

1. Implement within owning service
2. Version API changes appropriately
3. Add circuit breakers for external calls
4. Implement event publishing if needed

### Phase 4: Review (Code Review Agent)

1. Check API versioning and compatibility
2. Verify error handling for network failures
3. Confirm observability (logs, traces, metrics)

---

## Invariants

| Invariant | Action on Violation |
|-----------|---------------------|
| Services don't share databases | Introduce API, replicate data via events |
| API changes are backward compatible | Use versioning, deprecation strategy |
| Cross-service calls handle failures | Add circuit breaker, fallback, retry |
| Each service has observability | Add structured logging, tracing, metrics |
| Service owns its bounded context | Clarify boundaries or merge services |

---

## Patterns

### Service Structure

```
order-service/
├── src/
│   ├── api/                   # REST/gRPC endpoints
│   │   ├── v1/                # API version 1
│   │   └── v2/                # API version 2
│   ├── domain/                # Business logic
│   ├── application/           # Use cases
│   ├── infrastructure/
│   │   ├── persistence/       # This service's database
│   │   ├── messaging/         # Event publishing/consuming
│   │   └── clients/           # Other service clients
│   └── config/
├── api-contracts/             # OpenAPI/Protobuf definitions
└── docker/
```

### Communication Patterns

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Sync (REST/gRPC)** | Need immediate response | Get user profile |
| **Async (Events)** | Fire-and-forget, eventual consistency | Order placed → Notify shipping |
| **Saga** | Distributed transaction | Multi-service order fulfillment |
| **Query (CQRS)** | Cross-service reads | Aggregate data from multiple services |

### Resilience Patterns

| Pattern | Purpose |
|---------|---------|
| **Circuit Breaker** | Stop cascading failures |
| **Retry with Backoff** | Handle transient errors |
| **Bulkhead** | Isolate resource pools |
| **Timeout** | Prevent blocked threads |
| **Fallback** | Graceful degradation |

---

## Data Patterns

### Data Ownership

| Pattern | Description |
|---------|-------------|
| **Database per Service** | Exclusive ownership, no sharing |
| **Event Sourcing** | Store events, derive state |
| **CQRS** | Separate read/write models |
| **Data Replication** | Subscribe to events, maintain local copy |

### Cross-Service Queries

```
❌ BAD: Service A queries Service B's database directly
✓ GOOD: Service A calls Service B's API or subscribes to events
```

---

## Observability

| Pillar | Tool Examples | What to Capture |
|--------|---------------|-----------------|
| **Logs** | ELK, Loki | Request ID, user ID, operation, outcome |
| **Traces** | Jaeger, Zipkin | Cross-service request flow |
| **Metrics** | Prometheus, Datadog | Latency, error rate, throughput |

### Correlation

All services must propagate `X-Correlation-ID` header for request tracing.

---

## Common Issues

| Issue | Resolution |
|-------|------------|
| Distributed monolith | Reduce coupling, embrace eventual consistency |
| Chatty services (too many calls) | Batch requests, use events, cache |
| Inconsistent data across services | Accept eventual consistency, add reconciliation |
| Deployment coordination needed | Use API versioning, feature flags |
| Hard to debug cross-service issues | Ensure distributed tracing is in place |
