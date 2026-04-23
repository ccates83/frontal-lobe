# Build Backend Project

Build the backend project and report results.

## Arguments
- `$ARGUMENTS` — Optional build target or flags.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)), identify language and build tool
2. Read `go.mod` / `Cargo.toml` / `pom.xml` / `build.gradle.kts` / `*.csproj`
3. Determine build command

## Phase 2: Build
Delegate to the `backend-builder` subagent with build instructions. Fix errors (max 2 rounds).

## Phase 3: Report
Present: build status, errors/warnings, binary size or artifacts.
