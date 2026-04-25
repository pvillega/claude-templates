---
name: argocd
description: >
  Deep ArgoCD operational intuition — sync waves and hook lifecycle, ApplicationSet
  generators, Sync vs Health distinction, drift root causes (mutating webhooks, HPA,
  defaulting webhooks), sync options (`Replace`, `ServerSideApply`, `RespectIgnoreDifferences`),
  AppProject constraints, rollback semantics, multi-cluster patterns.
  Load ONLY when the task is about sync ordering, hook design, drift diagnosis,
  ApplicationSet generator selection, rollback planning, AppProject scoping, or
  multi-cluster registration. Do NOT load for ordinary "what is GitOps", initial
  ArgoCD install walkthroughs, or basic Application YAML authoring — those don't
  need this skill.
  Triggers on: "sync wave", "sync phase", "presync hook", "postsync hook", "syncfail",
  "postdelete hook", "applicationset generator", "matrix generator", "cluster generator",
  "out of sync drift", "hpa replicas drift", "mutating webhook drift", "ignoreDifferences",
  "ServerSideApply", "RespectIgnoreDifferences", "PruneLast", "Replace=true", "argocd app rollback",
  "self-heal", "appproject sync window", "argocd-image-updater", "preservedFields",
  "app-of-apps cascade", "argocd notifications".
---

# ArgoCD Operational Guide

Concise operational pointers for deep ArgoCD troubleshooting and design.

Assumes you already know Kubernetes, GitOps, and basic Application/ApplicationSet shape. This skill covers the **operational layer** — sync-wave/hook ordering, drift root causes, sync-option semantics, ApplicationSet pitfalls, multi-cluster, rollback caveats — the parts models tend to gloss over.

## When to use

Load when the question is about:
- Sync waves, hook phases, hook deletion policies, leftover-Job pitfalls
- Drift diagnosis (HPA, mutating/defaulting webhooks, status fields, Helm randomness)
- Sync option choice — `Replace` vs `ServerSideApply`, `RespectIgnoreDifferences`, `PruneLast`
- Sync vs Health distinction; custom Lua health for CRDs
- ApplicationSet generator selection, templating, regeneration semantics
- AppProject scoping (sourceRepos, destinations, sync windows, RBAC tokens)
- Rollback semantics, auto-sync vs manual revert, app-of-apps cascade
- Multi-cluster registration and discovery
- Image-updater and built-in notifications

**Do NOT load** for: explaining what GitOps is, first-time ArgoCD install walkthroughs, vanilla `Application` CRD authoring without operational tension. Those don't need this skill.

## Sync waves and phases

- **Phases run in fixed order**: `PreSync` → `Sync` → `PostSync`. On failure of any of those: `SyncFail`. On Application deletion (with finalizer): `PostDelete`.
- **Wave annotation**: `argocd.argoproj.io/sync-wave: "N"` — integer, **negatives allowed** (run before wave 0). Default for resources/hooks without the annotation is wave 0.
- **Within a phase**, ArgoCD orders by: phase → wave (lower first) → kind (Namespaces first, then native, then CRs) → name. Same wave + same kind → applied together (no further ordering guarantee).
- **Use waves for fine-grained ordering inside a phase**, hooks for coarse-grained phase placement. Combine: a `PreSync` Job with `sync-wave: "-5"` runs before another `PreSync` Job with wave `0`.
- **CRDs before CRs**: put the CRD in an early wave (e.g., `-10`) and the CR in wave `0`, or use `PruneLast=true` so deletion order reverses cleanly.

## Hooks

- **Hook annotation**: `argocd.argoproj.io/hook: PreSync|Sync|PostSync|SyncFail|PostDelete|Skip`. `Skip` tells ArgoCD not to apply the manifest at all (useful for resources you want present in the repo but managed elsewhere).
- **Sync-phase hook** runs *concurrently* with the regular Sync apply. Pre/PostSync hooks are gates: PostSync only runs once all Sync resources are Healthy.
- **Deletion policy** (`argocd.argoproj.io/hook-delete-policy:`):
  - `BeforeHookCreation` (default since v1.3): delete prior hook resource before re-creating. Idempotent re-runs.
  - `HookSucceeded`: delete after success.
  - `HookFailed`: delete after failure.
  - **Omitting any policy** + immutable Job spec → leftover `Job/Pod` accumulation, sync hangs reapplying the immutable resource. Always set one.
- **Common pattern**: PreSync DB migration `Job` (wave `-10`, `BeforeHookCreation`) + PostSync smoke-test `Job` (wave `10`, `HookSucceeded`).
- **PostDelete** (since v2.10): runs when the Application is deleted *and* the deletion finalizer (`resources-finalizer.argocd.argoproj.io`) is set. Adds two extra finalizers (`post-delete-finalizer.argocd.argoproj.io` and `.../cleanup`); known issues with ApplicationSet-generated apps stuck in `Deletion` state — manually remove finalizers if hung.
- **Hook resource naming**: use `generateName:` so each invocation gets a unique name; using `name:` plus `BeforeHookCreation` re-creates with the same name and is fine, but `HookSucceeded` + `name:` will collide on re-sync if the prior hook still exists.

## Sync options

Set per-app via `spec.syncPolicy.syncOptions: [Opt=value, ...]` or per-resource via annotation `argocd.argoproj.io/sync-options: Opt1=true,Opt2=false`.

- **`Replace=true`**: uses `kubectl replace/create` (not three-way merge). Destructive — drops fields ArgoCD didn't write (annotations from controllers, status, etc.). Recreates resources that fail to patch. **Takes precedence over `ServerSideApply=true`.** Use only for objects that legitimately need rewriting (Jobs with immutable spec).
- **`ServerSideApply=true`**: delegates to Kubernetes server-side apply with field manager **`argocd-controller`** (override via `argocd.argoproj.io/client-side-apply-migration-manager`). Conflicts with other field managers surface as sync errors; use `Force=true` on the same resource to overwrite.
- **`RespectIgnoreDifferences=true`**: makes `spec.ignoreDifferences[]` apply at *sync* time, not just diff time. Without this, Argo will *re-write* the field you said to ignore on the next sync (e.g., `replicas` for HPA). **Only effective once the resource exists** — initial creation still uses Git values. Pair with `ServerSideApply=true` for HPA-managed deployments.
- **`PruneLast=true`**: defers prunes to the end of the Sync phase, after creates/updates are Healthy. Avoids deleting CRDs before CRs, or Services before workloads. Per-resource annotation common for the resource that must die last.
- **`PrunePropagationPolicy=foreground|background|orphan`**: Kubernetes deletion propagation. `foreground` (default for prune) blocks until garbage-collected; `orphan` leaves children intact (rarely what you want for namespaces).
- **`CreateNamespace=true`**: creates `spec.destination.namespace` if absent. Note this only sets the bare namespace; for labels/annotations on the namespace, manage it as its own manifest.
- **`ApplyOutOfSyncOnly=true`**: skips re-applying already-in-sync resources. Reduces controller load on large apps. **Sync hooks still run** regardless.
- **`FailOnSharedResource=true`**: fail sync if another Application already manages a resource (otherwise, last-writer wins silently).
- **`Validate=false`**: skip kubectl validation. Almost never needed; usually a workaround for CRD conversion bugs.
- **`SkipDryRunOnMissingResource=true`**: skip dry-run when the CRD isn't installed yet. Required when the same Application installs the CRD and a CR of that kind in adjacent waves.
- **Server-side diff** is a separate concept from `ServerSideApply`: enable per-app via `argocd.argoproj.io/compare-options: ServerSideDiff=true` or controller-wide via `controller.diff.server.side: "true"`. Delegates diff computation to API server (sees defaulting webhooks, server defaults). Won't run on resource creation (resource doesn't exist yet to compare).

## Sync vs Health (orthogonal)

- **Sync** = "live state matches Git" — boolean `Synced`/`OutOfSync`/`Unknown`.
- **Health** = "resource is operationally OK" — `Healthy`, `Progressing`, `Degraded`, `Suspended`, `Missing`, `Unknown`.
- A `Synced` app can be `Degraded` (CrashLoopBackOff) and an `OutOfSync` app can be `Healthy` (someone scaled a Deployment in-cluster, replicas differ from Git but pods run).
- **App-level health rollup**: worst child wins, priority `Healthy > Suspended > Progressing > Missing > Degraded > Unknown`. Parent CRDs do **not** automatically inherit child status — the parent must surface child state in its own status fields, or you need a custom health check.
- **Custom health for a CRD** via Lua in `argocd-cm`:
  ```yaml
  data:
    resource.customizations.health.<group>_<kind>: |
      hs = {}
      if obj.status ~= nil and obj.status.phase == "Ready" then
        hs.status = "Healthy"
      else
        hs.status = "Progressing"
      end
      hs.message = obj.status and obj.status.message or ""
      return hs
  ```
  ArgoCD ships defaults for many common CRDs (cert-manager, Argo Rollouts, Flux); only override when defaults misclassify.

## Drift root causes

Live ≠ Git on apparently boring resources. Almost always one of:

- **HPA mutates `spec.replicas`** of Deployment/StatefulSet. Fix: omit `replicas` from Git **and** set `ignoreDifferences` with `jsonPointers: ["/spec/replicas"]` **and** `RespectIgnoreDifferences=true` (otherwise sync rewrites it).
- **Mutating admission webhooks** (Istio/Linkerd sidecar injection, Vault injector, Kyverno) add containers/volumes post-apply. Fix: `ignoreDifferences` with `jqPathExpressions` for the injected paths, or `managedFieldsManagers: [linkerd-proxy-injector]`.
- **Defaulting webhooks / server-side defaults** populate fields absent in Git (e.g., `volumeName` on PVC, `clusterIP` on Service, `caBundle` on webhook configs). Fix: server-side diff (`ServerSideDiff=true`) — API server returns the defaulted state for comparison, drift disappears.
- **CRD `status` fields shipped in Git**: ArgoCD diffs include status by default for CRDs. Fix: `resource.compareoptions.ignoreResourceStatusField: crd` in `argocd-cm` (system-wide) or `ignoreDifferences` per-app.
- **Helm non-determinism**: `randAlphaNum`, `now`, secret-generation templates produce different output every render → permanent OutOfSync. Fix: stable inputs, or store generated values in a Secret outside Helm.
- **CRD apiVersion conversion**: declared as `v1beta1`, served as `v1`. Fix: write Git in the served version.
- **System-wide ignore** for a noisy field across all kinds: `resource.customizations.ignoreDifferences.all` in `argocd-cm` with `managedFieldsManagers`.

## ApplicationSet

- **Generators** (canonical names): `list`, `cluster`, `git` (directory mode and file mode), `matrix`, `merge`, `scmProvider`, `pullRequest`, `clusterDecisionResource`, `plugin`.
- **`matrix`** combines two generators into the cartesian product. Limits: **only two child generators**, **only one level of matrix/merge nesting**. The consumer generator must come *after* the producer in the list. Same-named parameters from the inner override the outer.
- **`merge`** unions parameter sets by a `mergeKeys` field; later generators override earlier on key conflict. Use for "extend baseline list with overrides".
- **`cluster`** generator selects ArgoCD-registered clusters via `selector.matchLabels` against the cluster Secret labels (label your cluster Secrets `env=prod`, then select). Out of the box: `name`, `nameNormalized`, `server`, `metadata.labels.*`, `metadata.annotations.*` parameters.
- **`pullRequest`** (and `scmProvider`) hits SCM APIs — beware GitHub's 5,000/hour authenticated rate limit. Use `requeueAfterSeconds` (default 30 min) to throttle.
- **`goTemplate: true`** plus **`goTemplateOptions: ["missingkey=error"]`** is recommended — default `fasttemplate` silently leaves `{{ key }}` literal on missing values; `missingkey=error` fails the generation. Go template uses dot notation `{{ .name }}`. Sprig functions available except `env`/`expandenv`/`getHostByName`. Plus ArgoCD-specific `normalize` and `slugify`.
- **`applyNestedSelectors: true`** applies selectors inside nested generators. **In ArgoCD 3.0+ the field is ignored — behavior is always "as if true"**.
- **`preservedFields`** controls which Application annotations/labels survive ApplicationSet regeneration. Default preserved set covers ArgoCD's own `notifications.argoproj.io/*` and refresh annotations. Anything else added out-of-band (e.g., team-added skip-reconcile) is wiped on the next reconcile unless listed:
  ```yaml
  spec:
    preservedFields:
      annotations: ["my.org/skip-reconcile"]
      labels: ["my.org/team"]
  ```
- **`applicationsSync` policy**: `create-only` (no updates, no deletes), `create-update` (updates yes, deletes no), `sync` (default: full). Use `create-update` to prevent runaway deletes during testing.
- **`syncPolicy.preserveResourcesOnDeletion: true`**: deleting the ApplicationSet does *not* delete the child Application's managed resources. Important for "destroy ApplicationSet but keep prod" disasters.

## AppProject

- **Restrictions** (CR `AppProject.spec`):
  - `sourceRepos: [...]` — allowed repo URLs (glob).
  - `destinations: [{server, namespace}]` — allowed cluster+namespace pairs.
  - `clusterResourceWhitelist` / `clusterResourceBlacklist` — cluster-scoped kinds (e.g., allow only `Namespace`).
  - `namespaceResourceBlacklist` / `namespaceResourceWhitelist` — namespace-scoped kinds.
  - `permitOnlyProjectScopedClusters: true` — bars cluster bypass via other projects.
- **Roles + JWT tokens**: `roles[]` define policies (`p, proj:foo:role, applications, sync, foo/*, allow`) and can mint per-project JWT tokens for CI/CD without touching SSO.
- **Sync windows**: `windows[].kind: allow|deny` with `schedule` (cron) + `duration` + optional `timeZone`. **Deny overrides allow when both active.** Selectors (`applications`, `namespaces`, `clusters`) are OR'd. `manualSync: true` lets users override deny via CLI/UI — defaults to `false`.
- **Orphaned resources**: `orphanedResources.warn: true` flags resources in destination namespaces not owned by any Application; useful for audit.

## Rollback and auto-sync

- **`argocd app rollback APPNAME ID`** where `ID` is the **history ID** from `argocd app history APPNAME` (a small integer, **not a git SHA**). ArgoCD records the manifest snapshot at each sync and rolls back to that snapshot.
- **Hard precondition**: rollback is **rejected if `automated` sync is enabled**. Workflow: `argocd app set APPNAME --sync-policy none` → `argocd app rollback APPNAME 42` → fix Git → `argocd app set APPNAME --sync-policy automated --self-heal`.
- **Rollback is temporary if auto-sync is on** — even after disabling, the next manual sync (or re-enabled auto) pulls HEAD again. Permanent fix is `git revert` of the bad commit.
- **`automated.prune: true`**: deletes resources no longer in Git. Without it, removed-from-Git resources persist as orphans.
- **`automated.selfHeal: true`**: reverts in-cluster mutations within ~5s (`reconciliationTimeoutSeconds`). Off by default; without it, drift is detected but not auto-fixed.
- **`automated.allowEmpty: true`**: permits sync to a state with zero resources. Off by default — guards against an empty-repo accident wiping prod.

## Multi-cluster

- **Register a cluster**: `argocd cluster add CONTEXT [--name X] [--in-cluster]`. Creates a ServiceAccount + ClusterRole + ClusterRoleBinding in the target cluster (default name `argocd-manager`), extracts the bearer token, stores a Secret in the ArgoCD namespace labeled `argocd.argoproj.io/secret-type: cluster`. The Secret carries `name`, `server`, and `config` (JSON: bearer token, TLS, IAM/AWS/GCP auth).
- **Cluster generator** discovers these Secrets and matches via `selector.matchLabels` — label the cluster Secret (`metadata.labels.env=prod`) and the generator templates per cluster.
- **Per-cluster auth modes** in the Secret `config`: `bearerToken`, `awsAuthConfig` (IRSA), `execProviderConfig` (GCP, Azure AD), `tlsClientConfig`. Use IRSA/Workload Identity over long-lived tokens.
- **Project-scoped clusters**: set `project:` on the cluster Secret to bind it to one AppProject only.
- **Topology**: one ArgoCD controlling many clusters scales to ~50–100 clusters with appropriate sharding (`controller.sharding.algorithm`); beyond that, federation/ArgoCD-per-cluster.
- **RBAC split**: `argocd-server` only needs SSO/UI permissions; `argocd-application-controller` needs the broad cluster admin scope on remote clusters. Don't conflate the two ServiceAccounts.

## Auxiliary components

- **argocd-image-updater** (separate component, `argoproj-labs/argocd-image-updater`): bumps image tags. Annotate the Application:
  ```
  argocd-image-updater.argoproj.io/image-list: app=registry/myapp
  argocd-image-updater.argoproj.io/app.update-strategy: semver|latest|digest|name
  argocd-image-updater.argoproj.io/write-back-method: argocd|git
  ```
  - `argocd` write-back: imperative param override stored in Application spec → lost on `argocd app delete`, not visible in Git.
  - `git` write-back: commits to repo (Helm `values.yaml` or Kustomize image overrides). Required for true GitOps; needs SCM credentials Secret.
  - Update strategies — `semver`: respects ranges; `latest`: most recent build date; `digest`: pin to mutable tag (e.g., `latest`) and update on digest change; `name`: lexical sort.
  - Conflict on overlapping image-list patterns across multiple Applications causes ping-pong rewrites.
- **Notifications** (built-in since 2.3, was a separate `argocd-notifications` project): `argocd-notifications-cm` ConfigMap holds `triggers`, `templates`, `services`. Subscribe per-app via annotation `notifications.argoproj.io/subscribe.<trigger>.<service>: <recipient>` (e.g., `notifications.argoproj.io/subscribe.on-sync-failed.slack: my-channel`). Services: `slack`, `email`, `webhook`, `pagerduty`, `pagerdutyv2`, `teams`, `telegram`, etc.

## Common pitfalls

- **Stuck OutOfSync from defaulting webhooks** → switch to `ServerSideDiff=true` (server-side diff sees the defaulted live state).
- **`automated.prune: true` deletes a namespace and everything in it** when you remove the namespace from Git → use `PruneLast=true` on critical resources, or split namespace management out of the app.
- **Hook Job left behind every sync** → missing `hook-delete-policy`. Always `BeforeHookCreation` or `HookSucceeded`.
- **App-of-apps deletion wipes children** when finalizer `resources-finalizer.argocd.argoproj.io` is set on the parent. Use `cascade: false` on the manual delete (`argocd app delete --cascade=false`) or non-cascade Application delete.
- **HPA and `replicas` in Git** fight forever → omit `replicas`, add `ignoreDifferences` for `/spec/replicas`, `RespectIgnoreDifferences=true`. All three.
- **`Replace=true` to "fix" diff loops** → masks the real problem and rewrites runtime fields. Reach for `ServerSideApply=true` + `RespectIgnoreDifferences=true` first.
- **PostDelete hook hangs Application in `Deleting` state** (known issue v2.10+): manually remove `post-delete-finalizer.argocd.argoproj.io` and `post-delete-finalizer.argocd.argoproj.io/cleanup` from Application metadata.
- **ApplicationSet wipes user-added annotations** on next reconcile → add to `preservedFields.annotations`.
- **`argocd app rollback` rejected** → app has `automated` sync. Disable first.
- **Cluster Secret missing `argocd.argoproj.io/secret-type: cluster` label** → ArgoCD won't see the cluster, and Cluster generator won't list it either.

## Authoritative references

**Official ArgoCD docs** (`argo-cd.readthedocs.io/en/stable`):
- [Sync Phases and Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [Resource Hooks](https://argo-cd.readthedocs.io/en/release-2.9/user-guide/resource_hooks/) (canonical hook reference)
- [Sync Options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [Diffing / ignoreDifferences](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/)
- [Diff Strategies (ServerSideDiff)](https://argo-cd.readthedocs.io/en/stable/user-guide/diff-strategies/)
- [Resource Health](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/)
- [Automated Sync Policy](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
- [App Deletion / Finalizers](https://argo-cd.readthedocs.io/en/stable/user-guide/app_deletion/)
- [AppProject Spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/project-specification/)
- [Sync Windows](https://argo-cd.readthedocs.io/en/stable/user-guide/sync_windows/)
- [Declarative Cluster Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- [ApplicationSet Generators (overview)](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/)
- [Matrix Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/)
- [Go Templates in ApplicationSet](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/GoTemplate/)
- [Controlling Resource Modification (preservedFields)](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Controlling-Resource-Modification/)
- [Notifications](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/)
- [argocd app rollback](https://argo-cd.readthedocs.io/en/latest/user-guide/commands/argocd_app_rollback/)

**Image Updater** (separate component): [argocd-image-updater.readthedocs.io](https://argocd-image-updater.readthedocs.io/en/stable/)

**GitHub issue tracker** (canonical for known bugs): [argoproj/argo-cd](https://github.com/argoproj/argo-cd) — search before assuming behavior, especially around PostDelete hooks and ApplicationSet regeneration.

## Guardrails

Before recommending a non-trivial operational change (sync option flip, ignoreDifferences, AppProject restriction, multi-cluster topology):
1. Quote the specific annotation/field path and its default
2. Cite the official ArgoCD doc section
3. State the observed symptom that justifies the change — never blanket-tune

**Drift "fixed" by `Replace=true` is drift hidden, not resolved.** Diagnose the root cause (which manager owns which fields) before reaching for the destructive switch.
