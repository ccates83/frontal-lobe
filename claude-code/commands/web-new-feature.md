---
description: Plan and implement a new web feature end-to-end
argument-hint: "Feature description (e.g., 'user profile page with avatar upload', 'shopping cart with Stripe checkout')"
---

# New Web Feature

Plan and implement a new web feature from architecture through testing.

## Arguments

- `$ARGUMENTS` — Description of the feature to implement.

## Instructions

You are an orchestrator. Do NOT implement the feature yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read CLAUDE.md for project conventions
2. Scan project structure:
   - `package.json` (framework, dependencies, scripts)
   - Framework config (`next.config.*`, `vite.config.*`, etc.)
   - `tsconfig.json`
   - Directory structure (routing, components, lib, hooks)
3. Read related existing code to understand patterns:
   - Similar features already implemented
   - Component patterns, data fetching patterns, styling approach
   - API/backend patterns if applicable
4. Check for design system components (`components/ui/`)
5. Summarize: stack, architecture, patterns, and relevant existing code

## Phase 2: Architecture

Launch `web-architect` with:
- The feature description
- Complete project context from Phase 1
- Request for a detailed blueprint: component design, data flow, file structure, API design (if needed)
- Request for implementation phases noting parallelizable work

## Phase 3: Implement

Based on the architect's blueprint, launch `web-builder` with:
- Each implementation phase as a specific task
- File paths and patterns to follow
- The architect's blueprint as reference
- Acceptance criteria for the feature
- Launch parallel builders for independent pieces when possible

## Phase 4: Test

Launch `web-tester` with:
- Instructions to write tests for the new feature
- Test patterns from existing tests
- Coverage targets: component tests, integration tests, and e2e if warranted
- Specific behaviors and edge cases to test

## Phase 5: Review

Launch `web-reviewer` with:
- All new/modified files from implementation
- The original feature requirements as acceptance criteria
- Instructions for performance, accessibility, and security review

## Phase 6: Fix Cycle

If the reviewer found critical or important issues:
1. Launch `web-builder` with the specific fixes
2. Maximum 2 fix rounds

## Phase 7: Report

Present:
- **Feature**: What was implemented
- **Files**: Created and modified
- **Architecture**: Key design decisions
- **Tests**: What's covered
- **Build**: Build status
- **Review**: Summary of review findings and fixes applied
- **Next steps**: Suggested follow-up work
