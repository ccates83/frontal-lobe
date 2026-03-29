---
name: meta-patterns
description: "Claude Code ecosystem configuration patterns — agent definitions, skill files, slash commands, plugin structures, and hook configs. Reference material for meta-planner, meta-builder, meta-reviewer, and meta-architect agents."
compatibility: opencode
---
# Meta Patterns — Ecosystem Configuration Reference

Quick-reference guide for creating and auditing Claude Code configuration artifacts. Used by the meta planner ecosystem to produce consistent, convention-compliant agents, skills, commands, plugins, and hooks.

## When to Apply

Reference these patterns when:
- Creating a new agent definition
- Writing or updating a skill/pattern library
- Building a new slash command
- Scaffolding a plugin or hook configuration
- Auditing existing configs for convention compliance
- Adding a new domain to the agent ecosystem
- Updating frontal-lobe routing after adding agents

---

## 1. Agent Definition Patterns

### File Location and Naming

- **Path**: `~/.config/opencode/agents/{name}.md`
- **Naming**: `{domain}-{archetype}` in kebab-case
- **Examples**: `web-builder`, `python-planner`, `devops-reviewer`, `meta-architect`

### Frontmatter Fields

```yaml
---
name: web-builder
description: "What the agent does. For planners, include routing <example> blocks."
tools: Read, Write, Edit, Glob, Grep, Bash
model: opus
color: blue
---
```

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `name` | Yes | string | Must match filename (without `.md`) |
| `description` | Yes | quoted string | Planners need `<example>` blocks (minimum 3) |
| `tools` | Yes | comma-separated | Must match archetype (see table below) |
| `model` | Yes | string | `opus`, `sonnet`, or `haiku` |
| `color` | Yes | string | Terminal output color for the agent |

### Archetype Conventions

| Archetype | Model | Tools | Role | File Writes? |
|-----------|-------|-------|------|-------------|
| Planner | `opus` | `Bash, Glob, Grep, Read, TaskCreate, TaskUpdate, TaskList, TaskGet, WebFetch, WebSearch` | Routes tasks, returns structured plans | No |
| Architect | `sonnet` | `Read, Glob, Grep, Bash, WebSearch` | Designs systems, produces blueprints | No |
| Builder | `opus` | `Read, Write, Edit, Glob, Grep, Bash` | Implements code and config changes | Yes |
| Reviewer | `sonnet` | `Read, Glob, Grep, Bash` | Audits quality, reports findings | No |
| Tester | `sonnet` | `Read, Write, Edit, Glob, Grep, Bash` | Writes and runs tests | Yes |

### Description Field Requirements

**All agents**: Clear one-sentence summary of purpose.

**Planners only**: Must include routing `<example>` blocks (minimum 3). These are what frontal-lobe uses to decide when to invoke the planner.

```yaml
description: "Domain planner for X tasks. READ-ONLY.\n\nExamples:\n\n<example>\nContext: User wants Y\nuser: \"Do Y\"\nassistant: \"This is an X domain task. Let me use the task tool to launch x-planner.\"\n</example>\n\n<example>\nContext: User wants Z\nuser: \"Do Z\"\nassistant: \"This is an X domain task. Let me use the task tool to launch x-planner.\"\n</example>\n\n<example>\nContext: User wants W\nuser: \"Do W\"\nassistant: \"This is an X domain task. Let me use the task tool to launch x-planner.\"\n</example>"
```

### System Prompt Body Structure

**Planner:**
1. Identity statement ("You are the **X Planner**...")
2. CRITICAL read-only section (bold, emphatic)
3. Structured plan output format (markdown template)
4. Core Identity (what domains/expertise)
5. Fundamental Rules (numbered list)
6. Planning Protocol (step-by-step)
7. Agent Roster (table of agents this planner can invoke)
8. Anti-Patterns (what to never do)

**Builder:**
1. Identity statement ("You are an expert X engineer...")
2. Before Writing checklist (what to read first)
3. Style/Convention guide (domain-specific patterns)
4. Implementation Checklist (post-write verification)
5. Common Pitfalls (what breaks most often)

**Reviewer:**
1. Identity statement ("You are an expert X reviewer...")
2. CRITICAL read-only emphasis
3. Review Protocol (step-by-step)
4. Finding Format (severity, confidence, category template)
5. Scoring Guide (when to use each severity level)

**Architect:**
1. Identity statement ("You are the **X Architect**...")
2. CRITICAL read-only emphasis
3. Core Expertise (what the domain covers)
4. Analysis Protocol (step-by-step)
5. Blueprint Format (recommendation template)

### Minimum Viable Domain

A new domain requires at least: **planner + builder**. Add architect, reviewer, tester as needed.

```
{domain}-planner   (always required — routes and plans)
{domain}-builder   (always required — implements)
{domain}-architect (optional — for complex design tasks)
{domain}-reviewer  (optional — for quality auditing)
{domain}-tester    (optional — for test writing)
```

---

## 2. Skill Definition Patterns

### File Location and Structure

```
~/.config/opencode/skills/{skill-name}/
  SKILL.md         # Required — the pattern reference
  data/            # Optional — CSV lookup tables, reference data
  scripts/         # Optional — Python utilities for searchable queries
```

- **Naming**: `{domain}-patterns` (e.g., `web-patterns`, `python-patterns`)
- **The file MUST be in a subdirectory** — never `skills/{name}.md` directly

### Frontmatter

```yaml
---
name: web-patterns
description: "What patterns this covers and which agents use it."
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Matches directory name |
| `description` | Yes | Mention which agents consume this skill |

### Required Body Sections

1. **H1 Title**: `# {Name} -- {Subtitle} Reference`
2. **Intro paragraph**: One-sentence purpose statement
3. **When to Apply**: Bulleted list of situations triggering use
4. **`---` separator**
5. **Numbered pattern sections**: `## 1. Topic`, `## 2. Topic`, etc.
6. **Tables**: For structured reference material
7. **Code blocks**: With language hints for all examples

### When to Add data/ Files

Add CSV or JSON files in `data/` when:
- A lookup table exceeds 20 rows
- Reference data changes independently of the skill prose
- Multiple agents need to query the same dataset

### When to Add scripts/ Utilities

Add Python scripts in `scripts/` when:
- Agents need to search or filter large datasets
- Transformation logic is too complex for inline instructions
- A reusable query tool saves repeated work

---

## 3. Slash Command Patterns

### File Location and Naming

- **Path**: `~/.config/opencode/commands/{command-name}.md`
- **Naming**: `{domain}-{action}` (e.g., `web-review`, `ios-new-feature`, `docs-write`)

### Frontmatter

```yaml
---
description: Short description of what the command does
argument-hint: "what arguments to pass"
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `description` | Yes | Shown in command list |
| `argument-hint` | Optional | Shown when user types the command |

### Body Structure

```markdown
# Command Title

Brief description.

## Arguments

- `$ARGUMENTS` -- What the user provides.

## Instructions

You are an orchestrator. Do NOT implement yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read AGENTS.md for project conventions
2. Identify scope from user arguments
3. Gather relevant file paths

## Phase 2: Execute / Plan

Launch the appropriate planner or implementation agent with full context.

## Phase 3: Implement / Review

Launch builders/reviewers based on Phase 2 output.

## Final Phase: Report

Present results with summary and next steps.
```

### Key Command Conventions

- **Commands are orchestrators** — they say "Do NOT implement yourself. Plan and delegate."
- **Fix cycles are bounded** to a maximum of 2 rounds
- **$ARGUMENTS** is the placeholder for user input
- **Multi-phase pattern**: Understand -> Execute -> Implement -> Report
- Each phase names the specific agent(s) to invoke

---

## 4. Plugin Patterns

### Directory Structure

```
project/
  .claude-plugin/
    plugin.json     # Required — plugin manifest
    skills/         # Optional — skill files
    agents/         # Optional — agent definitions
    commands/       # Optional — slash commands
    hooks/          # Optional — hook configurations
```

### plugin.json

```json
{
  "name": "my-plugin",
  "description": "What the plugin provides",
  "author": "author-name",
  "version": "1.0.0"
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | kebab-case identifier |
| `description` | Yes | Human-readable purpose |
| `author` | Yes | Creator attribution |
| `version` | Optional | Semantic version |

### When to Bundle vs Keep Separate

**Bundle as a plugin** when:
- A set of agents + skills + commands form a cohesive domain package
- The config is meant to be shared across projects or teams
- Project-specific overrides are needed alongside global configs

**Keep separate** (in `~/.config/opencode/`) when:
- The config is personal/global
- It applies to all projects universally
- It is part of the core orchestrator ecosystem

---

## 5. Hook Patterns

### hooks.json Structure

```json
{
  "hooks": {
    "pre-commit": [
      {
        "command": "scripts/pre-commit-check.sh",
        "description": "Run linting before commit"
      }
    ],
    "post-commit": [
      {
        "command": "scripts/post-commit-notify.sh",
        "description": "Notify after successful commit"
      }
    ]
  }
}
```

### Event Types

| Event | Trigger | Common Use |
|-------|---------|-----------|
| `pre-commit` | Before a commit is created | Lint, format, validate |
| `post-commit` | After a commit is created | Notify, log, trigger CI |
| `pre-push` | Before pushing to remote | Run tests, check coverage |
| `post-push` | After pushing to remote | Deploy, notify |

### Handler Script Conventions

- Scripts live in a `scripts/` or `hooks/` directory
- Must be executable (`chmod +x`)
- Exit code 0 = success, non-zero = abort the operation
- Write to stdout for informational output, stderr for errors
- Keep scripts idempotent — safe to run multiple times

---

## 6. Frontal-Lobe Integration

### Adding New Agents to the Routing Table

Every new agent **MUST** be added to `~/.config/opencode/agents/frontal-lobe.md` in the Available Agents table. If the agent is not listed, frontal-lobe cannot invoke it.

**Steps after creating a new domain:**
1. Create the agent files (`{domain}-planner.md`, `{domain}-builder.md`, etc.)
2. Open `frontal-lobe.md`
3. Add the new agents to the Available Agents table
4. Add routing heuristics for the domain (keywords, file extensions, frameworks)

### Routing Heuristics

Frontal-lobe decides which planner to invoke based on:
1. **File extensions** in the working directory (`.tsx` -> web, `.swift` -> ios, `.py` -> python)
2. **Framework indicators** (`package.json` -> web, `Cargo.toml` -> backend, `Podfile` -> ios)
3. **Keywords in the user request** ("deploy" -> devops, "API" -> api, "test" -> tester)
4. **Description `<example>` blocks** — frontal-lobe pattern-matches against these to route

### Description `<example>` Blocks

These are the primary routing mechanism. Frontal-lobe reads all planner descriptions and matches the user's request against the example patterns.

```
<example>
Context: {situation description}
user: "{what the user says}"
assistant: "{how frontal-lobe responds and which agent it invokes}"
</example>
```

Minimum 3 examples per planner. Cover the most common routing scenarios for the domain.

---

## 7. Cross-Tool Compatibility

### Claude Code vs OpenCode Frontmatter

| Claude Code Field | OpenCode Equivalent | Notes |
|-------------------|--------------------|----|
| `name` | (derived from filename) | OpenCode uses filename as identifier |
| `description` | `description` | Same field |
| `tools` | `permission` block | Converted to allow/deny per category |
| `model` | `model` | Different format (see mapping) |
| `color` | `color` | Same field |
| (none) | `mode` | `primary` for frontal-lobe, `subagent` for others |
| (none) | `compatibility` | Added to skill files (`opencode`) |

### Model Name Mapping

| Claude Code | OpenCode |
|-------------|----------|
| `opus` | `anthropic/claude-sonnet-4-5` |
| `sonnet` | `anthropic/claude-sonnet-4-5` |
| `haiku` | `anthropic/claude-haiku-4-5` |

### Tool-to-Permission Mapping

| Claude Code Tools | OpenCode Permission | Value |
|-------------------|-------------------|-------|
| `Write`, `Edit` | `permission.edit` | `allow` |
| `Bash` | `permission.bash` | `allow` |
| `WebFetch`, `WebSearch` | `permission.webfetch` | `allow` |
| `Agent`, `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet` | `permission.task` | `allow` |
| `Glob`, `Grep`, `Read` | (always available) | implicit |

### Body Text Substitution Rules

| Claude Code | OpenCode |
|-------------|----------|
| `AGENTS.md` | `AGENTS.md` |
| `opencode` | `opencode` |
| `the task tool` | `the task tool` |
| `~/.config/opencode/` | `~/.config/opencode/` |
| `opencode/` | `opencode/` |
| `` Use the task tool to invoke `@agent-name` `` | `` Use the task tool to invoke `@agent-name` `` |

### After Creating Any Config

Always run the conversion script to keep both tool configs in sync:

```bash
scripts/convert.sh --to-opencode    # After editing opencode/ configs
scripts/convert.sh --to-claude      # After editing opencode/ configs
```

---

## 8. Common Mistakes

| Mistake | Impact | Prevention |
|---------|--------|-----------|
| Unquoted YAML description with special chars (`:`, `"`, `\n`) | Frontmatter parse failure | Always wrap `description` in double quotes; escape inner quotes |
| Wrong tools for archetype (giving Write to a reviewer) | Agent can modify files it should only read | Cross-reference the archetype conventions table |
| Missing `<example>` blocks on planner description | Frontal-lobe cannot route to the planner | Add minimum 3 examples covering common routing scenarios |
| Giving write tools to read-only agents (planners, reviewers, architects) | Violates read-only contract; agent may modify files | Planners: no Write/Edit. Reviewers: no Write/Edit. Architects: no Write/Edit |
| Wrong model tier (opus for a reviewer, sonnet for a builder) | Overspending on read-only tasks or underpowering write tasks | Planners/builders: opus. Reviewers/architects/testers: sonnet |
| Skill file at `skills/name.md` instead of `skills/name/SKILL.md` | Skill not discovered by agents | Always use the subdirectory structure |
| Not updating frontal-lobe routing table | New agents are invisible to the orchestrator | Add to Available Agents table after creating any new agent |
| Duplicating existing agent coverage | Conflicting agents, confused routing | Always inventory existing agents before creating new ones |
| Filename does not match `name` field | Agent invocation fails | Keep `name` in frontmatter identical to filename (minus `.md`) |
| Planner without a corresponding builder | Plans are generated but nothing can execute them | Minimum viable domain is planner + builder |
| Not running `scripts/convert.sh` after changes | OpenCode configs fall out of sync | Run conversion after every config edit |
| Agent prompt assumes shared context | Sub-agent fails (agents run in complete isolation) | Include all paths, code context, and acceptance criteria in every prompt |
