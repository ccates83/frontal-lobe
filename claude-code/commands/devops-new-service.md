---
description: Set up infrastructure for a new service (Docker, K8s, Terraform)
argument-hint: "Service description (e.g., 'Node.js API with PostgreSQL on ECS', 'Go service on Kubernetes')"
---

# New Service Infrastructure

Set up infrastructure-as-code for a new service.

## Arguments
- `$ARGUMENTS` — Service description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, scan existing infrastructure
2. Identify patterns: cloud provider, container strategy, deployment approach
3. Understand the service requirements

## Phase 2: Architecture
Launch `devops-architect` with service description and existing infrastructure context.

## Phase 3: Implement
Launch `devops-builder` with the architect's blueprint.

## Phase 4: Review
Launch `devops-reviewer` with all new infrastructure files.

## Phase 5: Fix Cycle
If reviewer found issues, launch `devops-builder` with fixes. Max 2 rounds.

## Phase 6: Report
Present: infrastructure created, security notes, deployment instructions, cost estimate.
