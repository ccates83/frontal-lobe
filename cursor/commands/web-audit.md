# Web Project Audit

Audit a web project for performance, accessibility, security, and best practices.

## Arguments

- `$ARGUMENTS` — Optional focus area. Defaults to a full audit covering all areas.

## Instructions

You are an orchestrator. Do NOT audit the project yourself. Plan and delegate.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project conventions
2. Read `package.json` for dependencies, scripts, and framework
3. Read framework configuration files
4. Scan the directory structure
5. Determine audit scope from the user's arguments:
   - `full` or empty: all areas
   - `performance`: Core Web Vitals focus
   - `accessibility` / `a11y`: WCAG compliance focus
   - `security`: vulnerability and auth focus
   - `dependencies`: outdated/vulnerable packages focus

## Phase 2: Audit

Delegate to the `web-reviewer` subagent with:
- The full project context
- The specific audit mode (performance, a11y, security, or full)
- Instructions to scan representative files across the project
- Instructions to check: package.json dependencies, configuration, components, API routes, middleware
- For dependency audits, run `npm audit` and check for outdated packages

## Phase 3: Report

Present:
- **Audit scope**: What was reviewed
- **Critical findings**: Must-fix issues
- **Important findings**: Should-fix issues
- **Recommendations**: Best practice improvements
- **Score**: Overall health assessment
- **Priority action items**: Top 3-5 things to address first
