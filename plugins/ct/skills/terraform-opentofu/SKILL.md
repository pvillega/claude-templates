---
name: terraform-opentofu
description: >
  Deep Terraform / OpenTofu operational intuition — state-file mechanics and locking,
  refactoring blocks (import / moved / removed) without recreate, lifecycle gotchas,
  count-vs-for_each migration, backend migration, and the post-1.5.5 fork divergence
  between Terraform (BSL) and OpenTofu (MPL2, Linux Foundation).
  Load ONLY when the task is about state surgery, refactoring blocks, lifecycle
  interactions, backend migration, count↔for_each migration, provider lockfile
  management, or choosing between TF and OpenTofu features. Do NOT load for ordinary
  resource authoring, basic HCL syntax, "what is Terraform", or first-time provider
  setup — those don't need this skill.
  Triggers on: "terraform state mv", "terraform import", "import block",
  "moved block", "removed block", "count to for_each", "lifecycle prevent_destroy",
  "create_before_destroy", "ignore_changes", "replace_triggered_by", "state lock",
  "force-unlock", "backend migration", "init -migrate-state", "terraform.lock.hcl",
  "terraform_remote_state", "state encryption", "OpenTofu vs Terraform",
  "BSL license", "tofu fork", "drift detection", "terragrunt run-all".
---

# Terraform / OpenTofu Operational Guide

Concise operational pointers for state surgery, refactoring without recreate, lifecycle pitfalls, and the post-fork TF↔OTF feature divergence.

Assumes you already know HCL syntax, what providers and modules are, and how `plan` / `apply` work. This skill covers the **operational layer** — the parts models tend to gloss over: state mechanics, locking, declarative refactor blocks, count/for_each migration mechanics, and the fork landscape since August 2023.

## When to use

Load when the question is about:
- State surgery (`terraform state mv|rm|pull|push`, manual JSON edits)
- Refactor blocks: `import {}` (TF 1.5+), `moved {}` (TF 1.1+), `removed {}` (TF 1.7+ / OTF 1.7+)
- Lifecycle interactions: `prevent_destroy`, `ignore_changes`, `create_before_destroy`, `replace_triggered_by`, pre/postconditions
- `count` ↔ `for_each` migrations and index-shift recreate cascades
- Backend migration (`init -migrate-state` / `-reconfigure`), state locking (DynamoDB → S3 native)
- Provider lockfile (`.terraform.lock.hcl`) and version pinning
- OpenTofu vs Terraform decisions: state encryption, removed block, dynamic provider iteration, `-exclude`, ephemeral resources
- Drift detection, terragrunt orchestration patterns
- `terraform_remote_state` security implications

**Do NOT load** for: writing your first resource block, choosing a provider, basic variable/output authoring, or "how do I install Terraform" — those don't need this skill.

## Terraform vs OpenTofu (post-fork landscape)

- **License split**: Terraform 1.5.5 (Aug 2023) was the last MPL-2.0 release. Terraform 1.6+ ships under BUSL-1.1 (Business Source License) — source-available, restricts commercial competition. OpenTofu forked from 1.5.7 (last MPL release line), accepted into Linux Foundation 2023-09-20.
- **CLI parity**: `tofu` mirrors `terraform`. `.tf` files are unmodified. Existing state files load in either.
- **OpenTofu-only features** (TF does not have these as of TF 1.x):
  - **State + plan encryption** (OTF 1.7, Apr 2024): client-side AES-GCM with key providers `pbkdf2`, `aws_kms`, `gcp_kms`, `azure_keyvault`, `openbao`. Configured via `terraform { encryption {} }` block or `TF_ENCRYPTION` env. Includes `fallback {}` for migration from unencrypted state.
  - **Early variable evaluation** (OTF 1.8): variables/locals usable in `backend`, `module source`, and `encryption` blocks during `init` (must be statically determinable — no resource/data refs).
  - **Provider `for_each`** (OTF 1.9): dynamic provider iteration; each iterated provider must have an `alias`. Depends on early evaluation.
  - **`-exclude` flag** (OTF 1.9): inverse of `-target`; applies everything except listed addresses.
  - **`enabled` lifecycle meta-arg** (OTF 1.11): alternative to `count = var.flag ? 1 : 0` for zero-or-one resources.
- **Cross-implemented features**: `removed {}` block ships in both TF 1.7 and OTF 1.7. `import {}` block (TF 1.5) works identically in OTF.
- **Provider registry**: registry.opentofu.org mirrors registry.terraform.io for HashiCorp + community providers; `required_providers` HCL is identical. Some HashiCorp-published providers may carry BUSL constraints.

## State file mechanics

- **Format**: `terraform.tfstate` is JSON. **Contains plaintext secrets** for resource attributes (DB passwords, generated keys, `random_password.result`). `sensitive = true` only hides from CLI output — does NOT encrypt in state.
- **Local backend**: file in working dir. No locking. Unsafe for any team/CI workflow.
- **Remote backends with native locking**: S3 (with DynamoDB or 1.10+ native lockfile), GCS, Azure Blob, HCP Terraform, Consul, etcd, `pg`, `http` (GitLab), `kubernetes`.
- **S3 + DynamoDB locking** (legacy, still ubiquitous): table must have a String partition key literally named `LockID`. The name is hardcoded; not configurable.
- **S3 native locking** (TF 1.10+, late 2024): `use_lockfile = true` on the S3 backend uses S3 conditional writes to create a `.tflock` object alongside state. DynamoDB args (`dynamodb_table`, etc.) deprecated 1.11; both can be configured simultaneously during transition. Requires `s3:DeleteObject` permission to clear the lock after run.
- **Force-unlock**: `terraform force-unlock LOCK_ID` — only after physically verifying no apply is running. Force-unlock during a live apply will corrupt state. The lock ID appears in the error message of the blocked command.
- **State at rest encryption**: S3 backend `encrypt = true` + KMS for at-rest. For client-side end-to-end use OpenTofu 1.7+ `encryption {}` block.

## State surgery (last-resort operations)

Prefer declarative refactor blocks (`moved`, `removed`, `import`) over CLI state subcommands. The CLI commands remain for ad-hoc fixes:

- `terraform state list` — enumerate addresses.
- `terraform state show ADDRESS` — inspect attributes for one resource.
- `terraform state mv SRC DST` — rename in state (now superseded by `moved {}` for code-reviewed changes).
- `terraform state rm ADDRESS` — drop from state without destroying real infra (now superseded by `removed { lifecycle { destroy = false } }`).
- `terraform state pull > state.json` then `terraform state push state.json` — manual JSON surgery. **Always copy `state.json` before editing**; a corrupt push can be unrecoverable. Increment the `serial` field on push.
- `terraform refresh` is deprecated as a standalone command; use `terraform plan -refresh-only` (TF 0.15.4+) which produces a reviewable plan before mutating state. Auto-applying a refresh with bad credentials can mark all resources as deleted — never run unattended in CI.

## Refactor blocks (declarative, code-reviewable)

- **`moved {}`** (TF 1.1+, OTF 1.6+): rename without recreate.
  ```hcl
  moved { from = aws_instance.web; to = aws_instance.frontend }
  ```
  Use cases: rename, wrap into nested module, split a module out, count→for_each migration (one block per index→key mapping). Multiple `moved` chains follow transitively. Safe to leave indefinitely; remove after all environments have applied at least once.
- **`import {}`** (TF 1.5, Jun 2023): declarative replacement for `terraform import` CLI.
  ```hcl
  import { to = aws_instance.example; id = "i-1234567890abcdef0" }
  ```
  Run `terraform plan -generate-config-out=generated.tf` to scaffold a `resource` block. **The generated file always needs hand cleanup** — defaults are spelled out, dependencies aren't inferred, and provider-specific quirks (e.g., AWS tag merging) come through verbatim. `for_each` on `import` is TF 1.7+ for bulk imports.
  Import is a plan-time operation, so it shows up in `terraform plan` output; remove the block after first successful apply, or leave it (it's idempotent — won't re-import).
- **`removed {}`** (TF 1.7, OTF 1.7): remove from state without destroying infra.
  ```hcl
  removed {
    from = aws_s3_bucket.legacy
    lifecycle { destroy = false }
  }
  ```
  Without `destroy = false` the resource is destroyed (equivalent to deleting the resource block normally). With it, real infra survives — used for handoff to another tool, splitting state files, or "stop managing this." Reviewable in PR; leaves audit trail in git history.

## Lifecycle meta-arguments (gotchas)

- `prevent_destroy = true`: **only blocks `destroy` and replace-via-destroy**. In-place updates that don't recreate still apply. Removing the entire resource block from config bypasses it (the lifecycle isn't read for removed config). Comment out and apply when an intentional teardown is needed.
- `ignore_changes = [tags, ami]` / `ignore_changes = all`: drift on listed attributes is silently accepted on `update`. `create` plans still consider them. Cannot reference data sources or other meta-args. Common abuse: pinning AMI to dodge replacement — preferable to use `replace_triggered_by` against a version variable.
- `create_before_destroy = true`: replacement creates new before destroying old. **Propagates automatically to dependents** — you cannot set it `false` on a resource depended on by a `create_before_destroy = true` resource (would create cycles). Breaks on resources with **globally unique names** (LBs, RDS identifiers, S3 buckets, security groups): use `name_prefix` instead of `name`, or rename first in a separate apply. Destroy-time provisioners are skipped.
- `replace_triggered_by = [aws_db_instance.main.id]` (TF 1.2+): force replacement when a referenced attribute changes. Cleaner than `null_resource` triggers.
- `precondition` / `postcondition` (TF 1.2+): assertion blocks on resources, data sources, and outputs. Postcondition failure prevents downstream resources from running. Use for invariants (e.g., AMI in expected region) not for input validation (use variable `validation` blocks).

## count vs for_each (and migration)

- `count = N`: integer-indexed (`module.X[0]`). **Removing a middle item shifts indices** — all trailing instances are destroyed-and-recreated. Catastrophic for stateful resources (DBs, EBS volumes).
- `for_each = toset(var.list)` / `for_each = var.map`: keyed by string (`module.X["key"]`). Removing a key only destroys that one. Default choice for stable identities.
- `count = var.enabled ? 1 : 0`: canonical conditional pattern. OpenTofu 1.11+ has `lifecycle { enabled = var.flag }` as a cleaner alternative.
- **Migration count→for_each**: TF/OTF treats the addresses as different. Without intervention every instance is destroy-recreate. Two paths:
  - Pre-1.1 / scripts: `terraform state mv 'aws_instance.c[0]' 'aws_instance.c["small"]'` per index.
  - 1.1+ declarative: one `moved {}` block per index→key.
    ```hcl
    moved { from = aws_instance.c[0]; to = aws_instance.c["small"] }
    moved { from = aws_instance.c[1]; to = aws_instance.c["tiny"] }
    ```

## Provider versions and lockfile

- `required_providers` block in `terraform {}`. Constraint syntax: `~> 5.0` means `>=5.0, <6.0`; `~> 5.30` means `>=5.30, <5.31`; `>= 5.0` open-ended; `5.30.0` exact.
- `.terraform.lock.hcl`: records exact resolved version + SHA-256 checksums of the provider zip per platform. **Commit it.** Drift between contributors otherwise.
- `terraform init -upgrade`: re-resolves within constraints, updates lockfile.
- `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`: pre-populate multi-platform checksums (lock file from one OS only contains that OS's hashes — CI on Linux + dev on macOS will conflict otherwise).
- The lockfile pins providers only — modules are NOT in the lock file. Pin module sources separately (next section).

## Modules (pinning, sources)

- Registry: `source = "hashicorp/aws"` + `version = "~> 5.0"`. `version` is registry-only.
- Git: `source = "git::https://github.com/X/Y.git//path?ref=v1.2.3"`. Subpath after `//`. Use `?ref=` with a **tag**, not a branch — `?ref=main` re-fetches default branch on every `init`. Note tags are mutable in git; pin to commit SHA (`?ref=abc123def`) for true immutability.
- Module `for_each` on the call (TF 0.13+) iterates module instances.
- Modules have no implicit globals — only declared variables and outputs cross the boundary.

## Workspaces vs separate state

- `terraform workspace new|select|list|delete`. Each workspace has separate state in the same backend. `terraform.workspace` interpolates the name.
- **CLI workspaces share backend creds and a single `terraform init`** — one mistype in `workspace select` applies dev changes to prod. Stronger isolation: separate working directories with separate backend prefixes (and ideally separate AWS accounts / GCP projects per env). Common production pattern.
- HCP Terraform / Terraform Cloud "workspaces" are isolated state instances per cloud workspace — different concept; don't conflate.

## Backend migration

- Change the `backend` block, then `terraform init -migrate-state`. Prompts to copy existing state to the new backend; `-force-copy` skips the prompt for CI.
- `terraform init -reconfigure`: discards prior backend state metadata. Use when you genuinely want a fresh backend (and have already moved state out of band, or are starting over).
- For chained migrations (local → S3 → S3 with new prefix): one `init -migrate-state` per hop, applying between each.

## terraform_remote_state and cross-stack outputs

- Data source reads root-module outputs from another state file:
  ```hcl
  data "terraform_remote_state" "vpc" {
    backend = "s3"
    config = { bucket = "...", key = "vpc/terraform.tfstate", region = "..." }
  }
  ```
- **Reading outputs requires read access to the entire state snapshot** — backend permissions cannot be scoped to "just outputs." Anything sensitive in that state is reachable. For HCP Terraform / Enterprise, prefer `tfe_outputs` data source which scopes to outputs only.
- Alternative for cross-stack data: provider data sources (e.g., `aws_ssm_parameter`, `aws_secretsmanager_secret`) — narrower blast radius.

## Diagnostics

- `terraform fmt -recursive`: canonicalize formatting.
- `terraform validate`: syntax + schema check (no API calls).
- `terraform plan -out=tfplan` then `terraform apply tfplan`: idempotent — apply runs exactly the saved plan, no re-evaluation. Required for any CI workflow that gates apply on plan review.
- `terraform plan -refresh=false`: skip the API refresh phase. Faster but stale.
- `terraform plan -refresh-only`: only reconcile state with reality, no config diff.
- `terraform plan -target=ADDRESS`: escape hatch; emits a "partial plan" warning. Not for routine use — leads to undetected drift across the rest of the graph.
- OpenTofu 1.9+ `tofu plan -exclude=ADDRESS`: inverse of `-target`.
- `TF_LOG=DEBUG terraform plan 2> tf.log`: verbose log. Levels: `ERROR < WARN < INFO < DEBUG < TRACE`. `TRACE` includes raw provider HTTP. Set `TF_LOG_PATH=/tmp/tf.log` to redirect (`TF_LOG_PATH` is ignored if `TF_LOG` is unset). `TF_LOG=JSON` emits trace-level structured logs. Provider-only logging via `TF_LOG_PROVIDER` (TF 0.15+).
- `terraform graph | dot -Tpng > graph.png`: DOT-format dependency graph for resource ordering.
- Static analysis: `tflint` (rules), `checkov` / `tfsec` / `terrascan` (security), `terraform-compliance` (BDD).

## Terragrunt (orchestration wrapper)

- `terragrunt.hcl` per leaf module + a root `terragrunt.hcl` with `remote_state {}` (DRY backend config) and `generate {}` blocks for provider injection.
- `include "root" { path = find_in_parent_folders() }` walks up to inherit parent config.
- `dependency "vpc" { config_path = "../vpc" }` blocks read another stack's outputs without `terraform_remote_state`. `mock_outputs = {...}` lets `plan` succeed before the dependency has been applied (`mock_outputs_allowed_terraform_commands = ["plan"]`).
- `terragrunt run --all apply` (formerly `run-all`) walks the dependency DAG. Use `--terragrunt-non-interactive` and `--terragrunt-parallelism N` to bound concurrency.
- Adds: dependency-graph orchestration, before/after hooks, optional retries, `--queue-include-dir` filters.

## Drift detection

- Cron `terraform plan -detailed-exitcode` in CI: exit `0` no changes, `1` error, `2` drift detected.
- HCP Terraform / Terraform Enterprise: built-in scheduled drift detection per workspace.
- `driftctl` (CloudSkiff): scans cloud APIs and compares to state — catches resources created out-of-band, not just attribute drift. Maintenance has slowed; verify project state before adopting.

## Common pitfalls (high-signal)

- `.terraform.lock.hcl` not committed → every contributor resolves a different provider patch version on first init → diffs that aren't in any `.tf` file.
- `count` removal from middle of list → trailing resources recreated. Switch to `for_each` first via `moved` blocks.
- `create_before_destroy = true` on a resource with a globally unique `name` → second create fails on the duplicate name. Switch to `name_prefix` first.
- Module `?ref=main` → silent breaking change on every `init`. Pin tag (`?ref=v1.2.3`) or commit SHA.
- `prevent_destroy = true` blocking a legitimate teardown → comment out, apply, restore. Don't comment out and forget.
- `terraform_remote_state` consumers receive read access to the entire upstream state — not just outputs. Audit who can read each state bucket.
- Auto-approving `-refresh-only` in CI with broken credentials → silently marks all resources deleted. Always require human review of refresh plans.
- Forgetting to remove `import {}` blocks: harmless idempotently, but reviewers will keep asking. Remove after first apply lands in main.
- `depends_on` papering over a missing implicit dependency → fix the reference instead. `depends_on` is for non-data dependencies (IAM eventual consistency, side-effect ordering).

## Authoritative references

**Terraform language docs** (`developer.hashicorp.com/terraform`):
- [State](https://developer.hashicorp.com/terraform/language/state)
- [`import` block](https://developer.hashicorp.com/terraform/language/import) and [generating configuration](https://developer.hashicorp.com/terraform/language/import/generating-configuration)
- [`moved` block](https://developer.hashicorp.com/terraform/language/moved)
- [`removed` block](https://developer.hashicorp.com/terraform/language/block/removed)
- [`lifecycle` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
- [Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [`terraform_remote_state` data source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Refresh-only mode](https://developer.hashicorp.com/terraform/tutorials/state/refresh)
- [Refactor modules](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [Debugging with TF_LOG](https://developer.hashicorp.com/terraform/internals/debugging)

**HashiCorp blog**:
- [Terraform 1.5 brings config-driven import and checks](https://www.hashicorp.com/en/blog/terraform-1-5-brings-config-driven-import-and-checks)

**OpenTofu docs** (`opentofu.org/docs`):
- [What's new in OpenTofu](https://opentofu.org/docs/intro/whats-new/)
- [State and plan encryption](https://opentofu.org/docs/language/state/encryption/)
- [OpenTofu 1.7 release notes](https://opentofu.org/blog/opentofu-1-7-0/) (state encryption, removed block, dynamic provider-defined functions)
- [OpenTofu 1.8 release notes](https://opentofu.org/blog/opentofu-1-8-0/) (early evaluation)
- [OpenTofu 1.9 release notes](https://opentofu.org/blog/opentofu-1-9-0/) (provider `for_each`, `-exclude`)
- [OpenTofu CHANGELOG](https://github.com/opentofu/opentofu/blob/main/CHANGELOG.md)

**Terragrunt** (`terragrunt.gruntwork.io/docs`):
- [Configuration blocks and attributes](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/)
- [Run command](https://terragrunt.gruntwork.io/docs/reference/cli/commands/run)

## Guardrails

Before recommending a non-trivial state operation (`state mv|rm|push`, force-unlock, backend migration, removed block):
1. Quote the exact block/command and version it was introduced in (e.g., `removed {}` requires TF 1.7+ / OTF 1.7+).
2. Confirm whether the user is on Terraform or OpenTofu — features diverge from 1.7 onward.
3. **For state-mutating operations**: require a state backup (`terraform state pull > backup-$(date +%s).tfstate`) before any push/rm/mv.
4. **For force-unlock**: require explicit confirmation that no apply is currently running on any host.
5. Prefer declarative refactor blocks (`moved` / `removed` / `import`) over CLI state subcommands when a code-review trail is wanted.

**State surgery without a backup is a one-way door.**
