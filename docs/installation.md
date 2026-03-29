# Installation

> Deploy agents, commands, and skills to Claude Code and/or OpenCode via symlinks.

---

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview) and/or [OpenCode](https://opencode.ai)
- Bash 4+
- Git

---

## Quick Start

```bash
git clone <repo-url>
cd frontal-lobe
scripts/install.sh
```

This installs configs for both Claude Code and OpenCode at the root level.

---

## Install Options

```bash
# Both tools, root-level (default)
scripts/install.sh

# Claude Code only
scripts/install.sh --claude

# OpenCode only
scripts/install.sh --opencode

# Both tools, project-level
scripts/install.sh --project /path/to/your/project

# Claude Code only, project-level
scripts/install.sh --project /path/to/your/project --claude

# Preview without making changes
scripts/install.sh --dry-run
```

---

## What Gets Installed Where

### Root-level install

| Source | Target (Claude Code) | Target (OpenCode) |
|--------|---------------------|------------------|
| `claude-code/agents/*.md` | `~/.claude/agents/*.md` | — |
| `claude-code/commands/*.md` | `~/.claude/commands/*.md` | — |
| `claude-code/skills/<name>/` | `~/.claude/skills/<name>/` | — |
| `claude-code/settings.json` | `~/.claude/settings.json` | — |
| `claude-code/settings.local.json` | `~/.claude/settings.local.json` | — |
| `opencode/agents/*.md` | — | `~/.config/opencode/agents/*.md` |
| `opencode/commands/*.md` | — | `~/.config/opencode/commands/*.md` |
| `opencode/skills/<name>/` | — | `~/.config/opencode/skills/<name>/` |
| `opencode/opencode.jsonc` | — | `~/.config/opencode/opencode.jsonc` |

All targets are **symlinks** — edits to symlinked files are edits to the repo.

### Project-level install

Settings files are **not** installed at the project level. Everything else installs to:

| Source | Target (Claude Code) | Target (OpenCode) |
|--------|---------------------|------------------|
| `claude-code/agents/*.md` | `<project>/.claude/agents/*.md` | — |
| `claude-code/commands/*.md` | `<project>/.claude/commands/*.md` | — |
| `claude-code/skills/<name>/` | `<project>/.claude/skills/<name>/` | — |
| `opencode/agents/*.md` | — | `<project>/.opencode/agents/*.md` |
| `opencode/commands/*.md` | — | `<project>/.opencode/commands/*.md` |
| `opencode/skills/<name>/` | — | `<project>/.opencode/skills/<name>/` |

---

## Conflict Handling

When a file or symlink already exists at a target path, the installer prompts:

```
[b] Backup    — move existing to <name>.bak.<timestamp>, then create symlink
[o] Overwrite — remove existing, create symlink
[s] Skip      — leave existing in place
```

Uppercase `[B]`, `[O]`, `[S]` apply the choice to all remaining conflicts.

---

## Uninstalling

Remove the symlinks from the target directory:

```bash
# Claude Code root-level
rm ~/.claude/agents/<name>.md
rm ~/.claude/commands/<name>.md
rm -rf ~/.claude/skills/<name>

# Or remove all at once (careful — only if everything came from this repo)
rm ~/.claude/agents/*.md
rm ~/.claude/commands/*.md
```

For project-level installs, remove the `.claude/` or `.opencode/` directories inside the project.

---

## Related Pages

- [Cross-Tool Sync](cross-tool-sync.md) — syncing changes back from live configs
- [Contributing](contributing.md) — workflow for editing and adding configs
