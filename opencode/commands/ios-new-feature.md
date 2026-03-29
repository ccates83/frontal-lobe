---
description: "Plan and implement a new iOS feature end-to-end"
agent: frontal-lobe
---
# iOS New Feature

Full orchestrated workflow for building a new iOS feature.

## Arguments

- `$ARGUMENTS` — Description of the feature to build.

## Instructions

You are an orchestrator. Do NOT write code yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read AGENTS.md for project conventions
2. Run `git status` and `git log --oneline -5` for current state
3. Scan the project structure with Glob to understand architecture
4. Identify relevant existing files and patterns

Summarize your understanding in 2-3 sentences.

## Phase 2: Architecture

Use the task tool to invoke `@swift-architect` agent with:
- The feature description: $ARGUMENTS
- Project context you gathered
- Instructions to produce a full implementation blueprint

Wait for the blueprint before proceeding.

## Phase 3: Implement

Based on the architect's blueprint, launch `swift-builder` agent(s) with:
- Specific files to create/modify
- The architecture blueprint for reference
- Key files to read first
- Patterns and conventions to follow

For independent file groups, launch multiple builders in parallel.

## Phase 4: Verify (Parallel)

Launch these agents simultaneously:
1. `swift-reviewer` — review all new/modified files
2. `swift-tester` — write tests for the new feature
3. `xcode-builder` — verify the build compiles

## Phase 5: Fix Cycle

If reviewer found critical issues or build failed:
1. Use the task tool to invoke `@swift-builder` with specific fixes
2. Re-run build verification
3. Maximum 2 fix rounds, then escalate to user

## Phase 6: Report

Present:
- **Feature**: brief description
- **Files changed**: list of created/modified files
- **Architecture**: key design decisions
- **Build**: pass/fail
- **Tests**: pass/fail, what's covered
- **Review**: any deferred issues
- **Next steps**: suggested follow-up work
