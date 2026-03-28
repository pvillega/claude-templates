#!/usr/bin/env bash

# jq JSON processor - install and uninstall functions
# Requires: critical_error, add_warning functions from parent script
install_jq() {
    echo "Checking for jq..."

    if command -v jq &> /dev/null; then
        echo "jq already installed: $(jq --version)"
        return 0
    fi

    echo "jq not found. Installing jq via Homebrew..."
    if ! brew install jq; then
        critical_error "Failed to install jq via Homebrew"
    fi

    if ! command -v jq &> /dev/null; then
        critical_error "jq installation appeared to succeed but jq command is still not available"
    fi

    echo "jq installed successfully"
}

update_jq() {
    echo "Updating jq..."

    if ! command -v jq &> /dev/null; then
        add_warning "jq is not installed, skipping update"
        return 0
    fi

    brew upgrade jq 2>/dev/null || echo "jq already up to date"
    echo "jq update complete"
}

uninstall_jq() {
    echo "Removing jq..."

    if ! command -v jq &> /dev/null; then
        echo "jq is not installed, nothing to remove"
        return 0
    fi

    brew uninstall jq 2>/dev/null || add_warning "Failed to uninstall jq via Homebrew"
    echo "jq removal complete"
}
