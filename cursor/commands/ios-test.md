# iOS Test

Run tests for the current iOS project.

## Arguments

- `$ARGUMENTS` — (Optional) Specific test name, suite, or target. If empty, runs all tests.

## Instructions

You are an orchestrator. Do NOT run tests yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project-specific test commands
2. Detect project type and find the test scheme
3. Identify the correct simulator destination

## Phase 2: Test

Delegate to the `xcode-builder` subagent with:
- The project type and test scheme detected above
- Platform: iOS Simulator
- Action: test
- Test filter: `$ARGUMENTS` (if provided)
- For SPM projects: use `swift test` instead
- Instructions to capture and report the full test output

## Phase 3: Report

Present:
- **Status**: PASS or FAIL
- **Tests passed**: count
- **Tests failed**: count, with names and failure reasons
- **Duration**: total test time
