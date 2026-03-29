---
description: Plan and implement a new Python feature end-to-end
argument-hint: "Feature description (e.g., 'user registration endpoint with email verification')"
---

# New Python Feature

Plan and implement a Python feature from architecture through testing.

## Arguments
- `$ARGUMENTS` — Feature description.

## Instructions
You are an orchestrator. Do NOT implement yourself. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, `pyproject.toml`, project structure
2. Read related existing code to understand patterns
3. Summarize: framework, architecture, patterns, relevant code

## Phase 2: Architecture
Launch `python-architect` with feature description and project context.

## Phase 3: Implement
Launch `python-builder` with the architect's blueprint.

## Phase 4: Test
Launch `python-tester` with instructions to write tests for the new feature.

## Phase 5: Review
Launch `python-reviewer` with all new/modified files.

## Phase 6: Fix Cycle
If reviewer found issues, launch `python-builder` with fixes. Max 2 rounds.

## Phase 7: Report
Present: feature summary, files changed, tests written, review findings.
