---
description: "Write a Product Requirements Document (PRD)"
agent: frontal-lobe
---
# Write a Product Requirements Document

Create a comprehensive PRD for a feature or product.

## Arguments

- `$ARGUMENTS` — The feature or product to document.

## Instructions

You are an orchestrator. Do NOT write the PRD yourself. Gather deep context, then delegate.

## Phase 1: Understand Context

1. Read AGENTS.md for project context
2. Scan the codebase to understand current state:
   - What exists today related to this feature?
   - What tech stack and architecture patterns are in use?
   - What constraints exist (platform, framework, dependencies)?
3. Read any existing planning docs in `docs/`, `plans/`, or similar directories
4. Check git history for related prior work: `git log --oneline --all --grep="<relevant-keyword>" 2>/dev/null | head -10`
5. Read existing PRDs to match format if any exist

Summarize what exists today and what the feature needs to accomplish.

## Phase 2: Plan the PRD

Determine:
- **Scope**: What the PRD should cover (full product vs. feature vs. enhancement)
- **Audience**: Who will review and approve this (product, engineering, leadership)
- **Key sections**: Problem, goals, requirements, design considerations, metrics
- **Technical depth**: How much implementation detail to include
- **Open questions**: What information is missing that should be flagged as TBD

## Phase 3: Write

Use the task tool to invoke `@docs-writer` with:
- Feature description: $ARGUMENTS
- Complete project context from Phase 1
- PRD template structure (from docs-patterns skill if available)
- Audience: product and engineering stakeholders
- Tone: clear, decisive, business-value focused
- File path: `docs/PRD-<feature-name>.md` (or matching existing convention)
- Instructions to:
  - Ground requirements in the actual codebase and tech stack
  - Be specific about technical constraints discovered during context gathering
  - Flag genuine open questions as TBD rather than guessing
  - Include success metrics that are measurable

## Phase 4: Review

Use the task tool to invoke `@docs-reviewer` with:
- The PRD document
- Instructions to verify:
  - Technical claims match the codebase
  - Requirements are specific and testable
  - Scope is clearly bounded (in-scope vs out-of-scope)
  - No critical sections are missing

## Phase 5: Fix Cycle

If reviewer found issues:
1. Use the task tool to invoke `@docs-writer` with specific fixes
2. Maximum 2 rounds

## Phase 6: Report

Present:
- **PRD**: file path
- **Feature**: one-line summary
- **Key decisions**: any significant scoping or requirement choices
- **Open questions**: items flagged as TBD that need stakeholder input
- **Next steps**: suggest creating an epic to break the PRD into implementable work
