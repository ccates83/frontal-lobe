---
description: "Plan and implement a new backend feature end-to-end"
agent: frontal-lobe
---
# New Backend Feature

Plan and implement a backend feature from architecture through testing.

## Arguments
- `$ARGUMENTS` — Feature description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, build config, project structure
2. Identify language, framework, patterns
3. Read related existing code

## Phase 2: Architecture
Use the task tool to invoke `@backend-architect` with feature description and context.

## Phase 3: Implement
Use the task tool to invoke `@backend-builder` with the architect's blueprint.

## Phase 4: Test
Use the task tool to invoke `@backend-tester` with test instructions.

## Phase 5: Review
Use the task tool to invoke `@backend-reviewer` with all new/modified files.

## Phase 6: Fix Cycle
Max 2 rounds.

## Phase 7: Report
Present: feature summary, files changed, build/test status, review findings.
