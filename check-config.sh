#!/usr/bin/env bash
#
# check-config.sh - Validate project configuration
#
# Checks that a target folder is properly configured for use with this project.
#
# Usage: check-config.sh <target-folder>
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more errors found
#   2 - Only warnings found (no errors)

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# (No configuration constants needed for this script)

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

# Color definitions
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

# Arrays to collect errors and warnings
errors=()
warnings=()

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Displays usage information and exits
usage() {
    echo "Usage: $0 <target-folder>"
    echo ""
    echo "Validates that a folder is properly configured for use with this project."
    echo ""
    echo "Checks performed:"
    echo "  - ~/.local/bin is in PATH"
    echo "  - cl.sh command is available"
    echo "  - buildAll.sh exists in target folder"
    echo "  - ~/.claude.json has autoCompactEnabled set to false"
    echo "  - MCP server environment variables are set (warning if missing)"
    echo "  - .worktreeinclude exists (creates with defaults if .env* files present)"
    echo "  - ~/.claude/Aliases.md exists (warning if missing)"
    echo "  - ~/.claude/settings.json sandbox configuration:"
    echo "    - alwaysThinkingEnabled is true"
    echo "    - sandbox.enabled is true"
    echo "    - sandbox.autoAllowBashIfSandboxed is true"
    echo "    - sandbox.allowUnsandboxedCommands is false"
    echo "    - sandbox.enableWeakerNestedSandbox is false (warning if not)"
    echo "    - sandbox.network.allowLocalBinding is false"
    echo "    - sandbox.excludedCommands is empty"
    exit 1
}

# Adds a warning message to the warnings array
add_warning() {
    warnings+=("$1")
}

# Adds an error message to the errors array
add_error() {
    errors+=("$1")
}

# Prints the final results including errors and warnings
# Args:
#   $1: Target folder path (for success message)
print_results() {
    local target_folder="$1"

    echo ""
    echo "Configuration Check Results"
    echo "=========================="
    echo ""

    # Count errors and warnings
    local error_count=${#errors[@]}
    local warning_count=${#warnings[@]}

    # Display errors
    if [[ $error_count -gt 0 ]]; then
        echo -e "${RED}✗ ERRORS ($error_count):${NC}"
        for error in "${errors[@]}"; do
            echo -e "${RED}  • $error${NC}"
        done
        echo ""
    fi

    # Display warnings
    if [[ $warning_count -gt 0 ]]; then
        echo -e "${YELLOW}⚠ WARNINGS ($warning_count):${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "${YELLOW}  • $warning${NC}"
        done
        echo ""
    fi

    # Display success or failure summary
    if [[ $error_count -eq 0 ]] && [[ $warning_count -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        echo "Target folder: $target_folder"
        echo "Configuration is ready for use."
        exit 0
    elif [[ $error_count -gt 0 ]]; then
        echo -e "${RED}Configuration check failed with $error_count error(s) and $warning_count warning(s)${NC}"
        exit 1
    else
        echo -e "${YELLOW}Configuration check completed with $warning_count warning(s)${NC}"
        exit 2
    fi
}

# ==============================================================================
# CHECK FUNCTIONS
# ==============================================================================

# Checks if ~/.local/bin is in PATH
check_local_bin_in_path() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        add_error "~/.local/bin is not in PATH"
    fi
}

# Checks if cl.sh command is available in PATH
check_cl_sh_available() {
    if ! command -v cl.sh &>/dev/null; then
        add_error "cl.sh command not found in PATH"
    fi
}

# Checks if buildAll.sh exists in the target folder
check_buildall_exists() {
    local target_folder="$1"
    if [[ -d "$target_folder" ]] && [[ ! -f "$target_folder/buildAll.sh" ]]; then
        add_error "buildAll.sh not found in $target_folder"
    fi
}

# Checks if ~/.claude.json has autoCompactEnabled set to false
check_claude_json_config() {
    if [[ ! -f "$HOME/.claude.json" ]]; then
        add_error "~/.claude.json not found"
    elif ! jq empty "$HOME/.claude.json" 2>/dev/null; then
        add_error "~/.claude.json is not valid JSON"
    else
        if ! jq -e 'has("autoCompactEnabled")' "$HOME/.claude.json" >/dev/null 2>&1; then
            add_error "~/.claude.json missing autoCompactEnabled key"
        else
            local auto_compact
            auto_compact=$(jq -r '.autoCompactEnabled | tostring' "$HOME/.claude.json" 2>/dev/null)
            if [[ "$auto_compact" != "false" ]]; then
                add_error "~/.claude.json autoCompactEnabled is not false (current value: $auto_compact)"
            fi
        fi
    fi
}

# Checks if MCP server environment variables are set (warnings only)
check_mcp_env_vars() {
    if [[ ! -f "$HOME/.claude.json" ]] || ! jq empty "$HOME/.claude.json" 2>/dev/null; then
        return 0
    fi

    # Get MCP server names
    local mcp_servers
    mcp_servers=$(jq -r '.mcpServers // {} | keys[]' "$HOME/.claude.json" 2>/dev/null | grep -v "^mcpServers$" || true)

    if [[ -n "$mcp_servers" ]]; then
        local mcp_path=".mcpServers"

        while IFS= read -r server_name; do
            # Get environment variable keys for this server
            local env_vars
            env_vars=$(jq -r "$mcp_path.\"$server_name\".env // {} | keys[]" "$HOME/.claude.json" 2>/dev/null)

            if [[ -n "$env_vars" ]]; then
                while IFS= read -r env_var; do
                    # Check if the environment variable is set and non-empty
                    if [[ -z "${!env_var:-}" ]]; then
                        add_warning "MCP server '$server_name' requires $env_var but it is not set or empty"
                    fi
                done <<< "$env_vars"
            fi
        done <<< "$mcp_servers"
    fi
}

# Checks if .worktreeinclude exists and creates it if .env* files are present
check_worktreeinclude() {
    local target_folder="$1"
    local worktreeinclude_path="$target_folder/.worktreeinclude"

    if [[ -f "$worktreeinclude_path" ]]; then
        return 0
    fi

    # Check if any .env* files exist in the target folder
    local env_files
    env_files=$(find "$target_folder" -maxdepth 1 -name '.env*' -type f 2>/dev/null | head -1)

    if [[ -n "$env_files" ]]; then
        # .env* files exist but no .worktreeinclude - create one with defaults
        cat > "$worktreeinclude_path" << 'EOF'
.env
.env.local
.env.*
**/.claude/settings.local.json
EOF
        add_warning ".worktreeinclude was missing but .env* files exist - created with defaults. See: https://code.claude.com/docs/en/desktop#copying-files-ignored-with-gitignore"
    else
        # No .env* files, just warn
        add_warning ".worktreeinclude not found in $target_folder. Consider creating one for git worktree support. See: https://code.claude.com/docs/en/desktop#copying-files-ignored-with-gitignore"
    fi
}

# Checks if ~/.claude/Aliases.md exists
check_aliases_file() {
    if [[ ! -f "$HOME/.claude/Aliases.md" ]]; then
        add_warning "~/.claude/Aliases.md not found. Run /ct:discover-aliases to generate it and avoid Claude getting confused when running aliased commands"
    fi
}

# Checks ~/.claude/settings.json sandbox configuration
check_sandbox_settings() {
    if [[ ! -f "$HOME/.claude/settings.json" ]]; then
        add_error "~/.claude/settings.json not found"
        return 1
    fi

    if ! jq empty "$HOME/.claude/settings.json" 2>/dev/null; then
        add_error "~/.claude/settings.json is not valid JSON"
        return 1
    fi

    # Check alwaysThinkingEnabled
    local always_thinking
    always_thinking=$(jq -r '.alwaysThinkingEnabled // "missing"' "$HOME/.claude/settings.json" 2>/dev/null)
    if [[ "$always_thinking" == "missing" ]]; then
        add_error "~/.claude/settings.json missing alwaysThinkingEnabled key"
    elif [[ "$always_thinking" != "true" ]]; then
        add_error "~/.claude/settings.json alwaysThinkingEnabled is not true (current: $always_thinking)"
    fi

    # Check sandbox.enabled
    local sandbox_enabled
    sandbox_enabled=$(jq -r '.sandbox.enabled // "missing"' "$HOME/.claude/settings.json" 2>/dev/null)
    if [[ "$sandbox_enabled" == "missing" ]]; then
        add_error "~/.claude/settings.json missing sandbox.enabled key"
    elif [[ "$sandbox_enabled" != "true" ]]; then
        add_error "~/.claude/settings.json sandbox.enabled is not true (current: $sandbox_enabled)"
    fi

    # Check sandbox.autoAllowBashIfSandboxed
    local auto_allow_bash
    auto_allow_bash=$(jq -r '.sandbox.autoAllowBashIfSandboxed // "missing"' "$HOME/.claude/settings.json" 2>/dev/null)
    if [[ "$auto_allow_bash" == "missing" ]]; then
        add_error "~/.claude/settings.json missing sandbox.autoAllowBashIfSandboxed key"
    elif [[ "$auto_allow_bash" != "true" ]]; then
        add_error "~/.claude/settings.json sandbox.autoAllowBashIfSandboxed is not true (current: $auto_allow_bash)"
    fi

    # Check sandbox.allowUnsandboxedCommands
    if ! jq -e '.sandbox | has("allowUnsandboxedCommands")' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
        add_error "~/.claude/settings.json missing sandbox.allowUnsandboxedCommands key"
    else
        local allow_unsandboxed
        allow_unsandboxed=$(jq -r '.sandbox.allowUnsandboxedCommands | tostring' "$HOME/.claude/settings.json" 2>/dev/null)
        if [[ "$allow_unsandboxed" != "false" ]]; then
            add_error "~/.claude/settings.json sandbox.allowUnsandboxedCommands is not false (current: $allow_unsandboxed)"
        fi
    fi

    # Check sandbox.enableWeakerNestedSandbox (warning only)
    if ! jq -e '.sandbox | has("enableWeakerNestedSandbox")' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
        add_warning "~/.claude/settings.json missing sandbox.enableWeakerNestedSandbox key"
    else
        local weaker_nested
        weaker_nested=$(jq -r '.sandbox.enableWeakerNestedSandbox | tostring' "$HOME/.claude/settings.json" 2>/dev/null)
        if [[ "$weaker_nested" != "false" ]]; then
            add_warning "~/.claude/settings.json sandbox.enableWeakerNestedSandbox is not false (current: $weaker_nested)"
        fi
    fi

    # Check sandbox.network.allowLocalBinding
    if ! jq -e '.sandbox.network | has("allowLocalBinding")' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
        add_error "~/.claude/settings.json missing sandbox.network.allowLocalBinding key"
    else
        local allow_local_binding
        allow_local_binding=$(jq -r '.sandbox.network.allowLocalBinding | tostring' "$HOME/.claude/settings.json" 2>/dev/null)
        if [[ "$allow_local_binding" != "false" ]]; then
            add_error "~/.claude/settings.json sandbox.network.allowLocalBinding is not false (current: $allow_local_binding)"
        fi
    fi

    # Check sandbox.excludedCommands is empty array
    local excluded_commands
    excluded_commands=$(jq -r '.sandbox.excludedCommands // "missing"' "$HOME/.claude/settings.json" 2>/dev/null)
    if [[ "$excluded_commands" == "missing" ]]; then
        add_error "~/.claude/settings.json missing sandbox.excludedCommands key"
    else
        local excluded_length
        excluded_length=$(jq -r '.sandbox.excludedCommands | length' "$HOME/.claude/settings.json" 2>/dev/null)
        if [[ "$excluded_length" != "0" ]]; then
            add_error "~/.claude/settings.json sandbox.excludedCommands is not empty (current length: $excluded_length)"
        fi
    fi
}

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

# Check if parameter provided
if [[ $# -eq 0 ]]; then
    usage
fi

readonly TARGET_FOLDER="$1"

# Validate target folder exists
if [[ ! -d "$TARGET_FOLDER" ]]; then
    add_error "Target folder does not exist: $TARGET_FOLDER"
fi

# Display header
echo "Checking configuration for: $TARGET_FOLDER"
echo ""

# Perform all checks
check_local_bin_in_path
check_cl_sh_available
check_buildall_exists "$TARGET_FOLDER"
check_claude_json_config
check_mcp_env_vars
check_sandbox_settings
check_aliases_file
check_worktreeinclude "$TARGET_FOLDER"

# Display results and exit
print_results "$TARGET_FOLDER"
