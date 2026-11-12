# Embabel Framework Best Practices

## Table of Contents
1. [Overview](#overview)
2. [Agent Design Principles](#agent-design-principles)
3. [Action Design](#action-design)
4. [Data Flow & Type Safety](#data-flow--type-safety)
5. [LLM Integration](#llm-integration)
6. [State Management](#state-management)
7. [Testing & Debugging](#testing--debugging)
8. [Common Patterns](#common-patterns)
9. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Overview

Embabel is an agentic AI framework that enables building intelligent agents with automatic orchestration, state management, and LLM integration. The framework uses annotations to define agent capabilities and automatically chains actions to achieve goals.

### Core Concepts
- **Agent**: A class annotated with `@Agent` that encapsulates domain-specific logic
- **Action**: Methods annotated with `@Action` that represent discrete operations
- **Goal**: Methods annotated with `@AchievesGoal` that define end-user objectives
- **State**: Managed through pre/post conditions and output bindings
- **Context**: `OperationContext` provides access to AI capabilities and state

---

## Agent Design Principles

### 1. Single Responsibility
Each agent should focus on a specific domain or capability.

```kotlin
// ✅ GOOD: Focused agent with clear responsibility
@Agent(
    description = """
    Market analyst agent is responsible for conducting a comprehensive, 
    time-sensitive market intelligence analysis for a specified stock ticker.
    """
)
class MarketAnalyst(
    private val properties: FinanceAnalystProperties,
    private val reportService: ReportService
)

// ❌ BAD: Agent trying to do too much
@Agent(description = "Does everything related to finance")
class FinanceAgent // Too broad, unclear responsibility
```

### 2. Clear Agent Description
Provide detailed descriptions that explain the agent's purpose, capabilities, and approach.

```kotlin
@Agent(
    description = """
    Graph market analyst agent is responsible for creating a knowledge graph 
    representation of a stock's ecosystem. It reads news, reports, and SEC 
    filings to extract entities (Company, Product, Competitor) and relationships.
    
    Phase 2 Implementation:
    - Uses Spring Data Neo4j repositories for direct database persistence
    - Eliminates manual Cypher script generation (deprecated but still available)
    - Provides type-safe, transactional database operations
    """
)
class GraphMarketAnalyst(...)
```

### 3. Dependency Injection
Use constructor injection for all dependencies. This improves testability and makes dependencies explicit.

```kotlin
// ✅ GOOD: Clear dependencies via constructor
@Agent(description = "...")
class TradingAnalyst(
    private val properties: FinanceAnalystProperties,
    private val chatService: FeedbackDrivenChatService,
    private val tradeReportGenerator: TradeReportGenerator,
    private val reportService: ReportService
)

// ❌ BAD: Hidden dependencies
@Agent(description = "...")
class TradingAnalyst {
    private val reportService = ReportService() // Hard to test
}
```

---

## Action Design

### 1. Granular Actions
Break down complex operations into smaller, focused actions. This improves context window management and reusability.

```kotlin
// ✅ GOOD: Granular, focused actions
@Action(toolGroups = [CoreToolGroups.WEB])
fun collectGraphSecFilings(
    researchRequest: ResearchRequest,
    context: OperationContext
): SECFilingsData { ... }

@Action(toolGroups = [CoreToolGroups.WEB])
fun collectGraphNews(
    researchRequest: ResearchRequest,
    context: OperationContext
): NewsData { ... }

@Action(toolGroups = [CoreToolGroups.WEB])
fun collectGraphAnalystReports(
    researchRequest: ResearchRequest,
    context: OperationContext
): AnalystReportsData { ... }

// ❌ BAD: Monolithic action doing everything
@Action(toolGroups = [CoreToolGroups.WEB])
fun collectAllData(...): AllData { 
    // Tries to collect SEC filings, news, and reports in one action
    // Large context window, hard to debug, not reusable
}
```

### 2. Descriptive Action Names
Use clear, verb-based names that describe what the action does.

```kotlin
// ✅ GOOD: Clear, descriptive names
fun extractCompanyProfile(...)
fun extractProductLandscape(...)
fun extractMarketDynamics(...)
fun persistToNeo4j(...)

// ❌ BAD: Vague or unclear names
fun process(...)
fun handle(...)
fun doStuff(...)
```

### 3. Action Descriptions
Add descriptions to complex actions to help the framework understand their purpose.

```kotlin
@Action(description = "Extracts company profile and leadership info from filings and news")
fun extractCompanyProfile(
    ticker: String,
    filings: List<DataPoint>,
    executives: List<DataPoint>,
    news: List<DataPoint>,
    context: OperationContext
): CompanyProfileData { ... }
```

### 4. Tool Groups
Specify tool groups when actions need specific capabilities (web search, file operations, etc.).

```kotlin
// Action that needs web search capabilities
@Action(toolGroups = [CoreToolGroups.WEB])
fun collectRecentNews(
    researchRequest: ResearchRequest,
    context: OperationContext
): NewsData { ... }
```

### 5. Clear Blackboard Attribute
Use `clearBlackboard = true` to reset context after an action completes. This removes all objects except the action's output, useful for multi-step workflows.

```kotlin
@Action(clearBlackboard = true)
fun preprocess(rawDocument: RawDocument): ProcessedDocument {
    return ProcessedDocument(rawDocument.content.trim())
}

@AchievesGoal(description = "Produce final output")
@Action
fun transform(doc: ProcessedDocument): FinalOutput {
    // Only ProcessedDocument is available, not RawDocument
    return FinalOutput(doc.content.toUpperCase())
}
```

---

## Data Flow & Type Safety

### 1. Distinct Return Types
Each action should return a specific, well-defined type. Avoid generic return types.

```kotlin
// ✅ GOOD: Specific return types for each action
data class SECFilingsData(val filings: List<DataPoint>)
data class NewsData(val newsItems: List<DataPoint>)
data class AnalystReportsData(val reports: List<DataPoint>)

@Action
fun collectSECFilings(...): SECFilingsData { ... }

@Action
fun collectRecentNews(...): NewsData { ... }

// ❌ BAD: All actions return the same generic type
@Action
fun collectSECFilings(...): GraphConstructionData { ... }

@Action
fun collectRecentNews(...): GraphConstructionData { ... }
// Framework can't distinguish between outputs
```

### 2. Immutable Data Classes
Use immutable data classes for all data transfer objects.

```kotlin
// ✅ GOOD: Immutable data class
data class ResearchRequest(
    val ticker: String,
    val maxDataAgeDays: Int = 7,
    val targetResultCount: Int = 10
)

// ❌ BAD: Mutable properties
data class ResearchRequest(
    var ticker: String,
    var maxDataAgeDays: Int = 7
)
```

### 3. Null Safety
Use Kotlin's null safety features. Provide defaults or use nullable types appropriately.

```kotlin
// ✅ GOOD: Clear null handling
data class Company(
    val ticker: String,
    val name: String,
    val sector: String? = null,  // Explicitly nullable
    val industry: String? = null,
    val description: String? = null
)

// Handle nulls explicitly
val sector = company.sector ?: "Unknown"
```

### 4. Validation
Validate inputs early, especially in actions that are entry points.

```kotlin
@Action
fun extractCompanyProfile(
    ticker: String,
    filings: List<DataPoint>,
    executives: List<DataPoint>,
    news: List<DataPoint>,
    context: OperationContext
): CompanyProfileData {
    // ✅ GOOD: Early validation
    if (filings.isEmpty() && executives.isEmpty() && news.isEmpty()) {
        return CompanyProfileData(Company(ticker, ticker), emptyList())
    }
    
    // Proceed with extraction
    return context.ai()
        .withLlmByRole(BEST_ROLE)
        .create<CompanyProfileData>(...)
}
```

---

## LLM Integration

### 1. Model Selection
Choose appropriate models based on task complexity and cost.

```kotlin
// ✅ GOOD: Use cheaper models for simple tasks
@Action
fun extractResearchRequest(userInput: UserInput, context: OperationContext): ResearchRequest =
    context.ai()
        .withLlmByRole(CHEAPEST_ROLE)  // Simple extraction task
        .createObject("Create a ResearchRequest from this user input...")

// Use best models for complex reasoning
@Action
fun synthesizeReport(marketData: MarketData, context: OperationContext): MarketAnalyseReport = 
    context.ai()
        .withLlmByRole(BEST_ROLE)  // Complex synthesis task
        .create(...)

// Fallback to available models
val llm = context.ai().withFirstAvailableLlmOf("mistral:7b", OpenAiModels.GPT_41)
```

### 2. Prompt Engineering
Write clear, structured prompts with specific instructions.

```kotlin
// ✅ GOOD: Clear, structured prompt
val reports = llm.create<List<DataPoint>>(
    """
    Search for analyst reports and earnings call transcripts for ${researchRequest.ticker}.
    Focus on:
    - Competitor analysis
    - Market sentiment and ratings
    - Future outlook
    
    Return up to 3 relevant reports.
    """.trimIndent()
)

// ❌ BAD: Vague prompt
val reports = llm.create<List<DataPoint>>(
    "Find some analyst stuff for ${ticker}"
)
```

### 3. Type-Safe LLM Calls
Use Kotlin's type system with LLM calls for automatic deserialization.

```kotlin
// ✅ GOOD: Type-safe LLM calls
val profile = context.ai()
    .withLlmByRole(BEST_ROLE)
    .create<CompanyProfileData>(...)  // Returns CompanyProfileData

val (risks, opportunities) = context.ai()
    .withLlmByRole(BEST_ROLE)
    .create<Pair<List<String>, List<String>>>(...)  // Returns Pair

// ✅ GOOD: Complex nested types
val executives = llm.create<List<DataPoint>>(...)  // Returns List<DataPoint>
```

### 4. Context Window Management
Keep prompts concise and focused. Use smaller actions instead of large prompts.

```kotlin
// ✅ GOOD: Focused prompt with specific data
@Action
fun extractCompanyProfile(
    ticker: String,
    filings: List<DataPoint>,
    executives: List<DataPoint>,
    news: List<DataPoint>,
    context: OperationContext
): CompanyProfileData {
    return context.ai()
        .withLlmByRole(BEST_ROLE)
        .create<CompanyProfileData>(
            """
            Extract company profile and leadership information for $ticker.
            
            Data:
            SEC Filings: $filings
            Executives: $executives
            News: $news
            
            Extract:
            1. Company: Name, Sector, Industry, Description, Exchange, Market Cap
            2. Executives: Name, Role, Since when
            """.trimIndent()
        )
}

// ❌ BAD: Massive prompt with all data
@Action
fun extractEverything(allData: MassiveDataObject, context: OperationContext) {
    // Prompt includes all filings, news, reports, financials, etc.
    // Exceeds context window, expensive, slow
}
```

---

## State Management

### 1. Pre/Post Conditions
Use pre and post conditions to manage agent state and control action execution flow.

```kotlin
// Define state conditions
@Condition(name = ReportStates.RISK_PROFILE)
fun riskProfile(riskProfile: RiskProfile?) = riskProfile != null

@Condition(name = ReportStates.INVESTMENT_PERIOD)
fun investmentTimeFrame(investmentPeriod: InvestmentPeriod?) = investmentPeriod != null

// Use in actions
@Action(post = [ReportStates.RISK_PROFILE])
fun promptUserToDefineTheirRiskProfile(context: OperationContext): RiskProfile { ... }

@Action(
    pre = [ReportStates.RISK_PROFILE],
    post = [ReportStates.INVESTMENT_PERIOD]
)
fun promptUserToDefineTimeFrame(context: OperationContext): InvestmentPeriod { ... }
```

### 2. Output Bindings
Use output bindings to name and track specific outputs in the state.

```kotlin
companion object {
    const val MARKET_ANALYSE_REPORT_BINDING = "marketAnalyseReport"
    const val MARKET_ANALYSE_REPORT_MD_BINDING = "marketAnalyseMarkDownReport"
}

@Action(outputBinding = MARKET_ANALYSE_REPORT_MD_BINDING)
fun generateReadableMarkdown(
    marketAnalyseReport: MarketAnalyseReport,
    context: OperationContext
): String = reportService.generateMarkdownReport(marketAnalyseReport, context)
```

### 3. RequireNameMatch
Use `@RequireNameMatch` to ensure the framework provides the correct named output.

```kotlin
@Action
fun saveReport(
    @RequireNameMatch
    marketAnalyseMarkDownReport: String,  // Must match output binding name
    researchRequest: ResearchRequest
): Boolean = reportService.saveReport(...)
```

### 4. State Organization
Group related state constants in companion objects.

```kotlin
companion object {
    object ReportStates {
        const val RISK_PROFILE = "riskProfile"
        const val INVESTMENT_PERIOD = "investmentPeriod"
        const val SATISFACTORY_TRADING_REPORT = "satisfactoryTradingReport"
    }

    object OutputBindings {
        const val TRADING_REPORT = "tradingReport"
        const val STRATEGY_PLAN = "executionStrategyReport"
    }
}
```

---

## Testing & Debugging

### 1. Logging
Use structured logging to track agent execution.

```kotlin
class GraphMarketAnalyst(...) {
    private val logger = LoggerFactory.getLogger(GraphMarketAnalyst::class.java)

    @Action
    fun collectGraphSecFilings(...): SECFilingsData {
        logger.info("Collecting SEC filings for ${researchRequest.ticker}")
        val filings = llm.create<List<DataPoint>>(...)
        logger.info("Collected ${filings.size} SEC filings")
        return SECFilingsData(filings)
    }
}
```

### 2. Initialization Logging
Log important configuration at agent initialization.

```kotlin
class MarketAnalyst(
    private val properties: FinanceAnalystProperties,
    private val reportService: ReportService
) {
    private val logger = LoggerFactory.getLogger(MarketAnalyst::class.java)

    init {
        logger.info("Market analyst agent initialized: $properties")
    }
}
```

### 3. Error Handling
Handle errors gracefully and provide meaningful error messages.

```kotlin
@Action
fun persistToNeo4j(extractedKnowledge: ExtractedKnowledge): CompanyEntity {
    logger.info("Persisting knowledge to Neo4j for ${extractedKnowledge.company.ticker}")
    
    try {
        val savedCompany = graphPersistenceService.persistKnowledge(extractedKnowledge)
        logger.info("Successfully persisted all knowledge for ${savedCompany.ticker} to Neo4j")
        return savedCompany
    } catch (e: Exception) {
        logger.error("Failed to persist knowledge for ${extractedKnowledge.company.ticker}", e)
        throw e
    }
}
```

---

## Common Patterns

### 1. Orchestration Pattern
Use a main action to orchestrate multiple sub-actions.

```kotlin
@Action(description = "Orchestrates the full knowledge extraction process")
fun extractKnowledge(
    graphData: GraphConstructionData,
    context: OperationContext
): ExtractedKnowledge {
    logger.info("Extracting knowledge for graph from collected data for ${graphData.ticker}")

    // Orchestrate multiple extraction actions
    val profile = extractCompanyProfile(...)
    val products = extractProductLandscape(...)
    val market = extractMarketDynamics(...)
    val financials = extractFinancialAnalysis(...)
    val sentiment = extractSentimentAndEvents(...)

    return ExtractedKnowledge(
        company = profile.company,
        executives = profile.executives,
        products = products,
        competitors = market.competitors,
        // ... combine all results
    )
}
```

### 2. Goal Achievement Pattern
Define clear goals with examples and tags.

```kotlin
@AchievesGoal(
    description = """
        Generates comprehensive market analysis reports by collecting data from multiple sources
        and synthesizing them into a structured report. The embabel framework orchestrates
        the data collection and synthesis steps automatically.
    """,
    tags = ["market analysis", "stock", "research"],
    examples = ["Market analysis for <ticker>"]
)
@Action
fun saveReport(
    @RequireNameMatch
    marketAnalyseMarkDownReport: String,
    researchRequest: ResearchRequest
): Boolean = reportService.saveReport(...)
```

### 3. Feedback Loop Pattern
Implement iterative refinement with user feedback.

```kotlin
@Action(post = [ReportStates.SATISFACTORY_TRADING_REPORT])
fun generateReport(...): TradingReport = 
    tradeReportGenerator.generateReport(...)

@Action(post = [ReportStates.SATISFACTORY_TRADING_REPORT], canRerun = true)
fun evaluateReport(
    tradingReport: TradingReport, 
    context: OperationContext
): Critique = context.ai()
    .withLlm(properties.criticModel)
    .create("Is this research report satisfactory?...")

@Action(post = [ReportStates.SATISFACTORY_TRADING_REPORT])
fun generateReportWithFeedback(
    marketAnalyseReport: MarketAnalyseReport,
    riskProfile: RiskProfile,
    investmentPeriod: InvestmentPeriod,
    critique: Critique,
    context: OperationContext
): TradingReport = tradeReportGenerator.generateReport(..., critique, ...)
```

### 4. Data Collection Pattern
**CRITICAL**: Let the framework orchestrate collection actions. Don't manually call them.

```kotlin
// ✅ BEST PRACTICE: Framework Orchestration
// Individual collection actions with specific return types
@Action(toolGroups = [CoreToolGroups.WEB])
fun collectSECFilings(
    researchRequest: ResearchRequest,
    context: OperationContext
): SECFilingsData { ... }

@Action(toolGroups = [CoreToolGroups.WEB])
fun collectRecentNews(
    researchRequest: ResearchRequest,
    context: OperationContext
): NewsData { ... }

@Action(toolGroups = [CoreToolGroups.WEB])
fun collectAnalystOpinions(
    researchRequest: ResearchRequest,
    context: OperationContext
): AnalystReportsData { ... }

// Combination action - Accept data as PARAMETERS
// Let Embabel discover and call the collection actions automatically
@Action(description = "Combines collected data from all sources")
fun combineMarketData(
    researchRequest: ResearchRequest,
    secFilingsData: SECFilingsData,        // ← Framework calls collectSECFilings()
    newsData: NewsData,                     // ← Framework calls collectRecentNews()
    analystReportsData: AnalystReportsData, // ← Framework calls collectAnalystOpinions()
    context: OperationContext
): MarketData {
    // Just combine - NO manual orchestration!
    return MarketData(
        ticker = researchRequest.ticker,
        secFilings = secFilingsData.filings,
        newsItems = newsData.newsItems,
        analystReports = analystReportsData.reports
    )
}

// ❌ ANTI-PATTERN: Manual Orchestration
@Action(toolGroups = [CoreToolGroups.WEB])
fun combineMarketDataManually(
    researchRequest: ResearchRequest,
    context: OperationContext
): MarketData {
    // DON'T DO THIS - Manual calls prevent framework optimization
    val filings = collectSECFilings(researchRequest, context)      // ❌ Manual call
    val news = collectRecentNews(researchRequest, context)          // ❌ Manual call
    val reports = collectAnalystOpinions(researchRequest, context)  // ❌ Manual call
    
    return MarketData(
        ticker = researchRequest.ticker,
        secFilings = filings.filings,
        newsItems = news.newsItems,
        analystReports = reports.reports
    )
}
```

**Why Framework Orchestration is Better:**
1. **Automatic Parallelization**: Embabel can run collection actions in parallel
2. **Smarter Execution**: Framework decides optimal execution order
3. **Better Caching**: Framework can cache and reuse results
4. **Cleaner Code**: Separation between collection and combination logic
5. **More Flexible**: Other actions can use individual collectors independently

**Rule of Thumb**: If you find yourself writing `val x = someAction(...)` inside another action, you're probably doing manual orchestration. Instead, accept `x` as a parameter and let the framework call `someAction()` for you.


### 6. Utility AI Pattern (Event-Driven Systems)
For event-driven systems without clear end goals, use `@EmbabelComponent` with Utility AI planner. Actions are selected based on value rather than goal achievement.

```kotlin
@EmbabelComponent
class IssueActions(
    private val communityDataManager: CommunityDataManager,
    private val gitHubUpdater: GitHubUpdater
) {
    @Action(outputBinding = "ghIssue")
    fun saveNewIssue(ghIssue: GHIssue, context: OperationContext): GHIssue? {
        val existing = communityDataManager.findIssueByGithubId(ghIssue.id)
        if (existing == null) {
            val issueEntityStatus = communityDataManager.saveAndExpandIssue(ghIssue)
            context += issueEntityStatus
            return ghIssue
        }
        return null
    }

    @Action(
        pre = ["spel:newEntity.newEntities.?[#this instanceof T(com.embabel.shepherd.domain.Issue)].size() > 0"]
    )
    fun reactToNewIssue(
        ghIssue: GHIssue,
        newEntity: NewEntity<*>,
        ai: Ai
    ): IssueAssessment {
        return ai
            .withLlm(properties.triageLlm)
            .creating(IssueAssessment::class.java)
            .fromTemplate("first_issue_response", mapOf("issue" to ghIssue))
    }

    @Action(pre = ["spel:issueAssessment.urgency > 0.0"])
    fun heavyHitterIssue(issue: GHIssue, issueAssessment: IssueAssessment) {
        // Take action on high-urgency issues
    }
}
```

**When to use Utility AI:**
- Event-driven systems reacting to incoming events
- Chatbots with multiple response options
- Exploratory scenarios without predetermined goals

### 7. Agent Skills Pattern
Use Agent Skills to provide reusable, shareable skill packages to agents. Skills are loaded dynamically and provide instructions, resources, and tools.

```kotlin
// Load skills from GitHub
val skills = Skills("financial-skills", "Financial analysis skills")
    .withGitHubUrl("https://github.com/wshobson/agents/tree/main/plugins/business-analytics/skills")

// Use skills in an action
val response = context.ai()
    .withLlm(llm)
    .withReference(skills)
    .withSystemPrompt("You are a helpful financial analyst.")
    .respond(conversation.messages)
```

**Skill directory structure:**
```
my-skill/
├── SKILL.md           # Skill definition with YAML frontmatter
├── scripts/           # Executable scripts
├── references/        # Documentation
└── assets/            # Templates and data files
```

### 8. RAG (Retrieval-Augmented Generation) Pattern
Embabel provides agentic RAG support where the LLM has full control over retrieval:

```kotlin
// Create a RAG reference
val ragStore = ToolishRag(searchOperations)

// Use in an action
val response = context.ai()
    .withLlm(llm)
    .withReference(ragStore)
    .createObject("Analyze this based on our knowledge base", Analysis::class.java)
```

**Agentic RAG capabilities:**
- Autonomous search: LLM decides when and what to search
- Iterative refinement: Multiple searches with different queries
- Cross-reference discovery: Follow references, expand chunks, zoom out to parent sections
- HyDE support: Generate hypothetical documents for better semantic search

### 9. Deprecation Pattern
When evolving your agent, properly deprecate old approaches.

```kotlin
/**
 * @deprecated Use persistToNeo4j instead. This Phase 1 method generates manual 
 * Cypher scripts which are error-prone and harder to maintain. 
 * Kept for backward compatibility.
 */
@Deprecated("Use persistToNeo4j for Phase 2 direct database persistence")
@Action
fun generateCypherScript(
    extractedKnowledge: ExtractedKnowledge,
    context: OperationContext
): String { ... }

// New, recommended approach
@Action(description = "Persists extracted knowledge directly to Neo4j database (Phase 2)")
fun persistToNeo4j(extractedKnowledge: ExtractedKnowledge): CompanyEntity { ... }
```

---

## Anti-Patterns to Avoid

### 1. ❌ Generic Return Types
```kotlin
// ❌ BAD: All actions return the same type
@Action
fun collectNews(...): GraphConstructionData { ... }

@Action
fun collectFilings(...): GraphConstructionData { ... }

// ✅ GOOD: Specific return types
@Action
fun collectNews(...): NewsData { ... }

@Action
fun collectFilings(...): SECFilingsData { ... }
```

### 2. ❌ Manual Orchestration of Actions
**This is one of the most common anti-patterns!**

```kotlin
// ❌ BAD: Manually calling other @Action methods
@Action(toolGroups = [CoreToolGroups.WEB])
fun collectAllData(
    researchRequest: ResearchRequest,
    context: OperationContext
): CombinedData {
    // DON'T manually call other actions!
    val filings = collectSECFilings(researchRequest, context)  // ❌
    val news = collectNews(researchRequest, context)            // ❌
    val reports = collectReports(researchRequest, context)      // ❌
    
    return CombinedData(filings, news, reports)
}

// ✅ GOOD: Let framework orchestrate
@Action(description = "Combines all collected data")
fun collectAllData(
    researchRequest: ResearchRequest,
    secFilingsData: SECFilingsData,     // ← Framework calls collectSECFilings()
    newsData: NewsData,                  // ← Framework calls collectNews()
    reportsData: ReportsData,            // ← Framework calls collectReports()
    context: OperationContext
): CombinedData {
    // Just combine the data
    return CombinedData(
        secFilingsData.filings,
        newsData.newsItems,
        reportsData.reports
    )
}
```

**Why this matters:**
- Manual calls prevent parallel execution
- Framework can't optimize execution order
- Harder to test individual actions
- Defeats the purpose of having separate actions
- Increases coupling between actions


### 3. ❌ Monolithic Actions
```kotlin
// ❌ BAD: One action does everything
@Action
fun doEverything(ticker: String, context: OperationContext): FinalReport {
    // Collects news, filings, analyst reports
    // Extracts entities, relationships
    // Generates report
    // Saves to database
    // 500+ lines of code
}

// ✅ GOOD: Break into focused actions
@Action fun collectData(...): CollectedData { ... }
@Action fun extractEntities(...): ExtractedEntities { ... }
@Action fun generateReport(...): Report { ... }
@Action fun saveToDatabase(...): Boolean { ... }
```

### 4. ❌ Hardcoded Values
```kotlin
// ❌ BAD: Hardcoded model names and limits
@Action
fun analyze(...) {
    val result = context.ai()
        .withLlm("gpt-4")  // Hardcoded
        .create<Report>("Analyze this data...")
}

// ✅ GOOD: Use configuration
@Action
fun analyze(...) {
    val result = context.ai()
        .withLlm(properties.analysisModel)  // Configurable
        .create<Report>("Analyze this data...")
}
```

### 5. ❌ Missing Descriptions
```kotlin
// ❌ BAD: No description
@Agent
class MyAgent { ... }

@Action
fun doSomething(...) { ... }

// ✅ GOOD: Clear descriptions
@Agent(
    description = """
    Detailed description of what this agent does,
    its capabilities, and approach.
    """
)
class MyAgent { ... }

@Action(description = "Extracts company profile from SEC filings and news")
fun extractCompanyProfile(...) { ... }
```

### 6. ❌ Ignoring Null Safety
```kotlin
// ❌ BAD: Unsafe null handling
val sector = company.sector!!  // Can throw NPE

// ✅ GOOD: Safe null handling
val sector = company.sector ?: "Unknown"
val description = company.description?.replace("'", "\\'") ?: ""
```

### 7. ❌ Side Effects in Data Classes
```kotlin
// ❌ BAD: Mutable state and side effects
data class Report(var content: String) {
    fun update(newContent: String) {
        content = newContent  // Mutation
        saveToDatabase()      // Side effect
    }
}

// ✅ GOOD: Immutable data, separate operations
data class Report(val content: String)

@Action
fun updateReport(report: Report, newContent: String): Report {
    return report.copy(content = newContent)
}

@Action
fun saveReport(report: Report): Boolean {
    return reportService.save(report)
}
```

### 8. ❌ Unclear State Dependencies
```kotlin
// ❌ BAD: Hidden state dependencies
@Action
fun generateReport(...): Report {
    // Assumes risk profile and investment period are already set
    // No pre-conditions specified
}

// ✅ GOOD: Explicit state dependencies
@Action(
    pre = [ReportStates.RISK_PROFILE, ReportStates.INVESTMENT_PERIOD]
)
fun generateReport(
    marketData: MarketData,
    riskProfile: RiskProfile,
    investmentPeriod: InvestmentPeriod,
    context: OperationContext
): Report { ... }
```

---

## Summary

### Key Takeaways

1. **Design for Clarity**: Use descriptive names, clear descriptions, and single-responsibility agents
2. **Type Safety First**: Leverage Kotlin's type system with distinct return types and null safety
3. **Granular Actions**: Break complex operations into smaller, focused actions
4. **Smart Model Selection**: Choose appropriate LLMs based on task complexity and cost
5. **Explicit State Management**: Use pre/post conditions and output bindings clearly
6. **Comprehensive Logging**: Track execution flow and debug issues effectively
7. **Immutable Data**: Use immutable data classes for predictable behavior
8. **Validate Early**: Check inputs at action entry points
9. **Handle Errors Gracefully**: Provide meaningful error messages and logging
10. **Document Evolution**: Use deprecation annotations when evolving your agents

### Quick Reference

```kotlin
// Agent Structure
@Agent(description = "Clear, detailed description")
class MyAgent(
    private val dependency1: Service1,
    private val dependency2: Service2
) {
    private val logger = LoggerFactory.getLogger(MyAgent::class.java)
    
    @Action(
        description = "What this action does",
        toolGroups = [CoreToolGroups.WEB],  // If needed
        pre = [States.REQUIRED_STATE],       // If needed
        post = [States.PRODUCES_STATE],      // If needed
        outputBinding = BINDING_NAME         // If needed
    )
    fun actionName(
        input: InputType,
        context: OperationContext
    ): OutputType {
        logger.info("Starting action...")
        // Implementation
        return result
    }
    
    @AchievesGoal(
        description = "User-facing goal description",
        tags = ["tag1", "tag2"],
        examples = ["Example usage"]
    )
    @Action
    fun achieveGoal(...): Boolean { ... }
    
    companion object {
        object States {
            const val REQUIRED_STATE = "requiredState"
            const val PRODUCES_STATE = "producesState"
        }
        const val BINDING_NAME = "outputBindingName"
    }
}
```

---

## Additional Resources

- **Framework Documentation**: Refer to Embabel's official documentation for advanced features
- **Example Agents**: Study `MarketAnalyst`, `GraphMarketAnalyst`, and `TradingAnalyst` in this codebase
- **Spring Data Neo4j**: For graph database integration patterns
- **Kotlin Best Practices**: Follow Kotlin coding conventions and idioms
- **Embabel Best Practices**: See [embabel.md](./embabel.md) for detailed best practices.
- **Embabel Testing Guidelines**: See [embabel-testing.md](./embabel-testing.md) for testing recommendations.

---

*Last Updated: 2025-11-19*
