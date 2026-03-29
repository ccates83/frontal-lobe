# AGENTS.md

This file provides guidance when working with OpenCode agent configurations in this repository.

## What This Repo Is

A version-controlled collection of OpenCode agent definitions — converted from and kept in sync with the Claude Code configs in `claude-code/`. There is no build system, test suite, or application code. All content is markdown (with YAML frontmatter) and shell scripts.

## Repository Structure

- `opencode/agents/*.md` — OpenCode agent definitions (YAML frontmatter + system prompt body)
- `claude-code/agents/*.md` — Source Claude Code agent definitions (61 total)
- `claude-code/commands/*.md` — 61 slash command definitions (Claude Code only)
- `claude-code/skills/<name>/` — 13 skill/pattern library directories (Claude Code only)
- `scripts/install.sh` — Deploys configs for both Claude Code and OpenCode
- `scripts/sync.sh` — Pulls changes from either tool back into the repo and cross-converts
- `scripts/convert.sh` — Translates agent definitions between Claude Code and OpenCode formats

## Cross-Tool Sync

This repo maintains configs for both Claude Code and OpenCode in parallel.

- `opencode/` is the authoritative config set for OpenCode; it deploys to the OpenCode config directory
- `claude-code/` is the authoritative config set for Claude Code; it deploys to `~/.claude/`
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

# Convert between formats manually
scripts/convert.sh --to-opencode    # claude-code/ → opencode/
scripts/convert.sh --to-claude      # opencode/ → claude-code/
```

## Agent Architecture

The orchestrator is `frontal-lobe`, which uses a two-phase model:

1. **Phase 1 (Plan):** Spawns domain planner agents (e.g., `web-planner`, `ios-planner`) that analyze the codebase and return structured implementation plans
2. **Phase 2 (Execute):** Spawns implementation agents in parallel (e.g., `web-builder`, `swift-tester`) based on planner output

Agents are organized by role: planners (read-only analysis), architects (read-only design), builders (write code), reviewers (read-only audit), and testers (write tests). Each domain (web, iOS, Python, backend, API, DevOps, data, mobile, GitHub, docs) follows this pattern.

## Agent File Format

OpenCode agent files use YAML frontmatter translated from the Claude Code source. Fields may differ from their Claude Code equivalents — `scripts/convert.sh` handles these translations automatically.

The body after the frontmatter is the agent's system prompt, identical in content to the Claude Code version.

## Conventions When Editing Configs

- Prefer editing the Claude Code source in `claude-code/agents/` and running `scripts/convert.sh --to-opencode` to propagate changes
- If you edit an OpenCode agent directly, run `scripts/sync.sh --opencode` to pull it back and cross-convert to Claude Code
- Agent prompts must be fully self-contained — agents run in complete isolation with no shared context
- Do not commit machine-generated conversion artifacts without reviewing the diff
