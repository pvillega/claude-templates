---
name: grafana
description: >
  Deep operational intuition for the Grafana stack — Prometheus/Mimir cardinality
  cost model, PromQL/LogQL pitfalls, recording vs alerting rule semantics, alert
  state lifecycle, dashboard variable scoping, provisioning + UID stability,
  histogram bucket math, exemplars, Tempo TraceQL, and Alertmanager grouping.
  Load ONLY when the task is about deep operational tuning, incident diagnosis,
  cardinality bombs, alert flapping/noise, dashboard provisioning at scale,
  histogram/quantile correctness, log-pipeline performance, or trace-to-metric
  correlation. Do NOT load for ordinary panel building, basic PromQL syntax
  questions, "how do I install Grafana", or first-time dashboard authoring —
  those don't need this skill.
  Triggers on: "cardinality bomb", "high cardinality", "rate vs irate",
  "rate_interval", "histogram_quantile", "le label", "recording rule",
  "alert flapping", "keep_firing_for", "for clause", "alert state",
  "logql performance", "structured metadata", "loki cardinality",
  "dashboard uid", "datasource uid", "provisioning grafana", "mimir limit",
  "max_global_series_per_user", "exemplars", "traceql", "service graph",
  "alertmanager group_wait", "group_interval", "vector matching",
  "group_left", "sum without vs by", "native histograms".
---

# Grafana Stack Operational Guide

Concise operational pointers for deep Grafana / Prometheus / Mimir / Loki / Tempo / Alertmanager troubleshooting.

Assumes you already know what dashboards, metrics, logs, and traces are, and can write a basic PromQL/LogQL query. This skill covers the **operational layer** — the parts models tend to gloss over: cardinality cost, rule semantics, alert lifecycle, query-language footguns, provisioning UID stability, and the cross-component contract.

## When to use

Load when the question is about:
- Cardinality bombs (Prometheus/Mimir/Loki) and how to detect them
- PromQL correctness around `rate`/`irate`/`increase`/`histogram_quantile`/vector matching
- Recording-rule vs alerting-rule semantics, eval intervals, naming
- Alert lifecycle (Inactive→Pending→Firing→Recovering), `for:`, `keep_firing_for:`
- Alertmanager grouping (`group_wait` / `group_interval` / `repeat_interval`) and inhibition
- LogQL filter ordering and structured metadata in Loki 3.x
- Dashboard / datasource provisioning and UID stability
- Variable scoping (`$__interval` vs `$__rate_interval`, formatting modifiers)
- Exemplars wiring metrics → traces, TraceQL service-graph metrics
- Native histograms (v2.40+ experimental, v3.8+ stable)

**Do NOT load** for: panel construction, picking a panel type, "how do I plot X", first-time install, basic PromQL syntax tutorials.

## Cardinality cost model

The **single biggest operational footgun** across Prometheus, Mimir, and Loki. Every unique label-set is a stored time-series; cost = series_count × samples_per_series.

- **Per-metric guideline**: keep cardinality below 10 per metric; investigate alternatives above 100. The vast majority of metrics should have no labels.
- **Common bombs** (do NOT label by these): `user_id`, `email`, `request_id`/`trace_id`, status text, raw URL paths, K8s pod names with random suffixes, container IDs.
- **Detect top metrics by series count**:
  ```promql
  topk(20, count by (__name__)({__name__=~".+"}))
  ```
- **Detect top labels for a hot metric**:
  ```promql
  topk(20, count by (label_name)(metric_name))
  ```
- **TSDB internals to watch**: `prometheus_tsdb_head_series` (current active), `prometheus_tsdb_symbol_table_size_bytes` (label string interning), `scrape_series_added` per target.
- **Mimir per-tenant limits**: `max_global_series_per_user` (active series across ingesters; flag `-ingester.max-global-series-per-user`), `max_global_series_per_metric`, `ingestion_rate`, `ingestion_burst_size`. Excess is **rejected as 4xx client error** (data discarded, not retried). Per-ingester hard cut-off ≈ 2.5M series default.
- **Loki cardinality**: each unique stream-label combo = one log stream. Multiplicative — 3 status × 5 actions × 3 endpoints = 45 streams. Static labels only (`app`, `namespace`, `env`); push high-cardinality fields to **structured metadata** (Loki 3.0+, schema v13, chunk format v4) — queryable as `{job="x"} | pod="..."` without index cost.

## PromQL gotchas

- **`rate()` minimum window**: needs ≥ 4 samples in the range vector for stability; with default 15s scrape, that's a 1-minute floor — but you almost always want longer (5m+). Counter resets are handled inside `rate`/`increase`.
- **`$__rate_interval` formula** (Grafana 7.2+): `max($__interval + scrape_interval, 4 * scrape_interval)`. Always ≥ 4× scrape. **Use this in dashboards, not `$__interval`** — `$__interval` alone can drop below the 4× floor on zoom-in and produce empty graphs or undercounted rates.
- **`irate()`**: only the last two samples; great for short bursts/debugging, **unstable for long ranges or alerts** because it's noisy and non-monotonic.
- **`increase()` = `rate() × seconds_in_range`**. Same minimum-window requirement. Prefer `rate()` in recording rules.
- **`histogram_quantile()` (classic histograms)**:
  - Must group by the `le` label: `histogram_quantile(0.99, sum by (le, job)(rate(http_request_duration_seconds_bucket[5m])))`.
  - `le` values are **string-encoded floats** — `"0.5"` and `"0.50"` are different label values and won't aggregate.
  - Returns `NaN` if too few buckets; `+Inf` for φ > 1, `-Inf` for φ < 0.
  - Quantile error margin = bucket width. A 95th percentile of 220 ms with buckets at 0.2 / 0.3 estimates as ~295 ms — silent 75 ms error.
  - Buckets must align across instances or aggregation silently drops series.
- **Native histograms** (v2.40 experimental via `--enable-feature=native-histograms`; v3.8+ stable; v3.9 flag becomes no-op): exponential bucketing, single composite sample, ad-hoc quantile, aggregation across instances. **Prefer these** — switches scrape exposition to protobuf.
- **`quantile_over_time(φ, scalar[5m])`** vs **`histogram_quantile(φ, …_bucket)`**: completely different. The former aggregates raw scalars across time; the latter interpolates over a histogram's bucket boundaries.
- **`@` modifier** (introduced 2.25 experimental, stable in 2.33): pin evaluation timestamp — `metric @ 1609746000` or `@ start()` / `@ end()`. Required to make `topk()` stable across a range query (otherwise re-evaluates per step and series flicker in/out).
- **`offset 1w`**: shift evaluation back; combine with `@` to compare current-vs-historical at fixed boundaries.
- **`topk` / `bottomk`**: evaluated independently per timestamp — series enter and leave the result set across a range. Use `@` to pin.
- **Vector matching**: `on(labels)` restricts match keys; `ignoring(labels)` excludes. `group_left(x)` / `group_right(x)` for many-to-one / one-to-many — names the side with higher cardinality. Default is 1:1 and **fails the query** on cardinality mismatch.
- **`sum without (instance)` ≠ `sum by (job)`**: `without` drops named labels, **keeps everything else** (including new labels added later); `by` keeps **only** named labels. A new label appearing in scrape config will silently break dashboards built with `without` but not those built with `by` (and vice versa, depending on intent). Pick deliberately.

## Recording rules

- **Naming**: `level:metric:operations`. Level = remaining aggregation labels (e.g. `job`, `instance_path`); metric = base name unchanged (drop `_total` only when applying `rate`); operations = transformations newest-first. Example: `job:http_requests:rate5m`.
- **Aggregation strategy**: when computing ratios, aggregate numerator and denominator separately, then divide. Never average ratios.
- **Group eval interval ≤ scrape interval**, otherwise rules see stale samples. Default = `global.evaluation_interval`.
- **Group cannot finish before next cycle?** The next eval is **skipped** and `rule_group_iterations_missed_total` increments — silent gaps in recorded series.
- **`for:` does NOT exist in recording rules** — alerting-only.
- **Replacing a query in a recording rule that's also referenced by an alert**: alerts must be updated together. Otherwise the alert continues using the old (cached) query against the now-different output series.

## Alerting rules and state lifecycle

- **Prometheus states**: Inactive → Pending (during `for:`) → Firing → (Inactive on resolve, after `keep_firing_for:` if set).
- **Grafana-managed states** add: **NoData** (query returned 0 series), **Error** (query/eval failure), **Recovering** (firing → normal during `keep_firing_for:` window). NoData/Error are Grafana-only — Prometheus-managed alerts simply don't fire.
- **`for: 5m`** is a smoothing window: condition must be true on **every evaluation** for 5 minutes before firing. An alert that flaps inside that window **never fires** — convenient for noise, dangerous if the underlying issue is genuinely intermittent.
- **`keep_firing_for:`** (Prometheus 2.42, Feb 2023): keep firing for N after the condition clears. Defaults to 0 (off). Use to dampen flapping resolves; default behaviour deactivates immediately after first eval where condition not met.
- **`labels:` vs `annotations:`**: labels are **indexed** in Prom, used for routing/dedup; annotations are **unindexed**, free-form (`summary`, `description`, `runbook_url`, `dashboard_url`). Don't put high-cardinality strings in labels — they multiply your alert series.
- **Alert dedup by label set**: identical `{alertname, ...labels}` are the same alert. Adding a high-cardinality label (e.g. `instance` per pod) creates one alert per pod.

## Alertmanager grouping and inhibition

Defaults (override per route):
- **`group_wait: 30s`** — initial buffer for a new group, lets sibling alerts coalesce into the first notification.
- **`group_interval: 5m`** — wait between notifications when **new** alerts join an already-notified group.
- **`repeat_interval: 4h`** — re-notify the same alert after this if still firing.
- **`group_by: [alertname, cluster]`** — alerts sharing these labels coalesce into one notification. Add too many labels → no grouping; too few → unrelated alerts merged.
- **Inhibition rules**: when a "source" alert fires, suppress matching "target" alerts. Classic use: `severity=critical` on a node down inhibits `severity=warning` for individual pods on that node. Requires shared `equal:` labels.
- **Silences**: time-bounded label-matcher mute, separate from inhibition. Good for maintenance windows.

## LogQL gotchas (Loki)

Filter ordering matters for performance — Loki applies in this order, so cheap filters first:

1. **Stream selector** `{app="api", env="prod"}` — only indexed filter, narrows reading from object storage.
2. **Line filters** `|= "error"` (substring, fastest), `|~ "regex"`, `!=`, `!~` — applied to raw line bytes before parsing.
3. **Parsers** `| json`, `| logfmt`, `| pattern "<ip> - <user>"`, `| regexp` — `pattern` is much cheaper than `regexp`.
4. **Label filters on parsed labels** `| status_code = 500`.
5. **Metric extraction** `| unwrap latency` for log-derived metrics: `sum(rate({...} | json | unwrap bytes [1m]))`.

- **Anti-pattern**: `{app=~".+"} |= "error"` — full-tenant scan. Always pin at least one indexed label.
- **Loki 2.x cardinality cost**: putting `pod` or `request_id` in stream labels exploded the index. **Loki 3.0+ structured metadata** is the fix — query as `{app="x"} | pod="..."`, no index growth.

## Dashboard variables

- **Types**: query, custom, interval, datasource, textbox, constant, filters, switch.
- **Time variables**: `$__from` / `$__to` are **epoch ms** by default. `${__from:date:seconds}` for Unix seconds, `${__from:date:YYYY-MM-DD}` for custom.
- **`$__interval`**: `(to - from) / panel_resolution_pixels`. Used for `group by (time)` style binning. **Do NOT use in `rate()`** — can fall under 4×scrape on zoom.
- **`$__rate_interval`**: `max($__interval + scrape_interval, 4 * scrape_interval)`. **Always use this for `rate`/`increase`** in PromQL.
- **Multi-value formatting**:
  - `${var}` (default per datasource) — Prometheus emits regex `(a|b|c)`, requires `=~` matcher in the query.
  - `${var:csv}` → `a,b,c`
  - `${var:pipe}` → `a|b|c`
  - `${var:regex}` → escaped for regex
  - `${var:json}` → JSON array
- **Include All**: defaults to a literal `.+` regex unless "Custom all value" overrides. Beware: `.+` against `=~` matcher matches **every series**, not nothing.
- **Variable interpolation order**: query variables refresh on time-range change only if "Refresh: On Time Range Change" is set; otherwise stale on dashboard load — cause of mysterious "missing" series.

## Provisioning and UID stability

- **Dashboard provisioning** (`provisioning/dashboards/*.yaml`):
  ```yaml
  providers:
    - name: 'team-x'
      folder: 'Team X'
      folderUid: 'team-x-folder'   # pin
      type: file
      updateIntervalSeconds: 10
      allowUiUpdates: false
      options:
        path: /var/lib/grafana/dashboards
        foldersFromFilesStructure: true
  ```
  - **The `uid` inside the dashboard JSON is the stable identity.** If absent, Grafana generates a new one on every reprovision → external links break, alert links break, history splits.
  - `allowUiUpdates: false` keeps file as source of truth; UI edits are reverted on next sync.
- **Datasource provisioning** (`provisioning/datasources/*.yaml`): **always set `uid:`** explicitly. Without it, the UID is randomly generated per instance — the same dashboard JSON imported into staging vs prod references different datasource UIDs and panels show "Datasource not found".
  ```yaml
  datasources:
    - name: Prometheus
      uid: prom-prod        # pin or pay later
      type: prometheus
      url: http://prom:9090
      version: 1
  ```
  `prune: true` removes provisioned datasources when files are deleted; `version` controls precedence across instances.
- **Mixin pattern** (`monitoring-mixin`, kube-prometheus-stack, prometheus-operator helm chart): jsonnet libraries shipping dashboards + alerts as code. Lets you template `datasource` and `cluster` labels at render time.

## Prometheus Operator / kube-prometheus-stack

CRDs you'll touch:
- **`ServiceMonitor`** discovers via Service+EndpointSlice; **`PodMonitor`** discovers Pods directly (use when there's no Service).
- **`Probe`** for blackbox-style external endpoints; **`ScrapeConfig`** for arbitrary configs that don't fit ServiceMonitor.
- **`PrometheusRule`** holds recording + alerting rules; reconciled and **hot-loaded — no Prometheus restart**.
- **`AlertmanagerConfig`** for routing/inhibition split per namespace.
- Resource selectors: empty `{}` = match all; `null`/unset = match none. Wrong selector = silent zero-targets.

## Exemplars and traces

- **Exemplars** link a metric data point to a trace ID. Requires `--enable-feature=exemplar-storage` on Prometheus (fixed circular buffer in memory; persisted to WAL).
- Instrumentation must emit them (Go `prometheus/client_golang` `ObserveWithExemplar`; Java `io.prometheus.client.exemplars`).
- Grafana Prometheus datasource: enable "Exemplars" in datasource settings, link to a Tempo datasource by UID.
- **TraceQL** (Tempo): `{ resource.service.name = "checkout" && duration > 1s && status = error }`. Three attribute scopes: **intrinsic** (`name`, `duration`, `status`), **`span.*`** (per-span), **`resource.*`** (per-process). Wrong scope returns zero results without error.
- **Service graph metrics** (Tempo metrics-generator): emits `traces_service_graph_request_total`, `traces_service_graph_request_failed_total`, `traces_service_graph_request_server_seconds_*` as Prometheus metrics. Cardinality = (caller × callee) pairs — bounded by service count, not trace count.
- **Span metrics** (similar generator): emits RED metrics from spans (`traces_spanmetrics_calls_total`, `traces_spanmetrics_latency_*`). Cardinality watch: `span.name` and `http.route` should be normalized; raw URLs explode it.

## Datasource considerations

- **`Resolution` / `Min interval` / `Min step`** override `$__interval` and feed the `step` parameter to PromQL `query_range`. Smaller step = more points = potentially blown query timeout.
- **`maxDataPoints`** in panel — Grafana downsamples by adjusting `step`. If your alert query uses a fixed range and the dashboard query uses dynamic step, results legitimately differ.
- **Per-query timeout** (datasource setting): default 60 s; long-range high-cardinality `histogram_quantile` queries hit this.

## Common pitfalls (consolidated)

- `sum without (instance)` vs `sum by (job)` — drops named vs keeps named. New scrape labels silently flip results.
- Alert reused across envs via `for:` — copying production thresholds to staging without adjusting `for:` causes noisy paging on lower-traffic environments.
- Recording-rule renamed series, alert still references old name → silent eval against absent metric (alert never fires; not the same as a "passing" alert).
- Dashboard imported via UI without UID pin → external bookmarks/email links break on reimport.
- Datasource UID drift between instances → dashboard panels say "Datasource not found"; pin in provisioning YAML.
- `irate()` in alerts → flapping. Use `rate()` with a longer window.
- High-cardinality label in alert `labels:` (e.g. per-pod) → 1 alert per pod, paging storm.
- `$__interval` in `rate(metric[$__interval])` on dashboards → empty graphs on zoom-in.
- Annotations are **unindexed** — don't expect to filter or route on annotation contents.
- `topk` in a range query without `@ end()` → series flicker; viewer assumes stability that isn't there.

## Authoritative references

**Prometheus** (`prometheus.io/docs`):
- [Querying functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)
- [Querying basics — `@` and `offset`](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Operators / vector matching](https://prometheus.io/docs/prometheus/latest/querying/operators/)
- [Recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Histograms and quantiles](https://prometheus.io/docs/practices/histograms/)
- [Instrumentation best practices](https://prometheus.io/docs/practices/instrumentation/)
- [Naming](https://prometheus.io/docs/practices/naming/)
- [Recording rule patterns (`level:metric:operations`)](https://prometheus.io/docs/practices/rules/)
- [Feature flags (exemplar-storage, native-histograms)](https://prometheus.io/docs/prometheus/latest/feature_flags/)
- [`@` modifier introduction blog](https://prometheus.io/blog/2021/02/18/introducing-the-@-modifier/)

**Grafana**:
- [Template variables (`$__interval`, `$__rate_interval`)](https://grafana.com/docs/grafana/latest/dashboards/variables/add-template-variables/)
- [Prometheus template variables](https://grafana.com/docs/grafana/latest/datasources/prometheus/template-variables/)
- [`$__rate_interval` formula](https://grafana.com/blog/new-in-grafana-7-2-rate-interval-for-prometheus-rate-queries-that-just-work/)
- [Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Alert rule state and health](https://grafana.com/docs/grafana/latest/alerting/fundamentals/alert-rules/state-and-health/)

**Loki**:
- [LogQL](https://grafana.com/docs/loki/latest/query/)
- [Cardinality](https://grafana.com/docs/loki/latest/get-started/labels/cardinality/)
- [Structured metadata (3.0+)](https://grafana.com/docs/loki/latest/get-started/labels/structured-metadata/)

**Mimir**:
- [Runbooks (limits, cardinality)](https://grafana.com/docs/mimir/latest/manage/mimir-runbooks/)
- [Configuration parameters](https://grafana.com/docs/mimir/latest/references/configuration-parameters/)

**Tempo**:
- [TraceQL](https://grafana.com/docs/tempo/latest/traceql/)

**Alertmanager**:
- [Configuration / routing](https://prometheus.io/docs/alerting/latest/configuration/)
- [Robust Perception: `group_wait` / `group_interval` / `repeat_interval`](https://www.robustperception.io/whats-the-difference-between-group_interval-group_wait-and-repeat_interval/)

**prometheus-operator / kube-prometheus-stack**:
- [Operator design and CRDs](https://prometheus-operator.dev/docs/getting-started/design/)

**Reliable authors**: Tom Wilkie, Bryan Boreham, Cyril Tovena (Grafana Labs blog); Björn Rabenstein, Julius Volz, Richard Hartmann (Prometheus core).

## Guardrails

Before recommending a non-trivial operational change (cardinality cap, `for:`/`keep_firing_for:`, scrape interval, `$__rate_interval` rollout, Mimir limit override):

1. Quote the specific parameter / function name and its default.
2. Cite the upstream doc (`prometheus.io/docs`, `grafana.com/docs/{loki,mimir,tempo}`).
3. Make the recommendation conditional on observed metrics — `prometheus_tsdb_head_series`, `cortex_limits_overrides`, `rule_group_iterations_missed_total`, alert flap rate — never blanket-tune.
4. Name a rollback: "if X spikes, revert by Y."

**Tuning without measurement is worse than defaults.** Cardinality, alert thresholds, and rate windows are environment-specific — what works for a 100-pod cluster will page non-stop on 10,000.
