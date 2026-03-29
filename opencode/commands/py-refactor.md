---
description: "Plan and execute a Python code refactoring"
agent: frontal-lobe
---
# Python Refactoring

Plan and execute a Python code refactoring with architecture guidance.

## Arguments
- `$ARGUMENTS` — Refactoring description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, `pyproject.toml`, project structure
2. Read affected code, identify current patterns
3. Check test coverage for affected code

## Phase 2: Plan
Use the task tool to invoke `@python-architect` with refactoring goal and current patterns.

## Phase 3: Implement
Use the task tool to invoke `@python-builder` with step-by-step instructions from the architect.

## Phase 4: Verify
Launch in parallel: `python-builder` (run build/lint/typecheck), `python-tester` (run tests), `python-reviewer` (review).

## Phase 5: Fix Cycle
Fix any build failures or test regressions. Max 2 rounds.

## Phase 6: Report
Present: what changed, build/test status, review findings, breaking changes.
