# Architecture

> How `frontal-lobe` thinks, plans, and delegates across a fleet of specialized agents.

---

## Two-Phase Execution Model

`frontal-lobe` is strictly read-only. It never writes a file. All work flows through sub-agents.

```
User request
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 1: PLAN                                          │
│  frontal-lobe spawns domain planner(s) in parallel      │
│                                                         │
│  web-planner ──┐                                        │
│  docs-planner ─┼──► structured implementation plans     │
│  ios-planner ──┘    (which agents, which prompts,       │
│                      which tasks are parallel)          │
└─────────────────────────────────────────────────────────┘
    │
    ▼ (planner output drives Phase 2)
┌─────────────────────────────────────────────────────────┐
│  Phase 2: EXECUTE                                       │
│  frontal-lobe spawns implementation agents in parallel  │
│                                                         │
│  web-builder ──┐                                        │
│  web-builder ──┼──► files written, tests run            │
│  docs-writer ──┘                                        │
└─────────────────────────────────────────────────────────┘
    │
    ▼
Delegation Log (summary of what ran, what changed)
```

### Concrete Example

```
User: "Fix the navigation bug and update the README"

Phase 1 (parallel):
  web-planner  → reads codebase, returns plan: 2 builder tasks
  docs-planner → reads codebase, returns plan: 1 writer task

Phase 2 (parallel, from planner output):
  web-builder  → fixes src/components/Navbar.tsx
  web-builder  → fixes src/components/Footer.tsx
  docs-writer  → updates README.md
```

### When to Skip Phase 1

For trivial tasks where the domain, files, and changes are obvious, `frontal-lobe` may gather context with `Glob`/`Grep`/`Read` itself and go directly to Phase 2.

---

## Agent Role Taxonomy

| Role | Read files | Write files | Key purpose |
|------|-----------|------------|-------------|
| **Orchestrator** (`frontal-lobe`) | Yes | No | Plans, coordinates, delegates |
| **Planner** (`*-planner`) | Yes | No | Domain analysis, returns structured plans |
| **Architect** (`*-architect`) | Yes | No | Design decisions, blueprints |
| **Builder** (`*-builder`, `*-writer`) | Yes | Yes | Code implementation |
| **Reviewer** (`*-reviewer`) | Yes | No | Audit, scoring, feedback |
| **Tester** (`*-tester`) | Yes | Yes | Test writing |

---

## Tool Access by Role

| Role | Read | Write/Edit | Bash | WebFetch | Agent/Task |
|------|------|-----------|------|----------|-----------|
| Orchestrator | Yes | No | No | Yes | Yes |
| Planner | Yes | No | Yes | Yes | No |
| Architect | Yes | No | Yes | Yes | No |
| Builder | Yes | Yes | Yes | No | No |
| Reviewer | Yes | No | Yes | No | No |
| Tester | Yes | Yes | Yes | No | No |

---

## Sub-Agent Isolation

Every sub-agent runs in **complete isolation** — no shared state, no shared context window. This means every prompt from `frontal-lobe` to a sub-agent must be fully self-contained:

- Absolute working directory path
- Specific file paths to read or modify
- Current code context (summarized from what the orchestrator read)
- Exact instructions
- Acceptance criteria

Planners receive an additional instruction: "Return a structured plan. Do NOT implement anything."

---

## Delegation Flow

```
User request
    └─► frontal-lobe gathers initial context (Glob, Grep, Read)
            └─► spawns planner(s) with task + file context
                    └─► planners return: agent list + prompts + parallelism map
                            └─► frontal-lobe spawns builders/testers in parallel
                                    └─► builders write code
                                    └─► testers write tests
                                    └─► reviewer audits (optional)
                                            └─► frontal-lobe emits Delegation Log
```

---

## Delegation Log

After completing work, `frontal-lobe` emits a structured summary:

```
## Delegation Log
| Phase   | Agent        | Task                    | Result                       |
|---------|--------------|-------------------------|------------------------------|
| Plan    | web-planner  | Analyze navigation bug  | Produced plan: 2 tasks       |
| Plan    | docs-planner | Analyze README          | Produced plan: 1 task        |
| Execute | web-builder  | Fix Navbar.tsx          | Updated navigation links     |
| Execute | web-builder  | Fix Footer.tsx          | Updated footer links         |
| Execute | docs-writer  | Update README.md        | Added features section       |
| Verify  | web-builder  | Run build               | Build passes                 |
```

---

## Related Pages

- [Agent Reference](agents.md) — full agent list and file format
- [Meta-Tooling](meta-tooling.md) — the meta domain that modifies the system itself
- [Command Reference](commands.md) — slash commands that invoke this system
- [Installation](installation.md) — getting everything set up
