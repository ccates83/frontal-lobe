---
description: "Code review for backend (Go, Rust, Java/Kotlin, C#) changes"
agent: plan
---
# Backend Code Review

Review backend code for bugs, concurrency issues, security, and convention violations.

## Arguments
- `$ARGUMENTS` — What to review.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, identify language and framework
2. Determine review scope

## Phase 2: Review
Use the task tool to invoke `@backend-reviewer` with files and project context.

## Phase 3: Report
Present: findings by severity, concurrency notes, security concerns.
