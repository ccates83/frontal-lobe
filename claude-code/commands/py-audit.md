---
description: Audit a Python project for quality, security, and best practices
argument-hint: "Audit focus (e.g., 'full', 'security', 'types', 'dependencies')"
---

# Python Project Audit

Audit a Python project for type safety, security, dependencies, and best practices.

## Arguments
- `$ARGUMENTS` — Optional focus area. Defaults to full audit.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read CLAUDE.md, `pyproject.toml`, project structure
2. Identify framework, Python version, tooling
3. Determine audit scope

## Phase 2: Audit
Launch `python-reviewer` with full project context and audit mode.

## Phase 3: Report
Present: critical findings, recommendations, priority action items.
