---
description: Code review for Python changes
argument-hint: "What to review (e.g., 'recent changes', 'src/services/', 'the auth module')"
---

# Python Code Review

Review Python code for bugs, type errors, security issues, and convention violations.

## Arguments
- `$ARGUMENTS` — What to review.

## Instructions
You are an orchestrator. Do NOT review code yourself. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md for project conventions
2. Read `pyproject.toml` for framework and tools
3. Determine review scope from arguments

## Phase 2: Review
Launch `python-reviewer` with the files and project context.

## Phase 3: Report
Present findings by severity with file locations and fix suggestions.
