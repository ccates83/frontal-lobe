---
description: "Design an API (REST, GraphQL, gRPC) with spec and implementation plan"
agent: frontal-lobe
---
# API Design

Design an API with specification and implementation plan.

## Arguments
- `$ARGUMENTS` — API description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, existing API routes/specs
2. Identify API protocol, framework, auth method, conventions
3. Check existing endpoint patterns

## Phase 2: Design
Use the task tool to invoke `@api-architect` with the API description and existing context. Request: resource model, endpoint catalog, error taxonomy, auth plan, pagination strategy.

## Phase 3: Implement
Use the task tool to invoke `@api-builder` with the architect's design.

## Phase 4: Test
Use the task tool to invoke `@api-tester` with tests for new endpoints.

## Phase 5: Review
Use the task tool to invoke `@api-reviewer` with all new endpoints for consistency and security.

## Phase 6: Report
Present: endpoints created, spec generated, auth requirements, test coverage.
