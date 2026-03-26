#!/usr/bin/env bash

# Claude Templates Update Script
# Discovers and updates all installed Claude plugins and npm global packages.
# Compatible with bash and zsh on macOS and Linux.

set -euo pipefail

# Script directory (for sourcing config)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared configuration (TOOLS, SKILLS, MARKETPLACES, PLUGINS)
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

# Load all tool scripts from tools/ directory
for _tool_script in "$SCRIPT_DIR"/tools/*.sh; do
    # shellcheck source=/dev/null
    source "$_tool_script"
done

# ==============================================================================
# TRACKING
# ==============================================================================

WARNINGS=()
ERRORS=()
UPDATED_PLUGINS=0
TOTAL_PLUGINS=0
UPDATED_TOOLS=0
TOTAL_TOOLS=0
UPDATED_SKILLS=0
TOTAL_SKILLS=0
UPDATED_GLOBAL_PKGS=0
TOTAL_GLOBAL_PKGS=0

add_warning() { WARNINGS+=("$1"); }
add_error() { ERRORS+=("$1"); }

# ==============================================================================
# UPDATE FUNCTIONS
# ==============================================================================

update_marketplaces() {
    echo "Updating all Claude plugin marketplaces..."
    echo ""

    # 'claude plugin marketplace update' with no args updates all marketplaces
    if claude plugin marketplace update 2>/dev/null; then
        echo "  All marketplaces updated."
    else
        add_warning "Failed to update marketplaces"
    fi

    echo ""
}

update_plugins() {
    echo "Discovering installed Claude plugins..."
    echo ""

    local plugin_json
    plugin_json=$(claude plugin list --json 2>/dev/null || echo "[]")

    # Extract plugin identifiers from JSON array (id field contains "name@marketplace")
    local plugin_names
    plugin_names=$(echo "$plugin_json" | jq -r '.[].id' 2>/dev/null || echo "")

    if [ -z "$plugin_names" ]; then
        echo "  No plugins installed."
        echo ""
        return
    fi

    TOTAL_PLUGINS=$(echo "$plugin_names" | wc -l | tr -d ' ')
    echo "  Found $TOTAL_PLUGINS installed plugin(s):"
    echo "$plugin_names" | while read -r p; do echo "    - $p"; done
    echo ""

    echo "Updating plugins..."
    echo ""

    while IFS= read -r plugin; do
        [ -z "$plugin" ] && continue
        echo "  Updating: $plugin..."
        if claude plugin update "$plugin" 2>/dev/null; then
            echo "  Updated: $plugin"
            ((UPDATED_PLUGINS++)) || true
        else
            add_warning "Failed to update plugin: $plugin"
        fi
    done <<< "$plugin_names"

    echo ""
}

update_tools() {
    echo "Updating CLI tools..."
    echo ""

    if [ ${#TOOLS[@]} -eq 0 ]; then
        echo "  No tools defined in config.sh."
        echo ""
        return
    fi

    TOTAL_TOOLS=${#TOOLS[@]}
    echo "  Found $TOTAL_TOOLS tool(s) to update:"
    for t in "${TOOLS[@]}"; do echo "    - $t"; done
    echo ""

    local os_type
    os_type="$(uname -s)"
    case "$os_type" in
        Darwin) os_type="macos" ;;
        Linux)  os_type="linux" ;;
        *)      os_type="unknown" ;;
    esac

    for tool in "${TOOLS[@]}"; do
        echo "  Updating: $tool..."
        if "update_${tool}" "$os_type" 2>/dev/null; then
            ((UPDATED_TOOLS++)) || true
        else
            add_warning "Failed to update tool: $tool"
        fi
    done

    echo ""
}

update_skills() {
    echo "Updating globally installed skills..."
    echo ""

    if ! command -v npx &> /dev/null; then
        add_error "npx not found, skipping skills update"
        return
    fi

    if [ ${#SKILLS[@]} -eq 0 ]; then
        echo "  No skills defined in config.sh."
        echo ""
        return
    fi

    TOTAL_SKILLS=${#SKILLS[@]}
    echo "  Found $TOTAL_SKILLS skill(s) to update:"
    for s in "${SKILLS[@]}"; do echo "    - $s"; done
    echo ""

    for skill in "${SKILLS[@]}"; do
        echo "  Updating: $skill..."
        # shellcheck disable=SC2086
        if npx skills add $skill -g --all 2>/dev/null; then
            echo "  Updated: $skill"
            ((UPDATED_SKILLS++)) || true
        else
            add_warning "Failed to update skill: $skill"
        fi
    done

    echo ""
}

update_global_packages() {
    echo "Updating globally installed packages (npm, go, rustup)..."
    echo ""

    # --- npm global packages ---
    if command -v npm &> /dev/null; then
        echo "  [npm] Checking outdated global packages..."
        local npm_outdated
        npm_outdated=$(npm outdated -g --json 2>/dev/null || echo "{}")

        local npm_packages
        npm_packages=$(echo "$npm_outdated" | jq -r 'keys[]' 2>/dev/null || echo "")

        if [ -n "$npm_packages" ]; then
            local npm_count
            npm_count=$(echo "$npm_packages" | wc -l | tr -d ' ')
            TOTAL_GLOBAL_PKGS=$((TOTAL_GLOBAL_PKGS + npm_count))
            echo "  [npm] Found $npm_count outdated package(s):"
            echo "$npm_packages" | while read -r p; do echo "    - $p"; done

            while IFS= read -r pkg; do
                [ -z "$pkg" ] && continue
                echo "  [npm] Updating: $pkg..."
                if npm install -g "$pkg@latest" 2>/dev/null; then
                    echo "  [npm] Updated: $pkg"
                    ((UPDATED_GLOBAL_PKGS++)) || true
                else
                    add_warning "Failed to update npm global package: $pkg"
                fi
            done <<< "$npm_packages"
        else
            echo "  [npm] All global packages are up to date."
        fi
    else
        echo "  [npm] npm not found, skipping."
    fi

    echo ""

    # --- go install binaries ---
    if command -v go &> /dev/null; then
        local gobin="${GOBIN:-$(go env GOPATH)/bin}"
        echo "  [go] Checking Go binaries in $gobin..."

        if [ -d "$gobin" ]; then
            local go_binaries
            go_binaries=()

            # Find binaries that have module info with a known import path
            for bin in "$gobin"/*; do
                [ -x "$bin" ] || continue
                local mod_path
                mod_path=$(go version -m "$bin" 2>/dev/null | awk '/^\tpath\t/ {print $2}' || echo "")
                if [ -n "$mod_path" ]; then
                    go_binaries+=("$mod_path")
                fi
            done

            if [ ${#go_binaries[@]} -gt 0 ]; then
                TOTAL_GLOBAL_PKGS=$((TOTAL_GLOBAL_PKGS + ${#go_binaries[@]}))
                echo "  [go] Found ${#go_binaries[@]} binary(ies) to update:"
                for b in "${go_binaries[@]}"; do echo "    - $b"; done

                for mod in "${go_binaries[@]}"; do
                    echo "  [go] Updating: $mod..."
                    if go install "${mod}@latest" 2>/dev/null; then
                        echo "  [go] Updated: $mod"
                        ((UPDATED_GLOBAL_PKGS++)) || true
                    else
                        add_warning "Failed to update Go binary: $mod"
                    fi
                done
            else
                echo "  [go] No Go binaries with module info found."
            fi
        else
            echo "  [go] GOBIN directory not found at $gobin, skipping."
        fi
    else
        echo "  [go] go not found, skipping."
    fi

    echo ""

    # --- rustup components ---
    if command -v rustup &> /dev/null; then
        echo "  [rustup] Updating Rust toolchain and components..."

        # Update the toolchain itself (includes rustc, cargo, clippy, rustfmt, etc.)
        if rustup update 2>/dev/null; then
            echo "  [rustup] Toolchain updated."
            ((UPDATED_GLOBAL_PKGS++)) || true
        else
            add_warning "Failed to run rustup update"
        fi
        ((TOTAL_GLOBAL_PKGS++)) || true

        # Update cargo-installed binaries
        if command -v cargo &> /dev/null; then
            echo "  [cargo] Checking installed cargo binaries..."
            local cargo_list
            cargo_list=$(cargo install --list 2>/dev/null | grep -E '^[a-zA-Z]' | awk '{print $1}' || echo "")

            if [ -n "$cargo_list" ]; then
                local cargo_count
                cargo_count=$(echo "$cargo_list" | wc -l | tr -d ' ')
                TOTAL_GLOBAL_PKGS=$((TOTAL_GLOBAL_PKGS + cargo_count))
                echo "  [cargo] Found $cargo_count installed crate(s):"
                echo "$cargo_list" | while read -r c; do echo "    - $c"; done

                while IFS= read -r crate; do
                    [ -z "$crate" ] && continue
                    echo "  [cargo] Updating: $crate..."
                    if cargo install "$crate" 2>/dev/null; then
                        echo "  [cargo] Updated: $crate"
                        ((UPDATED_GLOBAL_PKGS++)) || true
                    else
                        add_warning "Failed to update cargo crate: $crate"
                    fi
                done <<< "$cargo_list"
            else
                echo "  [cargo] No cargo-installed binaries found."
            fi
        fi
    else
        echo "  [rustup] rustup not found, skipping."
    fi

    echo ""
}

# ==============================================================================
# SUMMARY
# ==============================================================================

print_summary() {
    echo "============================================"
    echo "UPDATE SUMMARY"
    echo "============================================"
    echo ""
    echo "  CLI tools updated:      $UPDATED_TOOLS / $TOTAL_TOOLS"
    echo "  Claude plugins updated: $UPDATED_PLUGINS / $TOTAL_PLUGINS"
    echo "  Skills updated:         $UPDATED_SKILLS / $TOTAL_SKILLS"
    echo "  Global packages updated: $UPDATED_GLOBAL_PKGS / $TOTAL_GLOBAL_PKGS"
    echo ""

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "WARNINGS:"
        for warning in "${WARNINGS[@]}"; do
            echo "  - $warning"
        done
        echo ""
    fi

    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo "ERRORS:"
        for error in "${ERRORS[@]}"; do
            echo "  ! $error"
        done
        echo ""
    fi

    if [ ${#WARNINGS[@]} -eq 0 ] && [ ${#ERRORS[@]} -eq 0 ]; then
        echo "All updates completed successfully!"
    fi

    echo "============================================"
}

# ==============================================================================
# MAIN
# ==============================================================================

echo "Starting Claude Templates update..."
echo ""

# Check prerequisites
if ! command -v claude &> /dev/null; then
    echo "Error: claude command not found. Run install.sh first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for JSON parsing. Install it with: brew install jq"
    exit 1
fi

update_tools
update_marketplaces
update_plugins
update_skills
update_global_packages
print_summary
