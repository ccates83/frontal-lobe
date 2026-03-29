# Cross-Tool Sync

> How Claude Code and OpenCode configs are kept in sync across both tools.

---

## Why Dual-Tool Support

The repo maintains parallel config sets for Claude Code (`claude-code/`) and OpenCode (`opencode/`). Both tools use markdown agent files but with different frontmatter schemas. `convert.sh` handles the translation automatically so you can edit in either tool and keep both sets current.

---

## The Three Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install.sh` | Deploys `claude-code/` → `~/.claude/` and `opencode/` → `~/.config/opencode/` via symlinks |
| `scripts/sync.sh` | Pulls live changes from `~/.claude/` or `~/.config/opencode/` back into the repo, then cross-converts |
| `scripts/convert.sh` | Translates agent, command, and skill files between the two formats |

---

## The Sync Workflow

The intended loop when editing configs during active sessions:

```
Edit in ~/.claude/ or ~/.config/opencode/
    │
    ▼
scripts/sync.sh
    ├── Compares live config dirs against repo dirs
    ├── Shows color-coded diff (new / modified / deleted)
    ├── Prompts for confirmation
    ├── Copies changed files back into claude-code/ or opencode/
    └── Runs cross-conversion so both sides stay current
    │
    ▼
Review diff → commit
```

```bash
# Sync both tools + cross-convert (default)
scripts/sync.sh

# Sync Claude Code only, cross-convert to OpenCode
scripts/sync.sh --claude

# Sync OpenCode only, cross-convert to Claude Code
scripts/sync.sh --opencode

# Sync without cross-conversion
scripts/sync.sh --no-convert

# Preview only, no changes applied
scripts/sync.sh --dry-run
```

---

## Format Differences

### Agent Frontmatter

| Concept | Claude Code field | OpenCode field |
|---------|------------------|----------------|
| Agent name | `name: web-builder` | _(derived from filename)_ |
| Description | `description: "..."` | `description: "..."` |
| Write access | `tools: Write, Edit` | `permission: edit: allow` |
| Shell access | `tools: Bash` | `permission: bash: allow` |
| Web access | `tools: WebFetch, WebSearch` | `permission: webfetch: allow` |
| Sub-agent spawning | `tools: Agent, TaskCreate, ...` | `permission: task: allow` |
| Model | `model: opus` | `model: anthropic/claude-sonnet-4-5` |
| Agent mode | _(implicit)_ | `mode: subagent` / `mode: primary` |

### Model Name Mapping

| Claude Code | OpenCode |
|-------------|---------|
| `opus` | `anthropic/claude-sonnet-4-5` |
| `sonnet` | `anthropic/claude-sonnet-4-5` |
| `haiku` | `anthropic/claude-haiku-4-5` |

> Note: Claude Code's `opus` and `sonnet` both map to `anthropic/claude-sonnet-4-5` in OpenCode. Model selection in OpenCode is done via `permission` flags rather than named tiers.

### Body Text Substitutions

`convert.sh` also rewrites body text when converting:

| Claude Code text | OpenCode text |
|-----------------|--------------|
| `CLAUDE.md` | `AGENTS.md` |
| `claude --agent <name>` | `opencode` |
| `the Agent tool` | `the task tool` |
| `~/.claude/` | `~/.config/opencode/` |
| `claude-code/` (path refs) | `opencode/` |
| `` Launch `<name>` `` | `` Use the task tool to invoke `@<name>` `` |

### Command Frontmatter

| Claude Code | OpenCode |
|-------------|---------|
| `description` | `description` |
| `argument-hint` | _(no equivalent)_ |
| _(no equivalent)_ | `agent: frontal-lobe` |

### Skill Frontmatter

| Claude Code | OpenCode |
|-------------|---------|
| `name` | `name` |
| `description` | `description` |
| _(absent)_ | `compatibility: opencode` |

---

## Converting Manually

```bash
# Full conversion: claude-code/ → opencode/
scripts/convert.sh --to-opencode

# Full conversion: opencode/ → claude-code/
scripts/convert.sh --to-claude

# Single file
scripts/convert.sh --to-opencode --file agents/web-builder.md

# Preview without writing
scripts/convert.sh --to-opencode --dry-run
```

> Settings files (`settings.json`, `settings.local.json`, `opencode.jsonc`) are **not** auto-converted — their schemas differ significantly. Convert manually if needed.

---

## Conflict Handling

When both `~/.claude/` and `~/.config/opencode/` have changes to the same agent, `sync.sh` will detect the conflict and prompt:

```
[c] Use Claude Code version
[o] Use OpenCode version
[s] Skip (resolve manually)
```

Uppercase `[C]`, `[O]`, `[S]` apply to all remaining conflicts.

---

## Related Pages

- [Installation](installation.md) — initial setup and symlink management
- [Agents](agents.md) — the format details for each tool
- [Contributing](contributing.md) — recommended workflows for editing configs
