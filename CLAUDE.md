# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A version-controlled collection of Claude Code configurations — agents, slash commands, and skill/pattern libraries — that get symlinked into `~/.claude/` via install scripts. There is no build system, test suite, or application code. All content is markdown (with YAML frontmatter) and shell scripts.

## Repository Structure

- `claude-code/agents/*.md` — 61 agent definitions (YAML frontmatter + system prompt body)
- `claude-code/commands/*.md` — 61 slash command definitions
- `claude-code/skills/<name>/` — 13 skill/pattern library directories, each with a `SKILL.md` and optional `data/` or `scripts/`
- `claude-code/settings.json` / `settings.local.json` — Claude Code settings files
- `opencode/agents/*.md` — OpenCode agent definitions (converted from Claude Code format)
- `scripts/install.sh` — Deploys configs for both Claude Code and OpenCode
- `scripts/sync.sh` — Pulls changes from either tool back into the repo and cross-converts
- `scripts/convert.sh` — Translates agent definitions between Claude Code and OpenCode formats

## Cross-Tool Sync

This repo maintains configs for both Claude Code and OpenCode in parallel.

- `claude-code/` is the authoritative config set for Claude Code; it deploys to `~/.claude/`
- `opencode/` is the authoritative config set for OpenCode; it deploys to the OpenCode config directory
- The unified `scripts/install.sh` deploys both to their respective config directories in one step
- The unified `scripts/sync.sh` pulls changes from either tool and cross-converts so both sets stay in sync
- `scripts/convert.sh` handles format translation — frontmatter field differences, path references, and tool lists
- Editing in either tool is fine; running `scripts/sync.sh` propagates changes to the other

## Key Commands

```bash
# Install all configs (both Claude Code + OpenCode, root-level)
scripts/install.sh

# Install Claude Code only
scripts/install.sh --claude

# Install OpenCode only
scripts/install.sh --opencode

# Install to a specific project
scripts/install.sh --project /path/to/project

# Preview install without making changes
scripts/install.sh --dry-run

# Sync local changes back to repo (both tools + cross-convert)
scripts/sync.sh

# Sync Claude Code only
scripts/sync.sh --claude

# Sync OpenCode only
scripts/sync.sh --opencode

# Sync without cross-conversion
scripts/sync.sh --no-convert

# Preview sync
scripts/sync.sh --dry-run

# Apply changes without prompting (non-interactive mode)
scripts/sync.sh --yes

# Auto-resolve conflicts (claude, opencode, or skip)
scripts/sync.sh --yes --prefer claude

# Convert between formats manually
scripts/convert.sh --to-opencode    # claude-code/ → opencode/
scripts/convert.sh --to-claude      # opencode/ → claude-code/
```

## Agent Architecture

The orchestrator is `frontal-lobe` (run via `claude --agent frontal-lobe`). It is strictly read-only and uses a two-phase model:

1. **Phase 1 (Plan):** Spawns domain planner agents (e.g., `web-planner`, `ios-planner`) that analyze the codebase and return structured implementation plans
2. **Phase 2 (Execute):** Spawns implementation agents in parallel (e.g., `web-builder`, `swift-tester`) based on planner output

Agents are organized by role: planners (read-only analysis), architects (read-only design), builders (write code), reviewers (read-only audit), and testers (write tests). Each domain (web, iOS, Python, backend, API, DevOps, data, mobile, GitHub, docs, meta) follows this pattern.

## Agent File Format

Agent markdown files use YAML frontmatter with these fields:
- `name` — agent identifier (used in `--agent` flag and `subagent_type`)
- `description` — shown in agent selection; include usage examples as XML `<example>` blocks
- `tools` — comma-separated list of allowed tools
- `model` — model to use (e.g., `opus`, `sonnet`, `haiku`)
- `color` — terminal color for the agent's output

The body after the frontmatter is the agent's system prompt.

## Conventions When Editing Configs

- Agent prompts must be fully self-contained — sub-agents run in complete isolation with no shared context
- Skills are referenced by agents inline; the `SKILL.md` frontmatter needs `name` and `description`
- Commands are plain markdown instructions that Claude executes when the user types `/<command-name>`
- Settings files are only symlinked during root-level install, not project-level
- The `.gitignore` excludes ephemeral Claude Code directories (cache, sessions, telemetry, etc.) that exist in `~/.claude/` but should never be committed
