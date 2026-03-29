---
description: "Build the macOS project and report results"
agent: build
---
# macOS Build

Build the current macOS project and report the result.

## Instructions

1. Read AGENTS.md for project-specific build commands
2. Detect the project type:
   - `.xcworkspace` -> use `xcodebuild -workspace`
   - `.xcodeproj` -> use `xcodebuild -project`
   - `Package.swift` only -> use `swift build`
3. Find the primary scheme with `xcodebuild -list`
4. Run the build:
   ```bash
   xcodebuild -project <name>.xcodeproj -scheme <scheme> -configuration Debug \
     -destination 'platform=macOS' \
     build 2>&1 | tail -50
   ```
5. Report:
   - **Status**: PASS or FAIL
   - **Errors**: file:line and error message (if any)
   - **Warnings**: notable warnings (if any)
   - **Build time**: duration
