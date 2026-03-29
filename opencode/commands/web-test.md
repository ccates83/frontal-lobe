---
description: "Run web tests (all or specific)"
agent: build
---
# Run Web Tests

Run the project's test suite and report results.

## Arguments

- `$ARGUMENTS` — Optional test scope, file path, or test name filter.

## Instructions

You are an orchestrator. Do NOT run tests yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read AGENTS.md for test conventions
2. Read `package.json` for:
   - Test scripts (`test`, `test:unit`, `test:e2e`, `test:integration`)
   - Test framework (`vitest`, `jest`, `playwright`, `cypress`)
   - Package manager
3. Read test config if present (`vitest.config.ts`, `jest.config.*`, `playwright.config.ts`)
4. Determine the appropriate test command based on the user's scope argument

## Phase 2: Run Tests

Use the task tool to invoke `@web-tester` with:
- The test command to run
- Any file or name filters from the user's arguments
- Instructions to capture and report full test output
- Instructions to report pass/fail counts and any failures

## Phase 3: Report

Present:
- **Status**: All passed / some failed
- **Results**: Pass/fail/skip counts
- **Failures**: For each failure: test name, file, error message, relevant stack trace
- **Coverage**: If coverage was generated, show key numbers
- **Next steps**: Suggested fixes for any failures
