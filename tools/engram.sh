#!/usr/bin/env bash

# engram - Persistent memory for AI coding agents (https://github.com/Gentleman-Programming/engram)
# Requires: critical_error, add_warning functions from parent script
#
# Engram hooks are managed in plugins/ct/hooks/engram/ (part of the ct plugin).
# The MCP server is registered via `claude mcp add` (user scope).
# The engram@engram plugin is NOT used — MCP + hooks in ct provide everything needed.

# Upstream repo path for hook scripts
readonly _ENGRAM_UPSTREAM_BASE="https://raw.githubusercontent.com/Gentleman-Programming/engram/main/plugin/claude-code/scripts"
readonly _ENGRAM_HOOK_SCRIPTS=("_helpers.sh" "session-start.sh" "post-compaction.sh" "user-prompt-submit.sh" "session-stop.sh" "subagent-stop.sh")

install_engram() {
    echo "Checking for engram..."

    if command -v engram &> /dev/null; then
        echo "engram already installed: $(engram --version 2>/dev/null || echo 'version unknown')"
    else
        echo "engram not found. Installing engram via Homebrew..."
        if ! brew install gentleman-programming/tap/engram; then
            critical_error "Failed to install engram via Homebrew"
        fi

        if ! command -v engram &> /dev/null; then
            critical_error "engram installation appeared to succeed but engram command is still not available"
        fi

        echo "engram installed successfully: $(engram --version 2>/dev/null || echo 'version unknown')"
    fi

    # Register engram MCP server (standalone, not via plugin)
    _engram_setup_mcp
}

update_engram() {
    echo "Updating engram..."

    if ! command -v engram &> /dev/null; then
        add_warning "engram is not installed, skipping update"
        return 0
    fi

    brew upgrade gentleman-programming/tap/engram 2>/dev/null || echo "engram already up to date"

    # Re-register MCP in case the binary path changed after upgrade
    _engram_setup_mcp

    # Fetch upstream hooks and update both source and installed copies
    _engram_sync_all_hooks

    echo "engram update complete"
}

uninstall_engram() {
    echo "Removing engram..."

    # Remove MCP registration
    claude mcp remove --scope user engram 2>/dev/null && echo "Removed engram MCP server" || true
    # Clean up legacy config if present
    rm -f "$HOME/.claude/mcp/engram.json" 2>/dev/null

    if ! command -v engram &> /dev/null; then
        echo "engram is not installed, nothing to remove"
        return 0
    fi

    brew uninstall gentleman-programming/tap/engram 2>/dev/null || add_warning "Failed to uninstall engram via Homebrew"
    echo "engram removal complete"
}

# --- Internal helpers ---

# Register engram as a standalone MCP server via `claude mcp add` (user scope).
# Uses the absolute binary path so it survives brew upgrades.
_engram_setup_mcp() {
    local engram_bin
    engram_bin=$(command -v engram 2>/dev/null)

    if [ -z "$engram_bin" ]; then
        add_warning "engram binary not found, skipping MCP registration"
        return 0
    fi

    # Remove any existing registration first to avoid duplicates
    claude mcp remove --scope user engram 2>/dev/null || true

    # Register with user scope so it's available in all projects
    if claude mcp add --transport stdio --scope user engram -- "$engram_bin" mcp --tools=agent; then
        echo "Registered engram MCP server (user scope)"
    else
        add_warning "Failed to register engram MCP server via claude mcp add"
    fi

    # Clean up legacy config if present
    rm -f "$HOME/.claude/mcp/engram.json" 2>/dev/null
}

# Sync engram hooks to all relevant locations:
# 1. Source repo (plugins/ct/hooks/engram/) — keeps source up to date for commits
# 2. Installed plugin cache (~/.claude/plugins/cache/.../hooks/engram/) — makes it live immediately
_engram_sync_all_hooks() {
    # First, fetch all upstream scripts once (avoid downloading twice)
    echo "Checking upstream engram hooks for changes..."

    declare -A _upstream_cache
    local fetch_failed=0
    local fetch_ok=0

    for script in "${_ENGRAM_HOOK_SCRIPTS[@]}"; do
        local upstream_url="${_ENGRAM_UPSTREAM_BASE}/${script}"
        local content
        content=$(command curl -sf --max-time 10 "$upstream_url" 2>/dev/null)

        if [ -z "$content" ]; then
            ((fetch_failed++))
            continue
        fi

        # Apply local patches: rewrite MCP tool name prefix from plugin to standalone format
        _upstream_cache["$script"]=$(echo "$content" | sed 's/mcp__plugin_engram_engram__/mcp__engram__/g')
        ((fetch_ok++))
    done

    if [ "$fetch_ok" -eq 0 ]; then
        add_warning "Could not reach upstream engram repo — hook sync skipped"
        return 0
    fi

    # Sync target 1: source repo (if running from the repo)
    local source_dir="${SCRIPT_DIR}/plugins/ct/hooks/engram"
    if [ -d "$source_dir" ]; then
        _engram_sync_hooks_to "$source_dir" "source" _upstream_cache
    fi

    # Sync target 2: installed plugin cache
    local installed_hooks_dir
    installed_hooks_dir=$(_engram_find_installed_hooks_dir)
    if [ -n "$installed_hooks_dir" ] && [ -d "$installed_hooks_dir" ]; then
        # Skip if installed dir is the same as source (project-scoped install pointing at repo)
        if [ "$(cd "$source_dir" 2>/dev/null && pwd)" != "$(cd "$installed_hooks_dir" 2>/dev/null && pwd)" ]; then
            _engram_sync_hooks_to "$installed_hooks_dir" "installed" _upstream_cache

            # Also sync hooks.json from source to installed cache so engram hook
            # entries are registered without waiting for `claude plugin update`
            local source_hooks_json="${SCRIPT_DIR}/plugins/ct/hooks/hooks.json"
            local installed_hooks_json
            installed_hooks_json="$(dirname "$installed_hooks_dir")/hooks.json"
            if [ -f "$source_hooks_json" ] && [ -f "$installed_hooks_json" ]; then
                if ! diff -q "$source_hooks_json" "$installed_hooks_json" > /dev/null 2>&1; then
                    cp "$source_hooks_json" "$installed_hooks_json"
                    echo "  Updated hooks.json in installed plugin cache"
                fi
            fi
        fi
    elif [ -z "$installed_hooks_dir" ]; then
        echo "  No installed ct plugin found — only source updated"
    fi
}

# Sync upstream hooks to a specific target directory.
# Args:
#   $1: target directory path
#   $2: label for log messages ("source" or "installed")
#   $3: name of associative array with upstream content (passed by name)
_engram_sync_hooks_to() {
    local target_dir="$1"
    local label="$2"
    local -n cache_ref="$3"

    local updated=0

    for script in "${_ENGRAM_HOOK_SCRIPTS[@]}"; do
        local patched_content="${cache_ref[$script]}"
        [ -z "$patched_content" ] && continue

        local local_file="${target_dir}/${script}"

        if [ ! -f "$local_file" ]; then
            printf '%s\n' "$patched_content" > "$local_file"
            chmod +x "$local_file"
            ((updated++))
        else
            local local_content
            local_content=$(command cat "$local_file")

            if [ "$patched_content" != "$local_content" ]; then
                printf '%s\n' "$patched_content" > "$local_file"
                chmod +x "$local_file"
                ((updated++))
            fi
        fi
    done

    if [ "$updated" -gt 0 ]; then
        echo "  $updated hook(s) updated in $label ($target_dir)"
    else
        echo "  All hooks up to date in $label"
    fi
}

# Find the installed ct plugin's hooks/engram/ directory from installed_plugins.json.
# Returns the path or empty string if not found.
_engram_find_installed_hooks_dir() {
    local plugins_json="$HOME/.claude/plugins/installed_plugins.json"

    if [ ! -f "$plugins_json" ]; then
        return
    fi

    # Get the install path(s) for ct@claude-templates — may have project and user scopes
    local install_paths
    install_paths=$(command jq -r '.plugins["ct@claude-templates"][]?.installPath // empty' "$plugins_json" 2>/dev/null | sort -u)

    if [ -z "$install_paths" ]; then
        return
    fi

    # Use the first valid path that has a hooks/ directory
    while IFS= read -r path; do
        local hooks_dir="${path}/hooks/engram"
        if [ -d "$path/hooks" ]; then
            # Create engram subdir if it doesn't exist yet (first sync after migration)
            mkdir -p "$hooks_dir"
            echo "$hooks_dir"
            return
        fi
    done <<< "$install_paths"
}
