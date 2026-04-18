#!/usr/bin/env bash

# uv (Astral Python package manager, https://github.com/astral-sh/uv) - install/update/uninstall functions
# Requires: critical_error, add_warning functions from parent script
install_uv() {
    echo "Checking for uv..."

    if command -v uv &> /dev/null; then
        echo "uv already installed: $(uv --version)"
        return 0
    fi

    echo "uv not found. Installing uv via Homebrew..."
    if ! brew install uv; then
        critical_error "Failed to install uv via Homebrew"
    fi

    if ! command -v uv &> /dev/null; then
        critical_error "uv installation appeared to succeed but uv command is still not available"
    fi

    echo "uv installed successfully: $(uv --version)"
}

update_uv() {
    echo "Updating uv..."

    if ! command -v uv &> /dev/null; then
        add_warning "uv is not installed, skipping update"
        return 0
    fi

    brew upgrade uv 2>/dev/null || echo "uv already up to date"
    echo "uv update complete"
}

uninstall_uv() {
    echo "Removing uv..."

    if ! command -v uv &> /dev/null; then
        echo "uv is not installed, nothing to remove"
        return 0
    fi

    brew uninstall uv 2>/dev/null || add_warning "Failed to uninstall uv via Homebrew"
    echo "uv removal complete"
}
