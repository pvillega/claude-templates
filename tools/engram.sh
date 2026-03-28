#!/usr/bin/env bash

# engram - Persistent memory for AI coding agents (https://github.com/Gentleman-Programming/engram)
# Requires: critical_error, add_warning functions from parent script

install_engram() {
    echo "Checking for engram..."

    if command -v engram &> /dev/null; then
        echo "engram already installed: $(engram --version 2>/dev/null || echo 'version unknown')"
        return 0
    fi

    echo "engram not found. Installing engram via Homebrew..."
    if ! brew install gentleman-programming/tap/engram; then
        critical_error "Failed to install engram via Homebrew"
    fi

    if ! command -v engram &> /dev/null; then
        critical_error "engram installation appeared to succeed but engram command is still not available"
    fi

    echo "engram installed successfully: $(engram --version 2>/dev/null || echo 'version unknown')"
}

update_engram() {
    echo "Updating engram..."

    if ! command -v engram &> /dev/null; then
        add_warning "engram is not installed, skipping update"
        return 0
    fi

    brew upgrade gentleman-programming/tap/engram 2>/dev/null || echo "engram already up to date"
    echo "engram update complete"
}

uninstall_engram() {
    echo "Removing engram..."

    if ! command -v engram &> /dev/null; then
        echo "engram is not installed, nothing to remove"
        return 0
    fi

    brew uninstall gentleman-programming/tap/engram 2>/dev/null || add_warning "Failed to uninstall engram via Homebrew"
    echo "engram removal complete"
}
