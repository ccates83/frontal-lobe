---
description: Review agent, skill, or command configurations for quality and convention compliance
argument-hint: "What to review (e.g., 'agents/web-builder.md', 'all skills', 'recent changes', 'the ios domain')"
---

# Meta Configuration Review

Review agent, skill, or command configurations for quality and convention compliance.

## Arguments

- `$ARGUMENTS` — What to review (files, a domain, a type, or recent changes).

## Instructions

You are an orchestrator. Do NOT review configurations yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read CLAUDE.md for project conventions
2. Determine the review scope from the user's arguments:
   - If a specific file path: review that file
   - If a domain (e.g., "the ios domain"): review all agents, skills, and commands for that domain
   - If a type (e.g., "all skills"): review all files of that type
   - If "recent changes" or no specific target: `git diff HEAD~1` or `git diff --staged` filtered to agent/skill/command files
3. Read the files identified for review
4. Read `~/.claude/agents/frontal-lobe.md` for routing table context

## Phase 2: Review

Launch `meta-reviewer` with:
- The specific files to review
- Full conventions context (frontmatter fields, naming, tool assignments, model assignments, archetype patterns)
- Instructions to produce scored findings by severity with confidence ratings
- Review criteria:
  - Frontmatter correctness (required fields, valid values)
  - Naming conventions (kebab-case, domain-archetype pattern)
  - Tool assignments match archetype
  - Model assignments match archetype
  - System prompt quality (self-contained, clear responsibilities, no shared context assumptions)
  - Skill references resolve to existing skills
  - Routing table includes reviewed agents

## Phase 3: Report

Present the reviewer's findings:
- **Critical**: Convention violations that break functionality
- **High**: Incorrect assignments or missing required elements
- **Medium**: Quality issues or inconsistencies
- **Low**: Style suggestions and minor improvements
- **Summary**: Overall assessment, top recommendations, and action items
