---
description: Review database schema, queries, or migrations for correctness and performance
argument-hint: "What to review (e.g., 'schema', 'slow queries', 'recent migrations', 'all')"
---

# Data Review

Review database code for correctness, performance, and security.

## Arguments
- `$ARGUMENTS` — What to review.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, existing schema, ORM config
2. Determine review scope

## Phase 2: Review
Launch `data-reviewer` with files and context.

## Phase 3: Report
Present: findings by severity, performance recommendations, security concerns.
