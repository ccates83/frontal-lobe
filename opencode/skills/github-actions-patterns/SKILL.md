---
name: github-actions-patterns
description: "GitHub Actions workflow syntax reference, common CI/CD patterns, caching strategies, matrix configurations, security best practices, OIDC integration, reusable workflows, and composite actions. Reference material for actions-builder, actions-debugger, and github-orchestrator agents."
compatibility: opencode
---
# GitHub Actions Patterns — CI/CD Reference

Quick-reference guide for GitHub Actions workflow patterns. Used by the GitHub orchestrator ecosystem to make informed CI/CD decisions.

## When to Apply

Reference these patterns when:
- Designing new CI/CD workflows
- Choosing between workflow architectures
- Implementing caching correctly
- Setting up secure deployments with OIDC
- Writing reusable workflows or composite actions
- Debugging common workflow issues

---

## 1. Workflow Triggers

### Push and PR (Most Common)
```yaml
on:
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'package.json'
      - 'package-lock.json'
      - '.github/workflows/ci.yml'
  pull_request:
    branches: [main, develop]
    # paths filter optional — omit to run on all PRs
```

### Release
```yaml
on:
  release:
    types: [published]
  # Or tag-based:
  push:
    tags: ['v*.*.*']
```

### Scheduled (Cron)
```yaml
on:
  schedule:
    - cron: '0 6 * * 1'  # Every Monday at 6 AM UTC
    # Note: timezone support coming Q1 2026
```

### Manual Dispatch (up to 25 inputs)
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [staging, production]
      version:
        description: 'Version to deploy'
        required: true
        type: string
      dry-run:
        description: 'Perform dry run'
        type: boolean
        default: true
```

### Multiple Events
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
```

---

## 2. CI Workflow Patterns

### Node.js CI
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-node@<sha>  # v4
        with:
          node-version-file: '.node-version'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-node@<sha>  # v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test

  build:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
    needs: [lint, test]
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-node@<sha>  # v4
        with:
          node-version-file: '.node-version'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@<sha>  # v4
        with:
          name: build-output
          path: dist/
```

### Python CI
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-python@<sha>  # v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'
      - run: pip install -r requirements.txt
      - run: python -m pytest --tb=short
```

### Rust CI
```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: actions/cache@<sha>  # v4
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target/
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
          restore-keys: ${{ runner.os }}-cargo-
      - run: cargo clippy --all-targets -- -D warnings
      - run: cargo test
      - run: cargo build --release
```

### Go CI
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-go@<sha>  # v5
        with:
          go-version-file: 'go.mod'
          cache: true
      - run: go vet ./...
      - run: go test -race -coverprofile=coverage.out ./...
      - run: go build ./...
```

### iOS/macOS CI
```yaml
jobs:
  build-test:
    runs-on: macos-latest
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>  # v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app
      - name: Build and test
        run: |
          xcodebuild -project MyApp.xcodeproj \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -resultBundlePath TestResults.xcresult \
            test 2>&1 | xcpretty
      - uses: actions/upload-artifact@<sha>  # v4
        if: failure()
        with:
          name: test-results
          path: TestResults.xcresult
```

### Docker Build and Push
```yaml
jobs:
  docker:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: docker/setup-buildx-action@<sha>  # v3
      - uses: docker/login-action@<sha>  # v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@<sha>  # v6
        with:
          context: .
          push: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 3. Security Patterns

### OIDC Authentication (AWS)
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      id-token: write
      contents: read
    environment: production
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: aws-actions/configure-aws-credentials@<sha>  # v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
          aws-region: us-east-1
      - run: aws s3 sync ./dist s3://my-bucket/
```

### OIDC Authentication (GCP)
```yaml
      - uses: google-github-actions/auth@<sha>  # v2
        with:
          workload_identity_provider: 'projects/123/locations/global/workloadIdentityPools/github/providers/my-repo'
          service_account: 'deploy@project.iam.gserviceaccount.com'
```

### OIDC Authentication (Azure)
```yaml
      - uses: azure/login@<sha>  # v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Safe Input Handling
```yaml
# Never do this (injection risk):
- run: echo "Processing ${{ github.event.issue.title }}"

# Do this instead:
- name: Process issue
  env:
    ISSUE_TITLE: ${{ github.event.issue.title }}
  run: echo "Processing $ISSUE_TITLE"
```

### Minimal Permissions Reference
```yaml
# Read-only CI
permissions:
  contents: read

# CI that posts PR comments
permissions:
  contents: read
  pull-requests: write

# Release publishing
permissions:
  contents: write

# Package publishing
permissions:
  contents: read
  packages: write

# Deployment with OIDC
permissions:
  id-token: write
  contents: read

# Security scanning with code scanning upload
permissions:
  contents: read
  security-events: write
```

---

## 4. Caching Strategies

### Cache Key Patterns
```yaml
# Exact match on lockfile hash
key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

# With restore fallback
restore-keys: |
  ${{ runner.os }}-npm-

# Multi-file hash
key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}

# Branch-aware cache
key: ${{ runner.os }}-npm-${{ github.ref }}-${{ hashFiles('**/package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-npm-${{ github.ref }}-
  ${{ runner.os }}-npm-refs/heads/main-
  ${{ runner.os }}-npm-
```

### Cache Paths by Language
| Language | Cache Path | Lock File |
|----------|-----------|-----------|
| Node.js (npm) | `~/.npm` | `package-lock.json` |
| Node.js (yarn) | `~/.cache/yarn` | `yarn.lock` |
| Node.js (pnpm) | `~/.local/share/pnpm/store` | `pnpm-lock.yaml` |
| Python (pip) | `~/.cache/pip` | `requirements*.txt` |
| Python (poetry) | `~/.cache/pypoetry` | `poetry.lock` |
| Rust | `~/.cargo/registry`, `~/.cargo/git`, `target/` | `Cargo.lock` |
| Go | `~/go/pkg/mod` | `go.sum` |
| Gradle | `~/.gradle/caches`, `~/.gradle/wrapper` | `*.gradle*`, `gradle-wrapper.properties` |
| Maven | `~/.m2/repository` | `pom.xml` |
| Ruby | `vendor/bundle` | `Gemfile.lock` |
| Swift (SPM) | `.build/` | `Package.resolved` |

### Docker Layer Caching
```yaml
- uses: docker/build-push-action@<sha>  # v6
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
    # Alternative: registry-based cache
    # cache-from: type=registry,ref=ghcr.io/owner/repo:cache
    # cache-to: type=registry,ref=ghcr.io/owner/repo:cache,mode=max
```

### Cache Limits
- **10 GB** per repository
- **LRU eviction** — least recently used caches removed first
- **7-day expiry** for caches not accessed
- Branch caches: PRs can read base branch caches but writes are scoped

---

## 5. Reusable Workflow Patterns

### Centralized CI (Organization-Level)
```yaml
# .github/workflows/reusable-node-ci.yml (in shared repo)
name: Node.js CI
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
      working-directory:
        type: string
        default: '.'
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  ci:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@<sha>  # v4
      - uses: actions/setup-node@<sha>  # v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
          cache-dependency-path: '${{ inputs.working-directory }}/package-lock.json'
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

### Caller Workflow
```yaml
# .github/workflows/ci.yml (in consuming repo)
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: my-org/.github/.github/workflows/reusable-node-ci.yml@main
    with:
      node-version: '22'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Nesting Limits
- Up to **10 levels** of nested reusable workflows
- Up to **50 total** reusable workflow calls per run

---

## 6. Composite Action Patterns

### Setup Action
```yaml
# .github/actions/setup/action.yml
name: 'Project Setup'
description: 'Standard project setup with caching'
inputs:
  node-version:
    description: 'Node.js version'
    default: '20'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@<sha>  # v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    - run: npm ci
      shell: bash
    - run: echo "Setup complete"
      shell: bash
```

### Deploy Action with Outputs
```yaml
# .github/actions/deploy/action.yml
name: 'Deploy'
description: 'Deploy application'
inputs:
  environment:
    required: true
outputs:
  url:
    description: 'Deployment URL'
    value: ${{ steps.deploy.outputs.url }}
runs:
  using: 'composite'
  steps:
    - id: deploy
      run: |
        URL=$(./deploy.sh --env ${{ inputs.environment }})
        echo "url=$URL" >> $GITHUB_OUTPUT
      shell: bash
```

---

## 7. Matrix Strategy Patterns

### Cross-Platform Testing
```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    node: [18, 20, 22]
    exclude:
      - os: windows-latest
        node: 18  # Drop old Node on Windows
    include:
      - os: ubuntu-latest
        node: 22
        coverage: true  # Only run coverage on one combo
```

### Dynamic Matrix
```yaml
jobs:
  determine-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: |
          echo 'matrix={"include":[{"project":"api","path":"api/"},{"project":"web","path":"web/"}]}' >> $GITHUB_OUTPUT

  build:
    needs: determine-matrix
    strategy:
      matrix: ${{ fromJSON(needs.determine-matrix.outputs.matrix) }}
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building ${{ matrix.project }} from ${{ matrix.path }}"
```

---

## 8. Expression Reference

### Commonly Used Contexts
```yaml
${{ github.event_name }}          # push, pull_request, workflow_dispatch, etc.
${{ github.ref }}                  # refs/heads/main, refs/tags/v1.0.0
${{ github.ref_name }}             # main, v1.0.0 (short form)
${{ github.sha }}                  # Full commit SHA
${{ github.actor }}                # User who triggered the run
${{ github.repository }}           # owner/repo
${{ github.event.pull_request.number }}
${{ runner.os }}                   # Linux, macOS, Windows
${{ runner.arch }}                 # X86, X64, ARM, ARM64
${{ secrets.MY_SECRET }}
${{ vars.MY_VARIABLE }}
${{ needs.job-id.outputs.key }}
${{ matrix.os }}
```

### Useful Functions
```yaml
${{ contains(github.event.head_commit.message, '[skip ci]') }}
${{ startsWith(github.ref, 'refs/tags/') }}
${{ hashFiles('**/package-lock.json') }}
${{ toJSON(github.event) }}
${{ fromJSON(needs.setup.outputs.matrix) }}
${{ format('Hello {0}', github.actor) }}
${{ join(github.event.issue.labels.*.name, ', ') }}
```

### The `case` Function (New 2026)
```yaml
# Switch-case style logic in expressions
${{ case(
  matrix.os == 'ubuntu-latest', 'linux',
  matrix.os == 'macos-latest', 'darwin',
  matrix.os == 'windows-latest', 'windows',
  'unknown'
) }}
```

---

## 9. Deployment Patterns

### Environment Protection
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.example.com
    steps:
      - run: ./deploy.sh
# Configure in repo settings:
# - Required reviewers
# - Wait timer
# - Branch restrictions
# - Deployment branch rules
```

### Blue-Green / Canary
```yaml
jobs:
  deploy-canary:
    environment: canary
    steps:
      - run: ./deploy.sh --target canary --weight 10

  smoke-test:
    needs: deploy-canary
    steps:
      - run: ./smoke-test.sh --target canary

  deploy-full:
    needs: smoke-test
    environment: production
    steps:
      - run: ./deploy.sh --target production --weight 100
```

---

## 10. Maintenance Patterns

### Dependabot for Actions
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      actions:
        patterns: ["*"]
```

### Stale Issue Cleanup
```yaml
name: Stale Issues
on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly
jobs:
  stale:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
    steps:
      - uses: actions/stale@<sha>  # v9
        with:
          stale-issue-message: 'This issue has been inactive for 30 days.'
          days-before-stale: 30
          days-before-close: 7
```
