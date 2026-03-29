# Skills / Pattern Libraries

> Domain-specific reference material that agents consult when making architecture and implementation decisions.

---

## What Skills Are

Skills are directories in `claude-code/skills/` containing a `SKILL.md` and optional `data/` and `scripts/` subdirectories. They are not executed — they are **read by agents** during planning and implementation.

An agent references a skill by reading its `SKILL.md` (and any relevant data files) as part of its context-gathering step. This keeps domain knowledge out of individual agent prompts and in a single, versioned place.

---

## Directory Structure

```
claude-code/skills/
└── <skill-name>/
    ├── SKILL.md          # Required: frontmatter + reference content
    ├── data/             # Optional: CSV databases, lookup tables
    │   └── *.csv
    └── scripts/          # Optional: Python search utilities
        └── *.py
```

`SKILL.md` frontmatter:

```markdown
---
name: ios-patterns
description: "iOS architecture patterns, Swift concurrency reference..."
---

# iOS Patterns — Architecture & Implementation Reference

## When to Apply
...
```

| Field | Description |
|-------|-------------|
| `name` | Skill identifier |
| `description` | Used by agents to determine when to consult this skill |

---

## Skills Table

| Skill | Description |
|-------|-------------|
| `ios-patterns` | iOS architecture patterns, Swift concurrency, SwiftUI patterns, Apple framework integration |
| `macos-patterns` | macOS-specific AppKit patterns, sandboxing, distribution workflows, menu bar apps |
| `meta-patterns` | Claude Code ecosystem configuration patterns — agent definitions, skills, commands, plugins, hooks |
| `web-patterns` | Component architecture, performance optimization, accessibility, security |
| `python-patterns` | Python project patterns, Django/FastAPI/Flask conventions |
| `backend-patterns` | Go/Rust/Java/Kotlin/C# server patterns |
| `api-patterns` | REST/GraphQL/gRPC API design patterns |
| `devops-patterns` | Docker, Kubernetes, Terraform, cloud infrastructure patterns |
| `data-patterns` | Database schema, migration, and query optimization patterns |
| `mobile-patterns` | React Native and Flutter cross-platform patterns |
| `github-actions-patterns` | CI/CD workflow patterns and security best practices |
| `docs-patterns` | Documentation structure and writing standards |
| `ui-ux-pro-max` | Comprehensive UI/UX design intelligence (see below) |

---

## ui-ux-pro-max

The most comprehensive skill in the collection. It provides design intelligence across 13 technology stacks.

**Coverage:**
- 67 UI styles (glassmorphism, brutalism, neumorphism, bento grid, etc.)
- 96 color palettes
- 57 font pairings
- 99 UX guidelines
- 25 chart types
- Stacks: React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn/ui, Nuxt, Astro, Jetpack Compose, HTML+Tailwind

**Structure:**

```
claude-code/skills/ui-ux-pro-max/
├── SKILL.md
├── data/
│   ├── colors.csv          # 96 palettes
│   ├── styles.csv          # 67 UI styles
│   ├── typography.csv      # 57 font pairings
│   ├── ux-guidelines.csv   # 99 UX rules
│   ├── charts.csv          # 25 chart types
│   ├── stacks/             # Per-stack component examples
│   │   ├── react.csv
│   │   ├── nextjs.csv
│   │   ├── vue.csv
│   │   └── ...
│   └── ...
└── scripts/
    ├── search.py           # Searchable query interface
    ├── core.py             # Core data loading utilities
    └── design_system.py    # Design system helpers
```

Agents with access to `Bash` can run `python3 scripts/search.py` to query the CSV databases rather than loading all data into context.

---

## Creating a Custom Skill

1. Create `claude-code/skills/<name>/SKILL.md` with `name` and `description` in frontmatter.
2. Write reference content — patterns, code examples, decision tables, conventions.
3. Add `data/*.csv` files if the skill has large lookup tables that benefit from search.
4. Add `scripts/*.py` search utilities if agents need to query the data programmatically.
5. Run `scripts/install.sh` to symlink into `~/.claude/skills/`.

**Checklist:**
- [ ] `name` matches the directory name
- [ ] `description` is specific enough for agents to know when to use this skill
- [ ] Content is organized with clear headers and tables for scannability
- [ ] "When to Apply" section tells agents the triggering conditions
- [ ] Content is self-contained — no external links required for basic use

---

## Related Pages

- [Agents](agents.md) — agents that consume skills
- [Installation](installation.md) — how skills are deployed via symlinks
