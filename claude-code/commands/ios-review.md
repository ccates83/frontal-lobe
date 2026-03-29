---
description: Code review for iOS/Swift changes
argument-hint: File paths or scope to review (e.g., "Services/", "last commit", "staged")
---

# iOS Code Review

Run a comprehensive iOS code review on the specified scope.

## Arguments

- `$ARGUMENTS` — Scope of the review. Can be:
  - File or directory paths (e.g., `Sources/Networking/`)
  - `staged` — review staged git changes
  - `last commit` — review the last commit
  - `branch` — review all changes on the current branch vs main

## Instructions

You are an orchestrator for this review. Do NOT review code yourself. Delegate to the `swift-reviewer` agent.

1. Determine the scope:
   - If `staged`: run `git diff --cached --name-only` to get files
   - If `last commit`: run `git diff HEAD~1 --name-only` to get files
   - If `branch`: run `git diff main...HEAD --name-only` to get files
   - Otherwise: use the provided paths

2. Filter to only `.swift` files

3. Launch the `swift-reviewer` agent with:
   - The list of files to review
   - The diff context (if available)
   - Instructions to read CLAUDE.md first
   - Request confidence-scored findings

4. Report the reviewer's findings to the user
