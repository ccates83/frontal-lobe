---
description: "Code review for web/frontend/backend changes"
agent: plan
---
# Web Code Review

Review web code for bugs, performance, accessibility, security, and convention violations.

## Arguments

- `$ARGUMENTS` — What to review (files, directories, recent changes, or PR).

## Instructions

You are an orchestrator. Do NOT review code yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read AGENTS.md for project conventions
2. Read `package.json` for stack information
3. Determine the review scope from the user's arguments:
   - If "recent changes" or no specific files: `git diff HEAD~1` or `git diff --staged`
   - If a directory or file path: review those files
   - If a PR number: `gh pr diff <number>`
4. Identify the changed files and their purpose

## Phase 2: Review

Use the task tool to invoke `@web-reviewer` with:
- The specific files to review
- Project conventions and stack context
- Instructions to produce scored findings by severity
- Any specific focus area the user requested (performance, a11y, security)

## Phase 3: Report

Present the reviewer's findings:
- **Critical**: Issues that must be fixed
- **Important**: Issues that should be fixed
- **Low**: Suggestions for improvement
- **Summary**: Overall assessment and top recommendations
