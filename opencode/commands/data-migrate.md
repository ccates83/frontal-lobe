---
description: "Create or review database migrations"
agent: frontal-lobe
---
# Database Migration

Create safe, reversible database migrations.

## Arguments
- `$ARGUMENTS` — Migration description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, existing schema, migration history
2. Identify migration tool (Prisma, Alembic, Django, Drizzle Kit, Flyway)
3. Understand the change needed

## Phase 2: Plan
Use the task tool to invoke `@data-architect` to analyze migration safety: lock implications, rollback plan, multi-step strategy if needed.

## Phase 3: Implement
Use the task tool to invoke `@data-builder` with migration instructions.

## Phase 4: Review
Use the task tool to invoke `@data-reviewer` to verify migration safety, reversibility, and performance impact.

## Phase 5: Report
Present: migration files created, rollback plan, lock analysis, deployment notes.
