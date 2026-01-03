# Embabel Testing Notes

Based on the [Embabel Agent Framework User Guide](https://docs.embabel.com/embabel-agent/guide/0.3.1/#reference.testing).

Embabel facilitates testing of user applications with comprehensive support for both unit and integration testing scenarios, similar to Spring.

## 1. Unit Testing

Unit testing in Embabel enables testing individual agent actions without involving real LLM calls. Agents are typically POJOs that can be instantiated with fake or mock objects.

### Key Components
*   **`OperationContext`**: Passed to agent actions, enabling interception and verification of LLM calls.
*   **`FakePromptRunner` & `FakeOperationContext`**: Provided by the framework to mock LLM interactions while allowing verification of prompts, hyperparameters, and business logic.
*   **Mocking Libraries**:
    *   **Java**: [Mockito](https://site.mockito.org/) is the default choice.
    *   **Kotlin**: [mockk](https://mockk.io/) is recommended.

### Testing Patterns
*   **Testing Prompt Content**:
    *   Retrieve the actual prompt sent to the LLM: `context.getLlmInvocations().getFirst().getPrompt()` (Java) or `promptRunner.llmInvocations.first().prompt` (Kotlin).
    *   Verify key domain data is present: `assertTrue(prompt.contains(...))`.
*   **Testing Hyperparameters**:
    *   Verify temperature or other settings: `assertEquals(0.9, promptRunner.getLlmInvocations().getFirst().getInteraction().getLlm().getTemperature(), 0.01)`.
*   **Testing Tool Group Configuration**:
    *   Access tool groups: `getInteraction().getToolGroups()`.
    *   Verify expected tool groups are present or absent.
*   **Testing with Spring Dependencies**:
    *   Mock Spring-injected services using standard mocking frameworks.
    *   Pass mocked dependencies to the agent constructor for isolated testing.

### Example (Kotlin)
```kotlin
@Test
fun testCraftStory() {
    val agent = WriteAndReviewAgent(200, 400)
    val context = FakeOperationContext.create()
    val promptRunner = context.promptRunner() as FakePromptRunner
    
    context.expectResponse(Story("One upon a time..."))
    
    agent.craftStory(UserInput("Tell me a story", Instant.now()), context)
    
    // Verify prompt content
    Assertions.assertTrue(promptRunner.llmInvocations.first().prompt.contains("story"))
    
    // Verify temperature
    val actualTemp = promptRunner.llmInvocations.first().interaction.llm.temperature
    Assertions.assertEquals(0.9, actualTemp, 0.01)
}
```

## 2. Integration Testing

Integration testing exercises complete agent workflows with real or mock external services while avoiding actual LLM calls. This ensures agents are picked up by the platform, data flow is correct, and failure scenarios are handled.

### Key Features
*   **Spring Integration**: Built on top of Spring's integration testing support, allowing use of real databases or Testcontainers.
*   **`EmbabelMockitoIntegrationTest`**: A base class provided by Embabel that simplifies integration testing.
    *   Handles Spring Boot setup and LLM mocking automatically.
    *   Provides pre-configured `agentPlatform` and `llmOperations`.

### Helper Methods
*   **Stubbing**:
    *   `whenCreateObject(prompt, outputClass)`: Mock object creation calls.
    *   `whenGenerateText(prompt)`: Mock text generation calls.
    *   Supports exact prompts or `contains()` matching.
*   **Verification**:
    *   `verifyCreateObjectMatching(matcher, class, llmConfigMatcher)`: Verify prompts and configuration.
    *   `verifyGenerateTextMatching(matcher)`: Verify text generation calls.
    *   `verifyNoMoreInteractions()`: Ensure no unexpected LLM calls.

### Example (Java)
```java
class StoryWriterIntegrationTest extends EmbabelMockitoIntegrationTest {
    @Test
    void shouldExecuteCompleteWorkflow() {
        // Stubbing
        whenCreateObject(contains("Craft a short story"), Story.class)
            .thenReturn(new Story("..."));
            
        // Invocation
        var invocation = AgentInvocation.create(agentPlatform, ReviewedStory.class);
        var result = invocation.invoke(new UserInput("Write about AI"));
        
        // Verification
        verifyCreateObjectMatching(
            prompt -> prompt.contains("Craft a short story"), 
            Story.class, 
            llm -> llm.getLlm().getTemperature() == 0.9
        );
    }
}
```

### Example integration test
```java
package com.embabel.template.agent;

import com.embabel.agent.api.common.autonomy.AgentInvocation;
import com.embabel.agent.domain.io.UserInput;
import com.embabel.agent.testing.integration.EmbabelMockitoIntegrationTest;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Use framework superclass to test the complete workflow of writing and reviewing a story.
 * This will run under Spring Boot against an AgentPlatform instance
 * that has loaded all our agents.
 */
class WriteAndReviewAgentIntegrationTest extends EmbabelMockitoIntegrationTest {

    @BeforeAll
    static void setUp() {
        // Set shell configuration to non-interactive mode
        System.setProperty("embabel.agent.shell.interactive.enabled", "false");
    }

    @Test
    void shouldExecuteCompleteWorkflow() {
        var input = new UserInput("Write about artificial intelligence");

        var story = new WriteAndReviewAgent.Story("AI will transform our world...");
        var reviewedStory = new WriteAndReviewAgent.ReviewedStory(story, "Excellent exploration of AI themes.", Personas.REVIEWER);

        whenCreateObject(prompt -> prompt.contains("Craft a short story"), WriteAndReviewAgent.Story.class)
                .thenReturn(story);

        // The second call uses generateText
        whenGenerateText(prompt -> prompt.contains("You will be given a short story to review"))
                .thenReturn(reviewedStory.review());

        var invocation = AgentInvocation.create(agentPlatform, WriteAndReviewAgent.ReviewedStory.class);
        var reviewedStoryResult = invocation.invoke(input);

        assertNotNull(reviewedStoryResult);
        assertTrue(reviewedStoryResult.getContent().contains(story.text()),
                "Expected story content to be present: " + reviewedStoryResult.getContent());
        assertEquals(reviewedStory, reviewedStoryResult,
                "Expected review to match: " + reviewedStoryResult);

        verifyCreateObjectMatching(prompt -> prompt.contains("Craft a short story"), WriteAndReviewAgent.Story.class,
                llm -> llm.getLlm().getTemperature() == 0.7 && llm.getToolGroups().isEmpty());
        verifyGenerateTextMatching(prompt -> prompt.contains("You will be given a short story to review"));
        verifyNoMoreInteractions();
    }
}
```