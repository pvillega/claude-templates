#!/usr/bin/env bash

# fd - fast find alternative (https://github.com/sharkdp/fd)
# Requires: critical_error, add_warning functions from parent script
install_fd() {
    echo "Checking for fd..."

    if command -v fd &> /dev/null; then
        echo "fd already installed: $(fd --version)"
        return 0
    fi

    echo "fd not found. Installing fd via Homebrew..."
    if ! brew install fd; then
        critical_error "Failed to install fd via Homebrew"
    fi

    if ! command -v fd &> /dev/null; then
        critical_error "fd installation appeared to succeed but fd command is still not available"
    fi

    echo "fd installed successfully: $(fd --version)"

    # Configure find -> fd alias in shell RC files
    echo "Configuring find -> fd alias..."
    local alias_line="alias find='fd'"
    local alias_added=false

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            echo "  $rc_file does not exist, skipping"
            continue
        fi

        if grep -qF "alias find=" "$rc_file"; then
            echo "  Alias 'find' already present in $rc_file, skipping"
        else
            echo "" >> "$rc_file"
            echo "# Use fd as find replacement (added by claude-templates install.sh)" >> "$rc_file"
            echo "$alias_line" >> "$rc_file"
            echo "  Added 'find' alias to $rc_file"
            alias_added=true
        fi
    done

    if [ "$alias_added" = true ]; then
        echo ""
        echo "  NOTE: Run 'source ~/.bashrc' (or ~/.zshrc) or open a new terminal for the alias to take effect."
    fi

    # Message for other shells
    echo ""
    echo "  For other shells (fish, nushell, etc.), add the equivalent alias manually:"
    echo "    fish:    alias find fd; funcsave find"
    echo "    nushell: alias find = fd  (add to config.nu)"
}

update_fd() {
    echo "Updating fd..."

    if ! command -v fd &> /dev/null; then
        add_warning "fd is not installed, skipping update"
        return 0
    fi

    brew upgrade fd 2>/dev/null || echo "fd already up to date"
    echo "fd update complete"
}

uninstall_fd() {
    echo "Removing fd..."

    if ! command -v fd &> /dev/null; then
        echo "fd is not installed, nothing to remove"
        return 0
    fi

    brew uninstall fd 2>/dev/null || add_warning "Failed to uninstall fd via Homebrew"

    # Remove find -> fd alias from shell RC files
    echo "Removing find -> fd alias..."
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            continue
        fi

        if grep -qF "alias find='fd'" "$rc_file"; then
            sed -i.bak '/# Use fd as find replacement (added by claude-templates install.sh)/d' "$rc_file"
            sed -i.bak "/alias find='fd'/d" "$rc_file"
            rm -f "${rc_file}.bak"
            echo "  Removed find alias from $rc_file"
        fi
    done

    echo "fd removal complete"
}
