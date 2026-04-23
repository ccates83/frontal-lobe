# Debug Failed GitHub Actions Run

Analyze a failed GitHub Actions workflow run and identify the root cause.

## Arguments

- `$ARGUMENTS` — Run ID, PR number, or workflow name. If empty, analyzes the most recent failed run.

## Instructions

You are an orchestrator. Analyze the failure and delegate specific diagnostic tasks.

## Phase 1: Identify the Failed Run

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project-specific CI/CD context
2. If a run ID was provided, use it directly
3. If a PR number was provided: `gh pr checks <number>` to find failed checks
4. If a workflow name was provided: `gh run list --workflow <name> --status failure --limit 1`
5. If nothing provided: `gh run list --status failure --limit 5` and pick the most recent

## Phase 2: Gather Failure Data

Run these in parallel:
1. `gh run view <run-id>` — get run overview (event, branch, jobs, status)
2. `gh run view <run-id> --log-failed` — get failed step logs
3. Read the workflow YAML file that was executed (`.github/workflows/<name>.yml`)

## Phase 3: Analyze

Classify the failure:
- **Setup failure**: action version issue, runner availability, permissions
- **Dependency failure**: lockfile mismatch, registry down, cache corruption
- **Build failure**: code error, missing env var, wrong runtime version
- **Test failure**: test regression, flaky test, timeout
- **Deploy failure**: credential issue, target unreachable
- **Permission failure**: insufficient GITHUB_TOKEN permissions
- **Runner failure**: label mismatch, runner offline
- **Timeout**: hung process, missing timeout-minutes

For each failure:
1. Find the **first error** (not cascading failures)
2. Check the **exit code**
3. Identify the **root cause** vs symptoms
4. Compare with last successful run if helpful:
   `gh run list --workflow <name> --status success --limit 1`

## Phase 4: Report

Present findings:

```
## Failure Analysis

### Run
- **Workflow**: <name>
- **Run ID**: <id>
- **Branch**: <branch>
- **Event**: <push/pr/etc>
- **Failed at**: <job name> / <step name>

### Root Cause
[Clear explanation of what went wrong and why]

### Evidence
[Specific log lines or configuration issues]

### Fix
[Exact steps to fix the issue]

### Prevention
[How to prevent this class of failure]
```

## Phase 5: Optional Actions

If the user wants to act on the fix:
- If it is a workflow YAML change: delegate to `actions-builder`
- If it is a code change: flag it for the user
- If it needs a re-run: `gh run rerun <run-id> --failed`
- If it needs debug logs: `gh run rerun <run-id> --debug`
