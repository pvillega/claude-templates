#!/usr/bin/env bash

# Tavily CLI - install, update, and uninstall functions
# Requires: critical_error, add_warning functions from parent script
# Uses `uv tool` (installed via tools/uv.sh, sourced first alphabetically) to
# avoid PEP 668 issues on Ubuntu 24+ / modern macOS without needing pipx.

install_tavily() {
    echo "Checking for Tavily CLI..."

    if command -v tvly &> /dev/null; then
        echo "Tavily CLI already installed"
        return 0
    fi

    if ! command -v uv &> /dev/null; then
        critical_error "uv not found (expected from tools/uv.sh); cannot install Tavily CLI"
    fi

    echo "Tavily CLI not found. Installing via uv tool..."
    if ! uv tool install tavily-cli; then
        critical_error "Failed to install Tavily CLI"
    fi

    # uv installs binaries under ~/.local/bin; ensure it's on PATH for this session
    local uv_bin="$HOME/.local/bin"
    if [[ ":$PATH:" != *":$uv_bin:"* ]]; then
        export PATH="$uv_bin:$PATH"
    fi

    if ! command -v tvly &> /dev/null; then
        critical_error "Tavily CLI installation appeared to succeed but tvly command is still not available"
    fi

    echo "Tavily CLI installed successfully"
}

update_tavily() {
    echo "Updating Tavily CLI..."

    if ! command -v tvly &> /dev/null; then
        add_warning "Tavily CLI is not installed, skipping update"
        return 0
    fi

    if ! command -v uv &> /dev/null; then
        add_warning "uv not available, cannot update Tavily CLI"
        return 0
    fi

    if uv tool upgrade tavily-cli; then
        echo "Tavily CLI updated successfully"
    else
        add_warning "Failed to update Tavily CLI"
    fi
}

uninstall_tavily() {
    echo "Removing Tavily CLI..."

    if ! command -v tvly &> /dev/null; then
        echo "Tavily CLI is not installed, nothing to remove"
        return 0
    fi

    if command -v uv &> /dev/null && uv tool uninstall tavily-cli 2>/dev/null; then
        echo "Tavily CLI removed via uv tool"
        return 0
    fi

    # Manual fallback if uv is gone or the install was not uv-managed
    local tavily_path
    tavily_path=$(command -v tvly 2>/dev/null)
    if [ -n "$tavily_path" ]; then
        rm -f "$tavily_path" 2>/dev/null || add_warning "Failed to remove Tavily CLI binary at $tavily_path (may need elevated privileges)"
    fi

    echo "Tavily CLI removal complete"
}
