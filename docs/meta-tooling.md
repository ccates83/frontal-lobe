# Meta-Tooling

> Using the meta agents to extend, audit, and improve your agent ecosystem.

---

## What Meta-Tooling Is

The Meta domain is unique — it is the part of the system that modifies itself. While every other domain (web, iOS, backend, etc.) operates on application code, the meta agents operate on the workspace: the agents, skills, commands, plugins, and hooks that make up your configuration.

Through natural language requests to `frontal-lobe`, the meta agents let you:

- Create new agents for domains not yet covered
- Write skill files that codify patterns for agents to reference
- Build slash commands for repetitive workflows
- Scaffold plugins that bundle configs for distribution
- Configure hooks for event-driven automation
- Audit your existing config for gaps, inconsistencies, or convention violations
- Design full domain coverage (planner + builder + reviewer + tester) from a single request

This is the primary way to improve and customize the workspace. Instead of manually writing markdown config files and learning the frontmatter schema, you describe what you want and the meta agents handle structure, conventions, and cross-references.

---

## The Meta Agent Roster

| Agent | Role | Model | What It Does |
|-------|------|-------|--------------|
| `meta-planner` | Planner | opus | Routes meta tasks, produces structured implementation plans. Entry point for all meta work. |
| `meta-architect` | Architect | sonnet | Analyzes the ecosystem, identifies gaps, produces design blueprints for new coverage. Read-only. |
| `meta-builder` | Builder | opus | Creates and modifies config files — agents, skills, commands, plugins, hooks. The only meta agent that writes. |
| `meta-reviewer` | Reviewer | sonnet | Audits configs for quality, consistency, convention compliance, and coverage gaps. Read-only. |

The execution flow follows the standard two-phase model: `frontal-lobe` routes meta tasks to `meta-planner`, which reads the existing ecosystem and returns a structured plan. `frontal-lobe` then spawns `meta-builder` (and optionally `meta-architect` or `meta-reviewer`) to carry out the work.

```
User: "Add a Rust agent for embedded systems"
    │
    ▼
frontal-lobe (routes to meta domain)
    │
    ▼
meta-planner (reads existing agents, plans the work)
    │
    ▼ returns plan
frontal-lobe (spawns implementation agents)
    ├── meta-architect (designs the agent — if complex)
    ├── meta-builder (creates the agent file)
    └── meta-builder (updates frontal-lobe routing table)
```

---

## What You Can Do

### Create a New Agent

Describe the domain and role. `meta-planner` reads your existing agents to learn your conventions, plans the definition, and `meta-builder` creates the `.md` file with correct frontmatter, tools, model selection, and a self-contained system prompt. It also updates `frontal-lobe`'s routing table so the new agent is discoverable.

```bash
claude --agent frontal-lobe "Create a Rust builder agent for embedded systems development"
```

> **Shortcut:** Use `/meta-new-agent` for the same workflow without typing the full prompt.

### Create a New Skill

Skill files codify patterns, decision tables, and reference material that agents read when working in a domain. `meta-builder` creates the directory structure (`skills/{name}/SKILL.md`) and populates it with relevant content.

```bash
claude --agent frontal-lobe "Create a skill file for Terraform patterns that devops agents can reference"
```

### Create a New Slash Command

Commands are user-invoked instructions that Claude executes when you type `/<command-name>`. `meta-builder` creates the command file, writes the instruction body, and adds `$ARGUMENTS` injection where appropriate.

```bash
claude --agent frontal-lobe "Create a slash command for scaffolding new React components"
```

### Audit Your Configuration

`meta-reviewer` inventories all agents, skills, and commands, checks convention compliance, identifies coverage gaps, and produces a severity-scored findings report. Run this before adding new agents to understand what you already have and what is missing.

```bash
claude --agent frontal-lobe "Review all my agents and find gaps or inconsistencies"
```

> **Shortcut:** Use `/meta-audit` for the same workflow without typing the full prompt.

### Design New Domain Coverage

For new domains, `meta-architect` runs first to design a coherent agent suite before `meta-builder` starts writing files. This ensures the planner, builder, reviewer, tester, and architect roles are consistent with each other and with existing conventions.

```bash
claude --agent frontal-lobe "Add support for Elixir/Phoenix projects to my agent ecosystem"
```

### Scaffold a Plugin

Plugins bundle agents, skills, commands, and hooks into a distributable directory that can be dropped into any project. `meta-builder` creates the `plugin.json` manifest and all referenced artifacts.

```bash
claude --agent frontal-lobe "Build a plugin that bundles ESLint integration with hooks"
```

> **Shortcut:** Use `/meta-review` for targeted config review.

---

## Artifact Types the Meta Agents Manage

| Artifact | Location | Format | Purpose |
|----------|----------|--------|---------|
| Agent | `~/.claude/agents/{name}.md` | Markdown + YAML frontmatter | Autonomous task performers |
| Skill | `~/.claude/skills/{name}/SKILL.md` | Markdown + YAML frontmatter + optional `data/`, `scripts/` | Reference patterns for agents |
| Command | `~/.claude/commands/{name}.md` | Markdown + optional YAML frontmatter | User-invoked `/slash-commands` |
| Plugin | Project `.claude-plugin/` directory | `plugin.json` + bundled agents/skills/commands/hooks | Distributable config bundles |
| Hook | `hooks/hooks.json` + handler scripts | JSON config + scripts | Event-driven automation (pre/post actions) |

The `meta-patterns` skill in `~/.claude/skills/meta-patterns/` contains the full convention reference — frontmatter fields, archetype rules, naming conventions, and common mistakes. The meta agents consult this automatically during planning and implementation.

---

## Conventions the Meta Agents Follow

`meta-builder` enforces these automatically, but they are useful to know when reviewing generated output or making manual edits.

**Agent naming**: `{domain}-{archetype}` in kebab-case (e.g., `rust-builder`, `elixir-planner`).

**Archetype conventions**:

| Archetype | Model | Can Write | Key Tools |
|-----------|-------|-----------|-----------|
| Planner | opus | No | Read-only + Task tools |
| Architect | sonnet | No | Read-only + Bash + WebSearch |
| Builder | opus | Yes | Read + Write + Edit + Bash |
| Reviewer | sonnet | No | Read-only + Bash |
| Tester | sonnet | Yes | Read + Write + Edit + Bash |

**Minimum viable domain**: A planner + builder. Add reviewer, tester, and architect as the domain matures and the agent is used in production.

**Skill naming**: `{domain}-patterns` directory containing a `SKILL.md`.

**Command naming**: `{domain}-{action}` (e.g., `rust-build`, `elixir-review`).

---

## Tips

- Start with an audit — run `meta-reviewer` before adding new agents to understand what you already have and avoid duplicating coverage.
- Let `frontal-lobe` route — do not invoke meta agents directly. The orchestrator handles the planner → builder flow and ensures proper context is passed to each agent.
- After `meta-builder` creates new agents, run `scripts/install.sh` to symlink them into `~/.claude/` and `scripts/convert.sh --to-opencode` if you also use OpenCode.
- The meta agents read existing configs before creating new ones — they will match your naming conventions, model assignments, and tool selections automatically.
- For complex domain expansions (5+ new files), `meta-architect` runs first to produce a coherent blueprint before `meta-builder` starts writing. This avoids inconsistencies across agents in the same domain.

---

## Related Pages

- [Architecture](architecture.md) — how the two-phase execution model works
- [Agent Reference](agents.md) — full agent list and file format
- [Skills](skills.md) — skill library structure
- [Commands](commands.md) — command format and patterns
- [Contributing](contributing.md) — manual workflows for editing configs
- [Installation](installation.md) — deploying configs via symlinks
- [Cross-Tool Sync](cross-tool-sync.md) — keeping Claude Code and OpenCode configs in sync
