---
description: Build/check the Python project (type check, lint, test)
argument-hint: "Check scope (e.g., 'all', 'typecheck', 'lint', 'test')"
---

# Python Build/Check

Run Python project checks: type checking, linting, formatting, and tests.

## Arguments
- `$ARGUMENTS` — Optional scope. Defaults to all checks.

## Instructions
You are an orchestrator. Do NOT run checks yourself. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md for project conventions
2. Read `pyproject.toml` for: tools (ruff, mypy, pytest), scripts, Python version
3. Identify package manager (uv, poetry, pip)
4. Determine which checks to run from the user's scope

## Phase 2: Execute
Launch `python-builder` with instructions to run the appropriate checks:
- Type check: `mypy .` or `pyright`
- Lint: `ruff check .`
- Format check: `ruff format --check .`
- Tests: `pytest`
- Fix any issues (max 2 rounds)

## Phase 3: Report
Present: status per check, any errors/warnings, fix suggestions.
