---
description: "Build the macOS project and report results"
---

# macOS Build

Build the current macOS project and report the result.

## Instructions

You are an orchestrator. Do NOT build the project yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read CLAUDE.md for project-specific build commands
2. Detect the project type:
   - `.xcworkspace` → use `-workspace`
   - `.xcodeproj` → use `-project`
   - `Package.swift` only → use `swift build`
3. Find the primary scheme with `xcodebuild -list`

## Phase 2: Build

Launch `xcode-builder` with:
- The project type and scheme detected above
- Platform: macOS
- Configuration: Debug
- Instructions to capture and report the full build output
- Instructions to fix any build errors (max 2 rounds)

## Phase 3: Report

Present:
- **Status**: PASS or FAIL
- **Errors**: file:line and error message (if any)
- **Warnings**: notable warnings (if any)
- **Build time**: duration
