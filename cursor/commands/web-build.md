# Build Web Project

Build the web project and report results.

## Arguments

- `$ARGUMENTS` — Optional build target, flags, or context.

## Instructions

You are an orchestrator. Do NOT build the project yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions and build commands
2. Read `package.json` for:
   - Build script (`scripts.build`)
   - Package manager (`packageManager` field, or check for `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`)
   - Framework (Next.js, Vite, etc.)
3. Check for environment configuration (`.env.example`, `.env.local`)
4. Identify the build command to run

## Phase 2: Build

Delegate to the `web-builder` subagent with:
- Instructions to run the project's build command
- Framework-specific build flags if relevant
- Instructions to capture and report the full build output
- Instructions to fix any build errors (max 2 rounds)

## Phase 3: Report

Present:
- **Status**: Build succeeded or failed
- **Output**: Key build metrics (bundle sizes, page counts, warnings)
- **Errors**: Any errors or warnings that need attention
- **Duration**: Build time if reported
