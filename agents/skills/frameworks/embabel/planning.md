# Embabel Framework - Planning Agent Guide

## Purpose

This guide helps the Planning Agent create well-structured tasks for implementing Embabel agents. It ensures tasks include all necessary context for the Coding Agent to implement agents correctly.

## Task Planning Checklist

When creating tasks for Embabel agent implementation, ensure each task includes:

### 1. Agent Definition Requirements

**Must Include:**
- Clear agent description (what it does, its capabilities, approach)
- List of dependencies to inject (services, repositories, properties)
- Expected input types
- Goal achievement criteria

**Example Task Section:**
```markdown
## Agent Definition

Create `MarketAnalyst` agent with:
- Description: "Conducts comprehensive market intelligence analysis for stock tickers"
- Dependencies: `FinanceAnalystProperties`, `ReportService`
- Input: `UserInput` containing ticker symbol
- Goal: Produces `MarketAnalyseReport` saved to disk
```

### 2. Action Breakdown

**Must Include:**
- List of all actions with clear names
- Purpose of each action
- Input parameters for each action
- Return type for each action (must be distinct!)
- Tool groups required (e.g., `CoreToolGroups.WEB`)
- Pre/post conditions if applicable

**Example Task Section:**
```markdown
## Actions to Implement

1. **extractResearchRequest**
   - Purpose: Parse user input into structured request
   - Input: `UserInput`, `OperationContext`
   - Returns: `ResearchRequest`
   - LLM: Use `CHEAPEST_ROLE` (simple extraction)

2. **collectSECFilings**
   - Purpose: Gather SEC filings for ticker
   - Input: `ResearchRequest`, `OperationContext`
   - Returns: `SECFilingsData`
   - Tool Groups: `CoreToolGroups.WEB`
   - LLM: Use `BEST_ROLE`

3. **synthesizeReport**
   - Purpose: Combine all data into final report
   - Input: `MarketData`, `OperationContext`
   - Returns: `MarketAnalyseReport`
   - LLM: Use `BEST_ROLE` (complex reasoning)
   - Optional: `clearBlackboard = true` if intermediate data not needed after
```

### 3. Data Model Definitions

**Must Include:**
- All data classes needed
- Field names and types
- Immutability requirements
- Null safety considerations

**Example Task Section:**
```markdown
## Data Models

Create these immutable data classes:

\`\`\`kotlin
data class ResearchRequest(
    val ticker: String,
    val maxDataAgeDays: Int = 7,
    val targetResultCount: Int = 10
)

data class SECFilingsData(
    val filings: List<DataPoint>
)

data class NewsData(
    val newsItems: List<DataPoint>
)

data class MarketData(
    val ticker: String,
    val secFilings: List<DataPoint>,
    val newsItems: List<DataPoint>
)
\`\`\`
```

### 4. State Management

**Must Include:**
- Pre/post conditions if used
- Output bindings if used
- Condition methods

**Example Task Section:**
```markdown
## State Management

Define these conditions:

\`\`\`kotlin
companion object {
    object ReportStates {
        const val RISK_PROFILE = "riskProfile"
        const val INVESTMENT_PERIOD = "investmentPeriod"
    }
}

@Condition(name = ReportStates.RISK_PROFILE)
fun riskProfile(riskProfile: RiskProfile?) = riskProfile != null
\`\`\`

Use in actions:
- `promptUserToDefineRiskProfile`: post = [ReportStates.RISK_PROFILE]
- `generateReport`: pre = [ReportStates.RISK_PROFILE]
```

### 5. Testing Requirements

**Must Include:**
- Unit test requirements
- Integration test requirements
- Key scenarios to test

**Example Task Section:**
```markdown
## Testing Requirements

### Unit Tests
Create `MarketAnalystTest`:
- Test prompt content for each action
- Verify LLM model selection (CHEAPEST vs BEST)
- Test null handling and validation
- Mock all dependencies

### Integration Tests
Create `MarketAnalystIntegrationTest` extending `EmbabelMockitoIntegrationTest`:
- Test complete workflow from UserInput to saved report
- Stub all LLM calls with `whenCreateObject()`
- Verify execution order
- Test error handling
```

### 6. Architecture Compliance

**Must Include:**
- Reference to architecture tests
- Layer placement (if hexagonal architecture)
- Dependency rules

**Example Task Section:**
```markdown
## Architecture Compliance

- Place agent in `application.agent` package
- For event-driven systems without clear goals, consider using `@EmbabelComponent` with Utility AI planner
- Agent may depend on domain services and repositories
- Run architecture tests: `./mvnw test -Dtest=ArchitectureTest`
- Ensure no violations of hexagonal architecture rules
```

### 7. Configuration

**Must Include:**
- Configuration properties needed
- Default values
- Property file updates

**Example Task Section:**
```markdown
## Configuration

Add to `application.properties`:

\`\`\`properties
finance.analyst.analysis-model=gpt-4
finance.analyst.critic-model=claude-3-opus
finance.analyst.max-data-age-days=7
\`\`\`

Create configuration class:

\`\`\`kotlin
@ConfigurationProperties(prefix = "finance.analyst")
data class FinanceAnalystProperties(
    val analysisModel: String,
    val criticModel: String,
    val maxDataAgeDays: Int = 7
)
\`\`\`
```

## Critical Reminders for Tasks

### Framework Orchestration Pattern

**ALWAYS emphasize in tasks:**

> ⚠️ **CRITICAL**: Do NOT manually call `@Action` methods from within other actions. Let the Embabel framework orchestrate action execution.
>
> **WRONG:**
> ```kotlin
> @Action
> fun combineData(request: ResearchRequest, context: OperationContext): MarketData {
>     val filings = collectSECFilings(request, context)  // ❌ Manual call
>     val news = collectNews(request, context)            // ❌ Manual call
>     return MarketData(filings, news)
> }
> ```
>
> **CORRECT:**
> ```kotlin
> @Action
> fun combineData(
>     request: ResearchRequest,
>     secFilingsData: SECFilingsData,  // ← Framework calls collectSECFilings()
>     newsData: NewsData,               // ← Framework calls collectNews()
>     context: OperationContext
> ): MarketData {
>     return MarketData(secFilingsData.filings, newsData.newsItems)
> }
> ```

### Distinct Return Types

**ALWAYS emphasize in tasks:**

> ⚠️ **CRITICAL**: Each action must return a DISTINCT type. Do not use generic types like `Map<String, Any>` or reuse the same type across multiple actions.
>
> The framework uses return types to determine data flow and execution order. If multiple actions return the same type, the framework cannot distinguish between them.

### Immutability

**ALWAYS emphasize in tasks:**

> ⚠️ All data classes must use `val` (immutable) properties, not `var` (mutable). This ensures thread safety and predictable behavior.

## Task Template Integration

When using `task-template.md`, populate these sections:

### Implementation Details Section

```markdown
## Implementation Details

### Agent Structure
[Agent class definition with dependencies]

### Actions
[Detailed action breakdown as shown above]

### Data Models
[All data classes needed]

### State Management
[Conditions and bindings if applicable]
```

### Testing Section

```markdown
## Testing Requirements

### Unit Tests
[Specific test cases and assertions]

### Integration Tests
[Workflow tests with stubbing examples]

### Test Data
[Sample inputs and expected outputs]
```

### Architecture Validation Section

```markdown
## Architecture Validation

Run these commands to verify compliance:

\`\`\`bash
# Run architecture tests
./mvnw test -Dtest=ArchitectureTest

# Run agent tests
./mvnw test -Dtest=MarketAnalystTest
./mvnw test -Dtest=MarketAnalystIntegrationTest
\`\`\`

Expected: All tests pass with no architecture violations.
```

## Common Pitfalls to Address in Tasks

### 1. Vague Action Descriptions

**BAD:**
```markdown
Create actions to collect data and generate report.
```

**GOOD:**
```markdown
Create these specific actions:
1. `collectSECFilings` - Returns `SECFilingsData`
2. `collectNews` - Returns `NewsData`
3. `combineData` - Accepts both above types, returns `MarketData`
4. `synthesizeReport` - Accepts `MarketData`, returns `MarketAnalyseReport`
```

### 2. Missing LLM Configuration

**BAD:**
```markdown
Use LLM to extract data.
```

**GOOD:**
```markdown
Use `context.ai().withLlmByRole(CHEAPEST_ROLE)` for simple extraction tasks.
Use `context.ai().withLlmByRole(BEST_ROLE)` for complex reasoning tasks.
Configure models in `FinanceAnalystProperties`.
```

### 3. Unclear Data Flow

**BAD:**
```markdown
Implement data collection and processing.
```

**GOOD:**
```markdown
Data flow:
1. `UserInput` → `extractResearchRequest()` → `ResearchRequest`
2. `ResearchRequest` → `collectSECFilings()` → `SECFilingsData`
3. `ResearchRequest` → `collectNews()` → `NewsData`
4. `ResearchRequest` + `SECFilingsData` + `NewsData` → `combineData()` → `MarketData`
5. `MarketData` → `synthesizeReport()` → `MarketAnalyseReport`
6. `MarketAnalyseReport` → `saveReport()` → `Boolean` (goal achieved)
```

## Example Complete Task Specification

See `best-practices.md` for complete agent implementation examples that demonstrate all these principles in action.

## New Features in Embabel 0.3.1

### @EmbabelComponent for Event-Driven Systems
When creating tasks for event-driven systems without predetermined goals:

```markdown
## Agent Type: Event-Driven Component

Use `@EmbabelComponent` instead of `@Agent` for this implementation.
This component will use Utility AI planner to select actions based on value.

### Actions
Each action should specify:
- `value`: Relative value (0-1) for action selection
- `pre`: Preconditions using SpEL expressions
- `outputBinding`: Named outputs for state tracking
```

### clearBlackboard Attribute
When planning multi-step workflows where intermediate data should be discarded:

```markdown
## State Management

Action `preprocessData` should use `clearBlackboard = true` to remove
intermediate processing artifacts before final synthesis.
```

### Agent Skills Integration
When tasks require reusable capabilities:

```markdown
## Skills Integration

Load financial analysis skills:
\`\`\`kotlin
val skills = Skills("financial-skills", "Financial analysis skills")
    .withGitHubUrl("https://github.com/wshobson/agents/tree/main/plugins/business-analytics/skills")
\`\`\`

Use in actions via `context.ai().withReference(skills)`
```

### RAG Support
When tasks require knowledge base integration:

```markdown
## RAG Integration

Create RAG reference for knowledge base access:
\`\`\`kotlin
val ragStore = ToolishRag(searchOperations)
\`\`\`

Use in actions for agentic retrieval with autonomous search,
iterative refinement, and cross-reference discovery.
```

## References

- **best-practices.md**: Comprehensive patterns and anti-patterns
- **reference.md**: Framework API and configuration reference
- **testing.md**: Testing strategies and examples
- [Embabel Documentation](https://docs.embabel.com/embabel-agent/guide/0.3.1/)
