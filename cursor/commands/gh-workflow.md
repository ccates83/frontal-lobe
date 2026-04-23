# Create or Edit GitHub Actions Workflow

Plan and implement a GitHub Actions workflow.

## Arguments

- `$ARGUMENTS` — Description of the desired workflow.

## Instructions

You are an orchestrator. Do NOT write YAML yourself. Plan and delegate to specialized agents.

## Phase 1: Understand Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project-specific conventions
2. List existing workflows: `ls -la .github/workflows/ 2>/dev/null`
3. Read existing workflow files to understand current patterns
4. Identify the project language, framework, and build system:
   - Check for package.json, Cargo.toml, go.mod, requirements.txt, pom.xml, Package.swift, etc.
5. Check for existing composite actions: `ls -la .github/actions/ 2>/dev/null`
6. Note the repository's default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`

Summarize: language, build tool, existing CI/CD, and what needs to change.

## Phase 2: Design the Workflow

Based on the user's description and project context, design:
- **Triggers**: which events should start the workflow
- **Jobs**: what jobs are needed and their dependencies
- **Steps**: key steps in each job
- **Runner**: which runner to use (ubuntu-latest preferred unless platform-specific)
- **Caching**: what to cache and cache key strategy
- **Matrix**: if multi-version/platform testing is needed
- **Permissions**: minimum required permissions per job
- **Concurrency**: group and cancel-in-progress settings
- **Secrets/Variables**: what secrets or variables are needed

Present the design for confirmation if it is complex (3+ jobs or involves deployment).

## Phase 3: Implement

Delegate to the `actions-builder` subagent with:
- The workflow design from Phase 2
- File path for the workflow (`.github/workflows/<name>.yml`)
- Existing workflow files to read for pattern consistency
- Security requirements (SHA-pinned actions, least-privilege permissions)
- Any project-specific constraints

## Phase 4: Review

Delegate to the `actions-debugger` subagent with:
- The created/modified workflow file
- Instructions to:
  1. Validate YAML syntax
  2. Check security posture (permissions, action pinning, input sanitization)
  3. Check for common pitfalls
  4. Verify caching strategy
  5. Confirm trigger configuration

## Phase 5: Fix Cycle

If the reviewer found issues:
1. Delegate to the `actions-builder` subagent with specific fixes
2. Re-review if critical issues were found
3. Maximum 2 fix rounds

## Phase 6: Report

Present:
- **Workflow**: file path and name
- **Triggers**: what starts it
- **Jobs**: summary of each job
- **Security**: permissions, action pinning status
- **Caching**: what is cached
- **Estimated duration**: rough estimate based on steps
- **Required setup**: any secrets, variables, or repo settings needed
- **Next steps**: how to test the workflow (push to branch, manual dispatch, etc.)
