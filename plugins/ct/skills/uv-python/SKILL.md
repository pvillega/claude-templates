---
name: uv-python
description: >
  Deep operational intuition for uv (Astral's Rust-based Python packaging/runtime
  manager) — project model, lockfile semantics, workspaces, dependency groups
  (PEP 735), `[tool.uv.sources]`, build-isolation, managed Python toolchains,
  caching/link-modes, CI patterns, and migration gotchas from pip/pip-tools/poetry/pipx.
  Load ONLY when the task involves uv-specific workflow choices, lockfile behaviour,
  workspace layout, dependency-source quirks, build-isolation/wheels-only packages,
  cross-platform resolution, or migrating an existing project to uv. Do NOT load
  for ordinary Python coding, library API questions, or generic packaging primers
  that don't depend on uv internals.
  Triggers on: "uv add vs uv pip install", "uv lock", "uv sync --frozen", "uv sync --locked",
  "uv.lock universal resolution", "uv workspace members", "tool.uv.sources", "tool.uv.index",
  "dependency-groups PEP 735", "uv tool install vs uvx", "uv build backend", "uv migration from poetry",
  "uv migration from pip-tools", "uv no-build-isolation", "uv requires-python", "uv python pin",
  "UV_LINK_MODE", "UV_COMPILE_BYTECODE", "uv cache prune", "PEP 723 inline script", "uv run --script".
---

# uv (Astral) Operational Guide

Concise operational pointers for uv, Astral's Rust-based packaging and runtime tool — replaces pip / pip-tools / virtualenv / pyenv / poetry / pipx in one binary.

Assumes you already know pip basics, virtual envs, and `pyproject.toml`. This skill covers the **uv-specific layer** — project model, lockfile semantics, workspace layout, source resolution, build isolation, managed Python, and migration traps that LLMs gloss over because they look superficially like pip.

## When to use

Load when the question is about:
- uv project layout (`pyproject.toml` + `uv.lock` + `.python-version`) and the `[tool.uv]` / `[tool.uv.sources]` / `[tool.uv.workspace]` / `[tool.uv.index]` tables
- Lockfile behaviour: `uv lock`, `uv sync --locked` vs `--frozen`, `--upgrade-package`, universal resolution, environment markers, `requires-python`
- Dependency groups (PEP 735) vs optional-dependencies vs the legacy `tool.uv.dev-dependencies`
- Workspaces: `members` globs, source inheritance, when to prefer path deps
- Sources: alternative indexes, git/path/url, `--no-build-isolation`, `dependency-metadata`, wheels-only packages (PyTorch, flash-attn)
- Managed Python toolchain: `uv python install/pin`, `python-preference`, `requires-python` interplay
- Tool envs: `uv tool install` vs `uvx` (`uv tool run`), pipx migration
- CI patterns and Docker layering with `UV_LINK_MODE`, `UV_COMPILE_BYTECODE`, `--no-install-project`
- Migration from poetry / pip-tools / pipx (caret versions, dynamic versioning, `requirements.in`)
- PEP 723 inline-script metadata (`# /// script` block), `.py.lock` per-script

**Do NOT load** for: generic Python coding, library API questions, asking what a virtual env is, or "how do I install a package" with no uv-specific friction.

## Project model and lifecycle commands

- **Init flavours** (`uv init`): `--app` (default; flat `main.py`, no `[build-system]`, **not** installed into env), `--package` (adds `src/`, build-system, entry points; project IS installed), `--lib` (implies `--package`, adds `py.typed`). Default build backend since uv 0.8 is `uv_build` (`uv_build>=0.11.7,<0.12`) — pure-Python only; switch to `hatchling` for VCS versioning, native ext, build hooks. Pre-July-2025 default was `hatchling`.
- **`uv add <pkg>`** edits `pyproject.toml` AND relocks AND syncs. **`uv pip install <pkg>`** does none of those — it's a pip-shim that mutates `.venv` only. Mixing the two is the #1 newbie footgun: `uv pip install` packages disappear on the next `uv sync` because they aren't in `uv.lock`.
- **`uv lock`** re-resolves and writes `uv.lock` without touching `.venv`. Flags: `--upgrade` (relax all locked versions), `--upgrade-package <pkg>` (relax only one — preserves all other pins), `--check` (CI: fail if relock would change anything). `uv lock --script foo.py` writes `foo.py.lock` adjacent.
- **`uv sync`** reconciles `.venv` to match `uv.lock`. Default mode is **exact**: removes anything not in lock. Use `--inexact` to retain extras. Always installs the project as editable unless `--no-install-project` (deps only) or `--no-install-workspace` (workspace members excluded).
- **`uv sync --locked`** = "fail if `uv.lock` would change" (CI gate). **`uv sync --frozen`** = "skip the resolver entirely; use `uv.lock` as-is" — fastest, but errors if lock is missing/stale.
- **`uv run <cmd>`** = auto-sync THEN exec. For one-off invocations prefer `uv run --frozen <cmd>` in CI to skip resolution. `uv run --no-project` ignores `pyproject.toml` (pure script mode). `uv run --isolated` ignores caches/lockfile/sources.
- **`uvx`** is a hard alias for `uv tool run`. Not the same as `uv run`. `uvx` runs in a disposable cache env; `uv run` uses the project `.venv`.

## Lockfile semantics: universal by default

- `uv.lock` is **universal / cross-platform** — one lockfile encodes resolutions for every platform/Python combination, gated by PEP 508 markers. This is fundamentally different from pip-tools which produces one `requirements.txt` per platform.
- The resolution space is bounded by `requires-python` in `[project]` AND `[tool.uv.environments]`. Narrow `tool.uv.environments` (e.g., drop Windows) when resolution fails because of Windows-only wheels-conflict — common with ML stacks.
- `[tool.uv.required-environments]` = "the lock MUST cover these markers". Forces the resolver to fail loudly if a wheel-only dep (e.g. PyTorch CUDA) lacks coverage for a stated platform.
- Sources of stale-lock failures: `requires-python` widened in `pyproject.toml` but lockfile not regenerated; `--frozen` will then fail at sync. Run `uv lock` to repair.
- `uv.lock` format is uv-private TOML — do not edit by hand. Commit it for apps; for libraries it's still recommended (it locks the dev env, not what consumers see).
- Pre-release behaviour: uv requires explicit opt-in via `--prerelease allow` even for transitive deps. Pip accepts pre-releases of transitive deps silently — common surprise on migration.

## Dependency groups (PEP 735)

- The **standard** location is `[dependency-groups]` (top-level, NOT under `[tool.uv]`). The legacy `[tool.uv.dev-dependencies]` is **deprecated**; uv merges both into the `dev` group during resolution but new code should use `[dependency-groups]`.
- Group flags: `--group <name>`, `--no-group <name>` (exclusion wins), `--all-groups`, `--no-default-groups`, `--only-group`. The `dev` group is special-cased and synced by default; flags `--dev` / `--no-dev` / `--only-dev`.
- Override default groups via `[tool.uv] default-groups = ["dev", "test"]`. CI prod install: `uv sync --locked --no-default-groups` (or set `UV_NO_DEV=1` and use group-by-group).
- Groups can nest: `dev = [{include-group = "test"}, "ipython"]`.
- Groups are local-only — they do NOT publish to PyPI. Optional dependencies (`[project.optional-dependencies]`) DO publish — that's the structural distinction. Use extras for "consumers can opt in", groups for "developer tooling".
- `uv pip install --group <name>` was added later; pre-uv 0.5 the pip shim couldn't see groups.

## `[tool.uv.sources]` and alternative indexes

- Five source types: index (named), git (with `tag`/`branch`/`rev`/`subdirectory`/`lfs`), url, path, workspace (`{ workspace = true }`).
- Sources only apply during **development** — they are stripped on publish (so `git = "..."` deps don't leak into PyPI metadata). This is intentional and a common confusion.
- Multi-marker sources: provide a list with PEP 508 markers, e.g. `httpx = [{ git = "...", marker = "sys_platform == 'darwin'" }, { index = "internal", marker = "sys_platform == 'linux'" }]`.
- `[[tool.uv.index]]` defines named indexes: `name`, `url`, `default = true` (only one allowed since uv 0.10), `explicit = true` (packages from this index require an explicit source mapping — the typical PyTorch pattern).
- `--index-strategy unsafe-best-match` walks ALL indexes for the highest version. Default is `first-index` (security: no dependency confusion). Required for some PyTorch CUDA setups; understand the supply-chain trade-off before flipping it.
- Workspace member references: `mypkg = { workspace = true }`. The version comes from the member's own `pyproject.toml`, not the root.

## Workspaces

- Configured at the root `pyproject.toml`: `[tool.uv.workspace] members = ["packages/*"]`, optional `exclude`. Every matched dir must contain `pyproject.toml`.
- The **root is itself a workspace member** unless explicitly excluded. One `.venv` for the entire workspace, one `uv.lock` at the root.
- Source inheritance: `[tool.uv.sources]` in the root applies to all members; a member-local `[tool.uv.sources]` for a given dependency **fully overrides** the root entry — markers and all are discarded.
- All members share `requires-python` resolution; conflicting `requires-python` between members forces a single intersected version range.
- Use a workspace when members iterate together and share deps; use **path deps without `[tool.uv.workspace]`** when members must keep separate venvs / requires-python / conflicting deps.
- `uv sync --package <member>` syncs only that member's deps (still uses the workspace lock). `uv run --package <member> <cmd>` runs in the workspace venv but with that member as the project.

## Managed Python toolchain

- `uv python install 3.13` downloads python-build-standalone binaries to `${UV_PYTHON_INSTALL_DIR:-~/.local/share/uv/python}`. Multiple versions coexist; `uv python list` shows them. `uv python uninstall <ver>`.
- `uv python pin 3.13` writes `.python-version` (project-local). `uv python pin --global 3.13` writes user-config default. Pin is honoured by `uv tool install/run` since uv 0.10.
- Discovery order: managed pythons → `PATH` (`python`, `python3`, `python3.x`) → Windows registry / Microsoft Store. **First compatible** wins, NOT newest — easy gotcha when `python3.10` shadows a managed `3.13`.
- `python-preference` (also `UV_PYTHON_PREFERENCE`): `managed` (default; prefer managed but accept system), `only-managed` (refuse system), `system` (prefer system), `only-system` (refuse downloads). Set `only-system` in containers shipping their own CPython to prevent surprise downloads.
- Free-threaded / debug builds: `3.13t` (free-threaded), `3.13d` (debug). PyPy / GraalPy / Pyodide also supported — note since uv 0.10 their executables are named `pypy3.10` etc., not generic `python3.10`.
- Auto-download: `UV_PYTHON_DOWNLOADS=never` disables. Useful in air-gapped CI.

## Build isolation and wheels-only deps

- Default: every build runs in a clean isolated env using PEP 517 (correct, but slow for `flash-attn`/`deepspeed`-style packages that import `torch` at build time).
- Three escape hatches, in order of preference:
  1. **`extra-build-dependencies`** (uv 0.10+): augment the isolated env with extra packages. With `match-runtime = true`, uv injects the *runtime* version of the package into the build env — solves the `torch`-at-build-time problem cleanly.
  2. **`dependency-metadata`**: declare a package's metadata in `pyproject.toml` so the resolver doesn't need to build it for solving — only at install. Use for packages with stable, known metadata that are expensive to build.
  3. **`no-build-isolation-package = ["flash-attn"]`** (or `--no-build-isolation` globally): turn off isolation. You MUST then `uv pip install <build-deps>` first, or rely on what's in the env. Most fragile path; reach for it last.
- `[tool.uv.required-environments]` for wheels-only packages (PyTorch CUDA): forces the lock to verify wheel availability for declared markers; without it the lock can succeed but `uv sync` fails on a target machine.
- Conflicts (`[tool.uv] conflicts = [[{ extra = "cpu" }, { extra = "cu128" }]]`): tells the resolver these are mutually exclusive — required for the CPU/CUDA-extras pattern, otherwise universal resolution will try to satisfy both at once and fail.

## Cache, link mode, and bytecode

- Cache lives at `${UV_CACHE_DIR:-${XDG_CACHE_HOME:-~/.cache}/uv}`. Cache MUST live on the same filesystem as `.venv` for hardlink installs to work — the most common Docker layering bug.
- `UV_LINK_MODE` values: `clone` (CoW reflinks; APFS/btrfs/xfs default — fastest, zero-copy), `hardlink` (Linux ext4 default), `copy` (slowest, always safe), `symlink` (rare). In multi-stage Docker builds set `UV_LINK_MODE=copy` or links break across mounts.
- `UV_COMPILE_BYTECODE=1` runs `compileall` post-install; doubles install time but cuts cold-start for large apps. Standard in production Docker images, off in dev.
- `uv cache clean` nukes everything (or `uv cache clean <pkg>`). `uv cache prune` removes only **unused** entries — the routine maintenance command. `uv cache prune --ci` additionally drops pre-built wheels but keeps source-built wheels (rebuilding from source is more expensive than re-downloading).

## CI patterns

- Canonical CI sync: `uv sync --locked --no-default-groups --group ci` (or `--no-dev` if just dev exists). `--locked` gates the lockfile — fails if `pyproject.toml` drifted from `uv.lock`. **Never use `--frozen` for the install step in CI** unless you are also running `uv lock --check` separately; `--frozen` silently uses a stale lock.
- Reproducible exec: `uv run --frozen <cmd>` AFTER a successful `uv sync --locked` — skips re-resolution per command.
- GitHub Actions: `astral-sh/setup-uv@v6` with `enable-cache: true` and `cache-dependency-glob: "**/uv.lock"`. For matrix Python: pass `python-version` to the action OR set `UV_PYTHON` env var; do not also use `actions/setup-python` unless you set `python-preference: only-system`.
- Docker pattern: copy uv binary from `ghcr.io/astral-sh/uv:<tag>` (pin a digest for supply-chain), then `uv sync --locked --no-install-project` (deps layer), copy source, `uv sync --locked` (project layer). Always `UV_LINK_MODE=copy` and `UV_COMPILE_BYTECODE=1` and `UV_PYTHON_DOWNLOADS=never` in containers; add `.venv` to `.dockerignore`.
- Publishing: `uv build` then `uv publish` (supports PyPI trusted publishing via OIDC — no credentials in workflow).

## Migration gotchas

**From poetry**:
- Caret/tilde version specs (`^1.2`, `~1.2`) are NOT PEP 440. `uvx migrate-to-uv` translates `^1.2` → `>=1.2,<2`, `~1.2` → `>=1.2,<1.3`. Read the diff — the rewrite is occasionally wrong for pre-1.0 (poetry treats `^0.x.y` as `>=0.x.y,<0.x+1`).
- `[tool.poetry.group.<name>.dependencies]` → `[dependency-groups]` (PEP 735). The migrator offers four strategies (`set-default-groups`, `include-in-dev`, `merge-into-dev`, `keep-existing`); pick `set-default-groups` to retain semantics.
- `poetry-dynamic-versioning` plugin has no direct port — replace with `uv-dynamic-versioning` (separate project) OR switch build backend to `hatchling` + `hatch-vcs`. uv_build does not support dynamic versioning.
- `poetry.lock` and `uv.lock` are not interchangeable. Delete `poetry.lock` after migrating; do NOT try to import.
- `tool.poetry.scripts` → `[project.scripts]` (standard PEP 621).

**From pip-tools**:
- `requirements.in` → `[project.dependencies]`; dev `requirements-dev.in` → `[dependency-groups] dev`. `uv add -r requirements.in -c requirements.txt` preserves pinned versions during import. Strip leading `-r requirements.in` from the dev file before importing or you double-add.
- `pip-compile foo.in -o foo.txt` still works as **`uv pip compile foo.in -o foo.txt`** — useful for projects not yet ready to fully port to `pyproject.toml`.
- Universal lock means a single `uv.lock` replaces per-platform `requirements-{linux,win,mac}.txt`. If you need a per-platform export: `uv export --format requirements.txt --python-platform <platform>`.

**From pipx**:
- `pipx install ruff` → `uv tool install ruff`. `pipx run ruff` → `uvx ruff` (or `uv tool run ruff`).
- Tool envs live at `${UV_TOOL_DIR:-~/.local/share/uv/tools}`. Not in your project venv. `uv tool dir` prints the path.
- `uv tool install --with <extra>` adds runtime extras to the tool env without exposing their executables. `uv tool upgrade <tool>` respects original constraints; reinstall to change them.
- `uvx` runs in a **disposable** cache env per invocation (cached, not regenerated, but `uv cache clean` wipes it). For a stable installed CLI use `uv tool install`.

## PEP 723 inline scripts

- A script becomes self-describing with a `# /// script` block:
  ```python
  # /// script
  # requires-python = ">=3.12"
  # dependencies = ["httpx", "rich"]
  # ///
  ```
- `uv add --script foo.py 'httpx>=0.25'` injects/edits the block. `uv lock --script foo.py` writes `foo.py.lock` adjacent (per-script lockfile, not `uv.lock`).
- `uv run foo.py` runs in an ephemeral env built from the script's metadata — does NOT touch the project venv. To force project mode, drop the metadata block; to force script mode inside a project use `uv run --script foo.py` (or shebang `#!/usr/bin/env -S uv run --script`).
- `--with <pkg>` adds a one-off dep without rewriting the metadata block — useful for ad-hoc REPL/debug.

## Authoritative references

**Official uv docs** (`docs.astral.sh/uv`):
- [Project layout & `pyproject.toml`](https://docs.astral.sh/uv/concepts/projects/layout/)
- [Locking and syncing](https://docs.astral.sh/uv/concepts/projects/sync/)
- [Managing dependencies & `[tool.uv.sources]`](https://docs.astral.sh/uv/concepts/projects/dependencies/)
- [Workspaces](https://docs.astral.sh/uv/concepts/projects/workspaces/)
- [Resolution (universal, markers, strategies)](https://docs.astral.sh/uv/concepts/resolution/)
- [Python versions & toolchain](https://docs.astral.sh/uv/concepts/python-versions/)
- [Tools (`uv tool`, `uvx`)](https://docs.astral.sh/uv/concepts/tools/)
- [Cache management](https://docs.astral.sh/uv/concepts/cache/)
- [Build backend (`uv_build`)](https://docs.astral.sh/uv/concepts/build-backend/)
- [Configuration / `[tool.uv.environments]`](https://docs.astral.sh/uv/concepts/projects/config/)
- [Environment variables reference](https://docs.astral.sh/uv/reference/environment/)
- [Scripts (PEP 723)](https://docs.astral.sh/uv/guides/scripts/)
- [Docker integration](https://docs.astral.sh/uv/guides/integration/docker/)
- [GitHub Actions integration](https://docs.astral.sh/uv/guides/integration/github/)
- [PyTorch integration (alternative indexes)](https://docs.astral.sh/uv/guides/integration/pytorch/)
- [pip-to-uv migration](https://docs.astral.sh/uv/guides/migration/pip-to-project/)

**Repo / changelog**: [astral-sh/uv on GitHub](https://github.com/astral-sh/uv) — read the [CHANGELOG](https://github.com/astral-sh/uv/blob/main/CHANGELOG.md) before pinning a version; 0.10 is the current major behavioural cut.

**Migration tooling**: [`migrate-to-uv`](https://github.com/mkniewallner/migrate-to-uv) (run as `uvx migrate-to-uv`) — supports poetry, pipenv, pip-tools, pip.

**Community deep-dives**:
- [pydevtools handbook](https://pydevtools.com/handbook/) — `uv` vs `poetry`, `uv` vs `pip`, dependency-group semantics
- [SaaS Pegasus uv deep-dive](https://www.saaspegasus.com/guides/uv-deep-dive/)
- [Charlie Marsh on uv build backend stability](https://pydevtools.com/blog/uv-build-backend/)

## Guardrails

Before recommending a non-trivial uv configuration change (build-isolation off, `unsafe-best-match`, `tool.uv.environments` narrowing, `--frozen` in CI):
1. Quote the exact field/flag and its default.
2. Cite the relevant uv docs section.
3. State the failure mode the change accepts (e.g., dependency-confusion risk for `unsafe-best-match`; stale lock for `--frozen`).
4. Verify the user's uv version supports the feature — many flags (e.g., `extra-build-dependencies`, `--no-default-groups`, named-required indexes) landed in 0.10. Run `uv --version` first.

**Universal resolution and build isolation are correctness defaults — disable them only with a stated reason.**
