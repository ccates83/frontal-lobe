# Agent Reference

> Format, domain coverage, and how to create custom agents.

---

## File Format

Agent files are markdown with YAML frontmatter. The two tools use different field schemas.

### Claude Code (`claude-code/agents/*.md`)

```markdown
---
name: web-builder
description: "Implements web application code... <example>...</example>"
tools: Read, Write, Edit, Glob, Grep, Bash
model: opus
color: orange
---

You are an expert web developer...
```

| Field | Description |
|-------|-------------|
| `name` | Agent identifier — used in `--agent` flag and `subagent_type` |
| `description` | Shown at agent selection; include `<example>` XML blocks for usage context |
| `tools` | Comma-separated list of allowed tools |
| `model` | `opus`, `sonnet`, or `haiku` |
| `color` | Terminal output color |

### OpenCode (`opencode/agents/*.md`)

```markdown
---
description: "Implements web application code..."
model: anthropic/claude-sonnet-4-5
permission:
  edit: allow
  bash: allow
  webfetch: deny
  task: deny
color: orange
mode: subagent
---

You are an expert web developer...
```

| Field | Description |
|-------|-------------|
| `description` | Same as Claude Code |
| `model` | Full model ID: `anthropic/claude-sonnet-4-5` or `anthropic/claude-haiku-4-5` |
| `permission` | Four boolean capabilities: `edit`, `bash`, `webfetch`, `task` |
| `mode` | `subagent` for all agents except `frontal-lobe` which uses `primary` |

See [Cross-Tool Sync](cross-tool-sync.md) for the field mapping between formats.

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
| Meta (Agents, Skills, Commands, Plugins) | `meta-planner` | `meta-builder` | `meta-reviewer` | — | `meta-architect` |

---

## Specialized Agents

| Agent | Purpose |
|-------|---------|
| `xcode-builder` | Runs `xcodebuild` commands, manages schemes and targets |
| `pbxproj-surgeon` | Surgically modifies Xcode `.pbxproj` project files |
| `spm-manager` | Manages Swift Package Manager dependencies |
| `gh-cli-operator` | Executes `gh` CLI commands (PRs, issues, releases) |
| `runner-manager` | Manages GitHub Actions self-hosted runners |
| `actions-debugger` | Debugs failing GitHub Actions workflows |
| `brainstorm-interviewer` | Conducts structured ideation interviews |
| `brainstorm-researcher` | Performs research synthesis for brainstorming |

---

## Model Assignment Conventions

| Model | Used for |
|-------|---------|
| `opus` | Builders and planners — tasks that require writing code or deep analysis |
| `sonnet` | Architects and reviewers — read-only reasoning tasks |
| `haiku` | Fast utility agents (none currently, reserved for future lightweight tasks) |

---

## Creating a Custom Agent

1. Create `claude-code/agents/<name>.md` following the format above.
2. Choose a role and tools accordingly — builders get `Write, Edit`; planners do not.
3. Write a fully self-contained system prompt. Sub-agents have no shared context — everything the agent needs must be in the prompt body or passed by the caller.
4. Add `<example>` blocks in the `description` field to help `frontal-lobe` route tasks to your agent.
5. Run `scripts/install.sh` to symlink into `~/.claude/agents/`.
6. Run `scripts/convert.sh --to-opencode` if you also use OpenCode.

**Checklist:**
- [ ] `name` matches the filename (without `.md`)
- [ ] `tools` is restricted to what the agent actually needs
- [ ] System prompt is self-contained (no assumed context)
- [ ] `model` is `opus` for builders, `sonnet` for reviewers/architects
- [ ] Agent is listed in `frontal-lobe.md`'s Available Agents table if it should be orchestrated

---

## Related Pages

- [Architecture](architecture.md) — how agents fit into the two-phase model
- [Meta-Tooling](meta-tooling.md) — using meta agents to extend the ecosystem
- [Skills](skills.md) — domain knowledge libraries agents reference
- [Cross-Tool Sync](cross-tool-sync.md) — converting between Claude Code and OpenCode formats
