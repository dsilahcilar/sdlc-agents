# Embabel Agent Framework Skill

## Overview

Embabel is an agentic AI framework that enables building intelligent agents with automatic orchestration, state management, and LLM integration. This skill provides comprehensive guidance for implementing Embabel agents in your project.

## Skill Structure

This skill is organized into three main documents:

### 1. **best-practices.md** - Agent Design & Implementation Patterns
- Agent design principles (single responsibility, clear descriptions, dependency injection)
- Action design (granular actions, descriptive names, tool groups, clearBlackboard)
- Data flow & type safety (distinct return types, immutable data classes, null safety)
- LLM integration (model selection, prompt engineering, type-safe calls)
- State management (pre/post conditions, output bindings)
- Testing & debugging strategies
- Common patterns (orchestration, goal achievement, feedback loops, data collection, Utility AI, Agent Skills, RAG)
- Anti-patterns to avoid (generic return types, manual orchestration, monolithic actions)

### 2. **reference.md** - Framework Reference Documentation
- Agent process flow and lifecycle
- Planning with Goal-Oriented Action Planning (GOAP) and Utility AI
- Blackboard state management
- Domain objects with behavior
- Configuration and annotation model (@Agent, @EmbabelComponent, @Action)
- DSL for agent creation
- Core types (LlmOptions, PromptRunner)
- Tools and tool groups
- Agent Skills for reusable capabilities
- RAG (Retrieval-Augmented Generation) support
- **AgentPlatform and AgentInvocation** - Comprehensive guide with examples:
  - Basic synchronous and asynchronous invocation patterns
  - Named inputs and custom process options
  - Type-safe agent selection mechanism
  - Real-world Spring MVC controller example with htmx integration
- Spring integration
- Customization and integrations (MCP)
- Troubleshooting guide

### 3. **testing.md** - Testing Strategies
- Unit testing with FakePromptRunner and FakeOperationContext
- Integration testing with EmbabelMockitoIntegrationTest
- Testing patterns (prompt content, hyperparameters, tool groups)
- Helper methods for stubbing and verification
- Complete integration test examples

## When to Use This Skill

Load this skill when:
- Implementing new Embabel agents
- Designing agent workflows and action chains
- Integrating LLMs with business logic
- Setting up agent testing infrastructure
- Troubleshooting agent execution issues
- Migrating from other agent frameworks

## Key Principles

### Framework Orchestration Over Manual Calls
**CRITICAL**: Let Embabel orchestrate action execution. Don't manually call `@Action` methods from within other actions. Instead, accept outputs as parameters and let the framework discover and execute dependencies automatically.

### Type-Driven Data Flow
Use distinct, specific return types for each action. The framework uses types to determine execution order and data dependencies.

### Granular Actions
Break complex operations into smaller, focused actions. This improves:
- Context window management
- Reusability
- Testability
- Parallel execution opportunities

### Clear State Management
Use pre/post conditions and output bindings to manage agent state explicitly. This makes the execution flow predictable and debuggable.

## Integration with Planning Agent

When creating tasks for Embabel agent implementation:

1. **Reference Architecture Tests**: Ensure tasks include validation against hexagonal architecture rules
2. **Include Testing Requirements**: Every agent implementation should include both unit and integration tests
3. **Specify LLM Configuration**: Tasks should reference configurable LLM models, not hardcoded values
4. **Document State Flow**: Tasks should clearly define pre/post conditions and output bindings
5. **Emphasize Framework Orchestration**: Remind developers to avoid manual action orchestration

## Quick Reference

### Essential Annotations
- `@Agent(description = "...")` - Define an agent class
- `@EmbabelComponent` - Define a component providing actions (for Utility AI)
- `@Action(description = "...", toolGroups = [...], clearBlackboard = false)` - Define an action method
- `@AchievesGoal(description = "...", tags = [...])` - Mark goal-achieving actions
- `@Condition(name = "...")` - Define state conditions
- `@RequireNameMatch` - Bind parameters by name

### Common Patterns
- **Data Collection**: Separate collection actions + combination action
- **Orchestration**: Main action that coordinates sub-actions via parameters
- **Feedback Loop**: Generate → Evaluate → Refine with critique
- **Goal Achievement**: Final action with `@AchievesGoal` annotation

### Testing Approach
- **Unit Tests**: Use `FakeOperationContext` to verify prompts and logic
- **Integration Tests**: Extend `EmbabelMockitoIntegrationTest` for full workflow testing
- **Stubbing**: Use `whenCreateObject()` and `whenGenerateText()` helpers
- **Verification**: Use `verifyCreateObjectMatching()` to validate LLM calls

## Related Skills

- **hexagonal**: Embabel agents should follow hexagonal architecture principles
- **java/kotlin**: Embabel is built on Spring Boot and works with both languages
- **spec-driven**: Embabel agents can be designed using specification-first approaches

## References

- [Embabel Documentation](https://docs.embabel.com/embabel-agent/guide/0.3.1/)
- [Embabel Agent Examples](https://github.com/embabel/embabel-agent-examples)
- [Discord Community](https://discord.gg/t6bjkyj93q)
