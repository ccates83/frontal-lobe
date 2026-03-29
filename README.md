# 🧠 Frontal Lobe

**Version-controlled agents, commands, and skills for Claude Code and OpenCode.**

A shareable configuration toolkit — 59 specialized agents, 56 slash commands, and 13 skill/pattern libraries — that supercharges AI-assisted development across every major stack. Works with both [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) and [OpenCode](https://opencode.ai).

---

## Quick Start

```bash
git clone <repo-url>
cd frontal-lobe

# Install for both tools (symlinks into ~/.claude/ and the OpenCode config dir)
scripts/install.sh

# Install for one tool only
scripts/install.sh --claude
scripts/install.sh --opencode
```

**Claude Code:**

```bash
claude --agent frontal-lobe
```

**OpenCode:**

```bash
# frontal-lobe is set as the default agent in opencode.jsonc
opencode
```

---

## What's Included

- **59 agents** — Domain planners, builders, reviewers, testers, and architects plus the `frontal-lobe` orchestrator that coordinates them all
- **56 slash commands** — Focused workflows for building, testing, reviewing, releasing, and documenting across every domain
- **13 skill libraries** — Reference material (patterns, conventions, best practices) that agents draw on automatically; includes `ui-ux-pro-max` with 67 design styles and 96 color palettes

---

## Domain Coverage

| Web | Python | iOS | macOS | Backend |
|-----|--------|-----|-------|---------|
| API | DevOps | Data | Mobile | GitHub Actions |
| Docs | Brainstorming | Meta | | |

Each domain follows the same agent pattern: planner → builder → reviewer → tester → architect. See [docs/agents.md](docs/agents.md) for the full matrix.

---

## Usage Examples

```bash
# Orchestrate a complex, multi-domain task
claude --agent frontal-lobe "Fix the nav bug and update the changelog"

# New feature with full plan + implementation
/ios-new-feature "Settings screen with dark mode toggle"
/web-new-feature "Add infinite scroll to the feed"

# Audit and review workflows
/web-review
/devops-audit

# Docs generation
/docs-prd "User authentication system"
/docs-adr "Switch from REST to GraphQL"

# Other utilities
/brainstorm "An app for tracking hiking trails"
/commit
```

See [docs/commands.md](docs/commands.md) for the full command list.

---

## Installation

### Global (all projects)

```bash
scripts/install.sh           # both tools
scripts/install.sh --claude  # Claude Code only
scripts/install.sh --opencode  # OpenCode only
```

### Project-level (one project)

```bash
scripts/install.sh --project /path/to/project
```

Settings files are only installed at the global level. For conflict handling and dry-run options, see [docs/installation.md](docs/installation.md).

---

## Syncing & Cross-Tool Support

Edit configs in either tool's native UI and sync back to the repo — `scripts/sync.sh` pulls changes from `~/.claude/` or the OpenCode config directory, cross-converts between formats, and prompts for confirmation before applying.

```bash
scripts/sync.sh              # both tools + cross-convert
scripts/sync.sh --claude     # Claude Code only
scripts/sync.sh --opencode   # OpenCode only
scripts/sync.sh --dry-run    # preview without changes

# Manual format conversion
scripts/convert.sh --to-opencode   # claude-code/ → opencode/
scripts/convert.sh --to-claude     # opencode/ → claude-code/
```

> After syncing, commit the changes to keep the repo up to date.

See [docs/cross-tool-sync.md](docs/cross-tool-sync.md) for details on the sync and conversion workflow.

---

## Documentation

- [docs/architecture.md](docs/architecture.md) — Orchestrator design, two-phase execution model, agent isolation
- [docs/agents.md](docs/agents.md) — Full agent matrix with roles and tool permissions
- [docs/meta-tooling.md](docs/meta-tooling.md) — Meta agents for extending and auditing the ecosystem
- [docs/commands.md](docs/commands.md) — All 56 slash commands with descriptions
- [docs/skills.md](docs/skills.md) — Skill library reference
- [docs/installation.md](docs/installation.md) — Installation details, conflict handling, dry-run
- [docs/cross-tool-sync.md](docs/cross-tool-sync.md) — Cross-tool sync and format conversion
- [docs/contributing.md](docs/contributing.md) — How to add agents, commands, and skills

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) and/or [OpenCode](https://opencode.ai)
- Bash 4+
- Git

---

## Contributing

The fastest workflow: edit configs in your AI tool of choice, run `scripts/sync.sh` to pull changes back into the repo, review the diff, and commit. See [docs/contributing.md](docs/contributing.md) for conventions on adding new agents, commands, and skills.
