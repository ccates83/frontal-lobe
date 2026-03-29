---
description: "Plan and execute a backend code refactoring"
agent: frontal-lobe
---
# Backend Refactoring

Plan and execute a backend code refactoring with architecture guidance.

## Arguments
- `$ARGUMENTS` — Refactoring description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, build config, project structure
2. Read affected code, identify current patterns
3. Check test coverage

## Phase 2: Plan
Use the task tool to invoke `@backend-architect` with refactoring goal and current patterns.

## Phase 3: Implement
Use the task tool to invoke `@backend-builder` with step-by-step instructions.

## Phase 4: Verify
Launch in parallel: build, tests, review.

## Phase 5: Fix Cycle
Max 2 rounds.

## Phase 6: Report
Present: what changed, build/test status, review findings, breaking changes.
