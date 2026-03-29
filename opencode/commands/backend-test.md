---
description: "Run backend tests (Go, Rust, Java/Kotlin, C#)"
agent: build
---
# Run Backend Tests

Run the backend project's test suite.

## Arguments
- `$ARGUMENTS` — Optional test scope or filter.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, identify language and test framework
2. Determine test command

## Phase 2: Run Tests
Use the task tool to invoke `@backend-tester` with the test command and scope.

## Phase 3: Report
Present: pass/fail counts, failures with details, coverage if available.
