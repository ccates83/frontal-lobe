# New Mobile Feature

Plan and implement a cross-platform mobile feature from architecture through testing.

## Arguments
- `$ARGUMENTS` — Feature description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), `package.json`/`pubspec.yaml`, project structure
2. Identify framework, navigation, state management, existing patterns

## Phase 2: Architecture
Delegate to the `mobile-architect` subagent with feature description and project context.

## Phase 3: Implement
Delegate to the `mobile-builder` subagent with the architect's blueprint.

## Phase 4: Test
Delegate to the `mobile-tester` subagent with test instructions.

## Phase 5: Review
Delegate to the `mobile-reviewer` subagent with all new/modified files.

## Phase 6: Fix Cycle
Max 2 rounds.

## Phase 7: Report
Present: feature summary, files changed, platform notes, tests, review findings.
