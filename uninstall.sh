#!/usr/bin/env bash

# Claude Templates Uninstall Script
# Reverses actions performed by install.sh.
# Compatible with bash and zsh on macOS and Linux.

# ==============================================================================
# CONFIGURATION
# ==============================================================================

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
# GLOBAL STATE
# ==============================================================================

WARNINGS=()
ERRORS=()
DRY_RUN=false

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

add_warning() {
    WARNINGS+=("$1")
}

add_error() {
    ERRORS+=("$1")
}

# Required by tool scripts but unused during uninstall; map to add_error
critical_error() {
    add_error "$1"
}

show_help() {
    echo "Claude Templates Uninstall Script"
    echo ""
    echo "Reverses the actions performed by install.sh."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run     Show what would be removed without removing anything"
    echo "  --help, -h    Show this help message"
}

print_summary() {
    echo ""
    echo "============================================"
    echo "UNINSTALL SUMMARY"
    echo "============================================"
    echo ""

    if [ ${#WARNINGS[@]} -eq 0 ] && [ ${#ERRORS[@]} -eq 0 ]; then
        echo "Uninstall completed successfully!"
        echo ""
    fi

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

    echo "MANUAL STEPS REMAINING:"
    echo "  1. Review ~/.claude/settings.json — sandbox and permission settings"
    echo "     were merged by install.sh and cannot be safely auto-removed."
    echo "  2. Review ~/.claude/CLAUDE.md — may contain your personal modifications."
    echo "     Remove manually if no longer needed."
    echo "  3. Remove environment variables from your shell config (~/.bashrc or ~/.zshrc):"
    echo "     - TAVILY_API_KEY"
    echo ""
    echo "============================================"
}

# ==============================================================================
# UNINSTALL FUNCTIONS
# ==============================================================================

uninstall_cli_tools() {
    echo "Uninstalling CLI tools..."

    local os_type
    os_type="$(uname -s)"
    case "$os_type" in
        Darwin) os_type="macos" ;;
        Linux)  os_type="linux" ;;
        *)      os_type="unknown" ;;
    esac

    for tool in "${TOOLS[@]}"; do
        # Skip claude_code — user likely wants to keep Claude Code itself
        if [ "$tool" = "claude_code" ]; then
            echo "  Skipping Claude Code (not removed by uninstall)."
            echo "  To remove it manually, see: https://docs.anthropic.com/en/docs/claude-code"
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would uninstall tool: $tool"
        else
            echo "  Uninstalling $tool..."
            "uninstall_${tool}" "$os_type" || true
        fi
    done
}

uninstall_plugins() {
    echo "Uninstalling Claude plugins..."

    for plugin in "${PLUGINS[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would uninstall plugin: $plugin"
        else
            echo "  Uninstalling $plugin..."
            if claude plugin uninstall "$plugin" 2>/dev/null; then
                echo "  Removed plugin: $plugin"
            else
                add_warning "Could not uninstall plugin $plugin (may not be installed)"
            fi
        fi
    done

    # Also remove any LSP plugins the user may have installed manually
    echo "  Checking for installed LSP plugins..."
    local lsp_plugins
    lsp_plugins=$(claude plugin list 2>/dev/null | grep -oE '[a-z]+-lsp@[^ ]+' || true)

    if [ -n "$lsp_plugins" ]; then
        while IFS= read -r lsp_plugin; do
            if [ "$DRY_RUN" = true ]; then
                echo "  [dry-run] Would uninstall LSP plugin: $lsp_plugin"
            else
                echo "  Uninstalling LSP plugin: $lsp_plugin..."
                if claude plugin uninstall "$lsp_plugin" 2>/dev/null; then
                    echo "  Removed LSP plugin: $lsp_plugin"
                else
                    add_warning "Could not uninstall LSP plugin $lsp_plugin"
                fi
            fi
        done <<< "$lsp_plugins"
    else
        echo "  No LSP plugins found."
    fi
}

remove_marketplaces() {
    echo "Removing Claude plugin marketplaces..."

    for marketplace_config in "${MARKETPLACES[@]}"; do
        local marketplace_name="${marketplace_config##*:}"

        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would remove marketplace: $marketplace_name"
        else
            echo "  Removing $marketplace_name..."
            if claude plugin marketplace remove "$marketplace_name" 2>/dev/null; then
                echo "  Removed marketplace: $marketplace_name"
            else
                add_warning "Could not remove marketplace $marketplace_name (may not be configured)"
            fi
        fi
    done
}

uninstall_skills() {
    echo "Uninstalling skills..."

    if ! command -v npx &> /dev/null; then
        add_warning "npx not found, skipping skills removal"
        return 0
    fi

    for skill in "${SKILLS[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would remove skill: $skill"
        else
            echo "  Removing skill: $skill..."
            # shellcheck disable=SC2086
            if npx skills remove $skill -g --agent claude-code -y 2>/dev/null; then
                echo "  Removed skill: $skill"
            else
                add_warning "Failed to remove skill: $skill (may need manual removal)"
            fi
        fi
    done

    # Clean up orphaned skills from the lock file that are no longer in SKILLS array
    # (e.g. skill packages removed from config.sh but still installed on disk)
    cleanup_orphaned_skills
}

# Removes skills from ~/.agents that were installed via skills.sh but are no longer
# tracked in the SKILLS config array. Uses the lock file to identify them.
cleanup_orphaned_skills() {
    local lock_file="$HOME/.agents/.skill-lock.json"

    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    if ! command -v jq &> /dev/null; then
        add_warning "jq not found, skipping orphaned skills cleanup"
        return 0
    fi

    echo "  Checking for orphaned skills in lock file..."

    local orphaned_skills
    orphaned_skills=$(jq -r '.skills // {} | to_entries[] | select(.value.sourceType == "github") | "\(.key)\t\(.value.source)"' "$lock_file" 2>/dev/null) || return 0

    if [ -z "$orphaned_skills" ]; then
        return 0
    fi

    local removed=0
    while IFS=$'\t' read -r skill_name skill_source; do
        # Skip if this skill's source repo is still in the SKILLS config
        local still_configured=false
        for configured in "${SKILLS[@]}"; do
            if [[ "$configured" == *"$skill_source"* ]]; then
                still_configured=true
                break
            fi
        done

        if [ "$still_configured" = true ]; then
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would remove orphaned skill: $skill_name (from $skill_source)"
        else
            echo "  Removing orphaned skill: $skill_name (from $skill_source)..."
            rm -rf "$HOME/.agents/skills/$skill_name"
            rm -f "$HOME/.claude/skills/$skill_name"
            removed=$((removed + 1))
        fi
    done <<< "$orphaned_skills"

    # Update the lock file to remove orphaned entries
    if [ "$DRY_RUN" = false ] && [ "$removed" -gt 0 ]; then
        # Build a jq filter that keeps only skills whose source is still in SKILLS config
        local keep_sources=""
        for configured in "${SKILLS[@]}"; do
            # Extract the owner/repo part (handles both "owner/repo" and "https://...owner/repo --skill ...")
            local repo
            repo=$(echo "$configured" | grep -oE '[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+' | head -1)
            if [ -n "$repo" ]; then
                if [ -n "$keep_sources" ]; then
                    keep_sources="$keep_sources, \"$repo\""
                else
                    keep_sources="\"$repo\""
                fi
            fi
        done

        jq --argjson sources "[$keep_sources]" '
            .skills |= with_entries(
                select(.value.sourceType != "github" or ([.value.source] | inside($sources)))
            )
        ' "$lock_file" > "$lock_file.tmp" && mv "$lock_file.tmp" "$lock_file"

        echo "  Removed $removed orphaned skill(s) and updated lock file"
    fi
}

remove_auto_compact() {
    echo "Checking autoCompactEnabled in ~/.claude.json..."
    local claude_json="$HOME/.claude.json"

    if [ ! -f "$claude_json" ]; then
        echo "  ~/.claude.json not found, skipping"
        return 0
    fi

    if ! jq empty "$claude_json" 2>/dev/null; then
        add_warning "~/.claude.json is not valid JSON, skipping autoCompactEnabled removal"
        return 0
    fi

    if jq -e '.autoCompactEnabled == false' "$claude_json" > /dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would remove autoCompactEnabled (currently set to false)"
        else
            if jq 'del(.autoCompactEnabled)' "$claude_json" > "$claude_json.tmp" && mv "$claude_json.tmp" "$claude_json"; then
                echo "  Removed autoCompactEnabled"
            else
                rm -f "$claude_json.tmp"
                add_warning "Failed to remove autoCompactEnabled"
            fi
        fi
    else
        echo "  autoCompactEnabled is not set to false, skipping"
    fi
}

remove_shell_alias() {
    echo "Removing 'cl' alias from shell config files..."

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            continue
        fi

        if ! grep -qF "alias cl=" "$rc_file"; then
            echo "  No 'cl' alias found in $rc_file"
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Would remove 'cl' alias from $rc_file"
        else
            # Remove the comment line and alias line added by install.sh
            local tmp_file="${rc_file}.tmp"
            if grep -v "# Claude Code alias (added by claude-templates install.sh)" "$rc_file" \
                | grep -v "^alias cl=" > "$tmp_file" && mv "$tmp_file" "$rc_file"; then
                echo "  Removed 'cl' alias from $rc_file"
            else
                rm -f "$tmp_file"
                add_warning "Failed to remove alias from $rc_file"
            fi
        fi
    done
}

warn_settings_json() {
    if [ -f "$HOME/.claude/settings.json" ]; then
        add_warning "~/.claude/settings.json contains sandbox/permission settings merged by install.sh. These cannot be safely auto-removed. Please review manually."
    fi
}

warn_claude_md() {
    if [ -f "$HOME/.claude/CLAUDE.md" ]; then
        add_warning "~/.claude/CLAUDE.md exists and may contain your personal modifications. Review and remove manually if desired."
    fi
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

echo "Claude Templates Uninstall"
if [ "$DRY_RUN" = true ]; then
    echo "(dry-run mode — no changes will be made)"
fi
echo ""

# Confirmation prompt (skip in dry-run mode)
if [ "$DRY_RUN" = false ]; then
    echo "This will remove CLI tools, plugins, marketplaces, skills, and shell"
    echo "aliases installed by install.sh."
    echo ""
    read -r -p "Are you sure you want to continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo ""
            ;;
        *)
            echo "Uninstall cancelled."
            exit 0
            ;;
    esac
fi

# Uninstall plugins first (requires claude CLI)
if ! command -v claude &> /dev/null; then
    add_warning "claude CLI not found. Skipping plugin and marketplace removal."
    echo "Skipping plugin and marketplace removal (claude CLI not found)."
    echo ""
else
    uninstall_plugins
    echo ""

    remove_marketplaces
    echo ""
fi

# Uninstall skills
uninstall_skills
echo ""

# Uninstall CLI tools (after plugins, since plugins may depend on claude)
uninstall_cli_tools
echo ""

# Remove autoCompactEnabled from ~/.claude.json
if ! command -v jq &> /dev/null; then
    add_warning "jq not found. Skipping autoCompactEnabled removal from ~/.claude.json."
else
    remove_auto_compact
fi
echo ""

# Remove shell alias
remove_shell_alias
echo ""

# Warn about things that need manual review
warn_settings_json
warn_claude_md

# Print final summary
print_summary
