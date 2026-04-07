#!/usr/bin/env bash

# Semgrep OSS CLI - install, update, and uninstall
# SAST scanner used by the Semgrep Claude Code plugin for PostToolUse security scanning.
# Requires: critical_error, add_warning functions from parent script

install_semgrep() {
    echo "Checking for semgrep..."

    if command -v semgrep &> /dev/null; then
        echo "semgrep already installed: $(semgrep --version 2>&1 | head -1)"
        return 0
    fi

    echo "semgrep not found. Installing semgrep via Homebrew..."
    if ! brew install semgrep; then
        critical_error "Failed to install semgrep via Homebrew"
    fi

    if ! command -v semgrep &> /dev/null; then
        critical_error "semgrep installation appeared to succeed but semgrep command is still not available"
    fi

    echo "semgrep installed successfully: $(semgrep --version 2>&1 | head -1)"
}

update_semgrep() {
    echo "Updating semgrep..."

    if ! command -v semgrep &> /dev/null; then
        add_warning "semgrep is not installed, skipping update"
        return 0
    fi

    brew upgrade semgrep 2>/dev/null || echo "semgrep already up to date"
    echo "semgrep update complete"
}

uninstall_semgrep() {
    echo "Removing semgrep..."

    if ! command -v semgrep &> /dev/null; then
        echo "semgrep is not installed, nothing to remove"
        return 0
    fi

    brew uninstall semgrep 2>/dev/null || add_warning "Failed to uninstall semgrep via Homebrew"
    echo "semgrep removal complete"
}
