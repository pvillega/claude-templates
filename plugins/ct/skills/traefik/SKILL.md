---
name: traefik
description: >
  Deep Traefik (v2/v3) operational intuition — provider precedence, ACME challenge
  debugging, middleware ordering, router rule syntax, v2→v3 breaking changes,
  Docker/Swarm/Kubernetes label and CRD footguns, OTLP observability migration,
  TLS options and mTLS, certResolver storage gotchas.
  Load ONLY when the task involves Traefik static/dynamic config, ACME failures,
  middleware ordering, router rule debugging, v2→v3 migration, IngressRoute CRDs,
  or Docker label syntax — including Coolify-embedded Traefik. Do NOT load for
  generic reverse-proxy concepts, basic HTTP routing theory, or nginx/Caddy/HAProxy
  questions — those don't need this skill.
  Triggers on: "traefik labels", "traefik docker labels", "traefik middleware order",
  "ipallowlist", "ipwhitelist", "acme.json", "acme http challenge", "tls challenge",
  "dns challenge", "letsencrypt rate limit", "ingressroute", "hostsni", "pathprefix
  regex", "defaultRuleSyntax", "v2 to v3 traefik", "traefik pilot", "traefik http3",
  "traefik otlp", "traefik tracing", "traefik certresolver", "coolify traefik",
  "traefik docker network", "passhostheader".
---

# Traefik Operational Guide

Concise pointers for deep Traefik troubleshooting and config. Covers v2 and v3, with v2→v3 deltas called out by name.

Assumes you already know reverse-proxy basics, Docker, and YAML/labels. This skill covers the **operational layer** — provider precedence, ACME challenge mechanics, middleware ordering, label-syntax footguns, CRDs — the parts models gloss over.

## When to use

Load when the question is about:
- ACME failures (HTTP-01 / TLS-ALPN-01 / DNS-01 challenge debugging, `acme.json` permissions, LE rate limits)
- v2 → v3 migration (rule syntax, `IPWhiteList` rename, Pilot removal, tracing OTLP, `--experimental.http3`)
- Provider behavior (Docker labels, Swarm `deploy.labels`, Kubernetes IngressRoute CRD vs Ingress, file provider watch)
- Middleware chaining and order (auth → ratelimit → headers → compress)
- Router rule disambiguation (priority, `defaultRuleSyntax`, `PathPrefix` regex breakage)
- TLS options (mTLS via `clientAuth`, cipher suites, `sniStrict`)
- Observability (v3 OTLP-only tracing, removed Jaeger/Zipkin/Datadog backends)
- Coolify-embedded Traefik debugging (it ships v2 by default in older releases, v3 in newer)

**Do NOT load** for: generic reverse-proxy theory, "what is Traefik", nginx/Caddy comparison shopping, basic HTTP routing.

## v2 → v3 breaking changes

The biggest source of confusion. Reference: `migrate/v2-to-v3-details/`.

- **`IPWhiteList` → `IPAllowList`**. Middleware kind renamed in CRDs and labels. v2 syntax still works if `core.defaultRuleSyntax: v2`, but emits warnings. New deployments must use `IPAllowList`.
- **Router rule syntax v3** is the default; v2 syntax requires `--core.defaultRuleSyntax=v2` (deprecated, will be removed in v4).
  - `PathPrefix` no longer accepts regex. `PathPrefix(`/api/{id:[0-9]+}`)` (v2) → `PathRegexp(`^/api/[0-9]+`)` (v3).
  - `Headers`/`HeadersRegexp` → `Header`/`HeaderRegexp` (singular).
  - Path placeholders `{name}` and `{name:regex}` removed. Use `PathRegexp` with Go RE2.
  - `HostHeader` removed; use `Host`.
- **Pilot removed**. v2 ignored Pilot config; v3 **fails to start** if `pilot:` is present in static config. Strip it.
- **HTTP/3**: `--experimental.http3` flag removed. Now configured per-entryPoint with `http3: {}` stanza.
- **Tracing consolidated to OTLP**. Removed: Jaeger, Zipkin, Datadog, Instana, Haystack, Elastic. Migrate to `tracing.otlp.http` (port 4318) or `tracing.otlp.grpc` (port 4317). OTel Collector then fans out to vendors.
- **Metrics renamed**: `traefik_entrypoint_open_connections`, `traefik_router_open_connections`, `traefik_service_open_connections` → single `traefik_open_connections` with labels.
- **Docker provider lost `swarmMode`**. Swarm is now a separate provider (`providers.swarm`). Migrate the static config; labels move from container to `deploy.labels`.
- **Kubernetes**:
  - CRD apiGroup `traefik.containo.us` removed → `traefik.io`.
  - `networking.k8s.io/v1beta1` Ingress removed → `v1`.
  - `apiextensions.k8s.io/v1beta1` CRD definition removed → `v1`.
  - Ingress default path matching no longer accepts regex.
- **Removed provider options**: `tls.caOptional` (Docker, Consul, ConsulCatalog, HTTP, ETCD, Redis, Nomad). `namespace` (singular) removed in Consul/ConsulCatalog/Nomad → use `namespaces` (plural array).
- **Removed entirely**: Rancher v1, Marathon, InfluxDB v1 metrics.
- **Headers middleware deprecated keys removed**: `sslRedirect`, `sslTemporaryRedirect`, `sslHost`, `sslForceHost`, `featurePolicy`, `preferServerCipherSuites` (TLS options). Use `redirectScheme` middleware and `permissionsPolicy`.
- **StripPrefix**: `forceSlash` removed.
- **Tracing**: `tracing.datadog.globaltag` removed.

**Coolify note**: Coolify <= 4.0.x ships Traefik v2 by default; later releases ship v3. Check `docker inspect coolify-proxy | jq '.[0].Config.Image'` before assuming syntax.

## Providers and precedence

Traefik supports many providers; **all dynamic configs are merged**. Naming collisions are resolved by appending `@<providername>` to the resource (e.g. `my-router@docker`, `my-mw@file`, `auth@kubernetescrd`).

- **File provider**: `filename` (single) or `directory` (recursive). `watch: true` (default) hot-reloads via fsnotify. Watch the **parent directory** when mounting via Docker/k8s — atomic rename of the file invalidates the inode link.
- **Docker provider** (standalone): labels on container; `exposedByDefault: true` default — set `false` in production and require `traefik.enable=true` opt-in.
- **Docker Swarm provider** (v3): separate from Docker. Labels under `deploy.labels:` in the compose stanza, **not** at top-level `labels:`. Swarm has no port autodiscovery — `traefik.http.services.<name>.loadbalancer.server.port` is mandatory.
- **Kubernetes IngressRoute** (CRD): `traefik.io/v1alpha1` apiGroup. Native Traefik features (TCP, UDP, advanced middleware refs).
- **Kubernetes Ingress**: standard `networking.k8s.io/v1`. Less expressive — middlewares attached via annotation `traefik.ingress.kubernetes.io/router.middlewares: ns-name@kubernetescrd`.
- **Cross-provider middleware reference**: always namespace by provider — `auth-mw@file`, `cors@kubernetescrd`. Bare names resolve only within the same provider.
- **`providersThrottleDuration`**: default `2s`. All provider events debounced before re-applying. Bursts of container churn during deploy don't thrash routing.
- **Constraints**: `constraints = "Label(`environment`,`production`)"` filters which Docker containers/Swarm services are picked up. Reserved `traefik.*` namespace cannot be used as a constraint key.

## EntryPoints

- **`address`**: `:80`, `:443`, `:443/tcp`, `:443/udp`. Port + optional bind IP + optional protocol.
- **HTTP-to-HTTPS redirection** (no middleware needed):
  ```yaml
  entryPoints:
    web:
      address: :80
      http:
        redirections:
          entryPoint:
            to: websecure
            scheme: https
            permanent: true
  ```
- **HTTP/3** (v3): `entryPoints.websecure.http3: {}`. Requires TLS. Opens UDP on the same port — host firewall must allow it. Old `--experimental.http3` flag removed.
- **`forwardedHeaders.trustedIPs`**: list of CIDRs Traefik trusts to set `X-Forwarded-*`. Without this, behind a load balancer/CDN every client IP appears as the LB. **Never** use `forwardedHeaders.insecure: true` in production.
- **`proxyProtocol.trustedIPs`**: separate from forwardedHeaders. Required when AWS NLB / HAProxy / Cloudflare Spectrum sends PROXY protocol v1/v2.
- **`transport.respondingTimeouts`** defaults: `readTimeout=60s`, `writeTimeout=0` (unlimited), `idleTimeout=180s`. Long-running streaming responses need explicit `writeTimeout`.
- **`asDefault: true`** marks an entryPoint as a router default; routers without explicit `entryPoints:` attach only to defaults. v3 feature.

## ACME / Let's Encrypt

The most common production failure mode. Reference: `reference/install-configuration/tls/certificate-resolvers/acme/`.

- **Three challenge types**:
  - **HTTP-01**: `httpChallenge.entryPoint: web`. Port **80 must be reachable from public internet**. Cannot get wildcard certs.
  - **TLS-ALPN-01**: `tlsChallenge: {}`. Port **443 must be reachable**. Cannot get wildcard certs.
  - **DNS-01**: `dnsChallenge.provider: cloudflare` (or 100+ others). **Only method that supports wildcards** (`*.example.com`). Requires API credentials in env vars per provider.
- **`acme.json` storage file**: must be `chmod 600`. Traefik **refuses to start** otherwise. On Docker mount: `chmod 600` on the host file before `docker run`. Common error: `permissions ... are too open, expected 600`.
- **Staging server for testing**: `caServer: https://acme-staging-v02.api.letsencrypt.org/directory`. Use during all dev/CI work — production LE limits are aggressive.
- **LE rate limits**: 50 certs per registered domain per week, 5 duplicate certs/week, 5 failed validations/account/hostname/hour. Hitting them locks you out for 168h. Always test with staging first.
- **Cert renewal**: Traefik auto-renews 30 days before expiry (LE issues 90-day certs). Renewal happens at startup and on a periodic timer.
- **DNS-01 propagation**: `dnsChallenge.delayBeforeCheck: 60s` — wait this long before asking the resolver. `dnsChallenge.disablePropagationCheck: true` skips Traefik's own pre-check. `dnsChallenge.resolvers: ["1.1.1.1:53"]` overrides the system resolver (essential when split-horizon DNS hides the public record).
- **Multi-instance HA**: Traefik 2+ has no native lock on `acme.json`. Running multiple replicas with the same certResolver corrupts the file. Either run one Traefik replica with `acme.json` on shared storage, or use cert-manager + a separate `tls.certificates` source. Coolify deploys a single Traefik so this is moot there.
- **`certResolver` per router**: `traefik.http.routers.<name>.tls.certResolver=letsencrypt`. Without this the router will use locally-mounted certs in `tls.certificates` and **not** request from ACME.
- **Domain list**: certs by default cover the host(s) from the router's `Host()` rule. Override with `tls.domains[].main` and `tls.domains[].sans` for SAN coverage.

## Routers, middlewares, services pipeline

Each request: matched by **router** (rule + entryPoint + priority) → passes through ordered **middlewares** → forwarded to a **service** (load balancer).

- **Rule matchers**: `Host()`, `HostRegexp()`, `Path()`, `PathPrefix()`, `PathRegexp()` (v3), `Header()`, `HeaderRegexp()`, `ClientIP()`, `Method()`, `Query()`, `QueryRegexp()`. Combine with `&&`, `||`, `!`. Backticks delimit values: `Host(`api.example.com`)`.
- **Priority**: default = rule length. Longer rule wins, deterministically. Override with explicit `priority: 100`. `priority: 0` is ignored (= use length default).
- **Common pitfall**: `Host(`api.example.com`) && PathPrefix(`/v1`)` (rule length 49) loses to `Host(`api.example.com`) && PathPrefix(`/v1/users`)` (length 56) — longer wins. Test with the dashboard's `Routers` view sorted by computed priority.
- **Trailing-slash mismatch**: `PathPrefix(`/api/`)` matches `/api/foo` but **not** `/api`. `PathPrefix(`/api`)` matches both. Pair with `StripPrefix` only if backend expects no prefix.
- **Regex YAML/label escaping**: `PathRegexp(`^/v[0-9]+`)` in YAML is fine; in a Docker label, the surrounding double-quote rules require: `traefik.http.routers.api.rule=PathRegexp(\`^/v[0-9]+\`)` — backticks survive shell, but interpolating shells (Compose `${VAR}`) eat them. Single-quote the entire value in compose to preserve backticks.

## Middlewares: order matters

Middleware chain executes **left-to-right** as written. Order changes behavior in load-bearing ways.

- **Recommended order**: `ipallowlist → ratelimit → forwardauth/basicauth → headers (CORS, HSTS) → stripprefix → compress`. Auth before stripprefix so the auth service sees the original path; compress last so it sees the final body.
- **`ratelimit`**: `average=100`, `burst=200`, `period=1s` (default). `sourceCriterion` defaults to **client remote address**. Behind a CDN/LB, must set `sourceCriterion.ipStrategy.depth=1` (or higher) or `requestHeaderName: X-Real-IP`, otherwise every request appears to come from the LB and one client can DoS the global limit.
- **`headers`** for CORS:
  - `accessControlAllowOriginList: ["https://app.example.com"]` — exact origins
  - `accessControlAllowOriginListRegex: ["^https://[a-z]+\\.example\\.com$"]` — regex (note `\\.` for YAML escape)
  - `accessControlMaxAge: 100` (seconds)
  - Preflight `OPTIONS` is answered by Traefik; no need to handle it in the backend.
- **`headers` HSTS**: `stsSeconds: 31536000`, `stsIncludeSubdomains: true`, `stsPreload: true`. Don't set on `*.local` / staging — browsers cache for the full year.
- **`forwardauth`**: `address: http://auth:4181`. Sends a sub-request to `address`; 2xx response = authorized. `authResponseHeaders: [X-Forwarded-User]` copies headers from auth response onto the upstream request. `trustForwardHeader: true` is needed when Traefik sits behind another proxy, otherwise the downstream auth sees Traefik's IP.
- **`ipallowlist`** (v3) / `ipwhitelist` (v2): `sourceRange: ["10.0.0.0/8", "192.168.1.0/24"]`. `ipStrategy.depth=N` reads the Nth-from-right entry of `X-Forwarded-For` — **must** be set behind a proxy or you allowlist the proxy's IP, not the client.
- **`circuitbreaker`**: expression syntax — `NetworkErrorRatio() > 0.5`, `ResponseCodeRatio(500, 600, 0, 600) > 0.5`, `LatencyAtQuantileMS(50.0) > 100`. Combine with `&&`, `||`. `checkPeriod` (10s) and `fallbackDuration` (10s) tune recovery.
- **`retry`**: `attempts: 3`, `initialInterval: 100ms` (exponential backoff). Retries are silent — the client sees only the final response. Beware retrying non-idempotent POSTs.
- **`buffering`**: `maxRequestBodyBytes`, `memRequestBodyBytes`. Unbounded by default; setting these caps prevents request-size DoS. `retryExpression: IsNetworkError() && Attempts() < 2` enables retry on body buffering.
- **`compress`**: `excludedContentTypes: ["text/event-stream"]` is essential — gzipping SSE/WebSocket streams breaks them.
- **`redirectScheme`**: `scheme: https`, `permanent: true`. Use this **at the entryPoint redirection level** (see EntryPoints section) instead of per-router middleware when redirecting all of port 80 to 443 — saves a config round-trip.

## Services, TLS options, mTLS

**Service / load balancer**:
- **`healthCheck`**: `path: /healthz`, `interval: 30s`, `timeout: 5s`, `scheme: http`, `hostname: backend.local`, `port: 8080`. 2xx-3xx = healthy. **Without an explicit healthCheck Traefik does not probe** — it just routes and gets connection errors. Always configure one for production.
- **`sticky.cookie`**: `name` (default = sha1 hash like `_1d52e`), `secure: true`, `httpOnly: true`, `sameSite: lax`. Required for stateful backends without shared session storage.
- **Strategies** (per loadBalancer): `wrr` (default, weighted round-robin), `p2c` (power-of-two-choices, least-connections), `hrw` (consistent hash on client IP), `leasttime`. Set via `loadBalancer.strategy`.
- **`passHostHeader: true`** is the default — backends see the original `Host:` header. Set `false` only when backend expects its own internal hostname.
- **`serversTransport`** (HTTP) / **`tcpServersTransport`** (TCP): per-service TLS/dial config. `insecureSkipVerify: true` for self-signed backends; `rootCAs: [/ca.pem]` for private CA backends.

**TLS options** (`tls/options/`, `default` applies when none specified):
- **`minVersion`**: default `VersionTLS12`. Set `VersionTLS13` for new deployments. PCI-DSS requires >= TLS 1.2.
- **`cipherSuites`**: only configurable for TLS 1.2 and below; TLS 1.3 suites are fixed by Go stdlib.
- **`sniStrict: true`**: rejects connections with no SNI or mismatched SNI/cert. Breaks legacy IoT clients but mandatory for multi-tenant TLS.
- **mTLS**: `clientAuth.clientAuthType: RequireAndVerifyClientCert`, `clientAuth.caFiles: [/certs/ca.pem]`. Five modes: `NoClientCert`, `RequestClientCert`, `RequireAnyClientCert`, `VerifyClientCertIfGiven`, `RequireAndVerifyClientCert`.
- **`alpnProtocols`**: default `["h2", "http/1.1", "acme-tls/1"]`. Removing `acme-tls/1` breaks TLS-ALPN-01 challenge.
- **`preferServerCipherSuites`**: removed in v3 — now always defers to client preference.
- **`TLSStore`**: only `default` is meaningful. Default certificates served when SNI doesn't match any router's TLS config. Set with `tls.stores.default.defaultCertificate.certFile/keyFile`.

## Provider syntax (Docker, Swarm, Kubernetes, TCP)

**Docker labels** (standalone Docker provider):
- Minimal HTTP service requires:
  ```
  traefik.enable=true
  traefik.http.routers.<name>.rule=Host(`app.example.com`)
  traefik.http.routers.<name>.entrypoints=websecure
  traefik.http.routers.<name>.tls=true
  traefik.http.routers.<name>.tls.certresolver=letsencrypt
  traefik.http.services.<name>.loadbalancer.server.port=8080
  ```
- **Multiple Docker networks**: when a container is on >1 network, Traefik picks one non-deterministically and may pick the wrong one (`502` or no route). Fix: `traefik.docker.network=traefik-public` on the container, or provider-wide `providers.docker.network` / env `TRAEFIK_PROVIDERS_DOCKER_NETWORK`.
- **Compose backtick interpolation**: backticks in rule values get eaten by shell/`${VAR}` expansion. Single-quote the full label: `- 'traefik.http.routers.api.rule=Host(`api.example.com`)'`.
- **`exposedByDefault=false`** in production: forces opt-in via `traefik.enable=true`. Prevents accidental routing to sidecars/admin containers.

**Docker Swarm provider** (separate from Docker in v3):
- Labels under `deploy.labels:` in compose, **not** top-level `labels:` (those label the container, not the service).
- No port autodetection — `traefik.http.services.<name>.loadbalancer.server.port` is mandatory.

**Kubernetes IngressRoute CRD** (`traefik.io/v1alpha1`):
- Supports TCP, UDP, full Traefik middleware features, multi-layered routing via `parentRefs`. Standard Ingress is portable but limited.
- **Middleware reference**: `middlewares: - name: my-mw - namespace: default`. Cross-namespace requires `providers.kubernetesCRD.allowCrossNamespace: true`.
- **`IngressRouteTCP`**: routes on raw TCP. **`HostSNI` is mandatory** when TLS is used. For non-TLS catch-all use `HostSNI(`*`)`. `HostSNIRegexp` and `ClientIP` are alternatives. `tls.passthrough: true` forwards encrypted bytes unmodified (backend terminates).
- **`IngressRouteUDP`**: stateless, no rule matchers — only entryPoints + services.
- **`ServersTransport` CRD**: sets `insecureSkipVerify`, `serverName`, `rootCAsSecrets`, `certificatesSecrets` for upstream. Reference from service via `serversTransport`.
- **`TLSStore` CRD**: only `default` is honored.
- **`TLSOption` CRD**: per-router TLS settings.

**TCP routers** (across providers):
- Without TLS the router cannot match `HostSNI` (no handshake). `HostSNI(`*`)` is the non-TLS catch-all.
- Mixing HTTP and TCP on the same port not supported — separate entryPoints.

## Observability and plugins (v3)

**Tracing — OTLP only**:
```yaml
tracing:
  otlp:
    http:
      endpoint: http://otel-collector:4318/v1/traces
    # OR: grpc: { endpoint: "otel-collector:4317" }
  sampleRate: 0.1
```
- **`sampleRate`** uses `ParentBased(TraceIDRatioBased)` — root span sampled at the rate, children inherit. `1.0` traces everything (expensive at scale).
- **Auto resource attributes**: in Kubernetes, Traefik captures pod name/namespace/UID. Override via `OTEL_RESOURCE_ATTRIBUTES` env or static `tracing.resourceAttributes`.

**Metrics**: Prometheus (`metrics.prometheus`), Datadog StatsD (`metrics.datadog`), InfluxDB v2, OTLP. v3 dropped InfluxDB v1.
- **Internal observability**: routers/services for the API/dashboard/ping are **not** observed by default. Enable with `metrics.<backend>.addInternals: true` and `tracing.addInternals: true`.

**Access log**: `accesslog.format: json` (or `common`). `accesslog.fields.headers.defaultMode: keep` logs all headers (huge — usually whitelist via `fields.headers.names`).

**Plugins** (Pilot replacement):
```yaml
experimental:
  plugins:
    myplugin:
      moduleName: github.com/owner/plugin
      version: v1.2.3
```
- Pulled from GitHub by Go module path; requires non-air-gapped startup.
- **Local plugins**: `experimental.localPlugins.<name>.moduleName` + source at `/plugins-local/src/<moduleName>/`.

## Common pitfalls (operational)

- **`acme.json` mode 0644**: Traefik refuses start with `permissions ... too open`. `chmod 600` and re-mount.
- **Port 80/443 already in use**: when running Traefik on host network and Apache/nginx is also bound. `lsof -i :80` to find culprit.
- **CDN in front of Traefik, ratelimit hitting global**: missing `ipStrategy.depth=1` (or 2 for nested CDN). Every request appears from the CDN IP.
- **Cloudflare's `CF-Connecting-IP` not honored**: Traefik only knows `X-Forwarded-For`. Use `headers` middleware to copy `CF-Connecting-IP` to `X-Real-IP`, or trust Cloudflare's IPs in `forwardedHeaders.trustedIPs`.
- **Coolify**: when `acme.json` errors appear in `coolify-proxy` logs, the file is at `/data/coolify/proxy/acme.json` on the host. `ls -la` it. Permission resets on `chown -R coolify:coolify /data/coolify` are common.
- **Router not appearing in dashboard**: check the dashboard's Providers tab — provider parse errors show there but not in main logs unless `log.level: DEBUG`. `traefik validate` (v3) statically lints config files.
- **Multiple `defaultCertificate` definitions**: only one wins, silently. Keep `tls.stores.default` in a single file.

## Authoritative references

**Official Traefik v3 docs** (`doc.traefik.io/traefik/`):
- [Migrate v2 to v3 (overview)](https://doc.traefik.io/traefik/migrate/v2-to-v3/)
- [Migrate v2 to v3 (details)](https://doc.traefik.io/traefik/migrate/v2-to-v3-details/)
- [Routing rules and priority](https://doc.traefik.io/traefik/reference/routing-configuration/http/routing/rules-and-priority/)
- [ACME certificate resolvers](https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/)
- [Docker provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/)
- [Swarm provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/swarm/)
- [File provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/)
- [EntryPoints](https://doc.traefik.io/traefik/reference/install-configuration/entrypoints/)
- [HTTP middlewares overview](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/overview/)
- [RateLimit middleware](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/ratelimit/)
- [Headers middleware](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/)
- [Service / load-balancing](https://doc.traefik.io/traefik/reference/routing-configuration/http/load-balancing/service/)
- [Kubernetes IngressRoute CRD](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/ingressroute/)
- [Tracing (OTLP)](https://doc.traefik.io/traefik/reference/install-configuration/observability/tracing/)
- [TLS options](https://doc.traefik.io/traefik/reference/routing-configuration/http/tls/tls-options/)

**GitHub source**:
- [traefik/traefik releases & CHANGELOG](https://github.com/traefik/traefik/releases)
- [v2-to-v3 path-prefix regex breaking issue](https://github.com/traefik/traefik/issues/10672)

**Operational write-ups**:
- [Traefik Labs blog — Proxy 3.0 + OTel](https://traefik.io/blog/monitor-your-production-at-a-glance-with-traefik-3-0-and-opentelemetry)
- [Traefik Labs blog — 3.0 scope](https://traefik.io/blog/traefik-proxy-3-0-scope-beta-program-and-the-first-feature-drop)
- [lrvt.de — IPStrategy with CDNs](https://blog.lrvt.de/solving-traefiks-ipstrategy-dilemma-while-using-cdns/)

## Guardrails

Before recommending a non-trivial Traefik change (provider switch, ACME tweak, middleware reorder, TLS option):
1. Quote the exact label key, CRD field, or static-config path
2. State whether the syntax is v2 or v3 (and whether it survives `defaultRuleSyntax: v2` compat mode)
3. Cite the specific `doc.traefik.io` page
4. Make config changes conditional on observed symptoms — don't blanket-tune

**Checking for v2 vs v3** is the single highest-value question to ask before any Traefik recommendation. Wrong-version syntax is the modal failure mode.
