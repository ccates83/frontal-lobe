# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A version-controlled collection of Claude Code configurations — agents, slash commands, and skill/pattern libraries — that get symlinked into `~/.claude/` via install scripts. There is no build system, test suite, or application code. All content is markdown (with YAML frontmatter) and shell scripts.

## Repository Structure

- `claude-code/agents/*.md` — 55 agent definitions (YAML frontmatter + system prompt body)
- `claude-code/commands/*.md` — 53 slash command definitions
- `claude-code/skills/<name>/` — 12 skill/pattern library directories, each with a `SKILL.md` and optional `data/` or `scripts/`
- `claude-code/settings.json` / `settings.local.json` — Claude Code settings files
- `scripts/install.sh` — Symlinks `claude-code/` contents into `~/.claude/` (or a project's `.claude/`)
- `scripts/sync.sh` — Pulls changes from `~/.claude/` back into the repo

## Key Commands

```bash
# Install configs (root-level, symlinks into ~/.claude/)
scripts/install.sh

# Install configs (project-level, symlinks into <project>/.claude/)
scripts/install.sh --project /path/to/project

# Preview install without making changes
scripts/install.sh --dry-run

# Sync local ~/.claude/ changes back into repo
scripts/sync.sh

# Preview sync without applying
scripts/sync.sh --dry-run
```

## Agent Architecture

The orchestrator is `frontal-lobe` (run via `claude --agent frontal-lobe`). It is strictly read-only and uses a two-phase model:

1. **Phase 1 (Plan):** Spawns domain planner agents (e.g., `web-planner`, `ios-planner`) that analyze the codebase and return structured implementation plans
2. **Phase 2 (Execute):** Spawns implementation agents in parallel (e.g., `web-builder`, `swift-tester`) based on planner output

Agents are organized by role: planners (read-only analysis), architects (read-only design), builders (write code), reviewers (read-only audit), and testers (write tests). Each domain (web, iOS, Python, backend, API, DevOps, data, mobile, GitHub, docs) follows this pattern.

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
