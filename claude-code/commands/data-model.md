---
description: Design or modify a database schema / data model
argument-hint: "What to model (e.g., 'multi-tenant SaaS schema', 'add orders table', 'optimize user queries')"
---

# Data Modeling

Design or modify a database schema with migration safety.

## Arguments
- `$ARGUMENTS` — What to model or change.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, scan for database files
2. Read existing schema (Prisma, Drizzle, SQLAlchemy, Django models, raw SQL)
3. Read migration history
4. Identify ORM and migration tool

## Phase 2: Design
Launch `data-architect` with the modeling request and current schema context.

## Phase 3: Implement
Launch `data-builder` with the architect's schema design and migration plan.

## Phase 4: Review
Launch `data-reviewer` with the new schema and migration files.

## Phase 5: Fix Cycle
If reviewer found issues, launch `data-builder` with fixes. Max 2 rounds.

## Phase 6: Report
Present: schema changes, migration files, indexes added, rollback instructions, performance impact.
