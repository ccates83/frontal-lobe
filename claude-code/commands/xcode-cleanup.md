---
description: "Remove Swift source files from Xcode project (filesystem + pbxproj)"
argument-hint: "Space-separated file or directory paths to remove"
---

# Xcode Project Cleanup

Remove source files from an iOS/macOS Xcode project safely — handling both the filesystem and the `project.pbxproj` references.

## Arguments

- `$ARGUMENTS` — Space-separated list of Swift file paths (or directories) to remove. Paths are relative to the Xcode project root unless absolute.

## Instructions

You are performing an Xcode project cleanup. Follow these steps carefully and in order.

### Step 1: Locate the Xcode project

Find the `.xcodeproj` directory nearest to the files being removed. Read the `project.pbxproj` inside it. If there are multiple `.xcodeproj` files, ask the user which one to use.

### Step 2: Validate targets

For each file path in `$ARGUMENTS`:
1. Confirm the file exists on disk. If a directory is given, expand it to all `.swift` files within.
2. Search the codebase (excluding the files being removed) for any `import` statements, type references, or usages of symbols defined in these files. If a file is still actively referenced, **stop and warn the user** — do not silently remove files that are in use.
3. Find all references to each file in `project.pbxproj`:
   - `PBXBuildFile` entries (e.g., `/* FileName.swift in Sources */`)
   - `PBXFileReference` entries (e.g., `/* FileName.swift */`)
   - `PBXGroup` children entries that list the file
   - `PBXSourcesBuildPhase` file lists that include the build file reference

Report what was found so the user can confirm before proceeding.

### Step 3: Remove pbxproj references

For each file, remove the following from `project.pbxproj` in this order:
1. The `PBXBuildFile` line (the `in Sources` entry)
2. The `PBXFileReference` line
3. The file's UUID from any `PBXGroup` `children` arrays
4. The build file's UUID from any `PBXSourcesBuildPhase` `files` arrays

**Important pbxproj editing rules:**
- Each entry is identified by a UUID (e.g., `E86EB5542CA8C363001C5345`). A file typically has two UUIDs: one for the `PBXFileReference` and one for the `PBXBuildFile`. Make sure to remove both.
- When removing an entry from a `children` or `files` array, ensure the remaining comma/formatting is correct.
- Never modify UUIDs or entries that don't correspond to the files being removed.
- If a `PBXGroup` becomes empty after removing its last child, remove the entire group definition AND its reference from the parent group's `children` array.

### Step 4: Delete files from disk

Remove the actual files/directories from the filesystem. If removing a file leaves its parent directory empty, remove the empty directory too.

### Step 5: Verify the build

Run the Xcode build to confirm nothing is broken:

```
xcodebuild build -scheme <scheme> -destination '<destination>' -quiet
```

Use the main app scheme. Pick an iOS Simulator destination that's available (prefer a recent non-beta iOS version). If the build fails:
- Check if the failure is related to the cleanup (missing file references, broken imports)
- If yes, diagnose and fix
- If no (pre-existing issue), note it and move on

### Step 6: Report results

Summarize:
- Files removed (count and paths)
- pbxproj entries cleaned (count)
- Empty groups/directories removed
- Build result (pass/fail and any notes)

## Safety rules

- **Never remove files without first confirming they're unused.** Grep for all public symbols.
- **Always read the pbxproj before editing.** Never guess at UUIDs.
- **Back up nothing** — git tracks everything. But do remind the user to commit or stash before running this if they have uncommitted changes.
- If the `project.pbxproj` has merge conflicts or parse errors, stop and inform the user.
- This skill handles the **Xcode project file** (`.xcodeproj/project.pbxproj`). For SPM-only packages that don't use an `.xcodeproj`, file deletion is sufficient — no pbxproj editing needed. Detect this and skip pbxproj steps if appropriate.
