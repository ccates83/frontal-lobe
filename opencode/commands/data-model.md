---
description: "Design or modify a database schema / data model"
agent: frontal-lobe
---
# Data Modeling

Design or modify a database schema with migration safety.

## Arguments
- `$ARGUMENTS` — What to model or change.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, scan for database files
2. Read existing schema (Prisma, Drizzle, SQLAlchemy, Django models, raw SQL)
3. Read migration history
4. Identify ORM and migration tool

## Phase 2: Design
Use the task tool to invoke `@data-architect` with the modeling request and current schema context.

## Phase 3: Implement
Use the task tool to invoke `@data-builder` with the architect's schema design and migration plan.

## Phase 4: Review
Use the task tool to invoke `@data-reviewer` with the new schema and migration files.

## Phase 5: Fix Cycle
If reviewer found issues, launch `data-builder` with fixes. Max 2 rounds.

## Phase 6: Report
Present: schema changes, migration files, indexes added, rollback instructions, performance impact.
