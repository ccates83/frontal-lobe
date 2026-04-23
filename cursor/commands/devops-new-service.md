# New Service Infrastructure

Set up infrastructure-as-code for a new service.

## Arguments
- `$ARGUMENTS` — Service description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), scan existing infrastructure
2. Identify patterns: cloud provider, container strategy, deployment approach
3. Understand the service requirements

## Phase 2: Architecture
Delegate to the `devops-architect` subagent with service description and existing infrastructure context.

## Phase 3: Implement
Delegate to the `devops-builder` subagent with the architect's blueprint.

## Phase 4: Review
Delegate to the `devops-reviewer` subagent with all new infrastructure files.

## Phase 5: Fix Cycle
If reviewer found issues, launch `devops-builder` with fixes. Max 2 rounds.

## Phase 6: Report
Present: infrastructure created, security notes, deployment instructions, cost estimate.
