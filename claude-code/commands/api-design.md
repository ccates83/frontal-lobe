---
description: Design an API (REST, GraphQL, gRPC) with spec and implementation plan
argument-hint: "API description (e.g., 'REST API for e-commerce', 'GraphQL API for blog with subscriptions')"
---

# API Design

Design an API with specification and implementation plan.

## Arguments
- `$ARGUMENTS` — API description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, existing API routes/specs
2. Identify API protocol, framework, auth method, conventions
3. Check existing endpoint patterns

## Phase 2: Design
Launch `api-architect` with the API description and existing context. Request: resource model, endpoint catalog, error taxonomy, auth plan, pagination strategy.

## Phase 3: Implement
Launch `api-builder` with the architect's design.

## Phase 4: Test
Launch `api-tester` with tests for new endpoints.

## Phase 5: Review
Launch `api-reviewer` with all new endpoints for consistency and security.

## Phase 6: Report
Present: endpoints created, spec generated, auth requirements, test coverage.
