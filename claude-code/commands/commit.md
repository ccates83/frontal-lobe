Commit all pending changes on the current branch, splitting into multiple well-structured commits when the changes span distinct concerns.

Instructions:

1. Run `git status` (without `-uall`) to see all staged and untracked changes.
2. Run `git diff --cached` and `git diff` to understand what changed (both staged and unstaged).
3. Run `git log --oneline -5` to see recent commit message style for consistency.
4. **Group changes into logical commits.** Each commit should represent one cohesive concern (e.g., a feature, a bug fix, a refactor, documentation updates). Consider:
   - Do these changes serve different purposes (feature vs. docs vs. fix)?
   - Do they touch unrelated parts of the codebase?
   - Would a reviewer understand each commit independently?
   - When in doubt, fewer larger commits are better than many tiny ones. Don't split just for the sake of splitting.
5. **For each commit** (in logical order — dependencies first):
   a. Determine the commit **type**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`, or `build`
   b. Determine an optional **scope** in parentheses if changes are localized (e.g., `feat(pedometer):`)
   c. Write a concise **subject line** (imperative mood, lowercase, no period, under 72 chars)
   d. Write a **body** with enough detail to understand *what* changed and *why*, but no unnecessary filler. Use bullet points for multiple changes.
   e. Stage the specific files for this commit. Be specific — do not use `git add -A` or `git add .`. Never stage files that likely contain secrets (`.env`, credentials, tokens).
   f. Create the commit using this format and a HEREDOC:
   ```
   <type>(<optional scope>): <subject>

   <body — what changed and why, bulleted if multiple items>

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   ```
6. Repeat step 5 until all changes are committed.
7. Run `git status` after the final commit to confirm the working tree is clean.
8. Show the user a summary of all commits created.

Rules:
- **All changes must be committed by the end.** Do not leave uncommitted changes behind.
- If there are no changes to commit, tell the user and stop.
- Never amend an existing commit unless the user explicitly asks.
- Never push to remote unless the user explicitly asks.
- Never skip pre-commit hooks.
- Use a HEREDOC to pass each commit message to `git commit -m` for proper formatting.
