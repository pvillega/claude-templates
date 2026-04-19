#!/usr/bin/env bash

# Opt-in instructions helper for Postgres MCP (crystaldba/postgres-mcp).
#
# Standalone: runnable via `bash tools/optional/postgres_mcp.sh` or directly.
#
# Homebrew note: postgres-mcp is NOT on Homebrew (Python package on PyPI). This
# script relies on `uv`/`uvx` (installed by tools/uv.sh) to run postgres-mcp
# on-demand with zero persistent install.
#
# WHY THIS IS *NOT* A USER-SCOPE (GLOBAL) MCP REGISTRATION:
#
#   1. A user-scope MCP loads in EVERY project. Even with Claude Code's Tool
#      Search deferral, it pays ~100 tokens of metadata per session and risks
#      a process start whenever DATABASE_URI happens to be exported.
#
#   2. The intuitive escape hatch — `disabledMcpServers` per-project in
#      ~/.claude.json — has known bugs:
#         - anthropics/claude-code#13311 (not enforced at session startup)
#         - anthropics/claude-code#11085 (persistent enable/disable is a feature
#           request, not a shipped behavior)
#      So you CANNOT reliably disable a user-scope MCP in individual projects.
#
#   3. A live DB connection is trust-sensitive. Per-project opt-in keeps the
#      mental model "I explicitly opted this project in," not "it's on
#      everywhere and I'm relying on DATABASE_URI being unset."
#
#   4. `--scope local` is the native Claude Code primitive for opt-in per
#      project. It writes under that project's path in ~/.claude.json, so
#      `claude mcp list` shows it only where you opted in. Clean semantics,
#      no bug dependency.
#
# What this script DOES:
#   A. Check prereqs (`uv`, `claude`).
#   B. Pre-warm the `uvx` cache so the first real MCP startup is fast.
#   C. Print the exact per-project opt-in command and DATABASE_URI convention.
#
# What this script DOES NOT DO:
#   - Register the MCP at any scope.
#   - Touch ~/.claude.json, .mcp.json, or settings.json.
#   - Install anything persistently (uvx is on-demand).
#
# Flags / env:
#   --dry-run    Echo "DRY-RUN: <would do X>" for every mutating action. No state changes.
#   DRY_RUN=1    Same as --dry-run.

set -euo pipefail

# ------------------------------------------------------------------------------
# Minimal helpers (independent of install.sh)
# ------------------------------------------------------------------------------

_err() {
    echo "ERROR: $*" >&2
}

_warn() {
    echo "WARN:  $*" >&2
}

_info() {
    echo "$*"
}

# ------------------------------------------------------------------------------
# Flag parsing
# ------------------------------------------------------------------------------

DRY_RUN="${DRY_RUN:-0}"
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            cat <<USAGE
Usage: $0 [--dry-run]

Prepares the Postgres MCP (crystaldba/postgres-mcp) for per-project opt-in use.

This script does NOT register the MCP globally. It only verifies prereqs,
pre-warms the uvx cache, and prints the exact per-project opt-in command.
See the top of this file for the design rationale.

Environment:
  DRY_RUN=1     same as --dry-run
USAGE
            exit 0
            ;;
        *)
            _err "unknown argument: $arg"
            exit 1
            ;;
    esac
done

if [ "$DRY_RUN" = "1" ]; then
    _info "== DRY-RUN mode: no system state will be modified =="
fi

# Helper: perform an action, or echo the DRY-RUN equivalent.
# Usage: _do "description" -- cmd args...
_do() {
    local desc="$1"; shift
    if [ "${1:-}" = "--" ]; then shift; fi
    if [ "$DRY_RUN" = "1" ]; then
        echo "DRY-RUN: would $desc"
        return 0
    fi
    "$@"
}

# ------------------------------------------------------------------------------
# Section A — prereq gate (uv, claude)
# ------------------------------------------------------------------------------

_info ""
_info "[A] Checking prerequisites..."

_missing=()
for cmd in uv claude; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        _missing+=("$cmd")
    fi
done

if [ "${#_missing[@]}" -gt 0 ]; then
    _err "missing required command(s): ${_missing[*]}"
    _err "install hints:"
    _err "  uv     -> run tools/uv.sh in this repo  (or: curl -LsSf https://astral.sh/uv/install.sh | sh)"
    _err "  claude -> https://docs.anthropic.com/en/docs/claude-code"
    exit 2
fi
_info "  uv, claude: OK"

# ------------------------------------------------------------------------------
# Section B — pre-warm the uvx cache
# ------------------------------------------------------------------------------

_info ""
_info "[B] Pre-warming uvx cache for postgres-mcp..."

STATUS_WARM="unknown"
if _do "run: uvx postgres-mcp --help >/dev/null" -- \
        sh -c 'uvx postgres-mcp --help >/dev/null 2>&1'; then
    if [ "$DRY_RUN" = "1" ]; then
        STATUS_WARM="dry-run"
    else
        STATUS_WARM="cached"
        _info "  postgres-mcp resolved and cached by uv"
    fi
else
    _warn "could not pre-warm uvx cache (network issue?). First MCP startup will be slower."
    STATUS_WARM="skipped"
fi

# ------------------------------------------------------------------------------
# Section C — print per-project opt-in instructions
# ------------------------------------------------------------------------------

_info ""
_info "[C] Per-project opt-in instructions"
_info ""
_info "  This installer does NOT register the Postgres MCP globally — see top of"
_info "  this file for rationale. To enable postgres-mcp in a specific project:"
_info ""
_info "  1. cd into the project, then export the DSN for THIS shell:"
_info ""
_info "       export DATABASE_URI='postgresql://USER:PASS@HOST:5432/DB'"
_info ""
_info "  2. Register the MCP at LOCAL scope (current project only):"
_info ""
_info "       claude mcp add --scope local \\"
_info "         --env 'DATABASE_URI=\${DATABASE_URI}' \\"
_info "         postgres \\"
_info "         -- uvx postgres-mcp --access-mode=restricted"
_info ""
_info "  Notes:"
_info "  - '--access-mode=restricted' enforces read-only SQL. Use 'unrestricted'"
_info "    ONLY when you intentionally want Claude to run DDL/DML."
_info "  - The '\${DATABASE_URI}' env ref is expanded by Claude Code at launch"
_info "    from the terminal environment, so the DSN is NEVER stored in"
_info "    ~/.claude.json in plaintext. If DATABASE_URI is unset, the MCP will"
_info "    refuse to connect; launch Claude Code from a shell where it's set."
_info "  - To remove: 'claude mcp remove --scope local postgres' from the project."
_info "  - To inspect: 'claude mcp list' (local-scope servers only appear in"
_info "    the project where they were added)."

# ------------------------------------------------------------------------------
# Section D — final summary
# ------------------------------------------------------------------------------

_info ""
_info "=========================================="
_info "  Postgres MCP prep — summary"
_info "=========================================="
_info "  ✓ prereqs (uv, claude) : OK"
_info "  ✓ uvx cache            : $STATUS_WARM"
_info "  ✓ MCP registration     : intentionally skipped (per-project opt-in)"
_info ""
_info "Next step: cd into a project, export DATABASE_URI, and run the"
_info "'claude mcp add --scope local ...' command from section [C] above."
_info ""
if [ "$DRY_RUN" = "1" ]; then
    _info "DRY-RUN complete. No state was modified."
fi
exit 0
