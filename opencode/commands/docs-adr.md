---
description: "Write an Architecture Decision Record (ADR)"
agent: frontal-lobe
---
# Write an Architecture Decision Record

Create an ADR documenting an architecture decision with context, alternatives, and consequences.

## Arguments

- `$ARGUMENTS` — The architecture decision to document.

## Instructions

You are an orchestrator. Do NOT write the ADR yourself. Gather deep technical context, then delegate.

## Phase 1: Understand the Decision Context

1. Read AGENTS.md for project architecture and conventions
2. Analyze the codebase for evidence of the decision:
   - What technology/pattern is currently in use?
   - What code would be affected by this decision?
   - What constraints does the current architecture impose?
3. Check for existing ADRs to match format and numbering:
   - `ls docs/adr/ docs/decisions/ docs/ADR* 2>/dev/null`
4. Research the alternatives mentioned in the user's description:
   - What trade-offs exist between the options?
   - What is the team's existing expertise?
   - What are the operational implications of each choice?
5. Determine the next ADR number if a numbering scheme exists

Summarize: the decision context, key constraints, and alternatives to evaluate.

## Phase 2: Plan the ADR

Determine:
- **ADR number**: Next in sequence or first if no ADRs exist
- **Alternatives**: At least 2-3 alternatives to evaluate (including the chosen one)
- **Key trade-offs**: What factors matter most for this decision
- **Consequences**: Both positive and negative outcomes of the chosen approach
- **File location**: `docs/adr/ADR-NNN-<title>.md` or matching existing convention

## Phase 3: Write

Use the task tool to invoke `@docs-writer` with:
- Decision description: $ARGUMENTS
- Complete technical context from Phase 1
- ADR template structure
- Alternatives to evaluate with their trade-offs
- File path determined in Phase 2
- Instructions to:
  - Ground the context in the actual codebase state
  - Be objective about trade-offs — acknowledge real downsides of the chosen approach
  - Include at least 2 alternatives with specific pros/cons
  - Make consequences concrete and measurable where possible
  - Set the status to "Proposed" (not "Accepted" — the user/team decides acceptance)

## Phase 4: Review

Use the task tool to invoke `@docs-reviewer` with:
- The ADR document
- Instructions to verify:
  - Context accurately describes the current state
  - All alternatives are fairly evaluated (no straw-man arguments)
  - Consequences are honest (not just marketing the chosen option)
  - Technical claims are verified against the codebase
  - The decision follows logically from the context

## Phase 5: Fix Cycle

If reviewer found issues:
1. Use the task tool to invoke `@docs-writer` with specific fixes
2. Maximum 2 rounds

## Phase 6: Report

Present:
- **ADR**: file path and number
- **Decision**: one-line summary
- **Alternatives evaluated**: list
- **Key trade-off**: the most significant trade-off in the decision
- **Status**: Proposed (remind user to change to Accepted after team review)
- **Next steps**: what to do with the ADR (team review, update related docs)
