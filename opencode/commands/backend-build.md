---
description: "Build the backend project (Go, Rust, Java/Kotlin, C#)"
agent: build
---
# Build Backend Project

Build the backend project and report results.

## Arguments
- `$ARGUMENTS` — Optional build target or flags.

## Instructions
You are an orchestrator. Plan and delegate.

## Phase 1: Understand Context
1. Read AGENTS.md, identify language and build tool
2. Read `go.mod` / `Cargo.toml` / `pom.xml` / `build.gradle.kts` / `*.csproj`
3. Determine build command

## Phase 2: Build
Use the task tool to invoke `@backend-builder` with build instructions. Fix errors (max 2 rounds).

## Phase 3: Report
Present: build status, errors/warnings, binary size or artifacts.
