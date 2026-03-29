---
description: "Audit an iOS project for health, best practices, and common issues"
agent: plan
---
# iOS Project Audit

Comprehensive health check for an iOS project.

## Arguments

- `$ARGUMENTS` — (Optional) Focus area for the audit. If empty, runs a full audit.

## Instructions

You are an orchestrator. Analyze the project and delegate review tasks.

## Phase 1: Project Discovery

1. Read AGENTS.md if present
2. Map the project structure:
   - Targets and their types (app, extension, test, framework)
   - Deployment target and Swift version
   - Dependencies (SPM, CocoaPods, Carthage)
   - Build settings (concurrency mode, signing, etc.)
3. Count: Swift files, test files, lines of code (approximate)
4. Check git status for uncommitted changes

## Phase 2: Targeted Audits

Run these checks in parallel (or only the focus area if specified):

### Architecture Audit
- Is there a consistent architecture pattern?
- Are concerns properly separated (no business logic in views)?
- Is the dependency graph clean (no circular deps)?
- Are there god objects or massive files (>500 lines)?

### Concurrency Audit
- Is strict concurrency enabled? What mode?
- Are there data race risks (shared mutable state without actors)?
- Are closures properly using [weak self]?
- Is MainActor used correctly for UI code?

### Memory Audit
- Grep for potential retain cycles (closures capturing self without weak)
- Check delegates are declared weak
- Check for large allocations in extensions
- Look for notification observers without removal

### Dependency Audit
- Are dependencies up to date?
- Are there unused dependencies?
- Are there dependencies with known security issues?
- Could any dependency be replaced with Apple frameworks?

### Test Coverage Audit
- What percentage of source files have corresponding tests?
- Which critical paths lack tests?
- Are tests using the modern framework (Swift Testing)?
- Are there flaky tests or disabled tests?

### Build Configuration Audit
- Are signing settings correct?
- Are entitlements properly configured?
- Are build settings consistent across targets?
- Is bitcode disabled (required since Xcode 14)?

## Phase 3: Report

Present findings as a project health card:

```
## Project Health: [Project Name]

### Score: X/10

### Summary
[2-3 sentence overview]

### Critical Issues
- [issues that need immediate attention]

### Improvements
- [recommended changes, ordered by impact]

### Strengths
- [what the project does well]

### Metrics
- Swift files: N
- Test files: N
- Test coverage: ~N%
- Dependencies: N
- Deployment target: iOS N
- Swift version: N
```
