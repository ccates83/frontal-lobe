---
description: Run iOS tests (all or specific)
argument-hint: Optional test name or target to run
---

# iOS Test

Run tests for the current iOS project.

## Arguments

- `$ARGUMENTS` — (Optional) Specific test name, suite, or target. If empty, runs all tests.

## Instructions

1. Read CLAUDE.md for project-specific test commands
2. Detect project type and find the test scheme
3. If `$ARGUMENTS` is provided:
   ```bash
   xcodebuild -project <name>.xcodeproj -scheme <scheme> \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
     test -only-testing:<TestTarget>/$ARGUMENTS 2>&1
   ```
4. If no arguments:
   ```bash
   xcodebuild -project <name>.xcodeproj -scheme <scheme> \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
     test 2>&1
   ```
5. For SPM projects:
   ```bash
   swift test 2>&1
   ```
6. Report:
   - **Status**: PASS or FAIL
   - **Tests passed**: count
   - **Tests failed**: count, with names and failure reasons
   - **Duration**: total test time
