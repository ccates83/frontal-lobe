---
description: "List all available agents, skills, commands, and plugins"
agent: frontal-lobe
---
# List Available Tools

Display a comprehensive inventory of all Claude Code configuration artifacts.

## Arguments

- `$ARGUMENTS` — Optional filter: 'agents', 'skills', 'commands', 'plugins', or 'all'. Defaults to 'all'.

## Instructions

This is a read operation you can do directly.

1. Parse $ARGUMENTS to determine what to list.

2. For each type, read the directory and format output:

### Agents (`~/.config/opencode/agents/*.md`)
Read each frontmatter, extract name, description (first sentence), model.
Group by domain (web, ios, python, backend, api, devops, data, mobile, github, docs, brainstorm, meta, other).

### Skills (`~/.config/opencode/skills/*/SKILL.md`)
Read each frontmatter, extract name and description.

### Commands (`~/.config/opencode/commands/*.md`)
Read each frontmatter, extract description.

### Plugins (`~/.config/opencode/plugins/installed_plugins.json`)
Read manifest and list name, version, scope.

3. Format as tables grouped by domain with a coverage summary matrix at the end.
