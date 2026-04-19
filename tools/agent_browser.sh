#!/usr/bin/env bash

# agent-browser - AI-first browser automation CLI (https://agent-browser.dev/)
# Install, update, and uninstall via Homebrew.
# Requires: critical_error, add_warning functions from parent script

install_agent_browser() {
    echo "Checking for agent-browser..."

    if command -v agent-browser &> /dev/null; then
        echo "agent-browser already installed"
        return 0
    fi

    echo "agent-browser not found. Installing agent-browser via Homebrew..."
    if ! brew install agent-browser; then
        critical_error "Failed to install agent-browser via Homebrew"
    fi

    if ! command -v agent-browser &> /dev/null; then
        critical_error "agent-browser installation appeared to succeed but agent-browser command is still not available"
    fi

    echo "agent-browser installed successfully"

    echo "Installing browser (Chrome for Testing)..."
    if ! agent-browser install; then
        add_warning "Failed to install Chrome for Testing via agent-browser install"
    fi
}

update_agent_browser() {
    echo "Updating agent-browser..."

    if ! command -v agent-browser &> /dev/null; then
        add_warning "agent-browser is not installed, skipping update"
        return 0
    fi

    brew upgrade agent-browser 2>/dev/null || echo "agent-browser already up to date"
    echo "agent-browser update complete"
}

uninstall_agent_browser() {
    echo "Removing agent-browser..."

    if ! command -v agent-browser &> /dev/null; then
        echo "agent-browser is not installed, nothing to remove"
        return 0
    fi

    brew uninstall agent-browser 2>/dev/null || add_warning "Failed to uninstall agent-browser via Homebrew"
    echo "agent-browser removal complete"
}
