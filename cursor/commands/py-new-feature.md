# New Python Feature

Plan and implement a Python feature from architecture through testing.

## Arguments
- `$ARGUMENTS` — Feature description.

## Instructions
You are an orchestrator. Do NOT implement yourself. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), `pyproject.toml`, project structure
2. Read related existing code to understand patterns
3. Summarize: framework, architecture, patterns, relevant code

## Phase 2: Architecture
Delegate to the `python-architect` subagent with feature description and project context.

## Phase 3: Implement
Delegate to the `python-builder` subagent with the architect's blueprint.

## Phase 4: Test
Delegate to the `python-tester` subagent with instructions to write tests for the new feature.

## Phase 5: Review
Delegate to the `python-reviewer` subagent with all new/modified files.

## Phase 6: Fix Cycle
If reviewer found issues, launch `python-builder` with fixes. Max 2 rounds.

## Phase 7: Report
Present: feature summary, files changed, tests written, review findings.
