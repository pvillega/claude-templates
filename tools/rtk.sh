#!/usr/bin/env bash

# rtk - Rust Token Killer, token-optimized CLI proxy (https://github.com/rtk-ai/rtk)
# Requires: critical_error, add_warning functions from parent script

# Apply our config overrides to rtk's TOML config (idempotent).
#
# rtk's TOML parser requires complete sections — a partial file like just
# `[limits]\npassthrough_max_chars = 8000` fails with "missing field
# grep_max_per_file". So we work on the full default file instead:
#   1. If the file is missing, ask rtk to write its full defaults.
#   2. Sed-replace our two specific values to the desired overrides.
#
# Idempotent: if the values already match, sed is a no-op.
# Path discovered via `rtk config` so it works on macOS
# (~/Library/Application Support/rtk/) and Linux (~/.config/rtk/).
#
# Overrides applied:
#   passthrough_max_chars: 2000 -> 8000  (multi-line script outputs, diffs)
#   grep_max_results:       200 -> 500   (repo-wide audit-style searches)
_rtk_apply_config_overrides() {
    local config_file
    config_file=$(rtk config 2>/dev/null | awk -F': ' '/^Config:/ {print $2; exit}')

    if [ -z "$config_file" ]; then
        add_warning "Could not determine rtk config path via 'rtk config'; skipping override"
        return 0
    fi

    if [ ! -f "$config_file" ]; then
        # `rtk config --create` writes the full default file (no backup, no overwrite of existing).
        if ! rtk config --create > /dev/null 2>&1; then
            add_warning "Failed to seed rtk default config at $config_file; skipping override"
            return 0
        fi
    fi

    local tmp
    tmp=$(mktemp)
    # `-E` (extended regex) is supported on both BSD sed (macOS) and GNU sed (Linux).
    # `[[:space:]]` is POSIX-portable. `+` requires extended mode.
    sed -E \
        -e 's/^passthrough_max_chars[[:space:]]*=[[:space:]]*[0-9]+/passthrough_max_chars = 8000/' \
        -e 's/^grep_max_results[[:space:]]*=[[:space:]]*[0-9]+/grep_max_results = 500/' \
        "$config_file" > "$tmp" && mv "$tmp" "$config_file"

    # Verify both values landed (parse failure or missing keys will leave them un-set).
    # `command grep` bypasses any shell alias (e.g. `grep=rg` from a user's profile)
    # so we get real GNU/BSD grep semantics regardless of caller environment.
    if ! command grep -qE '^passthrough_max_chars[[:space:]]*=[[:space:]]*8000\b' "$config_file" \
        || ! command grep -qE '^grep_max_results[[:space:]]*=[[:space:]]*500\b' "$config_file"; then
        add_warning "rtk config override at $config_file did not apply both values cleanly. Inspect the file manually."
        return 0
    fi

    echo "rtk config: overrides applied (passthrough_max_chars=8000, grep_max_results=500) at $config_file"
}

install_rtk() {
    echo "Checking for rtk..."

    if command -v rtk &> /dev/null; then
        echo "rtk already installed: $(rtk --version)"
        _rtk_apply_config_overrides
        return 0
    fi

    echo "rtk not found. Installing rtk via Homebrew..."
    if ! brew install rtk-ai/tap/rtk; then
        critical_error "Failed to install rtk via Homebrew"
    fi

    if ! command -v rtk &> /dev/null; then
        critical_error "rtk installation appeared to succeed but rtk command is still not available"
    fi

    echo "rtk installed successfully: $(rtk --version)"

    # Initialize rtk globally (installs hooks, patches CLAUDE.md, registers in settings.json)
    echo "Initializing rtk globally..."
    if ! rtk init -g --auto-patch; then
        add_warning "rtk installed but 'rtk init -g --auto-patch' failed. Run 'rtk init -g' manually to complete setup."
    fi

    _rtk_apply_config_overrides
}

update_rtk() {
    echo "Updating rtk..."

    if ! command -v rtk &> /dev/null; then
        add_warning "rtk is not installed, skipping update"
        return 0
    fi

    brew upgrade rtk-ai/tap/rtk 2>/dev/null || echo "rtk already up to date"

    # Re-run init to update hooks if needed
    rtk init -g --auto-patch 2>/dev/null || add_warning "Failed to update rtk hooks"

    _rtk_apply_config_overrides

    echo "rtk update complete"
}

uninstall_rtk() {
    echo "Removing rtk..."

    if ! command -v rtk &> /dev/null; then
        echo "rtk is not installed, nothing to remove"
        return 0
    fi

    # Remove hooks, docs, and settings.json entries (creates settings.json.bak)
    echo "Removing rtk hooks and configuration..."
    rtk init --uninstall 2>/dev/null || add_warning "Failed to run 'rtk init --uninstall'"

    brew uninstall rtk-ai/tap/rtk 2>/dev/null || add_warning "Failed to uninstall rtk via Homebrew"

    echo "rtk removal complete"
}
