#!/usr/bin/env bash

# rtk - Rust Token Killer, token-optimized CLI proxy (https://github.com/rtk-ai/rtk)
# Requires: critical_error, add_warning functions from parent script

install_rtk() {
    echo "Checking for rtk..."

    if command -v rtk &> /dev/null; then
        echo "rtk already installed: $(rtk --version)"
        return 0
    fi

    echo "rtk not found. Installing rtk via Homebrew..."
    if ! brew install rtk-ai/tap/rtk; then
        critical_error "Failed to install rtk via Homebrew"
    fi

    if ! command -v rtk &> /dev/null; then
        critical_error "rtk installation appeared to succeed but rtk command is still not available"
    fi

    echo "rtk installed successfully: $(rtk --version)"

    # Initialize rtk globally (installs hooks, patches CLAUDE.md, registers in settings.json)
    echo "Initializing rtk globally..."
    if ! rtk init -g --auto-patch; then
        add_warning "rtk installed but 'rtk init -g --auto-patch' failed. Run 'rtk init -g' manually to complete setup."
    fi
}

update_rtk() {
    echo "Updating rtk..."

    if ! command -v rtk &> /dev/null; then
        add_warning "rtk is not installed, skipping update"
        return 0
    fi

    brew upgrade rtk-ai/tap/rtk 2>/dev/null || echo "rtk already up to date"

    # Re-run init to update hooks if needed
    rtk init -g --auto-patch 2>/dev/null || add_warning "Failed to update rtk hooks"

    echo "rtk update complete"
}

uninstall_rtk() {
    echo "Removing rtk..."

    if ! command -v rtk &> /dev/null; then
        echo "rtk is not installed, nothing to remove"
        return 0
    fi

    # Remove hooks, docs, and settings.json entries (creates settings.json.bak)
    echo "Removing rtk hooks and configuration..."
    rtk init --uninstall 2>/dev/null || add_warning "Failed to run 'rtk init --uninstall'"

    brew uninstall rtk-ai/tap/rtk 2>/dev/null || add_warning "Failed to uninstall rtk via Homebrew"

    echo "rtk removal complete"
}
