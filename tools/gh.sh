#!/usr/bin/env bash

# GitHub CLI (gh) - install and uninstall functions
# Requires: critical_error, add_warning functions from parent script
install_gh() {
    echo "Checking for GitHub CLI (gh)..."

    if command -v gh &> /dev/null; then
        echo "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    echo "GitHub CLI not found. Installing gh via Homebrew..."
    if ! brew install gh; then
        critical_error "Failed to install gh via Homebrew"
    fi

    if ! command -v gh &> /dev/null; then
        critical_error "gh installation appeared to succeed but gh command is still not available"
    fi

    echo "GitHub CLI installed successfully"
}

update_gh() {
    echo "Updating GitHub CLI (gh)..."

    if ! command -v gh &> /dev/null; then
        add_warning "GitHub CLI is not installed, skipping update"
        return 0
    fi

    brew upgrade gh 2>/dev/null || echo "gh already up to date"
    echo "GitHub CLI update complete"
}

uninstall_gh() {
    echo "Removing GitHub CLI (gh)..."

    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI is not installed, nothing to remove"
        return 0
    fi

    brew uninstall gh 2>/dev/null || add_warning "Failed to uninstall gh via Homebrew"
    echo "GitHub CLI removal complete"
}
