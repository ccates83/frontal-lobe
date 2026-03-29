# 🧠 Frontal Lobe

**Curated agents, commands, and skills that turn Claude Code into a full-stack development powerhouse.**

A version-controlled, shareable collection of Claude Code configurations — 55 specialized agents, 53 slash commands, and 12 skill/pattern libraries that supercharge [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) across every major development domain.

---

## Table of Contents

- [What This Is](#what-this-is)
- [Quick Start](#quick-start)
- [The Orchestrator: Frontal Lobe](#the-orchestrator-frontal-lobe)
- [Domain Coverage](#domain-coverage)
- [Slash Commands](#slash-commands)
- [Skills / Pattern Libraries](#skills--pattern-libraries)
- [Installation](#installation)
- [Syncing Local Changes Back](#syncing-local-changes-back)
- [How It Works](#how-it-works)
- [Requirements](#requirements)
- [Contributing](#contributing)

---

## What This Is

Frontal Lobe is a toolkit for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) — Anthropic's CLI for Claude. It provides:

- **55 specialized agents** organized into domain planners (read-only analysis), implementation agents (code writing), reviewers, testers, architects, and the top-level `frontal-lobe` orchestrator
- **53 slash commands** for common workflows: build, test, review, new features, refactor, audit, release, and more
- **12 skill/pattern libraries** providing domain-specific conventions, architecture patterns, and reference material that agents draw on automatically
- **Install and sync scripts** for easy setup and bidirectional config management between the repo and `~/.claude/`

Everything is version-controlled and symlinked — edit configs in one place and they stay in sync.

---

## Quick Start

```bash
git clone <repo-url>
cd frontal-lobe
scripts/install.sh
```

Then, in any Claude Code session:

```bash
# Run the full orchestrator for complex, multi-domain tasks
claude --agent frontal-lobe

# Or use a slash command for a focused workflow
/ios-new-feature "Add a settings screen with dark mode toggle"
/web-review
/docs-prd "User authentication system"
/brainstorm "An app for tracking hiking trails"
/commit
```

---

## The Orchestrator: Frontal Lobe

🧠 The centerpiece of the ecosystem. Run it via:

```bash
claude --agent frontal-lobe
```

`frontal-lobe` is a top-level orchestrator that coordinates all other agents. It is strictly read-only — it never modifies files directly. All work is delegated to sub-agents.

### Two-Phase Execution Model

**Phase 1 — Plan:** Spawns read-only domain planner agents that analyze the codebase and produce structured implementation plans, including which agents to invoke and with what prompts.

**Phase 2 — Execute:** Spawns implementation agents in parallel based on planner output. Independent tasks run concurrently for maximum speed.

```
User: "Fix the navigation bug and update the README"

Phase 1 (parallel planners):
  web-planner  → analyzes the navigation issue, returns a builder plan
  docs-planner → analyzes the README, returns a writer plan

Phase 2 (parallel implementation, from planner output):
  web-builder  → fixes src/components/Navbar.tsx
  web-builder  → fixes src/components/Footer.tsx
  docs-writer  → updates README.md
```

After completing work, `frontal-lobe` emits a **Delegation Log** summarizing what was planned, executed, and verified. It also detects gaps in your configuration and suggests new agents, commands, or skills when warranted.

---

## Domain Coverage

| Domain | Planner | Builder | Reviewer | Tester | Architect |
|--------|---------|---------|----------|--------|-----------|
| Web (React, Next.js, Vue, Node.js) | `web-planner` | `web-builder` | `web-reviewer` | `web-tester` | `web-architect` |
| Python (Django, FastAPI, Flask) | `python-planner` | `python-builder` | `python-reviewer` | `python-tester` | `python-architect` |
| iOS (Swift, SwiftUI, UIKit) | `ios-planner` | `swift-builder` | `swift-reviewer` | `swift-tester` | `swift-architect` |
| macOS (AppKit, SwiftUI-for-Mac) | `macos-planner` | `swift-builder` | `swift-reviewer` | `swift-tester` | `swift-architect` |
| Backend (Go, Rust, Java, Kotlin, C#) | `backend-planner` | `backend-builder` | `backend-reviewer` | `backend-tester` | `backend-architect` |
| API (REST, GraphQL, gRPC) | `api-planner` | `api-builder` | `api-reviewer` | `api-tester` | `api-architect` |
| DevOps (Docker, K8s, Terraform) | `devops-planner` | `devops-builder` | `devops-reviewer` | — | `devops-architect` |
| Data (SQL, Migrations, Redis) | `data-planner` | `data-builder` | `data-reviewer` | — | `data-architect` |
| Mobile (React Native, Flutter) | `mobile-planner` | `mobile-builder` | `mobile-reviewer` | `mobile-tester` | `mobile-architect` |
| GitHub (Actions, CI/CD) | `github-planner` | `actions-builder` | — | — | — |
| Docs (READMEs, PRDs, ADRs) | `docs-planner` | `docs-writer` | `docs-reviewer` | — | — |
| Brainstorming | `brainstorm-planner` | `brainstorm-synthesizer` | — | — | — |

### Additional Specialized Agents

| Agent | Purpose |
|-------|---------|
| `xcode-builder` | Runs `xcodebuild` commands and manages schemes |
| `pbxproj-surgeon` | Surgically modifies Xcode `.pbxproj` files |
| `spm-manager` | Manages Swift Package Manager dependencies |
| `gh-cli-operator` | Executes `gh` CLI commands (PRs, issues, releases) |
| `runner-manager` | Manages GitHub Actions self-hosted runners |
| `actions-debugger` | Debugs failing GitHub Actions workflows |
| `brainstorm-interviewer` | Conducts structured ideation interviews |
| `brainstorm-researcher` | Performs research synthesis for brainstorming |

---

## Slash Commands

Use these inside any Claude Code session by typing `/command-name`.

**iOS**
`/ios-build` `/ios-test` `/ios-review` `/ios-new-feature` `/ios-refactor` `/ios-audit` `/xcode-cleanup`

**macOS**
`/macos-build` `/macos-distribute` `/macos-new-feature` `/macos-audit`

**Web**
`/web-build` `/web-test` `/web-review` `/web-new-feature` `/web-refactor` `/web-audit`

**Python**
`/py-build` `/py-test` `/py-review` `/py-new-feature` `/py-refactor` `/py-audit`

**Backend**
`/backend-build` `/backend-test` `/backend-review` `/backend-new-feature` `/backend-refactor`

**API**
`/api-design` `/api-review`

**DevOps**
`/devops-review` `/devops-audit` `/devops-new-service`

**Data**
`/data-model` `/data-migrate` `/data-review`

**Mobile**
`/mobile-build` `/mobile-test` `/mobile-review` `/mobile-new-feature`

**GitHub**
`/gh-debug` `/gh-workflow` `/gh-release` `/gh-audit` `/gh-runners`

**Docs**
`/docs-write` `/docs-prd` `/docs-epic` `/docs-adr` `/docs-changelog` `/docs-review`

**General**
`/brainstorm` `/commit`

---

## Skills / Pattern Libraries

Skills are directories in `claude-code/skills/` that provide domain-specific reference material. Agents automatically consult the relevant skill library for conventions, patterns, and best practices.

| Skill | Description |
|-------|-------------|
| `ios-patterns` | iOS architecture patterns, Swift concurrency, SwiftUI patterns, Apple framework integration |
| `macos-patterns` | macOS-specific AppKit patterns, sandboxing, distribution workflows, menu bar apps |
| `web-patterns` | Component architecture, performance optimization, accessibility, security |
| `python-patterns` | Python project patterns, Django/FastAPI/Flask conventions |
| `backend-patterns` | Go/Rust/Java/Kotlin/C# server patterns |
| `api-patterns` | REST/GraphQL/gRPC API design patterns |
| `devops-patterns` | Docker, Kubernetes, Terraform, cloud infrastructure patterns |
| `data-patterns` | Database schema, migration, and query optimization patterns |
| `mobile-patterns` | React Native and Flutter cross-platform patterns |
| `github-actions-patterns` | CI/CD workflow patterns and security best practices |
| `docs-patterns` | Documentation structure and writing standards |
| `ui-ux-pro-max` | Comprehensive UI/UX design intelligence: 67 styles, 96 color palettes, 57 font pairings, 99 UX guidelines, 25 chart types across 13 technology stacks (React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn/ui, and more). Includes searchable Python scripts and CSV databases. |

---

## Installation

### Root-level install (applies to all projects)

Symlinks `agents/`, `commands/`, and `skills/` into `~/.claude/`, along with settings files.

```bash
git clone <repo-url>
cd frontal-lobe
scripts/install.sh
```

### Project-level install (applies to one project only)

Symlinks `agents/`, `commands/`, and `skills/` into `<project>/.claude/`. Settings files are not installed at the project level.

```bash
scripts/install.sh --project /path/to/your/project
```

### Dry run (preview without changes)

```bash
scripts/install.sh --dry-run
```

### Conflict handling

When an existing file or symlink is found at a target path, the installer prompts you to choose:

- **[b] Backup** — moves the existing item to `<name>.bak.<timestamp>`, then creates the symlink
- **[o] Overwrite** — removes the existing item and creates the symlink
- **[s] Skip** — leaves the existing item in place

Uppercase `[B]`, `[O]`, `[S]` apply your choice to all remaining conflicts.

---

## Syncing Local Changes Back

If you modify configs directly in `~/.claude/` and want to pull those changes back into the repo:

```bash
scripts/sync.sh
```

The script:
1. Compares `~/.claude/` against `claude-code/` across agents, commands, skills, and settings files
2. Shows a color-coded diff preview (new, modified, deleted)
3. Prompts for confirmation before applying any changes

```bash
# Preview only, no changes applied
scripts/sync.sh --dry-run
```

> After syncing, commit the changes to keep the repo up to date.

---

## How It Works

| Component | Format | Location |
|-----------|--------|----------|
| Agents | Markdown with YAML frontmatter (`name`, `description`, `tools`, `model`, `color`) | `claude-code/agents/*.md` |
| Commands | Markdown with instructions Claude executes as slash commands | `claude-code/commands/*.md` |
| Skills | Directories with a `SKILL.md` and optional data/scripts | `claude-code/skills/<name>/` |
| Settings | `settings.json` / `settings.local.json` | `claude-code/` |

The install script creates symlinks from `~/.claude/` (or `<project>/.claude/`) into the repo, so configs remain version-controlled. Edits to symlinked files are edits to the repo.

The `frontal-lobe` orchestrator uses the `Agent` tool to spawn sub-agents. Each sub-agent receives a fully self-contained prompt — working directory, relevant file paths, current code context, specific instructions, and acceptance criteria — because sub-agents run in complete isolation.

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview) — Anthropic's official CLI for Claude
- Bash 4+ (for `install.sh` and `sync.sh`)
- Git

---

## Contributing

The recommended workflow for contributing changes:

1. **Edit configs in `~/.claude/`** during active Claude Code sessions — this is the most natural place to iterate
2. **Run `scripts/sync.sh`** to pull your local changes back into the repo
3. **Review the diff**, confirm, and commit

Or edit files directly in `claude-code/` and run `scripts/install.sh` to re-link.

When adding a new agent, command, or skill:
- Follow the existing frontmatter conventions in `claude-code/agents/` and `claude-code/commands/`
- Add a `SKILL.md` with a `name` and `description` in the YAML frontmatter for new skills
- Agents should be self-contained — all domain knowledge they need should be either inline or in a referenced skill
