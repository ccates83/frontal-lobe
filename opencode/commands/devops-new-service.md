---
description: "Set up infrastructure for a new service (Docker, K8s, Terraform)"
agent: frontal-lobe
---
# New Service Infrastructure

Set up infrastructure-as-code for a new service.

## Arguments
- `$ARGUMENTS` — Service description.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, scan existing infrastructure
2. Identify patterns: cloud provider, container strategy, deployment approach
3. Understand the service requirements

## Phase 2: Architecture
Use the task tool to invoke `@devops-architect` with service description and existing infrastructure context.

## Phase 3: Implement
Use the task tool to invoke `@devops-builder` with the architect's blueprint.

## Phase 4: Review
Use the task tool to invoke `@devops-reviewer` with all new infrastructure files.

## Phase 5: Fix Cycle
If reviewer found issues, launch `devops-builder` with fixes. Max 2 rounds.

## Phase 6: Report
Present: infrastructure created, security notes, deployment instructions, cost estimate.
