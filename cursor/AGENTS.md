# AGENTS.md

This file provides guidance when working with **Cursor** configurations in this repository.

## What This Repo Is

A version-controlled collection of Cursor subagents, slash commands, and skill libraries — converted from and kept in sync with the Claude Code configs in `claude-code/`. There is no build system, test suite, or application code. All content is markdown (with YAML frontmatter where applicable) and shell scripts.

## Repository Structure

- `cursor/agents/*.md` — Cursor subagent definitions (YAML frontmatter + system prompt body). **Keep files flat** in this folder (Cursor discovers `*.md` directly under `agents/`, not nested directories).
- `cursor/commands/*.md` — Slash command bodies (markdown only; no YAML frontmatter in the Cursor format).
- `cursor/skills/<name>/` — Skill libraries (`SKILL.md` plus optional `data/`, `scripts/`, etc.).
- `claude-code/` — Primary authoring target for agents, commands, and skills in this repo.
- `scripts/install.sh` — Deploys Claude Code, OpenCode, and Cursor configs via symlinks.
- `scripts/sync.sh` — Pulls live configs back into the repo and cross-converts between tools.
- `scripts/convert.sh` — Translates definitions between Claude Code, OpenCode, and Cursor formats.

## Cross-Tool Sync

- `claude-code/` is the canonical source for shared content; `cursor/` is the **Cursor-shaped** parallel produced by `scripts/convert.sh --to-cursor`.
- `~/.cursor/skills/` holds user skills. Do **not** install into `~/.cursor/skills-cursor/` — that directory is reserved for Cursor’s built-in skills.

## Key Commands

```bash
# Install all three tools (Claude Code + OpenCode + Cursor), root-level
scripts/install.sh

# Cursor only
scripts/install.sh --cursor

# Install into a project’s .cursor/ (no settings files)
scripts/install.sh --project /path/to/project

# Generate or refresh cursor/ from claude-code/
scripts/convert.sh --to-cursor

# After editing Cursor-installed files, sync back and propagate to claude-code/ + opencode/
scripts/sync.sh
```

## Agent Architecture

The orchestrator is `frontal-lobe`. It is strictly read-only and uses a two-phase model: planners analyze domain-by-domain, then implementation agents run in parallel. Cursor maps these roles as subagents with `readonly` and `model` fields appropriate for each role.

## Conventions When Editing Configs

- Prefer editing `claude-code/` and running `scripts/convert.sh --to-cursor` (and `--to-opencode` as needed) to propagate.
- If you edit files under `~/.cursor/` directly, run `scripts/sync.sh` to pull changes into this repo and cross-convert.
