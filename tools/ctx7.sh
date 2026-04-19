#!/usr/bin/env bash

# ctx7 (Context7 CLI) - install, update, and uninstall via Homebrew
# Requires: critical_error, add_warning functions from parent script

install_ctx7() {
    echo "Checking for ctx7..."

    if command -v ctx7 &> /dev/null; then
        echo "ctx7 already installed"
        return 0
    fi

    echo "ctx7 not found. Installing ctx7 via Homebrew..."
    if ! brew install ctx7; then
        critical_error "Failed to install ctx7 via Homebrew"
    fi

    if ! command -v ctx7 &> /dev/null; then
        critical_error "ctx7 installation appeared to succeed but ctx7 command is still not available"
    fi

    echo "ctx7 installed successfully"
}

update_ctx7() {
    echo "Updating ctx7..."

    if ! command -v ctx7 &> /dev/null; then
        add_warning "ctx7 is not installed, skipping update"
        return 0
    fi

    brew upgrade ctx7 2>/dev/null || echo "ctx7 already up to date"
    echo "ctx7 update complete"
}

uninstall_ctx7() {
    echo "Removing ctx7..."

    if ! command -v ctx7 &> /dev/null; then
        echo "ctx7 is not installed, nothing to remove"
        return 0
    fi

    brew uninstall ctx7 2>/dev/null || add_warning "Failed to uninstall ctx7 via Homebrew"
    echo "ctx7 removal complete"
}
