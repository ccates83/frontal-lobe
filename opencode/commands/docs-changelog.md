---
description: "Generate or update a changelog from git history"
agent: frontal-lobe
---
# Generate Changelog

Generate or update a changelog from git history.

## Arguments

- `$ARGUMENTS` — The scope of the changelog (version range, date range, or "all").

## Instructions

You are an orchestrator. Do NOT write the changelog yourself. Gather git history, then delegate.

## Phase 1: Gather Git Context

1. Read the existing changelog if present: `cat CHANGELOG.md 2>/dev/null || cat docs/CHANGELOG.md 2>/dev/null`
2. List tags to understand versioning: `git tag --sort=-version:refname | head -20`
3. Determine the scope from $ARGUMENTS:
   - If a version range: `git log <from>..<to> --oneline --no-merges`
   - If a date range: `git log --since="<date>" --oneline --no-merges`
   - If "since last tag": `git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges`
   - If no scope specified: since the last tag or last 50 commits
4. Get detailed commit information: `git log <range> --format="%h %s" --no-merges`
5. Check for conventional commit format to enable automatic categorization

Summarize: version range, number of commits, major themes.

## Phase 2: Categorize Changes

Group commits by type:
- **Added**: New features (feat:, feature, add, new)
- **Changed**: Changes to existing functionality (change, update, refactor, improve)
- **Deprecated**: Soon-to-be-removed features (deprecate)
- **Removed**: Removed features (remove, delete)
- **Fixed**: Bug fixes (fix, bug, patch, resolve)
- **Security**: Security fixes (security, vuln, CVE)

## Phase 3: Write

Use the task tool to invoke `@docs-writer` with:
- Categorized commit list from Phase 2
- Existing changelog content (if updating)
- Keep a Changelog format specification
- File path: `CHANGELOG.md` (or matching existing location)
- Instructions to:
  - Follow Keep a Changelog format
  - Write human-readable descriptions (not raw commit messages)
  - Group related changes together
  - Include the version number and date
  - Link to compare views if the repo has a remote: `[X.Y.Z]: https://github.com/user/repo/compare/vOLD...vNEW`
  - If updating existing changelog, prepend the new section — do not overwrite history

## Phase 4: Report

Present:
- **Changelog**: file path
- **Version**: version number covered
- **Changes**: count by category (X added, Y changed, Z fixed)
- **Notable**: highlight the most significant changes
