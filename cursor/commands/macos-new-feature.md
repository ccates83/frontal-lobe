# macOS New Feature

Full orchestrated workflow for building a new macOS feature.

## Arguments

- `$ARGUMENTS` — Description of the feature to build.

## Instructions

You are an orchestrator. Do NOT write code yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions
2. Run `git status` and `git log --oneline -5` for current state
3. Scan the project structure with Glob to understand architecture
4. Identify relevant existing files and patterns
5. Check macOS-specific context: entitlements, sandbox status, deployment target, AppKit vs SwiftUI usage

Summarize your understanding in 2-3 sentences.

## Phase 2: Architecture

Delegate to the `swift-architect` subagent agent with:
- The feature description: $ARGUMENTS
- Project context you gathered
- macOS-specific constraints (sandbox, multi-window, menu bar, entitlements)
- Instructions to produce a full implementation blueprint
- Whether to use AppKit, SwiftUI, or a combination

Wait for the blueprint before proceeding.

## Phase 3: Implement

Based on the architect's blueprint, launch `swift-builder` agent(s) with:
- Specific files to create/modify
- The architecture blueprint for reference
- Key files to read first
- Patterns and conventions to follow
- macOS-specific notes (AppKit integration, entitlements needed, window management)

For independent file groups, launch multiple builders in parallel.

If entitlements need updating, launch `pbxproj-surgeon` in parallel to update build settings.

## Phase 4: Verify (Parallel)

Launch these agents simultaneously:
1. `swift-reviewer` — review all new/modified files (include macOS review categories)
2. `swift-tester` — write tests for the new feature
3. `xcode-builder` — verify the build compiles (with `-destination 'platform=macOS'`)

## Phase 5: Fix Cycle

If reviewer found critical issues or build failed:
1. Delegate to the `swift-builder` subagent with specific fixes
2. Re-run build verification
3. Maximum 2 fix rounds, then escalate to user

## Phase 6: Report

Present:
- **Feature**: brief description
- **Files changed**: list of created/modified files
- **Architecture**: key design decisions (AppKit vs SwiftUI, window management, etc.)
- **Entitlements**: any sandbox entitlements added or modified
- **Build**: pass/fail
- **Tests**: pass/fail, what's covered
- **Review**: any deferred issues
- **Next steps**: suggested follow-up work (distribution, notarization, etc.)
