---
name: docker-buildkit
description: >
  Deep BuildKit operational intuition — frontend syntax pinning, RUN --mount cache/secret/ssh/bind,
  cache export/import backends (registry/gha/s3/local/inline), multi-platform with QEMU vs native nodes,
  buildx drivers, multi-stage cache layout, image hardening (distroless, scratch, nonroot), attestations
  (SBOM, SLSA provenance), buildx bake, GC tuning, rootless caveats.
  Load ONLY when the task is about BuildKit-specific tuning, cache miss diagnosis, multi-platform builds,
  build secrets, registry-backed cache, attestations, or hardening final-stage images.
  Do NOT load for "what is Docker", basic Dockerfile syntax (FROM/COPY/RUN), `docker run`/compose runtime,
  or container orchestration (Kubernetes, Swarm) — those don't need this skill.
  Triggers on: "buildkit cache", "RUN --mount", "build secret", "syntax=docker/dockerfile",
  "cache-to registry", "cache-from gha", "buildx bake", "multi-platform build", "linux/arm64 emulation",
  "QEMU build slow", "COPY --link", "distroless", "nonroot user", "SBOM attestation",
  "SLSA provenance", "buildx prune", "buildx du", "rootless buildkit", "docker-container driver",
  ".dockerignore", "build cache invalidation".
---

# BuildKit Operational Guide

Concise operational pointers for deep Docker BuildKit troubleshooting and tuning.

Assumes you already know Dockerfile basics (FROM/COPY/RUN/CMD). This skill covers the **BuildKit layer** — the parts models gloss over: frontend versioning, mount types, cache backends, multi-platform mechanics, exporters, attestations, hardening final images.

## When to use

Load when the question is about:
- BuildKit cache miss diagnosis / cache export-import backends
- Build-time secret handling (`--mount=type=secret`, SSH agent forwarding)
- Multi-platform builds and QEMU-vs-native tradeoffs
- buildx drivers (`docker`, `docker-container`, `kubernetes`, `remote`) and their feature gaps
- Frontend syntax pinning and labs features
- Final-image hardening (distroless, scratch, nonroot, USER)
- Attestations (SBOM via Syft, SLSA provenance)
- buildx bake (declarative multi-target builds)
- BuildKit garbage collection / disk pressure

**Do NOT load** for: writing a first Dockerfile, `docker run` invocations, docker-compose runtime, image registry auth basics, container orchestration (Kubernetes, Swarm) — those don't need this skill.

## BuildKit vs legacy, and frontend syntax

- **Default since Docker Engine 23.0**: `docker build` is an alias for `docker buildx build` using the `docker` driver. `DOCKER_BUILDKIT=0` re-enables the legacy builder (deprecated; gone on Linux in newer engines).
- **`docker build` ≠ `docker buildx build` exactly**: the alias uses the `docker` driver — no multi-platform output, no cache export beyond `inline`. For those features, you need a `docker-container` builder.
- **Frontend pin (first line of Dockerfile)**: `# syntax=docker/dockerfile:1` (rolling 1.x), `:1.7` (locked to 1.7.x patches), `:1.7.1` (immutable), `:1-labs` (experimental). Without a pin, you get the engine-bundled frontend — older, fewer features.
- **Feature → frontend version map**: `RUN --mount` and `COPY --chmod` need 1.2; `RUN --network` needs 1.3; `COPY --link` / `ADD --link` need 1.4; `RUN --security` and `COPY --parents` need 1.20; `--exclude` for COPY/ADD needs 1.19; `RUN --device` (CDI) needs 1.14-labs. If a flag silently no-ops, your syntax pin is too old.
- **Heredoc** (1.4+): `RUN <<EOF` ... `EOF` works in shell form; useful for multi-line install scripts without `\` continuations.

## RUN --mount: cache, secret, ssh, bind, tmpfs

- **`--mount=type=cache,target=/path`** — persists across builds, scoped by `id` (defaults to `target`). Options: `sharing=shared|locked|private` (default `shared`), `mode=0755`, `uid=0`, `gid=0`, `from=<stage|image>`, `source=<subpath>`, `ro`. Cache is **not** in the final image. Example: `RUN --mount=type=cache,target=/root/.cache/go-build go build`.
- **APT cache pattern**: `RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked rm -f /etc/apt/apt.conf.d/docker-clean && apt-get update && apt-get install -y ...`. Use `sharing=locked` so concurrent builds serialize on the cache.
- **`--mount=type=secret,id=mytoken`** — secret available only during this `RUN`, never written to a layer. Default mount path `/run/secrets/<id>`, default `mode=0400`. Pass via `--secret id=mytoken,src=/path/to/file` or `--secret id=mytoken,env=ENVVAR`. Set `required=true` to fail the build if missing.
- **`--mount=type=ssh,id=default`** — forwards the host SSH agent socket for `git clone git@…` over private repos. Pass via `--ssh default` (uses `$SSH_AUTH_SOCK`) or `--ssh default=/path/to/socket`. Default socket mode `0600`.
- **`--mount=type=bind,from=builder,source=/out,target=/in`** — read-only bind from another stage or context without a `COPY`; use `rw` to allow writes (discarded after the `RUN`). Cheaper than `COPY` when you only need to read.
- **`--mount=type=tmpfs,target=/tmp,size=...`** — in-memory scratch space; not cached, not in the image.
- **`RUN --network=none|host|default`** — hermetic builds use `none` to prove no network dependency. `host` requires the `network.host` entitlement (`--allow network.host`).
- **`RUN --security=insecure`** — privileged build step (e.g., for `mount`, `nsenter`). Requires `--allow security.insecure` and is **not** available with the default `docker` driver.

## Cache: layout, ordering, export/import

- **Multi-stage cache is per-stage**: each `FROM ... AS name` is its own DAG node. Cache invalidation cascades downstream **within** a stage; sibling stages are independent. `--target name` builds only up to that stage.
- **Layer ordering rule**: install deps (slow, rarely-changing) **before** copying source (fast, frequently-changing). Copy lock-files alone first (`COPY package.json package-lock.json ./`), install, then `COPY . .` — keeps the install layer cached when only source changes.
- **`.dockerignore` is critical**: without it `COPY . .` ships `.git`, `node_modules`, `dist`, `.env*`, IDE files into the build context. Every modified file invalidates the COPY layer's content hash. Always add at least: `.git`, `node_modules`, `dist`, `build`, `.env*`, `**/*.log`.
- **`COPY --link`** (frontend 1.4+): copies become independent layers, decoupled from the base layer's digest. If only the base image rebuilds, downstream `COPY --link` layers are reused. Default `COPY` rebuilds when the base layer changes. Use `--link` for any `COPY` that doesn't depend on the prior filesystem state.
- **`COPY --chown=user:group --chmod=0755`**: avoid a follow-up `RUN chown ...` layer that bloats the image.
- **Cache backends** (require `docker-container` driver — the default `docker` driver only supports `inline`):
  - `--cache-to=type=registry,ref=myrepo/img:cache,mode=max` — stored as a separate manifest; `mode=min` (default) only caches layers in the final image, `mode=max` caches all intermediate stages too.
  - `--cache-to=type=local,dest=/tmp/buildcache,mode=max` — for persistent CI runners with cached volumes.
  - `--cache-to=type=gha,scope=mybuild,mode=max` — GitHub Actions cache (uses `ACTIONS_CACHE_URL` and `ACTIONS_RUNTIME_TOKEN` envs; configure via the `docker/build-push-action` GitHub Action).
  - `--cache-to=type=s3,region=...,bucket=...,name=...,mode=max` — S3-backed (also `azblob` for Azure).
  - `--cache-to=type=inline` — embeds metadata into the pushed image; only `mode=min` semantics; OK for small caches, useless for multi-stage.
- **`--cache-from`** mirrors the same backends, multiple allowed: `--cache-from=type=registry,ref=...,ref=...` to merge caches from main + feature branch.
- **ARG before FROM is global** (only consumed by `FROM` lines); ARG **after** FROM is per-stage and must be re-declared in each stage that uses it. ARG values are visible in `docker history` and provenance — never put secrets in ARG.

## Multi-platform builds

- **`--platform linux/amd64,linux/arm64,linux/arm/v7`** produces a manifest list. Requires a builder with multi-platform support — the default `docker` driver does NOT support this. Use `docker buildx create --driver docker-container --use`.
- **QEMU emulation** (`tonistiigi/binfmt`): registers `binfmt_misc` handlers so the engine can run non-native binaries. Compute-heavy stages (compilation, npm install of native modules) can be **5–20×** slower under emulation.
- **Native multi-node builders**: `docker buildx create --name multi --driver docker-container --node arm-node --platform linux/arm64 ...` then `docker buildx create --append --name multi --node amd-node --platform linux/amd64 ...`. BuildKit dispatches each platform to a node with that native arch — orders of magnitude faster than QEMU.
- **`FROM --platform=$BUILDPLATFORM`** in the build stage + `FROM --platform=$TARGETPLATFORM` in the runtime stage: cross-compile on the host, ship the target binary. `$BUILDPLATFORM` is the builder's arch; `$TARGETPLATFORM` is the requested output. Avoids QEMU for the heavy compile step.
- **Silent emulation gotcha**: building on x86 then `docker run`-ing the resulting image on the **same** x86 host but with a multi-arch image can hit a non-native variant under emulation — check `docker manifest inspect` and `--platform` on `docker run`.

## buildx drivers

| Driver | Multi-platform | Cache export | Notes |
|---|---|---|---|
| `docker` (default) | No | `inline` only | Uses dockerd's bundled BuildKit; least flexible |
| `docker-container` | Yes | All backends | Runs BuildKit in a managed container; required for most non-trivial builds |
| `kubernetes` | Yes | All backends | BuildKit pods in a cluster; for shared CI capacity |
| `remote` | Yes | All backends | Connects to an externally-managed BuildKit daemon |

- **Switch driver**: `docker buildx create --driver docker-container --use` (creates a builder). Inspect with `docker buildx inspect`.
- **Image push vs load**: non-`docker` drivers don't auto-load into the local image store. Use `--load` (uses `docker` exporter) for local single-platform images, `--push` (uses `image` exporter + push) for registries. Multi-platform builds can `--push` but not `--load` (the local image store is single-arch).
- **`--driver-opt`**: `image=moby/buildkit:v0.x` (pin BuildKit version), `network=host`, `env.HTTP_PROXY=...`, `default-load=true`, `cgroup-parent=...`.
- **Rootless**: `docker buildx create --driver docker-container --driver-opt image=moby/buildkit:rootless`. Requires user-namespace setup (`newuidmap`/`newgidmap`, 65k subuids). Limitations: cannot bind ports < 1024, slirp4netns networking, fuse-overlayfs slower than overlay2.

## Exporters and outputs

- **`--push`** = `--output type=image,push=true` with the tag from `-t`.
- **`--load`** = `--output type=docker,dest=-` piped to local image store (single-platform only).
- **`--output type=oci,dest=image.tar`** — OCI image layout tarball (for `crane` / `skopeo`).
- **`--output type=local,dest=./out`** — writes the final-stage **rootfs**, no image. Useful for "build a binary inside a container, copy it out."
- **`--output type=tar,dest=fs.tar`** — same idea, packed.
- **`--output type=registry,name=...`** — image + push, no local copy.

## buildx bake

- Declarative multi-target builds: `docker buildx bake -f docker-bake.hcl`. HCL format with `target` blocks and `group` blocks (groups run targets in parallel).
- Compose integration: `docker buildx bake -f docker-compose.yml` reads `services.*.build` blocks.
- **Matrix attribute** (HCL): expand a target across axis combinations (e.g., platforms × variants) without copy-paste.
- Use bake when: 5+ targets, repeated args/labels across targets, CI pipelines that want one command per stage. Skip for single-image projects — overhead not worth it.

## Image hardening

- **`USER nonroot`** (or `USER 65532:65532` to avoid name resolution) — set in the final stage. Many base images leave you as `root`. Distroless `:nonroot` tags use UID 65532.
- **`FROM scratch`** — empty base, zero bytes. Only works for fully-static binaries (Go with `CGO_ENABLED=0`, Rust musl). No shell, no `ls`, no debug.
- **Distroless** (`gcr.io/distroless/...-debian12`):
  - `static-debian12` — ~2 MiB, libc-only, for static binaries (alternative to `scratch` with `/etc/passwd`, CA certs).
  - `base-debian12` — adds glibc, OpenSSL.
  - `cc-debian12` — adds C/C++ runtime libs.
  - Language variants: `python3-debian12`, `nodejs22-debian12`, `java21-debian12`.
  - Tag suffixes: `:nonroot` (UID 65532), `:debug` (adds busybox shell — diagnostic only, never production), `:debug-nonroot`.
- **Alpine vs Debian-slim tradeoff**: Alpine uses musl libc — Node native modules, Python wheels, glibc-linked binaries break or need rebuilding. Debian-slim (`-slim`) variants are larger but compatible.
- **`HEALTHCHECK CMD ...`** options: `--interval=30s` (default), `--timeout=30s`, `--start-period=0s`, `--start-interval=5s` (Dockerfile 1.6+, only checks during start-period), `--retries=3`. Skip in distroless images that lack a shell.

## Attestations

- **Provenance** (SLSA-style): `--provenance=mode=max` records the full BuildKit invocation (cache mounts, secret IDs minus values, build args, source). Default is `mode=min` (basic invocation only). Disable with `--provenance=false` or `BUILDX_NO_DEFAULT_ATTESTATIONS=1`.
- **SBOM**: `--sbom=true` generates an in-toto SBOM via Syft, attached to the image manifest (queryable without pulling). Equivalent: `--attest type=sbom`.
- **Storage**: attached as additional manifests in the image index (in-toto JSON). For `oci`/`tar` exporters, written as separate JSON files under the export root.
- **Inspection**: `docker buildx imagetools inspect --format '{{json .Provenance}}' <ref>`.
- **Scanners**: `docker scout` (built-in, uses Grype DB), Trivy, Grype, Snyk all consume image SBOMs. Scout is fastest path; Trivy/Grype better for CI gating with SARIF output.

## GC and disk hygiene

- **Inspect**: `docker buildx du` (per-builder cache usage), `docker buildx du --verbose` (per-record).
- **Manual prune**: `docker buildx prune` (interactive), `--all` (everything), `--filter until=24h`, `--keep-storage 10GB`.
- **Default daemon GC** (`docker` driver, `daemon.json`): `defaultKeepStorage: "20GB"`, enabled by default.
- **Custom builder GC** (`docker-container` driver via `buildkitd.toml`): `reservedSpace` (default 10% disk or 10 GB), `maxUsedSpace` (default 60% disk or 100 GB), `minFreeSpace` (default 20 GB). Configure when creating: `docker buildx create --config /path/to/buildkitd.toml`.
- **Default GC policies** evaluate four passes in order: ephemeral cache > 48 h, unused cache > 60 days, unshared cache, all cache over threshold.

## Common pitfalls

- **`COPY` invalidates because timestamps changed**: `git checkout` rewrites mtimes. Use `COPY --link` so layer hash depends on file content, not on parent layer state.
- **`apt-get install` bloats by ~50 MB of indices**: end the same `RUN` with `apt-get clean && rm -rf /var/lib/apt/lists/*`, or use a `--mount=type=cache,target=/var/cache/apt,sharing=locked` so the cache lives outside the layer.
- **Build args containing tokens**: visible in `docker history` AND in provenance attestation. Always use `--secret` for credentials.
- **Cache "miss" on identical Dockerfile**: check `.dockerignore` (untracked files leaking in), check syntax pin (different frontend version → different cache key), check builder identity (different `docker-container` instance has independent cache).
- **`--cache-to=inline` doesn't speed up multi-stage builds**: only the final stage's layers are cached. Use `type=registry,mode=max`.
- **Multi-platform `--load` fails**: local image store can't hold a manifest list. Build single-platform locally, multi-platform for `--push`.
- **`USER` set before `COPY --chown` mismatch**: `COPY --chown=app` writes as that UID even if `USER` was set earlier — fine. But `RUN` after `USER nonroot` can't `apt-get install` (no root). Order: install → `USER` → `CMD`.
- **Squashing**: `--squash` is deprecated; `RUN --merge` is labs-only and rarely worth it. Better to merge logical work into one `RUN` with heredoc.

## Authoritative references

**Official Docker docs** (`docs.docker.com`):
- [BuildKit overview](https://docs.docker.com/build/buildkit/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) (RUN/COPY mount flags)
- [Cache backends](https://docs.docker.com/build/cache/backends/)
- [Cache optimization](https://docs.docker.com/build/cache/optimize/)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
- [Builder drivers](https://docs.docker.com/build/builders/drivers/)
- [Exporters](https://docs.docker.com/build/exporters/)
- [Bake reference](https://docs.docker.com/build/bake/)
- [Attestations](https://docs.docker.com/build/attestations/)
- [GC](https://docs.docker.com/build/cache/garbage-collection/)
- [Frontend syntax pinning](https://docs.docker.com/build/buildkit/frontend/)

**Upstream**:
- [moby/buildkit](https://github.com/moby/buildkit) — engine source, daemonless `buildctl`
- [Dockerfile frontend reference](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md)

**Hardening**:
- [Distroless](https://github.com/GoogleContainerTools/distroless) — Google's minimal runtime images

**Authors worth reading**:
- Tõnis Tiigi (BuildKit maintainer) — design rationale, cache internals
- Adrian Mouat — Dockerfile patterns, image size analysis

## Guardrails

Before recommending a non-trivial BuildKit change (cache backend choice, driver switch, multi-platform setup, attestation policy):
1. Quote the exact flag, default, and the frontend syntax version that introduced it
2. Cite the docs.docker.com section
3. State which `buildx` driver is required (the default `docker` driver lacks most features)
4. Make the recommendation conditional on observed behavior — never blanket-tune cache modes or platforms

**A `mode=max` registry cache is not free — it can balloon registry storage. Measure first.**
