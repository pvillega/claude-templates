#!/usr/bin/env bash

# jscpd (copy/paste detector) - install, update, and uninstall via Homebrew
# Requires: critical_error, add_warning functions from parent script

install_jscpd() {
    echo "Checking for jscpd..."

    if command -v jscpd &> /dev/null; then
        echo "jscpd already installed"
        return 0
    fi

    echo "jscpd not found. Installing jscpd via Homebrew..."
    if ! brew install jscpd; then
        critical_error "Failed to install jscpd via Homebrew"
    fi

    if ! command -v jscpd &> /dev/null; then
        critical_error "jscpd installation appeared to succeed but jscpd command is still not available"
    fi

    echo "jscpd installed successfully"
}

update_jscpd() {
    echo "Updating jscpd..."

    if ! command -v jscpd &> /dev/null; then
        add_warning "jscpd is not installed, skipping update"
        return 0
    fi

    brew upgrade jscpd 2>/dev/null || echo "jscpd already up to date"
    echo "jscpd update complete"
}

uninstall_jscpd() {
    echo "Removing jscpd..."

    if ! command -v jscpd &> /dev/null; then
        echo "jscpd is not installed, nothing to remove"
        return 0
    fi

    brew uninstall jscpd 2>/dev/null || add_warning "Failed to uninstall jscpd via Homebrew"
    echo "jscpd removal complete"
}
