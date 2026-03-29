---
description: "Run database and data pipeline tests"
agent: build
---
# Run Data Tests

Run database schema, migration, query, and data pipeline tests.

## Arguments
- `$ARGUMENTS` — Optional test scope or filter.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, identify ORM/framework and test framework
2. Determine test command and scope

## Phase 2: Run Tests
Use the task tool to invoke `@data-tester` with the test command and scope.

## Phase 3: Report
Present: pass/fail counts, failures with details, coverage if available.
