#!/usr/bin/env bash

# ripgrep - fast grep alternative (https://github.com/BurntSushi/ripgrep)
# Requires: critical_error, add_warning functions from parent script
install_rg() {
    echo "Checking for rg..."

    if command -v rg &> /dev/null; then
        echo "rg already installed: $(rg --version | head -1)"
        return 0
    fi

    echo "rg not found. Installing ripgrep via Homebrew..."
    if ! brew install ripgrep; then
        critical_error "Failed to install ripgrep via Homebrew"
    fi

    if ! command -v rg &> /dev/null; then
        critical_error "ripgrep installation appeared to succeed but rg command is still not available"
    fi

    echo "ripgrep installed successfully: $(rg --version | head -1)"

    # Configure grep -> rg alias in shell RC files
    echo "Configuring grep -> rg alias..."
    local alias_line="alias grep='rg'"
    local alias_added=false

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            echo "  $rc_file does not exist, skipping"
            continue
        fi

        if grep -qF "alias grep=" "$rc_file"; then
            echo "  Alias 'grep' already present in $rc_file, skipping"
        else
            echo "" >> "$rc_file"
            echo "# Use ripgrep as grep replacement (added by claude-templates install.sh)" >> "$rc_file"
            echo "$alias_line" >> "$rc_file"
            echo "  Added 'grep' alias to $rc_file"
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
    echo "    fish:    alias grep rg; funcsave grep"
    echo "    nushell: alias grep = rg  (add to config.nu)"
}

update_rg() {
    echo "Updating ripgrep..."

    if ! command -v rg &> /dev/null; then
        add_warning "ripgrep is not installed, skipping update"
        return 0
    fi

    brew upgrade ripgrep 2>/dev/null || echo "ripgrep already up to date"
    echo "ripgrep update complete"
}

uninstall_rg() {
    echo "Removing ripgrep..."

    if ! command -v rg &> /dev/null; then
        echo "ripgrep is not installed, nothing to remove"
        return 0
    fi

    brew uninstall ripgrep 2>/dev/null || add_warning "Failed to uninstall ripgrep via Homebrew"

    # Remove grep -> rg alias from shell RC files
    echo "Removing grep -> rg alias..."
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            continue
        fi

        if grep -qF "alias grep='rg'" "$rc_file"; then
            sed -i.bak '/# Use ripgrep as grep replacement (added by claude-templates install.sh)/d' "$rc_file"
            sed -i.bak "/alias grep='rg'/d" "$rc_file"
            rm -f "${rc_file}.bak"
            echo "  Removed grep alias from $rc_file"
        fi
    done

    echo "ripgrep removal complete"
}
