---
description: Plan and execute a web code refactoring
argument-hint: "What to refactor (e.g., 'migrate to App Router', 'extract shared hooks', 'convert to TypeScript')"
---

# Web Refactoring

Plan and execute a web code refactoring with architecture guidance.

## Arguments

- `$ARGUMENTS` — Description of the refactoring.

## Instructions

You are an orchestrator. Do NOT refactor code yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read CLAUDE.md for project conventions
2. Read `package.json` for stack information
3. Identify the files and patterns affected by the refactoring
4. Read representative files to understand current patterns
5. Check test coverage for affected code: existing tests that must still pass

## Phase 2: Plan

Launch `web-architect` with:
- The refactoring goal and scope
- Current code patterns to change
- Target patterns to achieve
- Request for: migration plan, dependency graph, risk assessment, rollback strategy

## Phase 3: Implement

Based on the architect's plan, launch `web-builder` with:
- Step-by-step refactoring instructions
- File-by-file changes to make
- Instructions to verify the build after each logical step
- Patterns to follow in the refactored code

## Phase 4: Verify

Launch in parallel:
- `web-builder` to run the build and fix any errors
- `web-tester` to run existing tests and verify nothing broke
- `web-reviewer` to review the refactored code for quality

## Phase 5: Fix Cycle

If build fails or tests break:
1. Launch `web-builder` with specific fixes
2. Re-run affected tests
3. Maximum 2 fix rounds

## Phase 6: Report

Present:
- **Refactoring**: What was changed and why
- **Files**: Modified, created, deleted
- **Build**: Status
- **Tests**: Pass/fail status (especially previously passing tests)
- **Review**: Any concerns from the reviewer
- **Breaking changes**: If any API or interface changes affect other code
