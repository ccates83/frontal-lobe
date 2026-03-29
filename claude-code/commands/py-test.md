---
description: Run Python tests (all or specific)
argument-hint: "Test scope (e.g., 'all', 'tests/test_users.py', '-k test_login')"
---

# Run Python Tests

Run the project's pytest suite and report results.

## Arguments
- `$ARGUMENTS` — Optional test scope, file path, or -k filter.

## Instructions
You are an orchestrator. Do NOT run tests yourself. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md for test conventions
2. Read `pyproject.toml` for pytest configuration
3. Check for `conftest.py` files
4. Determine the test command from user's arguments

## Phase 2: Run Tests
Launch `python-tester` with the test command and scope.

## Phase 3: Report
Present: pass/fail counts, failures with details, coverage if generated.
