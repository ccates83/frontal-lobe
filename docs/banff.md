# Banff

> A persistent mobile engineering team: iOS, Android, backend, UX, QA, PM, and EM — invoked like any other agent.

---

## What It Is

Banff is a named agent team built on the Claude Code Teams API. Unlike the domain agents that fire-and-forget to sub-agents, Banff spawns **persistent, named teammates** that communicate with each other, share a task queue, and can be redirected mid-flight via `SendMessage`.

The entry point is a single agent — `banff` — that acts as the team lead: it initializes the team, routes work to the right people, monitors progress, and synthesizes results.

```
claude --agent banff
```

Individual team members can also be invoked standalone:

```
claude --agent banff-ben
claude --agent banff-rob
claude --agent banff-tyler
```

---

## Team Roster

### Leadership & Product

| Agent | Name | Role | Model |
|-------|------|------|-------|
| `banff` | Team Lead | Orchestrator — plans, delegates, coordinates, tears down | opus |
| `banff-ben` | Ben | Engineering Manager | opus |
| `banff-stephen` | Stephen | Product Manager | sonnet |
| `banff-rikki` | Rikki | UX Designer | sonnet |

### iOS

| Agent | Name | Specialty |
|-------|------|-----------|
| `banff-oleksii` | Oleksii | Swift/SwiftUI performance — Instruments, render optimization, launch time |
| `banff-christian` | Christian | Architecture — MVVM, TCA, Clean Arch, SPM module design, concurrency boundaries |
| `banff-connor` | Connor | UI — SwiftUI components, animations, design system, accessibility |
| `banff-allen` | Allen | ObjC interop, Xcode build system, memory management, code signing |
| `banff-scott` | Scott | General purpose — broad Swift/SwiftUI/UIKit capability, fills gaps |

Stack: Swift, SwiftUI, Swift Concurrency, Combine, gRPC, OpenAPI, some ObjC/UIKit legacy.

### Android

| Agent | Name | Specialty |
|-------|------|-----------|
| `banff-austin` | Austin | Kotlin/Compose performance — Macrobenchmark, Perfetto, recomposition |
| `banff-emanuel` | Emanuel | Architecture — Clean Arch, MVVM/MVI, Hilt, module graph, gRPC |
| `banff-ben-w` | Ben W | UI — Jetpack Compose components, animations, Material 3, design system |
| `banff-josh` | Josh | Java interop, Gradle build system, memory/LeakCanary, ProGuard/R8 |
| `banff-jacob` | Jacob | General purpose — broad Kotlin/Compose/Coroutines capability, fills gaps |

Stack: Kotlin, Jetpack Compose, Coroutines, Flow, Room, gRPC, some Java legacy.

### Backend

| Agent | Name | Role |
|-------|------|------|
| `banff-rob` | Rob | Senior — defines API contracts, owns technical direction, directs Matt Dean |
| `banff-matt-dean` | Matt Dean | Junior — implements under Rob's direction |

Stack: Go, gRPC (protobuf), REST/HTTP, MongoDB, OAuth2.

### QA

| Agent | Name | Scope |
|-------|------|-------|
| `banff-tyler` | Tyler | Mobile — iOS and Android, unit tests + manual E2E |
| `banff-anna` | Anna | Backend — API contract testing, integration testing |

---

## How It Works

Banff uses the Claude Code Teams API: `TeamCreate`, named `Agent` spawns, `SendMessage`, and a shared task queue.

```
User: "Build the push notification preferences screen"

banff (team lead)
  │
  ├─► TeamCreate(team_name="banff")
  │
  ├─► [Planning — parallel]
  │     Agent(name="Ben")     → scope review, spec enforcement
  │     Agent(name="Stephen") → AC and PRD
  │     Agent(name="Rikki")   → design spec
  │
  ├─► [Implementation — parallel, after planning]
  │     Agent(name="Oleksii")  → performance review of notification handling
  │     Agent(name="Connor")   → SwiftUI preferences screen
  │     Agent(name="Ben W")    → Compose preferences screen
  │     Agent(name="Rob")      → API contract for notification settings
  │     Agent(name="Matt Dean")→ API implementation
  │
  ├─► [QA — after implementation]
  │     Agent(name="Tyler") → mobile test plan + E2E
  │     Agent(name="Anna")  → API contract validation
  │
  └─► Synthesize results → SendMessage shutdown → TeamDelete
```

Teammates communicate directly via `SendMessage` when blocked or when work crosses boundaries (e.g., Connor messaging Rikki about a spec ambiguity, or Oleksii messaging Rob about an API performance issue).

---

## Team Norms

These are encoded into each agent's prompt and enforced by Ben.

| Norm | Detail |
|------|--------|
| **Written spec required** | Complex work (new features, architectural changes, cross-platform changes) does not start without a written spec. Ben blocks it and requests one from Stephen. |
| **Peer review before QA** | All PRs require review from at least one same-platform engineer. iOS reviews iOS; Android reviews Android. No exceptions. |
| **QA gates releases** | Tyler and Anna have block authority on critical issues. Minor issues escalate to Ben for the final call. |
| **Bug routing** | Bugs caused by the current code changes go directly to the responsible engineer. Unrelated bugs go to Ben for triage and prioritization. |
| **Design authority** | Rikki drives design. Stephen validates against user needs. Engineers flag deviations to Rikki; she tracks all of them. |
| **API contracts** | Rob defines contracts before implementation. Mobile consumes. Mobile may request changes; Rob evaluates and decides. |
| **Backend hierarchy** | Matt Dean implements under Rob's direction. Rob reviews Matt Dean's work before it reaches Anna. |

---

## Persistent Memory

The team writes shared state to `.claude/banff/` relative to the working directory. This persists across sessions so retro learnings, design decisions, and deviations accumulate over time.

| Path | Owner | Content |
|------|-------|---------|
| `.claude/banff/learnings.md` | Ben | Persistent retro learnings — read at the start of each session |
| `.claude/banff/retros/retro-{date}.md` | Ben | Per-sprint retro documents |
| `.claude/banff/decisions.md` | Ben, Christian, Emanuel, Rob | Significant architectural and scoping decisions |
| `.claude/banff/build-notes.md` | Allen, Josh | Non-obvious build system configuration notes |
| `.claude/banff/prds/{feature}.md` | Stephen | Product Requirements Documents |
| `.claude/banff/design-system/` | Rikki | Design system component definitions |
| `.claude/banff/design-specs/{feature}.md` | Rikki | Per-feature design specs (markdown fallback for Figma) |
| `.claude/banff/design-deviations.md` | Rikki | Log of approved and rejected implementation deviations |
| `.claude/banff/qa/test-plans/{feature}.md` | Tyler, Anna | QA test plans per feature |

Ben reads `learnings.md` at the start of each session and incorporates past retro findings into current work.

---

## Routing Guide

The team lead uses this heuristic to spawn the right people for each task type. Not every task needs the whole team.

| Task type | Plan with | Implement with | QA with |
|-----------|-----------|----------------|---------|
| New feature (all platforms) | Ben + Stephen + Rikki | iOS + Android + Backend engineers | Tyler + Anna |
| iOS-only change | Ben + (Stephen if AC unclear) | Relevant iOS engineers | Tyler |
| Android-only change | Ben + (Stephen if AC unclear) | Relevant Android engineers | Tyler |
| Backend API change | Rob | Matt Dean | Anna |
| Design-only | Rikki | — | — |
| Bug fix | Ben (triage) | Engineer who owns the area | Tyler or Anna |
| Architecture change | Ben + Christian/Emanuel/Rob | Full platform team for review | Tyler + Anna |
| Performance investigation | — | Oleksii (iOS) or Austin (Android) | — |

---

## iOS Engineer Routing

| Work type | Route to |
|-----------|----------|
| Performance profiling, render/memory/launch optimization | Oleksii |
| Architectural patterns, module boundaries, concurrency design | Christian |
| SwiftUI components, animations, design system implementation | Connor |
| ObjC interop, build system, memory leaks, code signing | Allen |
| Everything else, gap work, parallel tasks | Scott |

## Android Engineer Routing

| Work type | Route to |
|-----------|----------|
| Performance profiling, recomposition, Coroutine optimization | Austin |
| Architecture, Hilt graph, module structure, Flow patterns | Emanuel |
| Compose components, animations, Material 3, design system | Ben W |
| Java interop, Gradle, memory leaks, ProGuard | Josh |
| Everything else, gap work, parallel tasks | Jacob |

---

## Differences from `frontal-lobe`

Banff and `frontal-lobe` are complementary but architecturally distinct.

| | `frontal-lobe` | `banff` |
|---|---|---|
| Delegation style | Fire-and-forget `Agent` calls | Persistent named teammates |
| Inter-agent communication | None | `SendMessage` by name |
| Mid-flight redirection | Not possible | `SendMessage` to redirect a running teammate |
| Task coordination | Lead assigns everything upfront | Shared queue; teammates self-claim |
| Plan approval | Not supported | Lead can gate on plan before implementation |
| Team memory | None | Persistent `.claude/banff/` state across sessions |
| Best for | General-purpose cross-domain tasks | Sustained mobile product development work |

---

## Agent Files

All 18 agent files live flat in `claude-code/agents/` with the `banff-` prefix:

```
claude-code/agents/
  banff.md            ← team lead (entry point)
  banff-ben.md
  banff-stephen.md
  banff-rikki.md
  banff-oleksii.md
  banff-christian.md
  banff-connor.md
  banff-allen.md
  banff-scott.md
  banff-austin.md
  banff-emanuel.md
  banff-ben-w.md
  banff-josh.md
  banff-jacob.md
  banff-rob.md
  banff-matt-dean.md
  banff-tyler.md
  banff-anna.md
```

Run `scripts/install.sh` to symlink all 18 into `~/.claude/agents/`.

---

## Related Pages

- [Architecture](architecture.md) — the `frontal-lobe` two-phase model that Banff extends
- [Agent Reference](agents.md) — full agent list and file format
- [Installation](installation.md) — deploying configs to `~/.claude/`
