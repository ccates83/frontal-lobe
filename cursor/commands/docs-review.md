# Review Documentation

Audit documentation for quality, completeness, accuracy against the codebase, and consistency.

## Arguments

- `$ARGUMENTS` — The scope of the review (specific file, directory, or "all docs").

## Instructions

You are an orchestrator. Do NOT review docs yourself. Determine scope, then delegate to the reviewer.

## Phase 1: Determine Review Scope

1. Identify what to review based on $ARGUMENTS:
   - Specific file: verify it exists
   - Directory: `ls <directory>` to list all docs
   - "all docs" or empty: find all documentation files:
     ```bash
     find . -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" | head -50
     ```
2. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions
3. Categorize each document by type (README, PRD, ADR, epic, contributing guide, etc.)

Summarize: number of documents, types found, review scope.

## Phase 2: Review

For small scope (1-3 documents), launch a single `docs-reviewer`:
- All documents to review
- Project context from project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md))
- Document types for appropriate completeness checklists

For large scope (4+ documents), launch multiple `docs-reviewer` agents in parallel:
- Split documents into groups of 2-3
- Each reviewer gets a subset
- All reviewers get the same project context

Ensure each reviewer:
- Verifies technical claims against the codebase (file paths, commands, code examples)
- Checks completeness based on document type
- Assesses clarity and accuracy
- Rates findings by severity (Critical / Important / Minor)

## Phase 3: Synthesize

Collect all reviewer results and produce a unified report:

1. **Deduplicate**: Remove findings reported by multiple reviewers
2. **Prioritize**: Order by severity (Critical first)
3. **Cross-reference**: Note if multiple docs have the same stale information (systemic issue)
4. **Summarize**: Overall documentation health assessment

## Phase 4: Report

Present:
- **Documents reviewed**: count and list
- **Overall health**: Good / Needs Work / Needs Significant Attention
- **Critical issues**: must-fix items (wrong commands, incorrect file paths, misleading information)
- **Important issues**: should-fix items (missing sections, incomplete information)
- **Minor issues**: nice-to-have improvements
- **Systemic issues**: patterns that appear across multiple documents
- **Suggested actions**: prioritized list of what to fix first
- Ask if the user wants to fix any issues now (delegate to `docs-writer` for fixes)
