---
description: Write an epic with stories and acceptance criteria
argument-hint: "Feature or initiative to plan (e.g., 'payment system migration', 'add dark mode support')"
---

# Write an Epic

Create an epic with detailed stories/tickets, acceptance criteria, and implementation guidance.

## Arguments

- `$ARGUMENTS` — The feature or initiative to plan.

## Instructions

You are an orchestrator. Do NOT write the epic yourself. Gather deep codebase context, then delegate.

## Phase 1: Deep Codebase Analysis

This phase is critical — epic quality depends entirely on understanding the codebase.

1. Read CLAUDE.md for project conventions and architecture
2. Map the relevant parts of the codebase:
   - Identify all files, modules, and systems that will be touched
   - Understand current architecture and data flow
   - Find existing patterns that new work should follow
   - Identify technical constraints and limitations
3. Read existing epics/planning docs to match format:
   - `ls docs/epics/ 2>/dev/null`
   - `ls docs/ plans/ 2>/dev/null`
4. Check git history for related work: `git log --oneline -20`
5. Identify dependencies — both internal (code dependencies) and external (APIs, services, teams)

Summarize: current state, what needs to change, key technical considerations.

## Phase 2: Plan the Epic Structure

Determine:
- **Stories**: Break the work into stories sized at 1-3 days each
- **Dependencies**: Map which stories depend on which
- **Order**: Determine implementation sequence
- **Risks**: Identify what could go wrong
- **Scope boundary**: What is explicitly out of scope

## Phase 3: Write

Launch `docs-planner` with:
- Initiative description: $ARGUMENTS
- Complete codebase analysis from Phase 1
- Number and structure of stories to create
- File path: `docs/epics/<epic-name>.md` (or matching existing convention)
- Instructions to:
  - Include specific file paths in technical notes for each story
  - Write testable acceptance criteria (not vague checkboxes)
  - Reference existing code patterns the implementer should follow
  - Include realistic effort estimates based on codebase complexity
  - Map dependencies between stories accurately
  - Flag risks with concrete mitigations

## Phase 4: Review

Launch `docs-reviewer` with:
- The epic document
- Instructions to verify:
  - All referenced file paths exist
  - Acceptance criteria are specific and testable
  - Dependencies are ordered correctly
  - Stories are appropriately sized (not too large, not too granular)
  - Technical notes are accurate

## Phase 5: Fix Cycle

If reviewer found issues:
1. Launch `docs-planner` with specific fixes
2. Maximum 2 rounds

## Phase 6: Report

Present:
- **Epic**: file path and title
- **Stories**: count and brief list
- **Estimated effort**: total T-shirt size
- **Critical path**: which stories are on the critical path
- **Risks**: top risks identified
- **Suggested start**: which story to tackle first and why
