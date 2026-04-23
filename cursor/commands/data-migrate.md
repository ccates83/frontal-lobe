# Database Migration

Create safe, reversible database migrations.

## Arguments
- `$ARGUMENTS` — Migration description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), existing schema, migration history
2. Identify migration tool (Prisma, Alembic, Django, Drizzle Kit, Flyway)
3. Understand the change needed

## Phase 2: Plan
Delegate to the `data-architect` subagent to analyze migration safety: lock implications, rollback plan, multi-step strategy if needed.

## Phase 3: Implement
Delegate to the `data-builder` subagent with migration instructions.

## Phase 4: Review
Delegate to the `data-reviewer` subagent to verify migration safety, reversibility, and performance impact.

## Phase 5: Report
Present: migration files created, rollback plan, lock analysis, deployment notes.
