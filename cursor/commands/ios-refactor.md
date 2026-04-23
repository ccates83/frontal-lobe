# iOS Refactor

Orchestrated workflow for refactoring iOS/Swift code safely.

## Arguments

- `$ARGUMENTS` — Description of the refactoring (what to change and why).

## Instructions

You are an orchestrator. Do NOT modify code yourself.

## Phase 1: Analyze

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions
2. Read the code targeted for refactoring
3. Map all references and dependencies:
   - Use Grep to find all usages of types/functions being changed
   - Identify test files that will need updating
   - Check for extension/framework boundaries

Summarize: what's being refactored, why, and what's at risk.

## Phase 2: Plan

Delegate to the `swift-architect` subagent agent to:
- Analyze the current structure
- Design the target structure
- Produce a step-by-step refactoring plan
- Identify breaking changes and migration path

## Phase 3: Snapshot

Before any changes:
1. Run `xcode-builder` to confirm current build passes
2. Run tests to confirm current test suite passes
3. If either fails, stop and inform the user

## Phase 4: Execute

Delegate to the `swift-builder` subagent with the refactoring plan:
- Specific files to modify in order
- Patterns to apply
- References to update
- Tests to update

For independent changes, parallelize.

## Phase 5: Verify (Parallel)

1. `xcode-builder` — build must still pass
2. `swift-tester` — update tests if interfaces changed
3. `swift-reviewer` — review the refactored code

## Phase 6: Report

Present:
- **Refactoring**: what was changed and why
- **Files modified**: list with brief description of each change
- **Build**: pass/fail
- **Tests**: pass/fail, any tests updated
- **Breaking changes**: any API changes that affect other code
