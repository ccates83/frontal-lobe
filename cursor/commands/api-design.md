# API Design

Design an API with specification and implementation plan.

## Arguments
- `$ARGUMENTS` — API description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), existing API routes/specs
2. Identify API protocol, framework, auth method, conventions
3. Check existing endpoint patterns

## Phase 2: Design
Delegate to the `api-architect` subagent with the API description and existing context. Request: resource model, endpoint catalog, error taxonomy, auth plan, pagination strategy.

## Phase 3: Implement
Delegate to the `api-builder` subagent with the architect's design.

## Phase 4: Test
Delegate to the `api-tester` subagent with tests for new endpoints.

## Phase 5: Review
Delegate to the `api-reviewer` subagent with all new endpoints for consistency and security.

## Phase 6: Report
Present: endpoints created, spec generated, auth requirements, test coverage.
