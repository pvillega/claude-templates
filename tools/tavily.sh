#!/usr/bin/env bash

# Tavily CLI - install, update, and uninstall functions
# Requires: critical_error, add_warning functions from parent script

_run_tavily_installer() {
    curl -fsSL https://cli.tavily.com/install.sh | bash
}

install_tavily() {
    echo "Checking for Tavily CLI..."

    if command -v tvly &> /dev/null; then
        echo "Tavily CLI already installed"
        return 0
    fi

    echo "Tavily CLI not found. Installing..."
    if ! _run_tavily_installer; then
        critical_error "Failed to install Tavily CLI"
    fi

    if ! command -v tvly &> /dev/null; then
        critical_error "Tavily CLI installation appeared to succeed but tavily command is still not available"
    fi

    echo "Tavily CLI installed successfully"
}

update_tavily() {
    echo "Updating Tavily CLI..."

    if ! command -v tvly &> /dev/null; then
        add_warning "Tavily CLI is not installed, skipping update"
        return 0
    fi

    if _run_tavily_installer; then
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

    # Tavily CLI doesn't have a standard uninstall; try removing the binary
    local tavily_path
    tavily_path=$(command -v tvly 2>/dev/null)
    if [ -n "$tavily_path" ]; then
        rm -f "$tavily_path" 2>/dev/null || add_warning "Failed to remove Tavily CLI binary at $tavily_path (may need elevated privileges)"
    fi

    echo "Tavily CLI removal complete"
}
