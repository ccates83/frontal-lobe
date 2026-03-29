---
description: Write a technical document (README, design doc, contributing guide, setup guide, API docs)
argument-hint: "What to document (e.g., 'README for this project', 'API docs for the auth module', 'contributing guide')"
---

# Write Technical Documentation

Write a technical document based on the user's request.

## Arguments

- `$ARGUMENTS` — Description of the document to write.

## Instructions

You are an orchestrator. Do NOT write documentation yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read CLAUDE.md for project conventions
2. Scan project structure to understand language, framework, and layout:
   - `ls -la` at root
   - Check for package.json, Cargo.toml, go.mod, Package.swift, pyproject.toml, pom.xml, etc.
3. Read existing documentation:
   - `ls docs/ 2>/dev/null`
   - Read README.md if it exists
   - Read CONTRIBUTING.md if it exists
4. Check git history for project context: `git log --oneline -15`
5. Identify the document type from the user's description

Summarize: project type, existing docs, and what needs to be written.

## Phase 2: Plan the Document

Based on the user's description, determine:
- **Document type**: README, design doc, contributing guide, API docs, setup guide, etc.
- **Audience**: developers, contributors, stakeholders, end-users
- **File location**: where to create the document
- **Sections**: high-level outline
- **Source material**: which code files, configs, or docs the writer needs to read

## Phase 3: Write

Launch `docs-writer` with:
- The document type and outline
- Complete project context gathered in Phase 1
- Audience and tone guidance
- Specific source files to read for accuracy
- Output file path
- Any existing documents to match style with

## Phase 4: Review

Launch `docs-reviewer` with:
- The newly created document
- Instructions to verify all technical claims against the codebase
- The document type (for completeness checklist)

## Phase 5: Fix Cycle

If the reviewer found critical or important issues:
1. Launch `docs-writer` with the specific fixes
2. Maximum 2 fix rounds

## Phase 6: Report

Present:
- **Document**: file path and type
- **Sections**: what was covered
- **Verified**: what was checked against the codebase
- **Gaps**: any sections marked TODO or needing user input
- **Next steps**: suggested follow-up docs
