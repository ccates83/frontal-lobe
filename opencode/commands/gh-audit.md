---
description: "Audit GitHub repository settings, workflows, and security posture"
agent: plan
---
# GitHub Repository Audit

Comprehensive audit of a GitHub repository's configuration, workflows, and security.

## Arguments

- `$ARGUMENTS` — (Optional) Focus area for the audit. If empty, runs a full audit.

## Instructions

You are an orchestrator. Analyze the repository and delegate diagnostic tasks.

## Phase 1: Repository Discovery

1. Read AGENTS.md if present
2. Gather repository info:
   ```
   gh repo view --json name,description,defaultBranchRef,visibility,isArchived,hasIssuesEnabled,hasWikiEnabled,mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed,deleteBranchOnMerge,autoMergeAllowed
   ```
3. List workflows: `ls -la .github/workflows/ 2>/dev/null`
4. List composite actions: `ls -la .github/actions/ 2>/dev/null`
5. Check for Dependabot config: `cat .github/dependabot.yml 2>/dev/null`
6. Check for CODEOWNERS: `cat .github/CODEOWNERS 2>/dev/null`
7. Check branch protection: `gh api repos/{owner}/{repo}/branches/main/protection 2>/dev/null`

## Phase 2: Targeted Audits

Run these checks (or only the focus area if specified):

### Workflow Security Audit
Delegate to `actions-debugger` — for each workflow file, check:
- [ ] All third-party actions are SHA-pinned (not tag-pinned)
- [ ] `permissions:` set at job level with minimum access
- [ ] No untrusted input in `run:` scripts (`${{ github.event.* }}`)
- [ ] No `pull_request_target` with code checkout
- [ ] No `secrets: inherit` in reusable workflow calls
- [ ] No hardcoded secrets or credentials
- [ ] `concurrency:` set for push/PR workflows
- [ ] `timeout-minutes:` set on all jobs
- [ ] OIDC used for cloud deployments (no long-lived credentials)

### Workflow Performance Audit
Delegate to `actions-debugger` — check:
- [ ] Caching configured for dependencies
- [ ] Path filters on triggers (avoid running on irrelevant changes)
- [ ] Jobs parallelized where possible
- [ ] No redundant setup steps across jobs (consider composite actions)
- [ ] Appropriate runner selection (not using macOS for non-Apple builds)
- [ ] Matrix strategies used where applicable

### Repository Settings Audit
Delegate to `gh-cli-operator` — check:
- [ ] Branch protection enabled on default branch
- [ ] Required status checks configured
- [ ] PR reviews required before merge
- [ ] Force push disabled on protected branches
- [ ] Delete branch on merge enabled
- [ ] Signed commits required (if applicable)
- [ ] Vulnerability alerts enabled
- [ ] Dependabot security updates enabled

### Secrets and Variables Audit
Delegate to `gh-cli-operator` — check:
- [ ] List configured secrets (names only): `gh secret list`
- [ ] List configured variables: `gh variable list`
- [ ] Check for environment-specific secrets
- [ ] Verify no secrets are referenced in workflows but not configured

### Runner Audit
Delegate to `gh-cli-operator` — check:
- [ ] List self-hosted runners: `gh api repos/{owner}/{repo}/actions/runners`
- [ ] Check runner labels match workflow `runs-on:` requirements
- [ ] Verify runner OS and architecture
- [ ] Check runner online/offline status

## Phase 3: Report

Present findings as a security and health card:

```
## Repository Audit: <owner>/<repo>

### Security Score: X/10

### Summary
[2-3 sentence overview of the repository's health]

### Critical Issues
- [Issues that need immediate attention — security vulnerabilities, exposed secrets]

### Warnings
- [Important issues that should be addressed soon]

### Recommendations
- [Best practice improvements, ordered by impact]

### Strengths
- [What the repository does well]

### Metrics
- Workflows: N
- Actions used: N (SHA-pinned: N/N)
- Secrets configured: N
- Environments: N
- Branch protection: enabled/disabled
- Dependabot: configured/not configured
- CODEOWNERS: present/absent
```
