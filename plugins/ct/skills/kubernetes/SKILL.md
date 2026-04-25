---
name: kubernetes
description: >
  Deep Kubernetes operational intuition — QoS/eviction, scheduler failure diagnosis,
  pod lifecycle and exit-code triage, ephemeral-container debugging, DNS/NetworkPolicy
  subtleties, PV/PVC lifecycle, rollout/PDB/HPA behavior, etcd hygiene.
  Load ONLY when the task is about cluster-level debugging, eviction/OOM/CrashLoop
  triage, scheduling failures (Pending pods), networking weirdness (DNS latency,
  policy not applying), storage stuck in Terminating, rollout/HPA/PDB tuning, or
  control-plane operations. Do NOT load for "what is a Pod/Deployment/Service",
  basic kubectl, manifest authoring, or Helm chart questions — those don't need
  this skill.
  Triggers on: "OOMKilled", "CrashLoopBackOff", "ImagePullBackOff", "Pending pod",
  "evicted", "QoS class", "ephemeral container", "kubectl debug", "ndots", "NetworkPolicy
  not blocking", "PVC stuck Terminating", "WaitForFirstConsumer", "PodDisruptionBudget",
  "rolling update stuck", "HPA not scaling down", "preStop", "terminationGracePeriod",
  "init container", "native sidecar", "etcd defrag", "Ingress v1beta1", "topology spread",
  "taint NoExecute", "PriorityClass preemption", "server-side apply".
---

# Kubernetes Operational Guide

Concise operational pointers for cluster-level debugging, scheduling/eviction triage, and lifecycle pitfalls.

Assumes you already know what Pods, Deployments, Services, and ConfigMaps are and basic `kubectl get`/`describe`/`apply`. This skill covers the **operational layer** — the parts models tend to gloss over: QoS internals, scheduler failure modes, exit-code semantics, DNS/policy subtleties, PV/PVC lifecycle, rollout/PDB/HPA behavior, etcd hygiene.

## When to use

Load when the question is about:
- Pod failure triage (OOMKilled, CrashLoopBackOff, ImagePullBackOff, Pending, Evicted)
- QoS classes and eviction order under node pressure
- CPU throttling / resource-limit anti-patterns
- `kubectl debug` ephemeral containers and node access
- Scheduling failures: taints, affinity, topology-spread, PriorityClass/preemption
- Networking: DNS `ndots`, NetworkPolicy default behavior per CNI, EndpointSlice
- Storage: PVC stuck Terminating, `volumeBindingMode`, finalizers
- Rollout pacing: `maxSurge`/`maxUnavailable`, PDB, HPA stabilization
- Lifecycle: SIGTERM, `preStop`, `terminationGracePeriodSeconds`, PID 1 signal forwarding
- ConfigMap/Secret update propagation; Secret encryption-at-rest
- API deprecations (e.g., Ingress `extensions/v1beta1` → `networking.k8s.io/v1`)
- etcd defrag / snapshots / `mvcc: database space exceeded`

**Do NOT load** for: writing manifests, Helm questions, "what is a Service", basic `kubectl` usage, Ingress controller selection, or operator authoring — those don't need this skill.

## Resources, QoS, and eviction

- **QoS classes** (`status.qosClass`):
  - `Guaranteed` — every container has `requests == limits` for **both** CPU and memory. Evicted last.
  - `Burstable` — at least one container has a request or limit set, but not all equal. Evicted second.
  - `BestEffort` — no requests or limits anywhere. First to die under node pressure.
- **Eviction order** under node pressure: `BestEffort` → `Burstable` (those exceeding requests, ordered by usage − request and Pod priority) → `Guaranteed` (only if system daemons are at risk).
- **Default hard eviction thresholds** (kubelet): `memory.available<100Mi`, `nodefs.available<10%`, `nodefs.inodesFree<5%`, `imagefs.available<15%`, `imagefs.inodesFree<5%`. Override via `--eviction-hard`.
- **CPU limits = CFS throttling**, not OOM. Limit enforced via cgroup CFS bandwidth: 100ms periods with per-pod quota. A multithreaded pod can be throttled even at low utilization because quota burns across cores. The "remove CPU limits, keep CPU requests" recommendation comes from this — set requests for scheduling fairness, omit limits for latency-sensitive services unless you've measured the throttling.
- **Memory limit = hard kill**. No throttling. Exceeding limit → OOMKilled (exit 137). cAdvisor `container_memory_working_set_bytes` is what kubelet actually compares against the limit (RSS + active page cache − inactive). Many OOMs surface because page cache counts.
- **Verify QoS**: `kubectl get pod X -o jsonpath='{.status.qosClass}'`.

## Pod failure triage

Read events first, logs second:
```
kubectl describe pod X        # bottom: Events: section, in chronological order
kubectl logs X -c <name>      # current container
kubectl logs X -c <name> --previous   # last crashed instance — essential for CrashLoop
kubectl get events --sort-by=.lastTimestamp -n <ns>
```

**Exit codes** (set by `state.terminated.exitCode`):
- `0` — clean exit
- `1` — generic application error
- `137` — `128 + 9` (SIGKILL). Almost always **OOMKilled** when paired with `reason: OOMKilled`. Check `kubectl describe pod` for the OOMKilled marker.
- `139` — `128 + 11` (SIGSEGV). Native crash, ABI mismatch, glibc/musl mismatch on Alpine, bad pointer.
- `143` — `128 + 15` (SIGTERM). Process honored shutdown signal — often expected for terminating pods.

**State / reason matrix**:
- `Pending` → scheduler can't place. `kubectl describe pod` Events show `FailedScheduling: 0/N nodes available: insufficient cpu, N node(s) had taint {…}, …`. Causes: resource requests > free, taints without tolerations, node-selector mismatch, `volumeBindingMode: WaitForFirstConsumer` waiting for a consumer, image-pull stalling on the node.
- `ImagePullBackOff` / `ErrImagePull` → kubelet failed to pull. `ErrImagePull` is the first error; `ImagePullBackOff` is the retry state with exponential delay capped at 5min. Diagnose: `kubectl describe pod` Events. `401/403` → `imagePullSecrets` missing or wrong; `manifest unknown` → tag doesn't exist; `no such host` → registry DNS / network egress.
- `CrashLoopBackOff` → container repeatedly exits. **Backoff is exponential, capped at 300s** (10s → 20s → 40s → … → 300s). Reset to base after 10min uptime. `kubelet.crashLoopBackOff.maxContainerRestartPeriod` (1.32+) lets you tune the cap. Always read `kubectl logs --previous` — the crashed instance's logs.
- `CreateContainerConfigError` → ConfigMap/Secret reference missing, or invalid `securityContext`. Check `kubectl describe pod` Events for the specific missing object.
- `Evicted` → node pressure. `kubectl get pod X -o yaml` shows `status.reason: Evicted`, `status.message` names the resource (memory/disk/inodes).

## Ephemeral-container debugging

Ephemeral containers GA'd in **v1.25** (KEP-277). Add a debug shell to a running pod without restarting:

```
kubectl debug -it pod/X --image=busybox:1.36 --target=<container-name>
```

- `--target=<name>` shares the **process namespace** of the named container (so `ps`, `/proc/<pid>/root` work). Requires CRI runtime support (containerd/CRI-O have it).
- `--image=nicolaka/netshoot` for network debugging tools.
- Ephemeral containers are **immutable once added** — you cannot remove them; pod must be deleted to clean up. They cannot define probes, ports, or resources.

**Copy-pod debugging** for crash-on-startup containers (you can't `exec` into a terminated container):
```
kubectl debug pod/X --copy-to=X-debug --container=app --image=alpine --share-processes -- sleep 3600
```

**Node debugging** (privileged pod with host filesystem at `/host`):
```
kubectl debug node/<node> -it --image=ubuntu
```

**When the API path fails** (kubelet unhealthy, network-segmented): SSH the node and use `crictl ps`, `crictl logs <id>`, `crictl exec` directly against the CRI socket (`/run/containerd/containerd.sock` or `/run/crio/crio.sock`).

## Init containers and sidecars

- **Init containers** run sequentially before regular containers; if any fails it's restarted per the Pod's `restartPolicy`. Pod stays in `Init:Error` / `Init:CrashLoopBackOff`.
- **Native sidecars** (KEP-753): set `restartPolicy: Always` on an `initContainer`. Alpha in v1.28, **beta and on-by-default in v1.29**. Behavior: the kubelet starts it during init phase but proceeds to the next init container after **startup probe / postStart** completes (not after exit), and keeps restarting it for the lifetime of the pod. Sidecars are shut down **after** main containers terminate — fixes the long-standing "log shipper dies before app finishes flushing" problem and lets `Job`-managed pods complete.
- **Pre-1.29 sidecars** are just regular containers with no ordering guarantees — the historical pain point.

## Lifecycle, signals, and graceful shutdown

- **Termination sequence**: pod marked Terminating → endpoints removed (eventually) → `preStop` hook runs → SIGTERM to PID 1 → grace-period countdown → SIGKILL on expiry.
- **`terminationGracePeriodSeconds` default = 30s** (`spec.terminationGracePeriodSeconds`). The grace period is a **shared budget** for `preStop` + app shutdown.
- **`preStop` with `sleep 30`** is the canonical "give endpoints time to propagate" pattern. The race: kubelet sends SIGTERM concurrently with the EndpointSlice update. kube-proxy on every node still has stale iptables for ~seconds. Without `preStop sleep`, in-flight requests hit a closed socket. KEP-3960 (v1.29 beta) added native `lifecycle.preStop.sleep.seconds` so you no longer need a `sleep` binary in the image.
- **PID 1 signal forwarding**: a shell-as-PID-1 (`CMD ["sh", "-c", "myapp"]`) does NOT forward SIGTERM. App never gets the signal, runs full grace period, gets SIGKILLed. Fix: `exec myapp` in entrypoint, or bake `tini` (`ENTRYPOINT ["/tini", "--"]`), or use `Pod.spec.shareProcessNamespace: true` + the runtime's init. Zombie reaping is the same problem class.
- **Graceful node shutdown**: `kubelet --graceful-shutdown-period` and `--graceful-shutdown-period-critical` (v1.21+) honor pod `terminationGracePeriodSeconds` on shutdown.

## Scheduling

- **Node affinity**: `requiredDuringSchedulingIgnoredDuringExecution` (hard) vs `preferredDuringSchedulingIgnoredDuringExecution` (soft). Note the `IgnoredDuringExecution` half — affinity is not re-evaluated after the pod is running.
- **Taints/tolerations** (`spec.tolerations`):
  - `NoSchedule` — new pods without toleration won't land here; running pods stay.
  - `PreferNoSchedule` — soft hint.
  - `NoExecute` — running pods without toleration are **evicted** unless they have `tolerationSeconds` (delays eviction). The built-in `node.kubernetes.io/not-ready` and `unreachable` taints get a default 300s tolerationSeconds — that's the 5-minute "node failure → pod evict" delay.
- **Topology spread** (`spec.topologySpreadConstraints`): `topologyKey: topology.kubernetes.io/zone`, `maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule` (hard, pod stays Pending if it would violate skew) vs `ScheduleAnyway` (soft, prefers least-skewed but schedules regardless). `minDomains` (v1.27+) prevents over-packing into too few zones.
- **PriorityClass + preemption**: `globalDefault: true` makes one class apply to pods without a class. `preemptionPolicy: PreemptLowerPriority` (default) lets higher-priority pods evict lower; `Never` skips ahead of the queue but doesn't preempt — useful for batch.
- **Why is my pod Pending?** Always `kubectl describe pod` and read the `Events` block. Scheduler emits "0/N nodes available: …" with a per-predicate breakdown.

## Networking subtleties

- **DNS `ndots:5`** (default in `/etc/resolv.conf` for in-cluster pods): names with fewer than 5 dots get tried against every search domain (`<ns>.svc.cluster.local`, `svc.cluster.local`, `cluster.local`, plus node search) **before** the unqualified lookup. `api.example.com` (2 dots) → 4 NXDOMAINs then success. Fix: trailing dot on FQDNs (`api.example.com.`) or override per-pod:
  ```yaml
  dnsConfig:
    options: [{name: ndots, value: "2"}]
  ```
- **Service types**:
  - `ClusterIP` (default) — virtual IP, kube-proxy iptables/IPVS DNAT.
  - `NodePort` — also opens `30000–32767` on every node.
  - `LoadBalancer` — cloud-provider integration; falls back to NodePort if no provider.
  - `ExternalName` — CNAME indirection, no proxy.
  - **Headless** (`clusterIP: None`) — no virtual IP. DNS returns one A record per Ready pod IP. Required by StatefulSets for stable per-pod DNS.
- **NetworkPolicy default**: with **no policy** selecting a pod, all ingress and egress is allowed. Once **any** policy selects the pod for a direction (ingress/egress), that direction becomes default-deny **for that pod** — only the union of allow rules applies. Empty `podSelector: {}` matches all pods in the namespace; empty `policyTypes: [Ingress]` with no `ingress:` rules = deny all ingress.
- **CNI must support NetworkPolicy** for it to do anything: Calico, Cilium, Weave, Antrea — yes. Default flannel — **silent no-op**, policies appear applied but enforce nothing. Verify CNI: `kubectl -n kube-system get ds`.
- **EndpointSlice** GA in v1.21 and **default kube-proxy backend since v1.21**. Replaces single-large-Endpoints object per Service with sliced (≤100 endpoints/slice). `kubectl get endpoints` still works (server synthesizes). For services with many backends, watch `kubectl get endpointslices` instead.

## Storage and PV/PVC lifecycle

- **PV phases**: `Available` → `Bound` (claimed by PVC) → `Released` (PVC deleted, PV not yet reclaimed) → `Failed` (reclaim error). With `reclaimPolicy: Delete` (default for dynamic), PV is destroyed on PVC delete; with `Retain`, PV sits in `Released` for manual cleanup; `Recycle` is deprecated.
- **PVC stuck `Terminating`**: almost always the `kubernetes.io/pvc-protection` finalizer. The PVC-protection controller refuses to drop the finalizer while any pod still references the PVC — even pods themselves Terminating. Diagnose:
  ```
  kubectl get pvc X -o jsonpath='{.metadata.finalizers}'
  kubectl get pods -A -o json | jq '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == "X") | .metadata.name'
  ```
  Last-resort patch (loses the safety net — use only after confirming detach):
  ```
  kubectl patch pvc X -p '{"metadata":{"finalizers":null}}'
  ```
- **`volumeBindingMode`** on StorageClass:
  - `Immediate` (default) — PV is provisioned at PVC create time. In multi-zone clusters this picks a zone before the pod is scheduled, often producing zone-mismatch and `0/N nodes available: had volume node affinity conflict`.
  - `WaitForFirstConsumer` — PV provisioning deferred until a pod consuming the PVC is scheduled. Provisioner gets the chosen node's zone. **Set this on every multi-zone cluster.**
- **Online expansion**: `allowVolumeExpansion: true` on the StorageClass plus a CSI driver that supports `EXPAND_VOLUME` and `ONLINE_EXPANSION` capability. Edit `spec.resources.requests.storage` on the PVC; CSI handles the rest. Many older drivers require pod restart (`offline` expansion).

## Rollouts, PDB, and HPA

- **Deployment `RollingUpdate`** defaults: `maxSurge: 25%`, `maxUnavailable: 25%`. Both can be percentages or absolute. With `replicas=4`, defaults give 1 surge + 1 unavailable. Set `maxUnavailable: 0` for zero-downtime at the cost of needing surge headroom.
- **Stuck rollout**: `kubectl rollout status deployment/X --timeout=2m`. New ReplicaSet not progressing → look at the new ReplicaSet's events (`kubectl describe rs <new>`) and pod failures.
- **PodDisruptionBudget** (`policy/v1`): protects against **voluntary** disruptions only (drain, eviction API). **Involuntary** disruptions (node hardware failure, kernel panic) bypass PDB but **count against the budget**. Use either `minAvailable` or `maxUnavailable`, never both. `maxUnavailable: 0` blocks all voluntary evictions — node drain will block forever. Empty selector `selector: {}` matches all pods in the namespace.
- **HPA stabilization** (`autoscaling/v2`):
  - Scale-down stabilization window: **default 300s** (`--horizontal-pod-autoscaler-downscale-stabilization`). Recent metrics retained; HPA picks the **highest** recommendation in the window. Prevents flapping.
  - Scale-up: 0s default — scale up immediately.
  - Override per-HPA: `spec.behavior.scaleDown.stabilizationWindowSeconds`, `policies`.
- **HPA "metrics not available"**: metrics-server staleness or missing. `kubectl get apiservice v1beta1.metrics.k8s.io` should show `True/Available`.

## ConfigMap, Secret, and config propagation

- **Mounted ConfigMap/Secret update**: kubelet syncs at `syncFrequency` (default 60s) plus a TTL-based cache. Effective propagation **30–90s**. Files are atomically replaced (symlink swap), so apps re-reading get a consistent snapshot.
- **`subPath` mounts do NOT update** — known long-standing limitation (kubernetes/kubernetes#50345). Use a directory mount and reference the file inside.
- **Env-var-sourced ConfigMap/Secret values are baked at pod start** — they never update without a pod restart. For hot reload, use a file mount and have the app re-read.
- **Secrets are base64-encoded, NOT encrypted**. etcd reads disclose them in cleartext-equivalent form. Encryption-at-rest requires kubelet-layer config: `EncryptionConfiguration` with a KMS provider (`k8s:enc:kms:v2:` prefix once stored). Without it, `etcdctl get` reveals every Secret.
- **Registry auth**: `Secret type: kubernetes.io/dockerconfigjson` with `.dockerconfigjson` data, referenced via `imagePullSecrets`. Most "ImagePullBackOff: 401" issues are this Secret in the wrong namespace (Secrets are namespaced; `imagePullSecrets` must be in the pod's namespace).

## RBAC and API hygiene

- **`Role` is namespaced; `ClusterRole` is cluster-scoped**. Bind via `RoleBinding` (namespaced; can reference a ClusterRole) or `ClusterRoleBinding` (cluster-wide).
- **`resourceNames`** pins a rule to specific named resources — useful for "may delete only this one ConfigMap." Note: `create` cannot use `resourceNames` (the resource doesn't exist yet).
- **ClusterRole aggregation** (`aggregationRule.clusterRoleSelectors`): match labels like `rbac.authorization.k8s.io/aggregate-to-admin: "true"` to dynamically extend `admin`, `edit`, `view`. Used by operators to add CRD permissions to the built-in roles without modifying them.
- **Impersonation** (`--as`, `--as-group`): grant via `impersonate` verb on `users`, `groups`, `serviceaccounts`. Powerful — anyone with `impersonate users *` is cluster-admin in disguise.
- **Check effective access**: `kubectl auth can-i <verb> <resource> --as=<user> -n <ns>` and `kubectl auth can-i --list`.
- **API deprecation** is real and removes APIs. Notable: Ingress `extensions/v1beta1` deprecated in v1.14, **removed in v1.22**. PSP removed in v1.25 (replaced by Pod Security Admission). Always check the deprecation guide before upgrade. `kubectl convert` (separate plugin, `kubectl-convert`) rewrites old manifests.

## kubectl operational tricks

- **JSONPath for piping**: `kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'`.
- **Schema introspection**: `kubectl explain pod.spec.containers.resources --recursive`.
- **Wait on conditions**: `kubectl wait --for=condition=Ready pod/X --timeout=60s`, `--for=jsonpath='{.status.phase}'=Running`.
- **Server-side apply**: `kubectl apply --server-side -f X.yaml`. Field ownership tracked in `metadata.managedFields`. Conflicts surface when another manager owns a field — resolve with `--force-conflicts` (transfers ownership to your `--field-manager`). Beware: `--force-conflicts` silently overrides without telling you which fields conflicted; review managedFields before forcing on shared resources.
- **Rollout control**: `kubectl rollout pause deployment/X`, `kubectl rollout undo deployment/X --to-revision=N`. Pause halts ongoing and future template updates.
- **Drain a node** correctly: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --grace-period=120`. Honors PDBs; will hang if PDB is `maxUnavailable: 0`.

## Control plane and etcd

- **etcd quota**: default `--quota-backend-bytes=2147483648` (2 GiB). Recommended max ~8 GiB. Past it: `mvcc: database space exceeded` → all writes fail, cluster effectively read-only.
- **What fills etcd**: leftover Events (default TTL 1h, but high churn workloads), large CRDs, Secrets/ConfigMaps with binary data, unused stale resources.
- **Compaction** prunes old MVCC revisions; **defrag** reclaims the space. Auto-compaction is on by default (`--auto-compaction-retention=8` hours typically). Defrag is **per member, sequentially**, blocks reads/writes on that member during run:
  ```
  ETCDCTL_API=3 etcdctl --endpoints=https://...:2379 --cacert ... --cert ... --key ... defrag
  ```
- **Snapshot before any risky op**: `etcdctl snapshot save backup.db`. Restore via `etcdutl snapshot restore` (etcd 3.5+) into a fresh data dir.
- **Useful metrics**: `etcd_mvcc_db_total_size_in_use_in_bytes` (logical), `etcd_mvcc_db_total_size_in_bytes` (physical incl. fragmentation), `etcd_disk_backend_commit_duration_seconds` (write latency). Disk latency >50ms p99 → etcd is the bottleneck, leader elections will flap.

## Authoritative references

**Official docs** (`kubernetes.io/docs`):
- [Pod QoS Classes](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- [Node-pressure Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Ephemeral Containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) and [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) (KEP-753)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) and [Topology-Aware Volume Provisioning](https://kubernetes.io/blog/2018/10/11/topology-aware-volume-provisioning-in-kubernetes/)
- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Specifying a Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) and [Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Server-Side Apply](https://kubernetes.io/docs/reference/using-api/server-side-apply/)
- [Encrypting Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) / [KMS Provider](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/)
- [Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [Operating etcd Clusters](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

**KEPs** (`github.com/kubernetes/enhancements`):
- KEP-753 (sidecar containers, beta in 1.29)
- KEP-277 (ephemeral containers, GA in 1.25)
- KEP-3960 (preStop sleep action, beta in 1.29)
- KEP-853 (configurable HPA scale velocity)

**etcd**: [etcd.io/docs/v3.5/op-guide/maintenance/](https://etcd.io/docs/v3.5/op-guide/maintenance/)

**Community deep-dives (reliable)**:
- Datadog/Sysdig blogs — eviction, throttling, OOMKilled
- iximiuz Labs / labs.iximiuz.com — sidecars, ephemeral containers, networking
- Learnk8s, CNCF blog — termination lifecycle, networking
- pracucci.com — `ndots:5` analysis

## Guardrails

Before recommending an operational change (resource limits, eviction config, policy rollout, PDB, HPA, etcd op):
1. Quote the specific field path or kubelet flag and its default
2. Cite the official doc section or KEP
3. Make the recommendation conditional on observed signals (events, metrics, exit code, phase) — never blanket-tune
4. State the Kubernetes version a feature requires (e.g., "native sidecar requires v1.29")

**Tuning without measurement is worse than defaults.** Every "increase the limit" recommendation needs the metric that justifies it.
