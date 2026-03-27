#!/usr/bin/env bash

# ripgrep - fast grep alternative (https://github.com/BurntSushi/ripgrep)
# Requires: OS_TYPE variable set to "macos" or "linux"
# Requires: critical_error, add_warning functions from parent script

install_rg() {
    echo "Checking for rg..."

    if command -v rg &> /dev/null; then
        echo "rg already installed: $(rg --version | head -1)"
        return 0
    fi

    echo "rg not found. Installing ripgrep..."
    local os_type="${1:-$OS_TYPE}"

    if [ "$os_type" = "macos" ]; then
        if ! command -v brew &> /dev/null; then
            critical_error "Homebrew is required to install ripgrep on macOS but is not installed. Please install Homebrew first: https://brew.sh"
        fi
        echo "Installing ripgrep via Homebrew..."
        if ! brew install ripgrep; then
            critical_error "Failed to install ripgrep via Homebrew"
        fi
    else
        if command -v apt-get &> /dev/null; then
            echo "Installing ripgrep via apt-get..."
            if ! (sudo apt-get update && sudo apt-get install -y ripgrep); then
                critical_error "Failed to install ripgrep via apt-get"
            fi
        elif command -v dnf &> /dev/null; then
            echo "Installing ripgrep via dnf..."
            if ! sudo dnf install -y ripgrep; then
                critical_error "Failed to install ripgrep via dnf"
            fi
        elif command -v yum &> /dev/null; then
            echo "Installing ripgrep via yum..."
            if ! sudo yum install -y ripgrep; then
                critical_error "Failed to install ripgrep via yum"
            fi
        else
            critical_error "Could not find a supported package manager (apt-get, dnf, or yum) to install ripgrep. Please install ripgrep manually: https://github.com/BurntSushi/ripgrep#installation"
        fi
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

    local os_type="${1:-$OS_TYPE}"

    if [ "$os_type" = "macos" ]; then
        if command -v brew &> /dev/null; then
            brew upgrade ripgrep 2>/dev/null || echo "ripgrep already up to date"
        else
            add_warning "Cannot update ripgrep: Homebrew not found"
        fi
    else
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install --only-upgrade -y ripgrep 2>/dev/null || add_warning "Failed to update ripgrep via apt-get"
        elif command -v dnf &> /dev/null; then
            sudo dnf upgrade -y ripgrep 2>/dev/null || add_warning "Failed to update ripgrep via dnf"
        elif command -v yum &> /dev/null; then
            sudo yum upgrade -y ripgrep 2>/dev/null || add_warning "Failed to update ripgrep via yum"
        else
            add_warning "Cannot update ripgrep: no supported package manager found"
        fi
    fi

    echo "ripgrep update complete"
}

uninstall_rg() {
    echo "Removing ripgrep..."

    if ! command -v rg &> /dev/null; then
        echo "ripgrep is not installed, nothing to remove"
        return 0
    fi

    local os_type="${1:-$OS_TYPE}"

    if [ "$os_type" = "macos" ]; then
        if command -v brew &> /dev/null; then
            brew uninstall ripgrep 2>/dev/null || add_warning "Failed to uninstall ripgrep via Homebrew"
        else
            add_warning "Cannot uninstall ripgrep: Homebrew not found"
        fi
    else
        if command -v apt-get &> /dev/null; then
            sudo apt-get remove -y ripgrep 2>/dev/null || add_warning "Failed to uninstall ripgrep via apt-get"
        elif command -v dnf &> /dev/null; then
            sudo dnf remove -y ripgrep 2>/dev/null || add_warning "Failed to uninstall ripgrep via dnf"
        elif command -v yum &> /dev/null; then
            sudo yum remove -y ripgrep 2>/dev/null || add_warning "Failed to uninstall ripgrep via yum"
        else
            add_warning "Cannot uninstall ripgrep: no supported package manager found"
        fi
    fi

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
