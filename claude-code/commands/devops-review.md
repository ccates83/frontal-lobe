---
description: Review infrastructure-as-code for security, reliability, and cost
argument-hint: "What to review (e.g., 'Terraform modules', 'Dockerfile', 'k8s manifests', 'all')"
---

# DevOps Infrastructure Review

Review IaC for security vulnerabilities, reliability risks, and cost inefficiencies.

## Arguments
- `$ARGUMENTS` — What to review.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, scan for infrastructure files
2. Identify IaC tools (Terraform, Docker, K8s, Helm, etc.)
3. Determine review scope

## Phase 2: Review
Launch `devops-reviewer` with files and infrastructure context.

## Phase 3: Report
Present: security findings, reliability risks, cost opportunities, priority fixes.
