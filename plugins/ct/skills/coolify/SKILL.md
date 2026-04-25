---
name: coolify
description: >
  Deep Coolify operational intuition — control-plane vs destination split, build-pack
  detection (Nixpacks/Dockerfile/Compose/Static), env-var build/runtime/precedence,
  Traefik label generation, magic SERVICE_* variables, deploy webhooks, preview
  deployments, persistent storage layout, database backups (pg_dump/-Fc),
  upgrade/downgrade via install.sh, rolling-update prerequisites.
  Load ONLY when the task is about diagnosing a Coolify deployment, env-var or
  webhook misbehavior, proxy/Traefik label issues, multi-server destination setup,
  database backup/restore, or upgrade/rollback. Do NOT load for generic Docker /
  docker-compose questions, generic Traefik tuning, or "what is a PaaS" — those
  don't need this skill.
  Triggers on: "coolify deploy stuck", "coolify webhook", "coolify traefik labels",
  "coolify FQDN", "coolify env var not applied", "preview deployment", "magic
  variable SERVICE_FQDN", "coolify backup s3", "coolify upgrade", "coolify rollback",
  "rolling update not triggering", "coolify proxy port 80 conflict",
  "Cloudflare Tunnel coolify", "destination not validated", "Sentinel agent",
  "Nixpacks detection", "build vs runtime variable".
---

# Coolify Operational Guide

Concise operational pointers for Coolify v4 self-hosted PaaS troubleshooting and tuning.

Assumes you already know Docker, docker-compose, Traefik basics, and Postgres basics. This skill covers the **Coolify-specific layer** — the parts models tend to gloss over or hallucinate: the control-plane/destination split, build-pack quirks, env-var precedence, magic `SERVICE_*` vars, Traefik label generation, deploy-webhook semantics, persistent-storage layout, and the upgrade/rollback path.

## When to use

Load when the question is about:
- Control plane vs destination (multi-server, agent install, validated/reachable state)
- Build-pack pick (Nixpacks vs Dockerfile vs Compose vs Static) and per-pack env injection
- Environment variables: build- vs runtime-flag, secrets, magic `SERVICE_*` generation, shared-variable scopes
- Deploy webhooks and the `/api/v1/deploy` endpoint (`force`, `pr`, `tag`, `uuid`)
- Preview deployments (GitHub App vs webhook, scoped secrets, `{{pr_id}}`/`{{random}}`)
- Traefik integration: auto-labels, read-only mode, www/non-www redirects, proxy switch (Traefik ↔ Caddy)
- Persistent storage layout under `/data/coolify/` and Compose `is_directory:` / `content:` sugar
- Database backups (cron + S3) and Postgres restore (`-Fc` vs plain on cross-version upgrade)
- Upgrade / downgrade via `install.sh -s <version>`, auto-update toggle, instance restore (`APP_KEY`, `APP_PREVIOUS_KEYS`)
- Rolling-update prerequisites and why redeploys recreate

**Do NOT load** for: writing `Dockerfile`s, vanilla `docker-compose.yml` syntax, generic Traefik routing, generic CI/CD pipeline design — those don't need this skill.

## Architecture: control plane vs destinations

- **Control plane** = the Coolify host. Owns the UI, the encrypted DB, SSH keys, scheduling, and on the same host runs the proxy (`coolify-proxy` Traefik container by default).
- **Destination** = any Linux host (incl. the control plane itself) where resources actually run. Reached **via SSH from the control plane** using a Coolify-managed key whose public half lives in the destination's `root@~/.ssh/authorized_keys`. Docker Engine 24+ required on every destination ([server prerequisites](https://coolify.io/docs/knowledge-base/server)).
- **Each destination runs its own proxy.** Traffic for an app on a non-control-plane destination goes **directly** to that host — DNS for that app must resolve to the destination IP, **not** the control plane ([multi-server architecture](https://coolify.io/docs/knowledge-base/server)).
- **"Reachable" vs "Validated"**: reachable = SSH+Docker handshake succeeded once; validated = full host check (sudo, Docker socket, OS info) passed. A reachable-but-not-validated server will refuse new resources.
- **Application vs Service**: an *application* is a git source that Coolify builds (Nixpacks/Dockerfile/Compose/Static); a *service* is a one-click template (e.g. Plausible, MinIO, Appwrite) defined by an upstream `docker-compose.yml` Coolify renders. Different UI tabs, different env-var handling rules.
- **Sentinel** is a separate lightweight container Coolify deploys per server when the metrics toggle is on — collects host CPU/RAM and per-container CPU/RAM. Marked **experimental** in the docs; metrics collection is not supported for Compose / Service-template resources ([Sentinel docs](https://coolify.io/docs/knowledge-base/server/sentinel)).

## Build packs

Coolify ships exactly **four** build packs ([overview](https://coolify.io/docs/applications/build-packs/overview)):

- **Nixpacks** (default for git source): auto-detects framework, generates a Dockerfile under the hood. Honors `nixpacks.toml`/`nixpacks.json` at repo root for install/build/start command overrides. Build args injected from Coolify env-vars marked "Build Variable."
- **Dockerfile**: uses your `Dockerfile` from the repo. Build args auto-injected by default — disable in *Advanced* if you want to manage `ARG`s manually. Network-port field must match the port the container actually `LISTEN`s on (`0.0.0.0`, not `127.0.0.1`); mismatch yields a Traefik *No available server* error ([Dockerfile pack](https://coolify.io/docs/applications/build-packs/dockerfile)).
- **Docker Compose**: your `docker-compose.yml` is the **source of truth** for env, ports, volumes, healthchecks. **Remove any user-defined `networks:`** — Coolify injects its own bridge for Traefik routing; custom networks cause intermittent 502s ([compose pack](https://coolify.io/docs/applications/build-packs/docker-compose)). Rolling updates **not supported** with Compose (static container names — see "Deployments" below).
- **Static**: takes pre-built artifacts and serves them via embedded **Nginx** (only option since beta.402). Set the *Base directory* to the build-output folder (`/dist`, `/out`, `/build`). Custom Nginx config via the *Generate* button + edit ([static pack](https://coolify.io/docs/applications/build-packs/static)).

## Environment variables

- **Two independent flags per variable**: *Build Variable* (passed as `ARG` / build-arg / `--env-file` to BuildKit) and *Runtime Variable* (written to a `.env` file at deploy and loaded by `docker compose --env-file`). Both default on. Disable build to keep secrets out of image layers ([env vars](https://coolify.io/docs/knowledge-base/environment-variables)).
- **Build secrets** use Docker BuildKit (Docker 18.09+). Secrets are **never** embedded in image layers and are not visible in `docker history` — use this in preference to `--build-arg` for tokens.
- **Literal flag** stops shell interpolation — required for values containing `$`, e.g. `P@ss$word123`.
- **Predefined**: `COOLIFY_FQDN`, `COOLIFY_URL`, `COOLIFY_BRANCH`, `COOLIFY_RESOURCE_UUID`, `COOLIFY_CONTAINER_NAME`, plus `SOURCE_COMMIT`, `PORT`, `HOST`. Available at runtime in every container.
- **Shared scopes** (template-resolved at deploy): `{{team.VAR}}`, `{{project.VAR}}`, `{{environment.VAR}}`. Resource-level wins over scoped — set the override on the resource, not by editing the team scope.
- **Magic generators** — Compose only — pattern `SERVICE_<TYPE>_<IDENTIFIER>` ([compose docs](https://coolify.io/docs/knowledge-base/docker/compose)):
  - `SERVICE_FQDN_<NAME>` — full host (e.g. `api-x9fk2.example.com`)
  - `SERVICE_URL_<NAME>_<PORT>` — full URL with optional path-prefix routing
  - `SERVICE_PASSWORD_<NAME>` / `SERVICE_PASSWORD_64_<NAME>` — generated, persisted, reused across redeploys
  - `SERVICE_USER_<NAME>` — random 16-char string
  - `SERVICE_BASE64_<NAME>` — random base64
  - First reference *creates and persists* the value; subsequent references in the same compose return the same value.
- **Pitfall**: changing an env var does **not** auto-redeploy. Click *Restart* (runtime-only var) or *Redeploy* (build var or Dockerfile-built app, where Coolify still triggers full rebuild — known behavior, [issue #2745](https://github.com/coollabsio/coolify/issues/2745)).

## Deployments

- **Git webhook**: GitHub (App or webhook), GitLab, Gitea, Bitbucket. With the GitHub App, PR events drive *preview* deployments; secret is generated and verified server-side. With raw webhook, you set the secret yourself ([CI/CD docs](https://coolify.io/docs/applications/ci-cd)).
- **Preview deployments**: GitHub App only for full PR-comment integration. Each preview gets a URL templated by `{{random}}` (random subdomain) or `{{pr_id}}` (PR number) — **wildcard DNS required**. Preview env-vars are a **separate scope** from production — production secrets do **not** leak to PR builds. Auto-cleaned on PR close/merge ([preview-deploy](https://coolify.io/docs/applications/ci-cd/github/preview-deploy)).
- **Manual / API deploy**: `POST /api/v1/deploy` with bearer token (Keys & Tokens → API tokens). Query params: `uuid` (CSV), `tag` (CSV), `force=true|false` (skip build cache), `pr` / `pull_request_id` (preview), `docker_tag` (preview only). `pr` is mutually exclusive with `tag` ([deploy endpoint](https://coolify.io/docs/api-reference/api/operations/deploy-by-tag-or-uuid)).
- **API access** must be **enabled** in Settings → Configuration → Advanced before any token will work.
- **Restart vs Redeploy**: *Redeploy* always rebuilds the image. *Restart* should only restart the container, but **any config change (incl. env var) promotes Restart to a full rebuild** ([discussion #2935](https://github.com/coollabsio/coolify/discussions/2935)). Compose deployments hide the Restart button entirely.
- **Rolling updates** require all four to be true ([rolling-updates](https://coolify.io/docs/knowledge-base/rolling-updates)): valid healthcheck passing, **default** container naming (no custom name), **not** Docker Compose, **no host port mapping**. Miss any → Coolify falls back to stop-then-start, with downtime.
- **Health checks**: configure path / expected status / interval in UI **or** Docker `HEALTHCHECK` instruction. Container needs `curl` or `wget` — Alpine images often need `apk add --no-cache curl` for the UI mode to work. Compose-pack services must use the compose-file `healthcheck:` attribute. Set `exclude_from_hc: true` on one-shot migration services ([health checks](https://coolify.io/docs/knowledge-base/health-checks)).
- **Failed healthcheck blocks the deploy** — Traefik returns 404 / *No available server* until it passes.

## Traefik integration

Coolify ships Traefik as the default proxy on the control plane and on every destination ([proxy overview](https://coolify.io/docs/knowledge-base/proxy/traefik/overview)). Caddy is supported but marked **experimental** ([supported proxies](https://coolify.io/docs/knowledge-base/server/proxies)).

- **Auto-labels** are written by Coolify into each container's labels: router rule (`Host()`), entry-points, TLS resolver (`letsencrypt`), service loadbalancer port. *Read-only labels* mode (default) means the UI controls them — your custom labels merge on top via the *Container Labels* field.
- **Switching proxy** (Traefik ↔ Caddy) is supported since beta.237. Pre-237 resources need the new label set: hit *Reset to Coolify Default Labels* (apps) or save the service, then restart.
- **FQDN protocol matters**: enter `https://app.example.com` and Coolify auto-issues a Let's Encrypt cert; enter `http://...` and **no TLS** is requested — useful when sitting behind another proxy that terminates TLS ([domains](https://coolify.io/docs/knowledge-base/domains)). Multiple domains: comma-separated. Path-based routing supported (`https://example.com/api`).
- **DNS pre-validation**: since beta.191 Coolify pre-checks domain DNS via `1.1.1.1` (override in Settings → Advanced). A misconfigured DNS will fail the *Check DNS* step **before** any cert request.
- **Let's Encrypt rate limit**: 50 certs/registered-domain/week (LE limit, not Coolify's). Repeated failed cert requests during DNS troubleshooting can blow this — Coolify falls back to a self-signed cert on issuance failure (browser warning).
- **www / non-www redirect**: with read-only labels enabled, the *Direction* dropdown gives *Allow both / Redirect to www / Redirect to non-www*. Both URLs must be in the FQDN field. Manual: `redirectregex` middleware in custom labels ([redirects](https://coolify.io/docs/knowledge-base/proxy/traefik/redirects)).
- **Port-80/443 conflict**: `coolify-proxy` *will not start* if 80/443 is occupied — even if you've configured the proxy to listen on different ports ([issue #6234](https://github.com/coollabsio/coolify/issues/6234)). To run Coolify behind another reverse proxy, edit `/data/coolify/proxy/docker-compose.yml`, change host ports to e.g. 5080/5443, restart, and set FQDNs as `http://...` (let the outer proxy do TLS).
- **Cloudflare Tunnel**: tunnels deliver HTTP at the edge, so the FQDN→TLS handshake at Coolify must be `http://` — using `https://` causes loops. For TCP services (SSH, raw TCP databases) the cloudflared connector must run with `network_mode: host` or be deployed as a separate TCP-mode application ([Cloudflare tunnels](https://coolify.io/docs/integrations/cloudflare/tunnels/overview)).

## Persistent storage

- **All Coolify state lives under `/data/coolify/` on the destination host** — applications, databases, ssh keys, proxy config, backups ([backup/restore](https://coolify.io/docs/knowledge-base/how-to/backup-restore-coolify)).
- **Application volumes** default to bind mounts under `/data/coolify/applications/<uuid>/`. The *Storages* tab in the UI is the source of truth — adding a volume there modifies the generated compose.
- **Compose-pack volumes**: declare in your `docker-compose.yml`. Coolify-specific sugar:
  - `is_directory: true` — pre-create as a directory, not a file (default behavior is "guess from path")
  - `content: |` — inline file content, supports `${VAR}` interpolation. Useful for config files generated at deploy time.
- **Named Docker volumes work**, but bind mounts are easier to back up. Both survive container recreation.
- **Pitfall**: deleting a service in the UI used to remove its bind-mount data; beta.474 ([release notes](https://github.com/coollabsio/coolify/releases)) added a guard against accidental data loss when persistent containers are pruned. On older versions, **export volumes manually** before delete.

## Databases (Postgres / MySQL / MariaDB / MongoDB / Redis / KeyDB / Dragonfly / Clickhouse)

- **Backups are per-DB**, configured via cron expression + S3-compatible destination (AWS S3, R2, B2, Wasabi, MinIO) ([backups](https://coolify.io/docs/databases/backups)).
- **Tooling per DB**: Postgres → `pg_dump -Fc` (custom format); MySQL → `mysqldump`; MariaDB → `mariadb-dump`; MongoDB → `mongodump --gzip`. Redis/KeyDB/Dragonfly use their respective dumpers; Clickhouse uses backup tables.
- **Restore Postgres**: drop the dump file in *Configuration → Import Backups* (file upload or drag-drop). Default import command is `pg_restore` — only valid for `-Fc` files. **For cross-version upgrades** (e.g. PG 14 → PG 16), `-Fc` is fragile — use plain or tar format on dump and switch the import command to `psql` ([Postgres docs](https://coolify.io/docs/databases/postgresql)).
- **Default volume** lives at `/data/coolify/databases/<uuid>/` on the destination — back this up at the filesystem level if you need consistency-with-WAL recovery rather than logical dump.
- **Each DB type's UI has different fields** — Postgres exposes `POSTGRES_USER/PASSWORD/DB`, Mongo exposes `MONGO_INITDB_ROOT_USERNAME/PASSWORD`. Don't assume parity.

## Upgrades and instance recovery

- **Three modes** ([upgrade docs](https://coolify.io/docs/get-started/upgrade)):
  - *Auto-update*: control plane checks `cdn.coollabs.io` periodically and self-installs new versions
  - *Semi-automatic*: notification only, Upgrade button in sidebar
  - *Manual*: SSH + `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash` (no version → latest)
- **Pin a version** (or downgrade): `... | bash -s 4.0.0-beta.<N>`. Disable auto-update **first** or you'll be re-upgraded next cycle ([downgrade](https://coolify.io/docs/get-started/downgrade)).
- **Downgrade caveats**: schema migrations are forward-only — a downgrade across a migration boundary will fail to boot. Always back up the Coolify DB *before* upgrading so you can restore the matching schema if you need to roll back.
- **Instance restore**: requires the `APP_KEY` from `/data/coolify/source/.env` (encrypts secrets at rest), the SSH keys at `/data/coolify/ssh/keys/` (or your destinations become unreachable), and the Postgres backup of the Coolify DB. Set `APP_PREVIOUS_KEYS=<old_key>` in the new install's `.env` to decrypt secrets encrypted under the old key. Without all three you'll hit decryption or SSH auth errors ([instance backup/restore](https://coolify.io/docs/knowledge-base/how-to/backup-restore-coolify)).
- **Server Patching** is OS-level (`apt`/`dnf`/`zypper`) — manual click only, never auto-applies. Docker package updates **restart Docker**, briefly killing every container including Coolify itself ([server patching](https://coolify.io/docs/knowledge-base/server/patching)).
- **Docker Swarm** support is **deprecated** as of beta.474 — slated for removal in v5.

## API and CLI

- **API**: REST under `/api/v1`, bearer-token auth (Keys & Tokens → API tokens). Must enable *API Access* in Settings → Configuration → Advanced first. Resources exposed: applications, services, servers, deployments, projects, teams, environment variables, private keys, databases.
- **`coolify-cli`**: separate Go binary, installable via `brew install coollabsio/coolify-cli/coolify-cli` or `go install github.com/coollabsio/coolify-cli/coolify@latest` ([repo](https://github.com/coollabsio/coolify-cli)). Multi-context (cloud + multiple self-hosted in one config). Authenticate with `coolify context add` (self-hosted) / `coolify context set-token cloud <token>`. Same surface as the API — apps, services, servers, deployments, env vars, GitHub Apps.

## Common pitfalls (cross-cutting)

- **Env var saved but not in container**: it was saved as build-only or runtime-only and the wrong layer was reloaded. Confirm both flags. After save, manually trigger Restart/Redeploy — there's **no implicit deploy**.
- **`restart: always` in your compose** combined with rolling-update conditions: rolling update needs to spawn a sibling, but a host-port mapping in the compose blocks it. Drop the host port and let Traefik do the routing.
- **Custom networks in compose**: remove them. Coolify needs to attach its own bridge for Traefik label discovery — your custom net leaves the container off the proxy network and Traefik returns 502.
- **Cert request loops** while iterating on DNS: each failed attempt counts toward the LE 50/week limit. Toggle FQDN to `http://` while debugging DNS, switch back to `https://` once `1.1.1.1` resolves correctly.
- **Container-name customization breaks rolling updates** — the rolling logic spawns `<name>-new`. If you renamed via compose `container_name:`, the rename collides.
- **Multi-server: app deployed but DNS still points at control plane** → traffic 404s. Move DNS to the destination's IP. Coolify does **not** front non-control-plane traffic.
- **`force=false` on deploy still rebuilds** for some pack/state combinations — known [issue #8104](https://github.com/coollabsio/coolify/issues/8104). Don't trust the param to cache reliably; treat any deploy as a potential full rebuild.

## Authoritative references

**Coolify docs** (`coolify.io/docs`):
- [Build Packs overview](https://coolify.io/docs/applications/build-packs/overview) — Nixpacks/Dockerfile/Compose/Static
- [Dockerfile build pack](https://coolify.io/docs/applications/build-packs/dockerfile)
- [Static build pack](https://coolify.io/docs/applications/build-packs/static)
- [Environment Variables](https://coolify.io/docs/knowledge-base/environment-variables) — build/runtime, secrets, `COOLIFY_*`
- [Docker Compose magic vars](https://coolify.io/docs/knowledge-base/docker/compose) — `SERVICE_FQDN_*`, `SERVICE_PASSWORD_*`
- [Domains / FQDN](https://coolify.io/docs/knowledge-base/domains)
- [Traefik proxy overview](https://coolify.io/docs/knowledge-base/proxy/traefik/overview)
- [www/non-www redirects](https://coolify.io/docs/knowledge-base/proxy/traefik/redirects)
- [Health checks](https://coolify.io/docs/knowledge-base/health-checks)
- [Rolling updates](https://coolify.io/docs/knowledge-base/rolling-updates)
- [Sentinel](https://coolify.io/docs/knowledge-base/server/sentinel)
- [Supported proxies](https://coolify.io/docs/knowledge-base/server/proxies)
- [Server Patching](https://coolify.io/docs/knowledge-base/server/patching)
- [Database Backups](https://coolify.io/docs/databases/backups)
- [PostgreSQL service](https://coolify.io/docs/databases/postgresql)
- [Upgrade](https://coolify.io/docs/get-started/upgrade) / [Downgrade](https://coolify.io/docs/get-started/downgrade)
- [Backup & Restore Coolify](https://coolify.io/docs/knowledge-base/how-to/backup-restore-coolify)
- [Cloudflare Tunnels](https://coolify.io/docs/integrations/cloudflare/tunnels/overview)
- [GitHub Preview Deploy](https://coolify.io/docs/applications/ci-cd/github/preview-deploy)
- [Deploy API endpoint](https://coolify.io/docs/api-reference/api/operations/deploy-by-tag-or-uuid)

**Source / release tracking**:
- [coollabsio/coolify Releases](https://github.com/coollabsio/coolify/releases) — beta cadence, breaking changes
- [coollabsio/coolify-cli](https://github.com/coollabsio/coolify-cli) — CLI repo and install methods

## Guardrails

Before recommending a non-trivial change (proxy switch, upgrade across ≥10 betas, DB engine version bump, restore from backup):

1. Quote the specific UI path or API field, not a paraphrase
2. Cite the doc page or a release note that confirms current behavior
3. Make the recommendation conditional on the user's current Coolify version — features land and rename rapidly

**Verify version: Coolify is fast-moving; check the docs/CHANGELOG before recommending any specific UI path or API field.** UI labels, API params (e.g. `force` semantics, [issue #8104](https://github.com/coollabsio/coolify/issues/8104)), and even default packs (Static gained Nginx-only mode at beta.402; Swarm deprecated at beta.474) shift between betas. Anchor every recommendation on a freshly read doc page or release note.
