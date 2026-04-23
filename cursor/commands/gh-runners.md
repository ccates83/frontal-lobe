# GitHub Actions Runner Management

Manage and troubleshoot GitHub Actions runners — both GitHub-hosted and self-hosted.

## Arguments

- `$ARGUMENTS` — Action to take. If empty, lists current runner status.

## Instructions

You are an orchestrator. Delegate runner operations to specialized agents.

## Phase 1: Assess Current State

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for runner-specific conventions
2. Check current runner usage in workflows:
   ```
   grep -r "runs-on:" .github/workflows/ 2>/dev/null
   ```
3. List self-hosted runners:
   ```
   gh api repos/{owner}/{repo}/actions/runners --jq '.runners[] | {name, status, os, labels: [.labels[].name]}'
   ```
   If no repo-level runners, try org level:
   ```
   gh api orgs/{org}/actions/runners --jq '.runners[] | {name, status, os, labels: [.labels[].name]}' 2>/dev/null
   ```
4. Check recent run history for runner issues:
   ```
   gh run list --limit 10 --json databaseId,status,conclusion,name
   ```

## Phase 2: Route by Action

### "list" or "status" (Default)
Delegate to `gh-cli-operator`:
- List all runners with status, labels, OS
- Show which workflows use which runners
- Report any offline runners
- Show recent run success/failure rates

### "debug" or troubleshooting
Delegate to `runner-manager`:
- Check runner service status and logs
- Verify network connectivity to GitHub
- Check disk space and memory
- Verify token/registration validity
- Check label configuration vs workflow requirements
- For ARC: check pod status, controller logs, scale set config

### "setup self-hosted"
Delegate to `runner-manager`:
- Determine runner OS and architecture
- Generate runner registration token
- Provide setup commands
- Configure as ephemeral runner (recommended)
- Set appropriate labels
- Install as system service

### "configure ARC"
Delegate to `runner-manager`:
- Check Kubernetes cluster access
- Install/upgrade ARC controller via Helm
- Configure runner scale set
- Set resource limits and scaling parameters
- Configure container mode (DinD vs kubernetes)
- Set up monitoring

### "optimize"
Analyze current runner usage and recommend:
- Runner type changes (GitHub-hosted vs self-hosted)
- Label optimization
- Cost reduction opportunities
- Performance improvements
- Caching strategies specific to runner type

## Phase 3: Report

Present:

```
## Runner Status

### Active Runners
| Name | Type | OS | Status | Labels |
|------|------|-----|--------|--------|
| ... | GitHub-hosted / Self-hosted | ... | online/offline | ... |

### Workflow-Runner Mapping
| Workflow | Runner Label | Type |
|----------|-------------|------|
| ... | ... | ... |

### Issues Found
- [Any problems detected]

### Recommendations
- [Optimization suggestions]
```

### For Troubleshooting Reports

```
## Runner Diagnostic: <runner-name>

### Status
- **Online**: yes/no
- **Last active**: <timestamp>
- **OS**: <os>
- **Labels**: <labels>

### Root Cause
[What is causing the issue]

### Fix Steps
1. [Step-by-step fix instructions]

### Prevention
[How to prevent recurrence]
```
