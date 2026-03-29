# Command Reference

> Slash commands for common workflows — typed in any Claude Code or OpenCode session.

---

## File Format

### Claude Code (`claude-code/commands/*.md`)

Commands are plain markdown. Frontmatter is optional but recommended.

```markdown
---
description: Plan and implement a new iOS feature end-to-end
argument-hint: Describe the feature you want to build
---

# iOS New Feature

## Arguments
- `$ARGUMENTS` — Description of the feature to build.

## Instructions
You are an orchestrator. Do NOT write code yourself. Plan and delegate...
```

| Field | Description |
|-------|-------------|
| `description` | Shown in command picker |
| `argument-hint` | Hint text displayed when user types the command |

Commands with no frontmatter (like `/commit`) are valid — the entire file is the instruction body.

### OpenCode (`opencode/commands/*.md`)

```markdown
---
description: "Plan and implement a new iOS feature end-to-end"
agent: frontal-lobe
---

# iOS New Feature
...
```

| Field | Description |
|-------|-------------|
| `description` | Shown in command picker |
| `agent` | Which agent handles the command (`frontal-lobe`, `build`, `plan`) |

---

## Multi-Phase Command Pattern

Most commands follow this structure, acting as orchestrators themselves:

1. **Understand Context** — read `CLAUDE.md`, scan project structure, run `git status`
2. **Architecture / Plan** — spawn an architect or planner agent
3. **Implement** — spawn builder agent(s), parallel when possible
4. **Verify** — spawn reviewer + tester + build check in parallel
5. **Fix Cycle** — spawn builder with specific fixes (max 2 rounds)
6. **Report** — present summary of changes, build status, test status

---

## Command Listing

### iOS

| Command | Description |
|---------|-------------|
| `/ios-build` | Build and verify the Xcode project |
| `/ios-test` | Run the test suite |
| `/ios-review` | Code review for iOS/Swift changes |
| `/ios-new-feature` | Plan and implement a new iOS feature end-to-end |
| `/ios-refactor` | Refactor iOS code with architecture guidance |
| `/ios-audit` | Security and quality audit |
| `/xcode-cleanup` | Clean derived data, reset simulators, fix common Xcode issues |

### macOS

| Command | Description |
|---------|-------------|
| `/macos-build` | Build and verify the macOS Xcode project |
| `/macos-distribute` | Package and distribute a macOS app |
| `/macos-new-feature` | Plan and implement a new macOS feature |
| `/macos-audit` | Security and quality audit for macOS |

### Web

| Command | Description |
|---------|-------------|
| `/web-build` | Build and verify the web project |
| `/web-test` | Run the test suite |
| `/web-review` | Code review for web/frontend/backend changes |
| `/web-new-feature` | Plan and implement a new web feature |
| `/web-refactor` | Refactor web code |
| `/web-audit` | Security, performance, and accessibility audit |

### Python

| Command | Description |
|---------|-------------|
| `/py-build` | Build and verify the Python project |
| `/py-test` | Run the test suite |
| `/py-review` | Code review for Python changes |
| `/py-new-feature` | Plan and implement a new Python feature |
| `/py-refactor` | Refactor Python code |
| `/py-audit` | Security and quality audit |

### Backend

| Command | Description |
|---------|-------------|
| `/backend-build` | Build and verify the backend service |
| `/backend-test` | Run the test suite |
| `/backend-review` | Code review for backend changes |
| `/backend-new-feature` | Plan and implement a new backend feature |
| `/backend-refactor` | Refactor backend code |

### API

| Command | Description |
|---------|-------------|
| `/api-design` | Design a new API (REST, GraphQL, or gRPC) |
| `/api-review` | Review API design and implementation |

### DevOps

| Command | Description |
|---------|-------------|
| `/devops-review` | Review infrastructure and CI/CD configs |
| `/devops-audit` | Security and best-practice audit |
| `/devops-new-service` | Scaffold a new service with Docker/K8s/Terraform |

### Data

| Command | Description |
|---------|-------------|
| `/data-model` | Design or revise a data model |
| `/data-migrate` | Plan and write a database migration |
| `/data-review` | Review schema, queries, and migrations |
| `/data-test` | Run database and data pipeline tests |

### Mobile

| Command | Description |
|---------|-------------|
| `/mobile-build` | Build and verify the React Native or Flutter project |
| `/mobile-test` | Run the mobile test suite |
| `/mobile-review` | Code review for mobile changes |
| `/mobile-new-feature` | Plan and implement a new mobile feature |

### GitHub

| Command | Description |
|---------|-------------|
| `/gh-debug` | Debug a failing GitHub Actions workflow |
| `/gh-workflow` | Create or update a GitHub Actions workflow |
| `/gh-release` | Cut a release (tags, changelogs, GitHub Release) |
| `/gh-audit` | Audit GitHub Actions workflows for security issues |
| `/gh-runners` | Manage self-hosted GitHub Actions runners |

### Docs

| Command | Description |
|---------|-------------|
| `/docs-write` | Write or update documentation |
| `/docs-prd` | Write a Product Requirements Document |
| `/docs-epic` | Write a product epic and user stories |
| `/docs-adr` | Write an Architecture Decision Record |
| `/docs-changelog` | Generate or update a changelog |
| `/docs-review` | Review documentation for accuracy and clarity |

### General

| Command | Description |
|---------|-------------|
| `/brainstorm` | Structured ideation: interview → research → synthesize |
| `/commit` | Commit all pending changes, split into logical commits |
| `/list-tools` | List all available agents, skills, commands, and plugins |

### Meta

| Command | Description |
|---------|-------------|
| `/meta-audit` | Audit the agent/skill/command ecosystem for gaps and convention violations |
| `/meta-new-agent` | Create a new agent definition with full ecosystem integration |
| `/meta-review` | Review agent/skill/command configs for quality and compliance |

---

## Creating a Custom Command

1. Create `claude-code/commands/<name>.md`.
2. Add optional frontmatter (`description`, `argument-hint`).
3. Write the instruction body. Use `$ARGUMENTS` for user-provided input.
4. If the command orchestrates agents, follow the multi-phase pattern above.
5. Run `scripts/install.sh` to symlink into `~/.claude/commands/`.
6. Run `scripts/convert.sh --to-opencode` if you also use OpenCode.

**Checklist:**
- [ ] Filename is the command name (e.g., `my-command.md` → `/my-command`)
- [ ] `description` field is present and clear
- [ ] `argument-hint` is set if the command accepts arguments
- [ ] Instructions say "Do NOT write code yourself — delegate to agents"
- [ ] Fix cycle is bounded (max 2 rounds)

---

## Related Pages

- [Architecture](architecture.md) — the two-phase model commands invoke
- [Agents](agents.md) — agents that commands delegate to
