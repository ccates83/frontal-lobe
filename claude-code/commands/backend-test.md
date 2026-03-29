---
description: Run backend tests (Go, Rust, Java/Kotlin, C#)
argument-hint: "Test scope (e.g., 'all', './internal/service/', 'integration', '-run TestUser')"
---

# Run Backend Tests

Run the backend project's test suite.

## Arguments
- `$ARGUMENTS` — Optional test scope or filter.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, identify language and test framework
2. Determine test command

## Phase 2: Run Tests
Launch `backend-tester` with the test command and scope.

## Phase 3: Report
Present: pass/fail counts, failures with details, coverage if available.
