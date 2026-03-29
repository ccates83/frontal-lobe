---
description: "Create a new agent definition with full ecosystem integration"
agent: frontal-lobe
---
# New Agent Definition

Create a new agent definition with full ecosystem integration, including routing and companion agents.

## Arguments

- `$ARGUMENTS` — Description of the agent(s) to create, including domain and role.

## Instructions

You are an orchestrator. Do NOT create agent files yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read AGENTS.md for project conventions
2. List existing agents in `~/.config/opencode/agents/`
3. Read `~/.config/opencode/agents/frontal-lobe.md` to understand the routing table
4. Identify the domain and archetype(s) from the user's arguments
5. Check for existing agents that might overlap with the request

## Phase 2: Architecture

Use the task tool to invoke `@meta-architect` with:
- The agent description from the user's arguments
- The existing agent inventory and routing table
- The full agent file format conventions (frontmatter fields, tool assignments, model assignments, naming)
- Request for a blueprint including:
  - Agent name (kebab-case, domain-archetype pattern)
  - Archetype (planner, architect, builder, reviewer, tester)
  - Model assignment (opus for planner/builder, sonnet for reviewer/architect/tester)
  - Tool list (per archetype conventions)
  - Color assignment
  - System prompt outline (sections, responsibilities, key instructions)
  - Whether companion agents are needed (e.g., creating a planner should also plan a builder)

## Phase 3: Implement

Based on the architect's blueprint, launch `meta-builder` with:
- Each agent definition to create as a specific task
- The blueprint as reference (name, archetype, model, tools, color, prompt outline)
- File paths to create under `~/.config/opencode/agents/`
- Existing agents in the same domain as style references

Then launch `meta-builder` again with:
- Instructions to update `~/.config/opencode/agents/frontal-lobe.md` routing table
- The new agent name(s) and their routing criteria

## Phase 4: Review

Use the task tool to invoke `@meta-reviewer` with:
- All newly created agent files
- The updated frontal-lobe.md
- Full conventions context
- Instructions to verify naming, frontmatter, tool assignments, model assignments, and prompt quality

## Phase 5: Fix Cycle

If the reviewer found critical or high issues:
1. Use the task tool to invoke `@meta-builder` with the specific fixes
2. Maximum 2 fix rounds

## Phase 6: Report

Present:
- **Created**: Agent files with paths
- **Archetype assignments**: Domain, role, model, tools for each agent
- **Routing**: Changes made to frontal-lobe.md
- **Review**: Summary of review findings and fixes applied
- **Next steps**: Run `scripts/install.sh` to deploy, run `scripts/convert.sh --to-opencode` for OpenCode sync
