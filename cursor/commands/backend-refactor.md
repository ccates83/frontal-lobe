# Backend Refactoring

Plan and execute a backend code refactoring with architecture guidance.

## Arguments
- `$ARGUMENTS` — Refactoring description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), build config, project structure
2. Read affected code, identify current patterns
3. Check test coverage

## Phase 2: Plan
Delegate to the `backend-architect` subagent with refactoring goal and current patterns.

## Phase 3: Implement
Delegate to the `backend-builder` subagent with step-by-step instructions.

## Phase 4: Verify
Launch in parallel: build, tests, review.

## Phase 5: Fix Cycle
Max 2 rounds.

## Phase 6: Report
Present: what changed, build/test status, review findings, breaking changes.
