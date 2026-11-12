# 3. Reference

## 3.1. Invoking an Agent
Agents can be invoked programmatically or via user input.
See [Invoking Embabel Agents](#314-invoking-embabel-agents) for details on programmatic invocation. Programmatic invocation typically involves structured types other than user input.
In the case of user input, an LLM will choose the appropriate agent via the `Autonomy` class. Behavior varies depending on configuration:

- **Closed mode**: The LLM will select the agent based on the user input and the available agents in the system.
- **Open mode**: The LLM will select the goal based on the user input and then assemble an agent that can achieve that goal from the present world state.

## 3.2. Agent Process Flow
When an agent is invoked, Embabel creates an `AgentProcess` with a unique identifier that manages the complete execution lifecycle.

### 3.2.1. AgentProcess Lifecycle
An `AgentProcess` maintains state throughout its execution and can transition between various states:
- **NOT_STARTED**: The process has not started yet
- **RUNNING**: The process is executing without any known problems
- **COMPLETED**: The process has completed successfully
- **FAILED**: The process has failed and cannot continue
- **TERMINATED**: The process was killed by an early termination policy
- **KILLED**: The process was killed by the user or platform
- **STUCK**: The process cannot formulate a plan to progress (may be temporary)
- **WAITING**: The process is waiting for user input or external event
- **PAUSED**: The process has paused due to scheduling policy

Process Execution Methods:
- `tick()`: Perform the next single step and return when an action completes
- `run()`: Execute the process as far as possible until completion, failure, or a waiting state

Each `AgentProcess` maintains:
- **Unique ID**: Persistent identifier for tracking and reference
- **History**: Record of all executed actions with timing information
- **Goal**: The objective the process is trying to achieve
- **Failure Info**: Details about any failure that occurred
- **Parent ID**: Reference to parent process for nested executions

### 3.2.2. Planning
Planning occurs after each action execution using Goal-Oriented Action Planning (GOAP). The planning process:
1. **Analyze Current State**: Examine the current blackboard contents and world state
2. **Identify Available Actions**: Find all actions that can be executed based on their preconditions
3. **Search for Action Sequences**: Use A* algorithm to find optimal paths to achieve the goal
4. **Select Optimal Plan**: Choose the best action sequence based on cost and success probability
5. **Execute Next Action**: Run the first action in the plan and replan

This creates a dynamic OODA loop (Observe-Orient-Decide-Act).

### 3.2.3. Blackboard
The Blackboard serves as the shared memory system that maintains state throughout the agent process execution.
Key Characteristics:
- **Central Repository**: Stores all domain objects, intermediate results, and process state
- **Type-Based Access**: Objects are indexed and retrieved by their types
- **Ordered Storage**: Objects maintain the order they were added, with latest being default
- **Immutable Objects**: Once added, objects cannot be modified (new versions can be added)
- **Condition Tracking**: Maintains boolean conditions used by the planning system

### 3.2.4. Binding
By default items in the blackboard are matched by type. When there are multiple candidates the most recent one is provided. It is also possible to assign a keyed name to blackboard items using `context.bind("name", object)`.

### 3.2.5. Context
Embabel offers a way to store longer term state: the `com.embabel.agent.core.Context`. While a blackboard is tied to a specific agent process, a context can persist across multiple processes. Contexts are identified by a unique `contextId` string.

## 3.4. Domain Objects
Domain objects in Embabel are not just strongly-typed data structures - they are real objects with behavior that can be selectively exposed to LLMs and used in agent actions.

### 3.4.1. Objects with Behavior
Unlike simple structs or DTOs, Embabel domain objects can encapsulate business logic and expose it to LLMs through the `@Tool` annotation.

### 3.4.2. Selective Tool Exposure
The `@Tool` annotation allows you to selectively expose domain object methods to LLMs:
- **Business Logic**: Expose methods that provide safely invocable business value
- **Calculated Properties**: Methods that compute derived values
- **Business Rules**: Methods that implement domain-specific rules

### 3.4.3. Use of Domain Objects in Actions
Domain objects can be used naturally in action methods, combining LLM interactions with traditional object-oriented programming.

### 3.4.4. Domain Understanding is Critical
Domain objects serve as the bridge between Business Domain, Agent Behavior, and Code Actions.

### 3.4.5. Benefits
- **Rich Context**: LLMs receive both data structure and behavioral context
- **Encapsulation**: Business logic stays within domain objects
- **Reusability**: Domain objects can be used across multiple agents
- **Testability**: Domain logic can be unit tested independently
- **Evolution**: Adding new tools to domain objects extends agent capabilities

## 3.5. Configuration

### 3.5.1. Enabling Embabel
Annotate your Spring Boot application class with `@EnableAgents`.

### 3.5.2. Configuration Properties
Properties are organized by their configuration prefix.
- `embabel.models.default-llm`: Default LLM name
- `embabel.models.llms`: Map of role to LLM name
- `embabel.agent.platform.name`: Core platform identity name
- `embabel.agent.platform.scanning.annotation`: Whether to auto register beans with `@Agent`
- `embabel.agent.platform.ranking.llm`: Name of the LLM to use for ranking
- `embabel.agent.platform.autonomy.agent-confidence-cut-off`: Confidence threshold for agent operations

(See documentation for full list of properties for Anthropic, OpenAI, SSE, Testing, etc.)

## 3.6. Annotation model
Embabel provides a Spring-style annotation model to define agents, actions, goals, and conditions.

### 3.6.1. The @Agent annotation
Used on a class to define an agent. Triggers Spring component scanning. Must provide a `description`.

### 3.6.2. The @Action annotation
Marks methods that perform actions. Metadata includes:
- `description`: Human-readable description
- `pre`: Preconditions
- `post`: Postconditions
- `canRerun`: Boolean
- `clearBlackboard`: Boolean - When true, removes all objects except action's output
- `cost`: Relative cost (0-1)
- `value`: Relative value (0-1)
- `toolGroups`: Named tool groups required

### 3.6.3. The @EmbabelComponent annotation
Used on a class to define a component that provides actions without being a full agent. Particularly useful with Utility AI planner for event-driven systems. Unlike `@Agent`, components don't have goals - actions are selected based on value and preconditions.

### 3.6.4. The @Condition annotation
Marks methods that evaluate conditions. Should not have side effects.

### 3.6.5. Parameters
- **Domain objects**: Normal inputs backed by the blackboard.
- **Infrastructure parameters**: `OperationContext`, `ProcessContext`, `Ai`.

### 3.6.6. Binding by name
The `@RequireNameMatch` annotation can be used to bind parameters by name.

### 3.6.7. Handling of return types
Action methods normally return a single domain object. Nullable return types are allowed (trigger replanning).
Union types can be achieved by implementing the `SomeOf` interface.

### 3.6.8. Action method implementation
`@Action` methods are normal methods that can use `OperationContext` to access the blackboard and invoke LLMs.

### 3.6.9. The @AchievesGoal annotation
Indicates that the completion of the action achieves a specific goal.

### 3.6.10. Implementing the StuckHandler interface
Allows an agent to handle situations where it gets stuck (e.g., by adding data to the blackboard).

### 3.6.11. Advanced Usage: Nested processes
An `@Action` method can invoke another agent process using `ActionContext.asSubProcess`.

## 3.7. DSL
You can create agents using a DSL in Kotlin or Java.

### 3.7.1. Standard Workflows
- `SimpleAgentBuilder`: Simplest agent
- `ScatterGatherBuilder`: Fork join pattern
- `ConsensusBuilder`: Consensus among multiple sources
- `RepeatUntil`: Repeats until condition met
- `RepeatUntilAcceptable`: Repeats with evaluator feedback

### 3.7.2. Registering Agent beans
When using DSL, register the agent as a `@Bean`.

## 3.8. Core Types

### 3.8.1. LlmOptions
Specifies which LLM to use and its hyperparameters (model, temperature, topP, etc.).

### 3.8.2. PromptRunner
Interface for making LLM calls. Obtained from `OperationContext`.
Methods:
- `createObject(String, Class<T>)`: Create typed object
- `createObjectIfPossible`: Try to create object
- `generateText`: Generate simple text
- `withToolGroup`, `withToolObject`, `withLlm`, `withTemplate`

## 3.9. Tools
Tools can be passed to LLMs to perform actions.

### 3.9.1. In Process Tools
Implement methods annotated with `@Tool` on a class.

### 3.9.2. Tool Groups
Indirection between user intent and tool selection (e.g., "web" tools). Can be backed by MCP.

### 3.9.3. PromptContributor and LlmReference
`PromptContributor` provides text for the prompt. `LlmReference` is a contributor that can also provide tools.

### 3.9.4. Built-in Convenience Classes
- `Persona`: Defines agent personality
- `RoleGoalBackstory`: Defines role, goal, and backstory

## 3.10. Templates
Embabel supports Jinja templates for generating prompts via `PromptRunner.withTemplate(String)`.
The default location is under `classpath:/prompts/` with `.jinja` extension.

## 3.11. The AgentProcess
An `AgentProcess` is created every time an agent is run. It has a unique id.

## 3.12. ProcessOptions
Agent processes can be configured with `ProcessOptions`, which controls:
- `contextId`: Identifier of existing context
- `blackboard`: Initial blackboard state
- `test`: Test mode flag
- `verbosity`: Logging level (prompts, responses, planning)
- `control`: Termination policy (max actions, budget)
- `Delays`: Delays for actions and tools to avoid rate limiting

## 3.13. The AgentPlatform
An `AgentPlatform` provides the ability to run agents in a specific environment. It is an SPI interface.

## 3.14. Invoking Embabel Agents
Agents can be invoked programmatically with strong typing, which is deterministic.

### 3.14.1. Creating an AgentProcess Programmatically
Use `agentPlatform.createAgentProcess` or `createAgentProcessFrom`.
Then run with `start(agentProcess)` (async) or `agentProcess.run()` (sync).

### 3.14.2. Using AgentInvocation

`AgentInvocation` provides a higher-level, type-safe API for invoking agents. It automatically finds the appropriate agent based on the expected result type, making it ideal for web applications and programmatic agent execution.

#### Basic Usage

**Java:**
```java
// Simple invocation with explicit result type
var invocation = AgentInvocation.create(agentPlatform, TravelPlan.class);
TravelPlan plan = invocation.invoke(travelRequest);
```

**Kotlin:**
```kotlin
// Type-safe invocation with inferred result type
val invocation: AgentInvocation<TravelPlan> = AgentInvocation.create(agentPlatform)
val plan = invocation.invoke(travelRequest)
```

#### Invocation with Named Inputs

When your agent actions require multiple named parameters, you can pass them as a map:

**Java:**
```java
// Invoke with a map of named inputs
Map<String, Object> inputs = Map.of(
    "request", travelRequest,
    "preferences", userPreferences
);
TravelPlan plan = invocation.invoke(inputs);
```

#### Custom Process Options

Configure execution behavior such as verbosity, budget limits, and debugging:

**Java:**
```java
var invocation = AgentInvocation.builder(agentPlatform)
    .options(options -> options
        .verbosity(verbosity -> verbosity
            .showPrompts(true)
            .showResponses(true)
            .debug(true)))
    .build(TravelPlan.class);
TravelPlan plan = invocation.invoke(travelRequest);
```

**Kotlin:**
```kotlin
val processOptions = ProcessOptions(
    verbosity = Verbosity(
        showPrompts = true,
        showResponses = true,
        debug = true
    )
)
val invocation: AgentInvocation<TravelPlan> = AgentInvocation.builder(agentPlatform)
    .options(processOptions)
    .build()
val plan = invocation.invoke(travelRequest)
```

#### Asynchronous Invocation

For long-running operations, use async invocation to avoid blocking:

**Java:**
```java
CompletableFuture<TravelPlan> future = invocation.invokeAsync(travelRequest);

// Handle result when complete
future.thenAccept(plan -> {
    logger.info("Travel plan generated: {}", plan);
});

// Or wait for completion
TravelPlan plan = future.get();
```

#### Agent Selection

`AgentInvocation` automatically finds agents by examining their goals:
- Searches all registered agents in the platform
- Finds agents with goals that produce the requested result type
- Uses the first matching agent found
- Throws an error if no suitable agent is available

This makes agent invocation type-safe and eliminates the need for manual agent lookup.

#### Real-World Web Application Example

Here's a complete Spring MVC controller example showing how to use `AgentInvocation` with htmx for asynchronous UI updates:

```kotlin
@Controller
class TripPlanningController(
    private val agentPlatform: AgentPlatform
) {
    private val activeJobs = ConcurrentHashMap<String, CompletableFuture<TripPlan>>()

    @PostMapping("/plan-trip")
    fun planTrip(
        @ModelAttribute tripRequest: TripRequest,
        model: Model
    ): String {
        // Generate unique job ID for tracking
        val jobId = UUID.randomUUID().toString()

        // Create agent invocation with custom options
        val invocation: AgentInvocation<TripPlan> = AgentInvocation.builder(agentPlatform)
            .options { options ->
                options.verbosity { verbosity ->
                    verbosity.showPrompts(true)
                        .showResponses(false)
                        .debug(false)
                }
            }
            .build()

        // Start async agent execution
        val future = invocation.invokeAsync(tripRequest)
        activeJobs[jobId] = future

        // Set up completion handler
        future.whenComplete { result, throwable ->
            if (throwable != null) {
                logger.error("Trip planning failed for job $jobId", throwable)
            } else {
                logger.info("Trip planning completed for job $jobId")
            }
        }

        model.addAttribute("jobId", jobId)
        model.addAttribute("tripRequest", tripRequest)

        // Return htmx template that will poll for results
        return "trip-planning-progress"
    }

    @GetMapping("/trip-status/{jobId}")
    @ResponseBody
    fun getTripStatus(@PathVariable jobId: String): ResponseEntity<Map<String, Any>> {
        val future = activeJobs[jobId] ?: return ResponseEntity.notFound().build()

        return when {
            future.isDone -> {
                try {
                    val tripPlan = future.get()
                    activeJobs.remove(jobId)
                    ResponseEntity.ok(mapOf(
                        "status" to "completed",
                        "result" to tripPlan,
                        "redirect" to "/trip-result/$jobId"
                    ))
                } catch (e: Exception) {
                    activeJobs.remove(jobId)
                    ResponseEntity.ok(mapOf(
                        "status" to "failed",
                        "error" to e.message
                    ))
                }
            }
            future.isCancelled -> {
                activeJobs.remove(jobId)
                ResponseEntity.ok(mapOf("status" to "cancelled"))
            }
            else -> {
                ResponseEntity.ok(mapOf(
                    "status" to "in_progress",
                    "message" to "Planning your amazing trip..."
                ))
            }
        }
    }

    @GetMapping("/trip-result/{jobId}")
    fun showTripResult(
        @PathVariable jobId: String,
        model: Model
    ): String {
        // Retrieve completed result from cache or database
        val tripPlan = tripResultCache[jobId] ?: return "redirect:/error"
        model.addAttribute("tripPlan", tripPlan)
        return "trip-result"
    }

    @DeleteMapping("/cancel-trip/{jobId}")
    @ResponseBody
    fun cancelTrip(@PathVariable jobId: String): ResponseEntity<Map<String, String>> {
        val future = activeJobs[jobId]
        return if (future != null && !future.isDone) {
            future.cancel(true)
            activeJobs.remove(jobId)
            ResponseEntity.ok(mapOf("status" to "cancelled"))
        } else {
            ResponseEntity.badRequest()
                .body(mapOf("error" to "Job not found or already completed"))
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(TripPlanningController::class.java)
        private val tripResultCache = ConcurrentHashMap<String, TripPlan>()
    }
}
```

**Key Patterns:**
- **Async Execution**: Uses `invokeAsync()` to avoid blocking the web request
- **Job Tracking**: Maintains a map of active futures for status polling
- **htmx Integration**: Returns status updates that htmx can consume for UI updates
- **Error Handling**: Proper exception handling and user feedback
- **Resource Cleanup**: Removes completed jobs from memory
- **Process Options**: Configures verbosity and debugging for production use

## 3.15. API vs SPI
- **API**: Public interface for users
- **SPI**: Service Provider Interface for extending or customizing Embabel

## 3.16. Embabel and Spring
Embabel is built on Spring Boot and Spring AI. It leverages dependency injection for composability and AOP for cross-cutting concerns.

## 3.17. Working with LLMs
Embabel supports any LLM supported by Spring AI.
**Choosing an LLM**:
- Consider return type complexity
- Consider task nature
- Consider tool calling sophistication
- Consider local LLMs (Ollama, Docker)

## 3.18. Customizing Embabel

### 3.18.1. Adding LLMs
Add custom LLMs as Spring beans of type `Llm`.
Requires: name, provider, `OptionsConverter`, knowledge cutoff, pricing model.

### 3.18.2. Adding embedding models
Add as beans of type `EmbeddingService`.

### 3.18.3. Configuration via application.properties
Standard Spring configuration.

### 3.18.4. Customizing logging
Use `logging.level` properties or `logback-spring.xml`.
Disable personality-based logging by removing `loggingTheme` from `@EnableAgents`.

## 3.19. Integrations

### 3.19.1. Model Context Protocol (MCP)
Embabel Agent can expose agents as MCP servers.
- **Server Configuration**: `spring.ai.mcp.server.type` (SYNC or ASYNC)
- **Automatic Publishing**: Goals annotated with `@Export(remote = true)` are published as tools.
- **Tool Groups**: Configure MCP clients to consume external tools.

## 3.20. Choosing a Planner

Embabel supports multiple planning strategies:

### 3.20.1. GOAP (Goal-Oriented Action Planning) - Default
**Best for**: Business processes with defined outputs
- Goal-oriented, deterministic planning
- Plans a path from current state to goal using preconditions and effects
- Uses A* algorithm to find optimal action sequences

### 3.20.2. Utility AI
**Best for**: Exploration and event-driven systems
- Selects the highest-value available action at each step
- Ideal when you don't know the outcome upfront
- Use with `@EmbabelComponent` instead of `@Agent`
- Actions selected based on value, not goal achievement

**When to use Utility AI:**
- Event-driven systems reacting to incoming events (issues, webhooks)
- Chatbots with multiple response options
- Exploratory scenarios without predetermined goals

### 3.20.3. Supervisor
**Best for**: Flexible multi-step workflows
- LLM-orchestrated composition
- An LLM selects which actions to call based on type schemas and gathered artifacts

## 3.21. Agent Skills

Agent Skills provide a standardized way to extend agent capabilities with reusable, shareable skill packages.

### 3.21.1. What are Agent Skills?
An Agent Skill is a directory containing:
- `SKILL.md` - Skill definition with YAML frontmatter and markdown instructions
- `scripts/` - Executable scripts (Python, Bash, etc.)
- `references/` - Documentation and reference materials
- `assets/` - Static resources like templates and data files

### 3.21.2. Loading Skills from GitHub
```kotlin
val skills = Skills("my-skills", "Skills for my agent")
    .withGitHubUrl("https://github.com/anthropics/skills/tree/main/skills")
```

### 3.21.3. Loading Skills from Local Directories
```kotlin
val skills = Skills("my-skills", "Local skills")
    .withLocalSkill("/path/to/my-skill")
```

### 3.21.4. Using Skills with PromptRunner
```kotlin
val response = context.ai()
    .withLlm(llm)
    .withReference(skills)
    .withSystemPrompt("You are a helpful assistant.")
    .respond(conversation.messages)
```

## 3.22. RAG (Retrieval-Augmented Generation)

Embabel provides agentic RAG support through the `LlmReference` interface.

### 3.22.1. Agentic RAG Architecture
Unlike traditional RAG with single retrieval, Embabel's RAG is entirely agentic:
- **Autonomous Search**: LLM decides when to search and what queries to use
- **Iterative Refinement**: Multiple searches with different queries
- **Cross-Reference Discovery**: Follow references, expand chunks, zoom out to parent sections
- **HyDE Support**: Generate hypothetical documents for better semantic search

### 3.22.2. Using RAG
```kotlin
val ragStore = ToolishRag(searchOperations)
val response = context.ai()
    .withLlm(llm)
    .withReference(ragStore)
    .createObject("Analyze based on knowledge base", Analysis::class.java)
```

### 3.22.3. SearchOperations Interface
The `ToolishRag` facade exposes tools based on which `SearchOperations` subinterfaces the store implements:
- `VectorSearch` - Semantic search capabilities
- `TextSearch` - Full-text search (BMI25)
- `ResultExpander` - Expand chunks to see surrounding context
- `RegexSearchOperations` - Pattern-based search

## 3.22. Troubleshooting

### 3.22.1. Common Problems and Solutions
- **Compilation Error**: Check dependency versions.
- **Don't Know How to Invoke Your Agent**: Review `AgentInvocation` and `UserInput` examples.
- **Agent Flow Not Completing**: Check data flow types and GOAP planning.
- **LLM Prompts Look Wrong**: Write unit tests to verify prompts.
- **Agent Gets Stuck in Planning**: Check `@Action` signatures for missing/circular dependencies.
- **Tools Not Available**: Ensure `toolGroups` are specified in `@Action`.
- **Poor Results**: Review prompt engineering, persona, and LLM settings.
- **Struggling to Express Plan**: Use builders like `ScatterGatherBuilder`.
- **Custom conditions not working**: Declare `post` and `pre` conditions correctly.
- **No Goals**: Ensure at least one action has `@AchievesGoal`.
- **Not Visible to MCP Client**: Add `@Export(remote=true)` to `@AchievesGoal`.

### 3.22.2. Debugging Strategies
Enable debug logging: `logging.level.com.embabel.agent: DEBUG`.

### 3.22.3. Getting Help
Join the [Discord](https://discord.gg/t6bjkyj93q) server.

## 3.23. Migrating from other frameworks

### 3.23.1. Migrating from CrewAI
- **Role/Goal/Backstory** -> `RoleGoalBackstory` / `PromptContributor`
- **Sequential Tasks** -> Typed data flow
- **Crew** -> Actions with shared contributors

### 3.23.2. Migrating from Pydantic AI
- **@system_prompt** -> `PromptContributor`
- **@tool** -> `@Tool` annotated methods
- **Agent class** -> `@Agent` annotated record/class
- **RunContext** -> `OperationContext`

### 3.23.3. Migrating from LangGraph
LangGraph uses state machines; Embabel uses GOAP and type-driven flow.

## 3.24. API Evolution
Embabel strives to avoid breaking changes.
- Use stable versions.
- Avoid `com.embabel.agent.experimental`.
- Avoid `@ApiStatus.Experimental` or `@ApiStatus.Internal`.


