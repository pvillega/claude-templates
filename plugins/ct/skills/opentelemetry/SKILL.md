---
name: opentelemetry
description: >
  Deep OpenTelemetry operational intuition — propagator selection in mixed
  environments, head- vs tail-based sampling decision points, semantic-convention
  stability, collector pipeline ordering and deployment topology, OTLP transport
  pitfalls, instrumentation-library compatibility, span/metric cardinality cost
  control, and resource auto-detection.
  Load ONLY when the task is about deep OTel SDK/collector tuning, propagator
  mixing, sampling design, semantic-convention migration, collector pipeline
  ordering, OTLP protocol/port mismatches, or instrumentation-library upgrade
  pain. Do NOT load for "what is a span", "explain observability", first-time
  Grafana/Tempo/Jaeger setup, or generic dashboard authoring — those don't need
  this skill. Pairs with the `grafana` skill on the consumer side.
  Triggers on: "OTEL_PROPAGATORS", "tracecontext baggage", "b3multi propagator",
  "tail sampling", "head sampling", "ParentBased", "TraceIdRatioBased",
  "load-balancing exporter", "tail_sampling processor", "OTLP 4317", "OTLP 4318",
  "memory_limiter processor", "batch processor order", "k8sattributes processor",
  "service.name unknown_service", "OTEL_SEMCONV_STABILITY_OPT_IN",
  "http.method http.request.method migration", "OTEL_RESOURCE_ATTRIBUTES",
  "exemplars otel", "exponential histogram", "Views API cardinality",
  "javaagent instrumentation", "opentelemetry-bootstrap",
  "auto-instrumentation duplicate spans", "OTEL collector pipeline",
  "agent vs gateway collector", "baggage PII", "logs bridge MDC trace_id",
  "go ebpf instrumentation".
---

# OpenTelemetry Operational Guide

Concise operational pointers for deep OpenTelemetry SDK and Collector troubleshooting and tuning.

Assumes you already know what traces/metrics/logs are, what a span is, and that propagation carries context across services. This skill covers the **operational layer** — the parts models tend to gloss over: propagator selection in mixed fleets, sampling design, semantic-convention stability, collector pipeline ordering, OTLP transport quirks, instrumentation-library upgrade pain, and cardinality cost control.

## When to use

Load when the question is about:
- Propagator selection across mixed Zipkin/Jaeger/W3C fleets (`OTEL_PROPAGATORS`)
- Head-based vs tail-based sampling design and the load-balancing-exporter pattern
- Semantic-convention stability levels and the HTTP migration (`OTEL_SEMCONV_STABILITY_OPT_IN`)
- Collector pipeline ordering (`memory_limiter` first, `batch` last)
- Collector deployment topology (agent / sidecar / gateway / coordinator+sampler)
- OTLP transport mismatches (4317 gRPC vs 4318 HTTP, protocol/port pairing)
- Resource auto-detection and `service.name = unknown_service` diagnosis
- Instrumentation-library version compatibility, duplicate-span pollution
- Metric cardinality control via Views API and exemplar-based high-cardinality offload
- Span lifecycle bugs (forgotten `End()`, mutations after end, orphan parents)
- Logs bridge into log4j/logback/slog/python-logging with `trace_id`/`span_id` injection
- Histogram choice (explicit-bucket vs base-2 exponential)

**Do NOT load** for: explaining what tracing is, picking a backend, first-time install, basic span-creation tutorials, or "show me a Grafana dashboard."

## Three signals: SDKs and resource layer

- **Three independent data models, three SDKs**: `TracerProvider`, `MeterProvider`, `LoggerProvider`. They share `Resource` and propagation context but otherwise evolve on independent stability tracks. Trace SDK is stable; Metric SDK stable since 1.x; Log SDK stable for the bridge surface, individual log appenders still vary.
- **Resource = process-level identity**, attached to every signal. `service.name` is **REQUIRED** by spec; missing it → SDKs fall back to literal `unknown_service` (or `unknown_service:python`, etc.). Spans bucket under that string in every backend.
- **Set `service.name`** by precedence: `OTEL_SERVICE_NAME` env (highest), `OTEL_RESOURCE_ATTRIBUTES=service.name=foo`, programmatic `Resource.builder().put("service.name", ...)`, then SDK default.
- **Other recommended resource attrs**: `service.version`, `service.namespace`, `service.instance.id`, `deployment.environment.name` (renamed from `deployment.environment` in newer semconv).
- **Auto-detection**: SDKs ship resource detectors for `host.id`, `host.name`, `os.type`, `process.pid`, `process.runtime.*`, `container.id` (parsed from `/proc/self/cgroup`). Kubernetes attrs (`k8s.pod.name`, `k8s.namespace.name`, `k8s.node.name`) come from either: (a) Downward API → `OTEL_RESOURCE_ATTRIBUTES`, or (b) the `k8sattributes` collector processor enriching at the gateway. Prefer the collector path — survives missing pod-spec env vars.

## Propagators

- **Default since spec 1.0**: `tracecontext,baggage` (W3C). `traceparent: 00-{trace_id_32hex}-{span_id_16hex}-{flags_2hex}` plus `tracestate` for vendor-specific add-ons. **Only the W3C TraceContext Level 2 random-flag is required for consistent probability sampling.**
- **`OTEL_PROPAGATORS`** is comma-separated and **order matters for injection** (the first propagator that matches on extract wins; all are written on inject). Known values: `tracecontext`, `baggage`, `b3` (single header), `b3multi` (`X-B3-TraceId`/`X-B3-SpanId`/`X-B3-Sampled`), `jaeger` (`uber-trace-id`, deprecated), `xray` (third-party), `ottrace` (deprecated), `none`.
- **Mixed fleet rule**: if you're migrating in from a Zipkin-instrumented service, set `OTEL_PROPAGATORS=tracecontext,baggage,b3multi`. New services emit W3C; old services keep working. Drop `b3multi` only after the last B3 emitter is gone.
- **Baggage** (`baggage` header): cross-cutting key-value, propagated alongside trace context. **W3C cap: 8192 bytes total, 64 list-members; OpenTelemetry Python enforces 4096 per value, 180 entries**. Excess silently dropped on inject — no error.
- **DO NOT put PII / credentials / API keys in baggage**. Auto-instrumentation forwards baggage on every outbound HTTP — including to third parties. Strip in egress middleware if you must carry sensitive context internally.
- **Baggage ≠ span attributes**: baggage doesn't auto-attach to spans. To turn baggage into attributes, use the `baggage` SDK span processor (Java/Python) or a `transform` collector processor.
- **Sampling decision propagates via `traceparent` flags byte** (`01` = sampled). If a parent service samples-out (`flags=00`), all downstream services inherit "not sampled" under `ParentBased` — child `AlwaysOn` doesn't override, by design.

## Sampling: head- vs tail-based

**Head-based** — decision at span start, in the SDK:
- `AlwaysOn` / `AlwaysOff` — trivial.
- `TraceIdRatioBased(0.1)` — deterministic hash of trace_id, 10% of traces. Same trace_id = same decision across services (consistent).
- `ParentBased(root=TraceIdRatioBased(0.1))` — **default in most SDKs**. If parent context exists, follow parent's sampled flag. Otherwise apply root sampler. Prevents partial traces.
- **`OTEL_TRACES_SAMPLER` defaults to `parentbased_always_on`**; for ratio sampling set `OTEL_TRACES_SAMPLER=parentbased_traceidratio` and `OTEL_TRACES_SAMPLER_ARG=0.1`.
- **W3C TraceContext Level 2 + OTEP 235 consistent probability sampling**: SDKs encode the sampling threshold in `tracestate` (`ot=th:...`) so downstream collectors / backends know the effective rate without re-deriving it. Required for accurate rate analytics under sampling. Adoption is rolling out per-SDK in 2025/2026.

**Tail-based** — decision after the trace completes, in the collector:
- `tail_sampling` processor (in `opentelemetry-collector-contrib`). Buffers all spans of a trace for `decision_wait` (default 30s), then evaluates policies:
  - `latency` (p95 > N ms), `status_code` (ERROR), `string_attribute` (e.g. tenant), `numeric_attribute`, `rate_limiting` (spans/sec), `probabilistic`, `composite` (AND/OR of policies).
- **Hard requirement: all spans of one trace MUST land at the same collector instance.** A multi-replica collector behind a normal LB will split the trace and each replica makes a different decision → broken/missing spans.

**Coordinator+sampler topology (canonical)**: two-tier collector deployment.
1. Tier 1 (coordinator/router): receives OTLP, applies the **`loadbalancing` exporter** with `routing_key: traceID`, `resolver: dns` (Kubernetes headless service) or `static`. Hashes trace_id → routes to a fixed Tier-2 replica.
2. Tier 2 (sampler): runs the `tail_sampling` processor. Stateful — sticky per trace_id.
- Without this topology, sharing trace state across collector pods would require external storage. The load-balancer is cheaper.
- `loadbalancing` exporter routing keys: `traceID` (default for traces), `service` (default for metrics), `streamID` for logs, `resource` for resource-grouped routing.
- Watch `otelcol_loadbalancer_num_backends` — if it doesn't match expected replicas, DNS hasn't converged or readiness is stuck.

## Semantic conventions

The contract between instrumentation and backends. **Stability matters or your dashboards break on SDK upgrade.**

- **Stability levels**: `development` (was `experimental`) → `alpha` → `beta` → `release_candidate` → `stable`. Only `stable` is a breaking-change-protected contract. **Default is `development` if unset.**
- **Stable in 2024+**: HTTP (spans + metrics), database (partial), system metrics. **In flight**: gen-ai, RPC, messaging, k8s. Check `semantic-conventions/model/<area>` `stability:` field before depending.
- **HTTP migration (the canonical one)**: `http.method` → `http.request.method`, `http.status_code` → `http.response.status_code`, `http.url` → `url.full`, `http.host` → `server.address` + `server.port`, `http.scheme` → `url.scheme`, `http.target` → `url.path` + `url.query`, `net.peer.name` → `server.address`. Span name template changed to `{method} {http.route}` (e.g. `GET /users/:id`).
- **`OTEL_SEMCONV_STABILITY_OPT_IN`** controls instrumentation library output: `http` (new only), `http/dup` (both old and new — for migration windows), unset (old only, deprecated). Per-domain comma-list possible (`http,db`).
- **Other stable attribute clusters**: `db.system.name` (was `db.system`), `db.namespace`, `db.query.text` (was `db.statement`), `messaging.system`, `messaging.destination.name`, `messaging.operation.type`, `rpc.system`, `rpc.service`, `rpc.method`, `network.peer.address`, `network.peer.port`, `network.protocol.name`.
- **Span name discipline**: low-cardinality. `GET /users/:id` (route template) — NOT `GET /users/12345`. Raw URLs in span name → metrics-from-spans (RED) explode.

## OTLP exporter and ports

- **OTLP/gRPC default port: 4317.** **OTLP/HTTP default port: 4318.** This is the single most common misconfiguration.
- **Endpoints differ by protocol**:
  - gRPC: just `http://collector:4317` (no path, the gRPC service name is in the proto).
  - HTTP: append `/v1/traces`, `/v1/metrics`, `/v1/logs`. SDKs append automatically when given a base URL **only for HTTP**, and **only on `OTEL_EXPORTER_OTLP_ENDPOINT`**, not on signal-specific overrides like `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` (which is treated as the full URL including path).
- **`OTEL_EXPORTER_OTLP_PROTOCOL`**: `grpc` (default), `http/protobuf`, `http/json`. **Mismatch with collector port = silent connection refused or 404**. Pointing gRPC at 4318 → "transport closed" / `UNAVAILABLE`. Pointing HTTP at 4317 → handshake failure or "Method Not Allowed" / 405.
- **Receivers can multiplex by `Content-Type`** if both protocols listen on the same port — the collector OTLP receiver supports this when both `protocols.grpc` and `protocols.http` are configured. Standard receiver YAML still binds 4317 + 4318 separately; multiplexing requires explicit shared bind.
- **Headers** (`OTEL_EXPORTER_OTLP_HEADERS=key=val,key2=val2`) — comma-separated, URL-encoded values. SaaS backends use this for API keys.
- **Compression**: `OTEL_EXPORTER_OTLP_COMPRESSION=gzip`. ~5-10× payload reduction on traces; cheap CPU cost; turn on by default.
- **Batch span processor knobs**: `OTEL_BSP_SCHEDULE_DELAY=5000` (ms between exports), `OTEL_BSP_MAX_QUEUE_SIZE=2048`, `OTEL_BSP_MAX_EXPORT_BATCH_SIZE=512`. High span rate + small queue = drops with `BatchSpanProcessor` warnings; raise queue or shorten delay.

## Collector pipeline ordering

Pipelines are per-signal. Order of processors **matters semantically**:

```yaml
receivers:
  otlp:
    protocols: { grpc: { endpoint: 0.0.0.0:4317 }, http: { endpoint: 0.0.0.0:4318 } }
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 4000
    spike_limit_mib: 800
  k8sattributes: {}    # gateway only
  resource: { attributes: [{ key: deployment.environment.name, value: prod, action: upsert }] }
  tail_sampling: { decision_wait: 30s, policies: [...] }
  batch: { timeout: 10s, send_batch_size: 8192 }
exporters:
  otlp/tempo: { endpoint: tempo:4317, tls: { insecure: true } }
service:
  pipelines:
    traces: { receivers: [otlp], processors: [memory_limiter, k8sattributes, resource, tail_sampling, batch], exporters: [otlp/tempo] }
```

- **`memory_limiter` MUST be first.** Applies backpressure at the receiver before any allocation downstream. Without it, a burst → OOM kill → data loss > a controlled drop.
  - `limit_mib`: hard cap. `spike_limit_mib`: distance below `limit_mib` at which soft refusal starts (default 20% of `limit_mib`).
  - Also set `GOMEMLIMIT=80%-of-container-limit` env var — Go runtime cooperates with the soft limit.
- **`batch` MUST be last** in the processor chain. Batching before sampling/dropping wastes work batching data that gets discarded.
- **Sampling processors before `batch`**, after `memory_limiter`. Tail sampling's buffering is its own memory pressure — `memory_limiter` first protects against it.
- **`k8sattributes`** processor enriches with pod metadata via Kubernetes API. Place after `memory_limiter`, before any processor that depends on those attrs. Needs RBAC — `pods` get/list/watch, optionally `replicasets` and `deployments`.
- **Pipelines per signal**: `service.pipelines.traces`, `.metrics`, `.logs`. A processor configured but not referenced in any pipeline silently doesn't run.

## Collector deployment topology

Three patterns, often combined:

- **Agent (DaemonSet)**: one collector pod per K8s node. SDKs send to `$NODE_IP:4317`. Wins: low latency, no network egress per app, scales 1:1 with nodes. Use for receiving + batching + minor enrichment, then forward upstream.
- **Sidecar**: one collector container per app pod. Wins: per-pod isolation, app-tied lifecycle. Costs: 1× collector overhead per pod. Use only when DaemonSet doesn't fit (multi-tenant clusters, app-specific scrape config).
- **Gateway (Deployment)**: centralized collector replica set behind a service. Wins: tail sampling, fan-out to multiple backends, central policy. Receives from agents over OTLP. Run with HPA + the coordinator/sampler split if doing tail sampling.
- **Hybrid (canonical for prod)**: Agent (DaemonSet) → Gateway-coordinator → Gateway-sampler. Each tier owns one concern.

## Span lifecycle

- **`Start → set attributes/events/status → End`**. After `End()`, the span is **immutable**; mutations are silently dropped. Set `RecordException` and `SetStatus(Error)` **before** `End`.
- **Forgotten `End()` = SDK memory leak**. Span object stays in the active-set, never reaches `BatchSpanProcessor`. Use language idioms: Go `defer span.End()`, Python `with tracer.start_as_current_span(...)`, Java try-with-resources on `Scope`, Node.js `tracer.startActiveSpan(name, span => {...; span.end()})`.
- **Span events**: structured timestamped key-value records attached to a span. Cheaper than separate logs for low-frequency in-context detail (e.g., "cache miss"). **The Span Events API is being deprecated in favor of bridging to Logs (2026 announcement)** — new code should use the Logs SDK with span context instead.
- **Span links**: relate spans across traces (async producer/consumer, batch-job processing N upstream traces). Carry context without parent-child relationship. Use when one span legitimately corresponds to many trace_ids.
- **Span status**: `Unset` (default), `Ok`, `Error` (with description). `Unset` is correct for non-errors — instrumentation should NOT pre-set `Ok`. Backends interpret `Error` distinctively.
- **Orphan span**: child ends after parent already exported (parent's `BatchSpanProcessor` flushed). The child still emits but its parent reference points to a span the backend has already stored — usually fine for trace assembly, but if parent and child go to different collectors during routing, the child can lose the parent. Tail-sampling decision_wait must be longer than the longest realistic span gap.

## Auto-instrumentation per-language

| Language | Mechanism | Key invocation |
|---|---|---|
| Java | bytecode via `javaagent` JAR (JVMTI) | `java -javaagent:opentelemetry-javaagent.jar -jar app.jar` |
| Python | monkey-patch via wrapper | `opentelemetry-bootstrap -a install` then `opentelemetry-instrument python app.py` |
| Node.js | `--require` hook | `NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register"` |
| .NET | profiler attach | `OpenTelemetry.AutoInstrumentation` MSI / shell installer |
| Go | **eBPF** (no bytecode) | `opentelemetry-go-instrumentation` agent as sidecar (operator-injected); or `Auto SDK` for manual+auto bridge |
| Ruby | monkey-patch | `OpenTelemetry::SDK.configure` + `c.use_all` |

- **Go is the outlier**: no runtime bytecode rewrite is possible on compiled binaries, so the OTel project ships an **eBPF agent** (Beta as of 2025) that hooks `net/http`, `database/sql`, gRPC, `kafka-go`. Runs as sidecar with `CAP_SYS_ADMIN` / `CAP_BPF`. For most teams: stick with manual instrumentation via `otelhttp`, `otelgrpc`, `otelpgx`.
- **Operator (`opentelemetry-operator`)** auto-injects per-language agents into pods via `Instrumentation` CRD + pod annotations (`instrumentation.opentelemetry.io/inject-java=true`). Sets `JAVA_TOOL_OPTIONS` / `PYTHONPATH` / `NODE_OPTIONS` — **collides with user-set values in the same env vars** (known issue; precedence is manifest > injected).
- **Duplicate-span pitfall**: HTTP-server framework (Express, Spring, Flask) auto-instruments AND the underlying HTTP library (Node `http`, Servlet, WSGI) auto-instruments → two spans per request, parent-child or sibling depending on hook depth. Disable one — usually the lower-level library — via per-instrumentation env (`OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=urllib3`) or disable in code at SDK init.
- **Instrumentation library version bounds**: each `opentelemetry-instrumentation-<lib>` declares supported library version range (e.g., `opentelemetry-instrumentation-flask >=1.0,<4.0`). Mismatch silently degrades (no spans) or breaks startup with import errors. Pin in lockfile; check the contrib repo's per-instrumentation README for current bounds.

## Metrics: instrument types and cardinality control

- **Synchronous**: `Counter` (monotonic up), `UpDownCounter` (signed), `Histogram` (distribution), `Gauge` (synchronous Gauge added 1.30+; previously only Observable).
- **Asynchronous (callback-driven)**: `ObservableCounter`, `ObservableUpDownCounter`, `ObservableGauge`. SDK calls back at collection time. Use for sampling external state (queue depth, DB connection count).
- **Histograms**:
  - **Explicit-bucket**: legacy default. Buckets are static, must be tuned per-metric. Cross-instance aggregation requires identical bucket boundaries (string-encoded `le` labels).
  - **Base-2 exponential** (OTel-native, since spec 1.x): scale parameter auto-adjusts. Far better cross-instance aggregation, no bucket-mismatch silent drops, smaller wire size for high-resolution distributions. **Default in newer SDKs (Java since 2.x, .NET since 1.9, Python defaults still explicit unless View overrides)**. Prefer.
- **Cardinality control via the Views API** (SDK-level, before export):
  ```python
  view = View(
      instrument_type=Counter,
      instrument_name="http.server.request.count",
      attribute_keys=["http.method", "http.response.status_code"],  # drop everything else
  )
  ```
  - **`attribute_keys` whitelist drops all other attributes** at the SDK boundary — backend sees only listed keys. Single biggest cardinality lever.
  - Views can also rename instruments, change aggregation (force exponential histogram), or drop instruments entirely.
- **Cardinality bombs in metrics**: `user_id`, `trace_id`, `request_id`, `session_id`, raw URL paths, K8s pod names with random suffix → series count explodes. Bound aggregate metrics with cardinality-safe attrs only; use **exemplars** (next section) to reach the high-cardinality detail.
- **Common metrics SDK env vars**: `OTEL_METRICS_EXPORTER=otlp|prometheus|console|none`, `OTEL_METRIC_EXPORT_INTERVAL=60000` (ms), `OTEL_METRIC_EXPORT_TIMEOUT=30000`.

## Exemplars (metrics ↔ traces bridge)

- **Exemplar**: a `(value, trace_id, span_id, timestamp, attributes)` tuple attached to a histogram bucket / counter point. Lets users jump from a metric to one representative trace.
- **`OTEL_METRICS_EXEMPLAR_FILTER`**: `trace_based` (default — only emit when in active sampled span context), `always_on`, `always_off`.
- **Histogram only on Prometheus** — Prometheus exemplar API attaches to histogram buckets. Counters carry exemplars in OTLP but most query layers (PromQL via Prom-OTLP receiver) only surface histogram exemplars.
- **Prometheus side**: `--enable-feature=exemplar-storage` flag. Fixed-size in-memory ring buffer per series.
- **The cardinality-control idiom**: keep metric labels low-cardinality (status_class, method); for the high-cardinality dimension (user_id, customer), record on the trace, link via exemplar. Cardinality stays bounded; high-cardinality detail is reachable on demand.

## Logs bridge

OpenTelemetry's logs story is a **bridge** from existing loggers to the OTel data model — not a new logging API. Use the existing logger.

- **Java**: `OpenTelemetryAppender` for log4j2 / logback. The `javaagent` auto-bridges. MDC is auto-populated with `trace_id`, `span_id`, `trace_flags` for the active span — reference in pattern as `%X{trace_id}`. Log file then carries the trace pointer.
- **Python**: `LoggingHandler` from `opentelemetry-sdk._logs`; or `OTEL_PYTHON_LOG_CORRELATION=true` injects via the `LoggingInstrumentor` to add `otelTraceID`/`otelSpanID` to the standard `logging` record's `extra`.
- **Go**: `go.opentelemetry.io/contrib/bridges/otelslog` for `log/slog`; `otelzap` for `zap`. Bridge wraps a logger and injects context.
- **Node.js**: bridges for Winston, Pino, Bunyan in `@opentelemetry/instrumentation-<logger>`.
- **`OTEL_LOGS_EXPORTER`**: `otlp` (default), `console`, `none`. Logs SDK is stable, but coverage of language-native logger bridges still varies.
- **Pitfall**: enabling the Python `LoggingInstrumentor` AND the `LoggingHandler` simultaneously double-emits — one writes to stdout, one writes via OTLP. Pick the path your collector pipeline expects.

## Common pitfalls (consolidated)

- `service.name` unset → spans bucketed as `unknown_service`. Set `OTEL_SERVICE_NAME` in every container.
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` against port 4318 → connection refused. HTTP against 4317 → 405.
- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` is treated as the full URL **including signal path**; setting it to `https://collector:4318` (no `/v1/traces`) breaks HTTP exports while leaving `OTEL_EXPORTER_OTLP_ENDPOINT` working — base vs override paths differ.
- Tail sampling without the `loadbalancing` exporter coordinator → split decisions, missing spans. Trace assembly looks fine in some traces, broken in others.
- `tail_sampling.decision_wait` shorter than your slowest span → decisions made on partial trace, late spans dropped.
- `memory_limiter` placed after `batch` → OOM kill before backpressure activates; data loss instead of controlled drop.
- Auto-instrumentation enabled at framework AND library level → duplicate spans, broken parent-child chain.
- `OTEL_SEMCONV_STABILITY_OPT_IN` unset on a deprecated instrumentation → still emits `http.method` etc.; new dashboards keyed on `http.request.method` show empty.
- `OTEL_PROPAGATORS=tracecontext` only, talking to a Zipkin/B3 service → context drops at the boundary, child spans get new trace_id (broken trace).
- High-cardinality metric attribute (`user_id`) → series count blows up at backend, cost/perf cliff. Use Views to drop, exemplars to reach.
- Span ended after parent already exported → orphan; parent reference dangles. In tail sampling, child can land on a different sampler replica if `loadbalancing` routing key isn't `traceID`.
- PII in baggage → leaks to every downstream HTTP, including third-party APIs (auto-instrumentation forwards by default).
- `OTEL_BSP_MAX_QUEUE_SIZE` too small under burst → `BatchSpanProcessor` queue full warnings + dropped spans. Raise queue OR shorten `OTEL_BSP_SCHEDULE_DELAY`.
- Forgetting `defer span.End()` (or equivalent) on early-return paths → SDK memory grows, eventually OOM.

## Authoritative references

**Specification** (`opentelemetry.io/docs/specs/otel`):
- [SDK environment variables](https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/)
- [Trace SDK](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/sdk.md)
- [Metrics SDK](https://opentelemetry.io/docs/specs/otel/metrics/sdk/)
- [OTLP Protocol](https://opentelemetry.io/docs/specs/otlp/)
- [Propagators API](https://opentelemetry.io/docs/specs/otel/context/api-propagators/)
- [Probability sampling (TraceState)](https://opentelemetry.io/docs/specs/otel/trace/tracestate-probability-sampling/)
- [Versioning and stability](https://opentelemetry.io/docs/specs/otel/versioning-and-stability/)

**Semantic conventions** (`github.com/open-telemetry/semantic-conventions`):
- [HTTP migration guide](https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/)
- [HTTP spans](https://opentelemetry.io/docs/specs/semconv/http/http-spans/)
- [Group stability levels](https://opentelemetry.io/docs/specs/semconv/general/group-stability/)
- [Resources](https://opentelemetry.io/docs/concepts/resources/)
- [Releases](https://github.com/open-telemetry/semantic-conventions/releases)

**Collector** (`opentelemetry.io/docs/collector` and `github.com/open-telemetry/opentelemetry-collector-contrib`):
- [Collector configuration](https://opentelemetry.io/docs/collector/configuration/)
- [Memory limiter processor](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/memorylimiterprocessor/README.md)
- [Batch processor](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/batchprocessor/README.md)
- [Tail-sampling processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/tailsamplingprocessor/README.md)
- [Load-balancing exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/loadbalancingexporter/README.md)
- [k8sattributes processor](https://pkg.go.dev/github.com/open-telemetry/opentelemetry-collector-contrib/processor/k8sattributesprocessor)
- [Gateway deployment](https://opentelemetry.io/docs/collector/deployment/gateway/)
- [Scaling the collector](https://opentelemetry.io/docs/collector/scaling/)

**Sampling and instrumentation guides**:
- [Tail sampling blog](https://opentelemetry.io/blog/2022/tail-sampling/)
- [HTTP semantic conventions stable announcement](https://opentelemetry.io/blog/2023/http-conventions-declared-stable/)
- [Sampling milestones (2025)](https://opentelemetry.io/blog/2025/sampling-milestones/)
- [Stability proposal (2025)](https://opentelemetry.io/blog/2025/stability-proposal-announcement/)
- [Go eBPF auto-instrumentation Beta](https://opentelemetry.io/blog/2025/go-auto-instrumentation-beta/)
- [Java agent](https://opentelemetry.io/docs/zero-code/java/agent/)

**Operator and Kubernetes**:
- [opentelemetry-operator](https://github.com/open-telemetry/opentelemetry-operator)
- [Auto-instrumentation injection](https://opentelemetry.io/docs/platforms/kubernetes/operator/automatic/)
- [k8s metadata enrichment blog](https://opentelemetry.io/blog/2022/k8s-metadata/)

**Reliable authors**: Ted Young, Steve Flanders (Splunk/OTel governance); Tyler Yahn, Jacob Aronoff (collector core); Trask Stalnaker (Java instrumentation lead); Daniel Dyla (JS); Lightstep / ServiceNow / Honeycomb / Grafana Labs OTel blogs.

## Guardrails

Before recommending a non-trivial OTel change (sampler, propagator list, processor order, OTLP protocol switch, semconv migration):

1. Quote the **specific env var or config key** and its default.
2. Cite the upstream doc — `opentelemetry.io/docs/specs/otel`, the contrib README for the processor/exporter, or `github.com/open-telemetry/semantic-conventions` at a pinned version.
3. Make the recommendation conditional on **observed** signals — span drop rate, collector memory, tail-sampling `decision_wait` overflow, `unknown_service` count, sampler effective rate — never blanket-tune.
4. Name a rollback: "if X spikes, revert by Y."
5. For semconv migration, **always go through `http/dup` (or per-domain dup) for one release window** — never flip atomically while dashboards are live.

**Tuning without measurement is worse than defaults.** Sampling rates, batch sizes, memory limits, and propagator order are environment-specific — a 1% sample that's correct for a 10k-RPS service is invisible at 10 RPS, and a propagator list that works in a homogeneous OTel fleet drops trace context the day a B3-emitting service joins.
