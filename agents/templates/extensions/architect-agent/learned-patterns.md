# Learned Architectural Patterns

Patterns extracted from retrospectives and validated learnings.

> [!NOTE]
> This file is maintained by the **Curator Agent**. Entries are extracted from `learning-playbook.md` after validation.

---

## Structural Patterns

### Pattern: Spring Data Neo4j Custom Repository Fragments for Projections

When implementing Neo4j repository queries that return projections, use custom repository fragments with manual mapping instead of relying on Spring Data Neo4j's automatic projection mapping with `@Query` annotations.

- **Trigger**: `MappingException` or `Neo4jPersistenceExceptionTranslator` warnings when using `@Query` with projection return types
- **Problem**: Spring Data Neo4j's automatic projection mapping can fail unpredictably, especially with nullable fields or complex type conversions
- **Solution**: Create a custom repository fragment interface and implementation class that uses `Neo4jClient` with `.fetchAs()` and `.mappedBy()` for explicit mapping
- **Evidence**: 
  - Financial metrics endpoint (2026-01-01): `@Query` with `FinancialMetricProjection` caused `MappingException`
  - Executives endpoint: Already using custom fragment pattern successfully
  - Pattern validated across multiple projection queries
- **Example**:
  ```kotlin
  // Fragment interface
  interface CompanyFinancialMetricRepository {
      fun findFinancialMetricsForCompany(ticker: String): List<FinancialMetricProjection>
  }
  
  // Fragment implementation
  class CompanyFinancialMetricRepositoryImpl(private val neo4jClient: Neo4jClient): CompanyFinancialMetricRepository {
      override fun findFinancialMetricsForCompany(ticker: String): List<FinancialMetricProjection> {
          return neo4jClient.query("""
              MATCH (c:Company {ticker: $ticker})-[:REPORTED]->(fm:FinancialMetric)
              RETURN fm.company as ticker, fm.year as year, ...
          """.trimIndent())
          .bind(ticker).to("ticker")
          .fetchAs(FinancialMetricProjection::class.java)
          .mappedBy { _, record ->
              FinancialMetricProjection(
                  ticker = record.get("ticker")?.asString(),
                  year = record.get("year")?.asInt(),
                  ...
              )
          }
          .all().toList()
      }
  }
  
  // Main repository extends the fragment
  interface CompanyRepository : Neo4jRepository<CompanyEntity, String>,
      CompanyFinancialMetricRepository { ... }
  ```

<!-- Curator Agent: Add validated structural patterns here -->
<!-- Example:
### Pattern: Centralized Authorization Guard
When implementing data access, use a centralized authorization service rather than inline checks.
- **Trigger**: Any feature accessing user-owned data
- **Evidence**: SEC-001 retrofit, 100% endpoint coverage
-->

---

## Anti-Patterns

<!-- Curator Agent: Add validated anti-patterns here -->
<!-- Example:
### Anti-Pattern: Cross-Layer Reach-Through
Direct controller-to-repository calls bypass business rules.
- **Detection**: Architecture tests for layer violations
- **Fix**: Route through service layer
-->

---

## Boundary Rules

<!-- Curator Agent: Add validated boundary rules here -->
<!-- Example:
### Rule: Domain Independence
Domain layer must not depend on infrastructure types.
- **Enforcement**: ArchUnit tests
-->

---

## Debt Patterns

<!-- Curator Agent: Add validated debt patterns here -->
