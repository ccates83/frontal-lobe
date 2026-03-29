---
description: Create a GitHub release with changelog
argument-hint: "Version tag and optional notes (e.g., 'v1.2.0', 'v2.0.0-beta.1 --prerelease')"
---

# Create GitHub Release

Create a GitHub release with an auto-generated or custom changelog.

## Arguments

- `$ARGUMENTS` — Version tag (e.g., `v1.2.0`). Add `--prerelease` for pre-releases.

## Instructions

You are an orchestrator. Delegate all gh CLI operations to `gh-cli-operator`.

## Phase 1: Pre-Flight Checks

1. Read CLAUDE.md for release conventions
2. Verify gh is authenticated: `gh auth status`
3. Verify clean working tree: `git status`
4. Identify the last release tag: `gh release list --limit 1`
5. Check if the tag already exists: `git tag -l "<version>"`
6. Review commits since last tag: `git log <last-tag>..HEAD --oneline --no-merges`

## Phase 2: Generate Changelog

Delegate to `gh-cli-operator`:

1. Get the list of commits since the last release:
   ```
   git log <last-tag>..HEAD --pretty=format:"- %s (%h)" --no-merges
   ```

2. Categorize commits if they follow conventional commits:
   - **Features**: commits starting with `feat:`
   - **Bug Fixes**: commits starting with `fix:`
   - **Breaking Changes**: commits with `BREAKING CHANGE` or `!:`
   - **Other**: everything else

3. Get list of contributors:
   ```
   git log <last-tag>..HEAD --format="%aN" | sort -u
   ```

4. Get merged PRs since last release (if available):
   ```
   gh pr list --state merged --base main --search "merged:>$(git log -1 --format=%ai <last-tag>)" --json number,title,author
   ```

## Phase 3: Create Release

Delegate to `gh-cli-operator`:

1. Create the git tag if it does not exist:
   ```
   git tag <version>
   git push origin <version>
   ```

2. Create the release:
   ```
   gh release create <version> --title "<version>" --notes "<changelog>"
   ```

   Or for pre-release:
   ```
   gh release create <version> --prerelease --title "<version>" --notes "<changelog>"
   ```

   Or use auto-generated notes:
   ```
   gh release create <version> --generate-notes
   ```

3. Upload any build artifacts if applicable

## Phase 4: Verify

1. Confirm the release was created: `gh release view <version>`
2. Verify the tag points to the correct commit
3. Check if any release workflows were triggered: `gh run list --limit 3`

## Phase 5: Report

Present:
- **Release**: tag, title, URL
- **Changelog**: summary of changes
- **Artifacts**: any uploaded assets
- **Workflows**: any triggered release workflows
- **Next steps**: announcements, deployment steps, etc.
