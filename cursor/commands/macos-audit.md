# macOS Project Audit

Comprehensive health check for a macOS project.

## Arguments

- `$ARGUMENTS` — (Optional) Focus area for the audit. If empty, runs a full audit.

## Instructions

You are an orchestrator. Analyze the project and delegate review tasks.

## Phase 1: Project Discovery

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) if present
2. Map the project structure:
   - Targets and their types (app, extension, test, framework, system extension)
   - Deployment target and Swift version
   - Dependencies (SPM, CocoaPods, Carthage)
   - Build settings (concurrency mode, signing, sandbox, hardened runtime)
   - Entitlements files and their contents
3. Count: Swift files, test files, lines of code (approximate)
4. Check git status for uncommitted changes

## Phase 2: Targeted Audits

Run these checks in parallel (or only the focus area if specified):

### Architecture Audit
- Is there a consistent architecture pattern?
- Are concerns properly separated (no business logic in views)?
- Is AppKit and SwiftUI integration clean (no hacks)?
- Are there god objects or massive files (>500 lines)?
- Is multi-window state managed correctly?

### Sandbox & Security Audit
- Is App Sandbox enabled? Are entitlements minimal (least privilege)?
- Is Hardened Runtime enabled?
- Are Security-Scoped Bookmarks used for persisted file access?
- Are `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource` balanced?
- Are temporary sandbox exceptions used? (Flag for removal)
- Is sensitive data stored in Keychain (not UserDefaults)?

### Distribution Audit
- Is code signing configured correctly (Developer ID or App Store)?
- Is the app notarizable? (hardened runtime, no unsigned code)
- Are ExportOptions.plist files present and correct?
- Is there a Sparkle integration for auto-updates (if direct distribution)?
- Are build numbers properly incremented?

### Concurrency Audit
- Is strict concurrency enabled? What mode?
- Are there data race risks (shared mutable state without actors)?
- Are closures properly using [weak self]?
- Is MainActor used correctly for UI code?

### Memory Audit
- Grep for potential retain cycles
- Check delegates are declared weak
- Look for notification observers without removal
- Check for unbounded growth in long-running processes

### Dependency Audit
- Are dependencies up to date?
- Are there unused dependencies?
- Could any dependency be replaced with Apple frameworks?

### Test Coverage Audit
- What percentage of source files have corresponding tests?
- Which critical paths lack tests?
- Are tests using the modern framework (Swift Testing)?
- Do tests run with macOS destination?

### macOS UI Audit
- Are standard keyboard shortcuts implemented (Cmd+W, Cmd+Q, Cmd+,)?
- Does the app respect system appearance (dark mode, accent color)?
- Is the menu bar properly configured?
- Does the app handle multiple windows correctly?
- Are toolbar items appropriate and functional?
- Does the app support full screen?

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
- Deployment target: macOS N
- Swift version: N
- Sandbox: enabled/disabled
- Hardened Runtime: enabled/disabled
- Notarization ready: yes/no
```
