# Embabel Framework - Architect Review Guide

Use this file when reviewing features that introduce or modify Embabel agents.

## Core Architecture Checks

- Ensure agent interaction flows through `AgentPlatform`/`AgentInvocation`, not direct calls to `@Action` methods.
- Verify domain and application layers do not depend on Embabel framework types.
- Confirm Embabel-specific logic stays in agent/infrastructure boundaries.
- Check `@Agent` classes are not also annotated with Spring stereotypes (`@Service`, `@Component`).
- Validate ports remain framework-agnostic and are implemented by adapters.

## Boundary Anti-Patterns to Reject

- Controller or service directly invoking an Embabel `@Action` method.
- Domain models/ports importing `com.embabel..` types.
- Agent orchestration logic duplicated in controllers/services instead of framework invocation.
- Shared mutable state crossing actions without explicit model handoff.

## Test Expectations

- Add architecture tests to enforce no Embabel dependencies in domain ports/models.
- Add at least one integration test proving invocation through `AgentInvocation` or `AgentPlatform`.
- For feature-flagged agents, include a configuration contract test for `@ConditionalOnProperty` keys.

## Review Output Requirements

- Record findings with file-level references.
- Distinguish quick workaround vs robust architecture choice for each debt item.
- If exceptions are accepted, require follow-up task IDs and explicit expiry criteria.
