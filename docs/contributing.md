# Contributing

> Workflows for editing, adding, and testing configs in this repo.

---

## Recommended Workflow

**Edit live, then sync back** — the most natural loop:

```
1. Use Claude Code or OpenCode in a project session
2. Iterate on agent/command/skill configs in ~/.claude/ or ~/.config/opencode/
3. Run: scripts/sync.sh
4. Review the diff, confirm, commit
```

**Edit directly in repo** — cleaner for significant additions:

```
1. Edit files in claude-code/ or opencode/ directly
2. Run: scripts/install.sh   (re-symlinks any new files)
3. Test in a Claude Code or OpenCode session
4. Commit
```

---

## Adding a New Agent

1. Create `claude-code/agents/<name>.md` with YAML frontmatter and system prompt.
2. Choose role and tools:
   - Planners: no `Write`/`Edit`, add `Bash` for codebase analysis
   - Builders: `Read, Write, Edit, Glob, Grep, Bash`
   - Reviewers/Architects: `Read, Glob, Grep, Bash` (no `Write`/`Edit`)
3. Write the system prompt as fully self-contained — no shared context.
4. Add `<example>` blocks to the `description` field.
5. Add the agent to `frontal-lobe.md`'s Available Agents table if it should be orchestrated.
6. Run `scripts/install.sh --claude` to symlink it.
7. Run `scripts/convert.sh --to-opencode --file agents/<name>.md` to generate the OpenCode version.
8. Test by invoking the agent in a Claude Code session.

**Naming conventions:**
- Domain planners: `<domain>-planner`
- Domain builders: `<domain>-builder` or `<tool>-builder`
- Domain reviewers: `<domain>-reviewer`
- Domain testers: `<domain>-tester`
- Domain architects: `<domain>-architect`

---

## Adding a New Command

1. Create `claude-code/commands/<name>.md`.
2. Add `description` and (if applicable) `argument-hint` in frontmatter.
3. Write the instruction body following the [multi-phase pattern](commands.md#multi-phase-command-pattern).
4. Use `$ARGUMENTS` where user input should be injected.
5. Run `scripts/install.sh --claude` to symlink it.
6. Run `scripts/convert.sh --to-opencode --file commands/<name>.md` to generate the OpenCode version.

**Naming conventions:**
- Domain-prefixed: `<domain>-<action>` (e.g., `ios-review`, `web-new-feature`)
- General commands: descriptive verb (e.g., `commit`, `brainstorm`)

---

## Adding a New Skill

1. Create directory `claude-code/skills/<name>/`.
2. Create `SKILL.md` with `name` and `description` in frontmatter.
3. Write reference content — patterns, code examples, decision tables.
4. Add a "When to Apply" section so agents know when to use it.
5. Add `data/*.csv` files for large lookup datasets.
6. Add `scripts/*.py` search utilities if agents need to query data programmatically.
7. Run `scripts/install.sh --claude` to symlink the directory.
8. Run `scripts/convert.sh --to-opencode` to generate the OpenCode version.

---

## Naming Conventions

| Artifact | Convention | Examples |
|----------|-----------|---------|
| Agent files | `<domain>-<role>.md` | `web-builder.md`, `ios-planner.md` |
| Command files | `<domain>-<action>.md` | `web-review.md`, `ios-new-feature.md` |
| Skill directories | `<domain>-patterns` | `web-patterns`, `ios-patterns` |
| Skills without domain | descriptive name | `ui-ux-pro-max` |

---

## Testing Your Changes

There is no automated test suite. Verify manually:

1. **Syntax check** — ensure YAML frontmatter is valid (no unescaped quotes, correct indentation).
2. **Install check** — run `scripts/install.sh --dry-run` to confirm no unexpected conflicts.
3. **Agent invocation** — invoke the agent in a real Claude Code session with a representative task.
4. **Conversion check** — run `scripts/convert.sh --to-opencode --dry-run` to verify the conversion works.

For agents: test with a real project, verify the agent reads the right files, produces the right output format, and stays within its role (e.g., planners do not write code).

---

## Related Pages

- [Installation](installation.md) — install and re-install commands
- [Cross-Tool Sync](cross-tool-sync.md) — sync from live configs back into the repo
- [Meta-Tooling](meta-tooling.md) — automated alternative to manual config editing
- [Agents](agents.md) — agent format reference
- [Commands](commands.md) — command format and patterns
- [Skills](skills.md) — skill directory structure
