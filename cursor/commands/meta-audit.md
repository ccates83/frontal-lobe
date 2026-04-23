# Meta Ecosystem Audit

Audit the agent, skill, and command ecosystem for gaps, inconsistencies, and convention violations.

## Arguments

- `$ARGUMENTS` — Optional focus area. Defaults to a full audit covering all areas.

## Instructions

You are an orchestrator. Do NOT audit the ecosystem yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions
2. List all agents in `~/.cursor/agents/`
3. List all skills in `~/.cursor/skills/`
4. List all commands in `~/.cursor/commands/`
5. Read `~/.cursor/agents/frontal-lobe.md` for the routing table
6. Determine audit scope from the user's arguments:
   - `full` or empty: all areas
   - `agents`: agent definitions only
   - `skills`: skill definitions only
   - `commands`: command definitions only
   - `coverage`: domain x archetype coverage gaps
   - `conventions`: convention compliance only

## Phase 2: Audit

Delegate to the `meta-reviewer` subagent with:
- The full ecosystem inventory (agents, skills, commands)
- The specific audit focus from Phase 1
- Instructions to check:
  - Convention compliance (frontmatter fields, naming, file structure)
  - Coverage gaps (missing archetypes per domain, domains without planners or builders)
  - Tool assignments (correct tools per archetype)
  - Model assignments (correct model per archetype)
  - Naming conventions (kebab-case, domain-archetype pattern)
  - Orphaned agents (defined but not referenced in any routing table or command)
  - Missing skills (referenced by agents but not present)
  - Missing commands (domains with agents but no corresponding commands)
  - Routing table completeness (all agents reachable from frontal-lobe)

## Phase 3: Report

Present:
- **Audit scope**: What was reviewed
- **Critical findings**: Convention violations, broken references, missing routing
- **High findings**: Coverage gaps, incorrect tool/model assignments
- **Medium findings**: Naming inconsistencies, orphaned definitions
- **Low findings**: Style suggestions, minor improvements
- **Info**: Ecosystem statistics and health summary
- **Coverage map**: Domain x archetype table showing present/missing agents
- **Recommendations**: Prioritized by impact, with specific action items
