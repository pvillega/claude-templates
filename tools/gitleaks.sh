#!/usr/bin/env bash

# Gitleaks secret scanner - install, update, and uninstall
# Installs gitleaks CLI and sets up a global git pre-commit hook for secret detection.
# Requires: critical_error, add_warning functions from parent script

readonly GITLEAKS_HOOKS_DIR="$HOME/.git-hooks"
readonly GITLEAKS_HOOK_FILE="$GITLEAKS_HOOKS_DIR/pre-commit"

# Marker comments to identify the gitleaks section in the hook file
readonly GITLEAKS_MARKER_START="# --- gitleaks-start ---"
readonly GITLEAKS_MARKER_END="# --- gitleaks-end ---"

_gitleaks_hook_content() {
    cat <<'HOOK'
#!/usr/bin/env bash

# --- gitleaks-start ---
# Gitleaks pre-commit hook: scans staged changes for secrets
# Skip with: SKIP_GITLEAKS=1 git commit -m "..."
if [ "${SKIP_GITLEAKS}" != "1" ] && command -v gitleaks &> /dev/null; then
    gitleaks git --pre-commit --staged --redact -v
    if [ $? -ne 0 ]; then
        echo ""
        echo "gitleaks: secrets detected in staged changes. Commit blocked."
        echo "To skip: SKIP_GITLEAKS=1 git commit -m \"...\""
        exit 1
    fi
fi
# --- gitleaks-end ---

# Chain to repo-local pre-commit hook if it exists
_repo_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
if [ -x "$_repo_hook" ]; then
    exec "$_repo_hook"
fi
HOOK
}

install_gitleaks() {
    echo "Checking for gitleaks..."

    if command -v gitleaks &> /dev/null; then
        echo "gitleaks already installed: $(gitleaks version 2>&1)"
    else
        echo "gitleaks not found. Installing gitleaks via Homebrew..."
        if ! brew install gitleaks; then
            critical_error "Failed to install gitleaks via Homebrew"
        fi

        if ! command -v gitleaks &> /dev/null; then
            critical_error "gitleaks installation appeared to succeed but gitleaks command is still not available"
        fi

        echo "gitleaks installed successfully: $(gitleaks version 2>&1)"
    fi

    # Set up global git pre-commit hook
    _setup_gitleaks_hook
}

_setup_gitleaks_hook() {
    # Create hooks directory
    mkdir -p "$GITLEAKS_HOOKS_DIR"

    # Configure core.hooksPath if not already set
    local current_hooks_path
    current_hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")

    if [ -z "$current_hooks_path" ]; then
        echo "Setting global git hooks path to $GITLEAKS_HOOKS_DIR..."
        git config --global core.hooksPath "$GITLEAKS_HOOKS_DIR"
    elif [ "$current_hooks_path" != "$GITLEAKS_HOOKS_DIR" ]; then
        add_warning "core.hooksPath is already set to '$current_hooks_path' (not $GITLEAKS_HOOKS_DIR). Gitleaks hook will be installed there instead."
        # Use the existing hooks path
        GITLEAKS_HOOKS_DIR_ACTUAL="$current_hooks_path"
        mkdir -p "$GITLEAKS_HOOKS_DIR_ACTUAL"
    fi

    local target_dir="${GITLEAKS_HOOKS_DIR_ACTUAL:-$GITLEAKS_HOOKS_DIR}"
    local target_hook="$target_dir/pre-commit"

    # Check for existing pre-commit hook
    if [ -f "$target_hook" ]; then
        if grep -q "$GITLEAKS_MARKER_START" "$target_hook" 2>/dev/null; then
            echo "gitleaks hook already present in $target_hook"
            return 0
        fi
        add_warning "Pre-commit hook already exists at $target_hook. Gitleaks not added automatically. Add gitleaks manually — see README for instructions."
        return 0
    fi

    # Write the hook
    _gitleaks_hook_content > "$target_hook"
    chmod +x "$target_hook"
    echo "gitleaks pre-commit hook installed at $target_hook"
}

update_gitleaks() {
    echo "Updating gitleaks..."

    if ! command -v gitleaks &> /dev/null; then
        add_warning "gitleaks is not installed, skipping update"
        return 0
    fi

    brew upgrade gitleaks 2>/dev/null || echo "gitleaks already up to date"
    echo "gitleaks update complete"
}

uninstall_gitleaks() {
    echo "Removing gitleaks..."

    # Remove the binary
    if command -v gitleaks &> /dev/null; then
        brew uninstall gitleaks 2>/dev/null || add_warning "Failed to uninstall gitleaks via Homebrew"
    else
        echo "gitleaks is not installed, nothing to remove"
    fi

    # Clean up the pre-commit hook
    local hooks_path
    hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "$GITLEAKS_HOOKS_DIR")
    local target_hook="$hooks_path/pre-commit"

    if [ -f "$target_hook" ]; then
        if grep -q "$GITLEAKS_MARKER_START" "$target_hook" 2>/dev/null; then
            # Check if the hook contains ONLY gitleaks content
            local non_gitleaks_content
            non_gitleaks_content=$(sed "/$GITLEAKS_MARKER_START/,/$GITLEAKS_MARKER_END/d" "$target_hook" | grep -v '^#!/usr/bin/env bash' | grep -v '^#' | grep -v '^$' | grep -v '_repo_hook' | grep -v 'exec ')
            if [ -z "$non_gitleaks_content" ]; then
                rm "$target_hook"
                echo "gitleaks pre-commit hook removed"
            else
                add_warning "Pre-commit hook at $target_hook contains other content besides gitleaks. Remove the gitleaks section (between markers) manually."
            fi
        fi
    fi

    echo "gitleaks removal complete"
}
