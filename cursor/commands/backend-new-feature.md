# New Backend Feature

Plan and implement a backend feature from architecture through testing.

## Arguments
- `$ARGUMENTS` — Feature description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), build config, project structure
2. Identify language, framework, patterns
3. Read related existing code

## Phase 2: Architecture
Delegate to the `backend-architect` subagent with feature description and context.

## Phase 3: Implement
Delegate to the `backend-builder` subagent with the architect's blueprint.

## Phase 4: Test
Delegate to the `backend-tester` subagent with test instructions.

## Phase 5: Review
Delegate to the `backend-reviewer` subagent with all new/modified files.

## Phase 6: Fix Cycle
Max 2 rounds.

## Phase 7: Report
Present: feature summary, files changed, build/test status, review findings.
