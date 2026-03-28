#!/usr/bin/env bash

# gabb - Local code indexer for semantic code understanding (https://github.com/gabb-software/gabb-cli)
# Requires: critical_error, add_warning functions from parent script

install_gabb() {
    echo "Checking for gabb..."

    if command -v gabb &> /dev/null; then
        echo "gabb already installed: $(gabb --version 2>/dev/null || echo 'version unknown')"
        return 0
    fi

    echo "gabb not found. Installing gabb via Homebrew..."
    if ! brew tap gabb-software/homebrew-tap; then
        critical_error "Failed to add gabb Homebrew tap"
    fi
    if ! brew install gabb; then
        critical_error "Failed to install gabb via Homebrew"
    fi

    if ! command -v gabb &> /dev/null; then
        critical_error "gabb installation appeared to succeed but gabb command is still not available"
    fi

    echo "gabb installed successfully: $(gabb --version 2>/dev/null || echo 'version unknown')"

    # Register Gabb MCP server for Claude Code (user scope, not project)
    echo "Registering Gabb MCP server for Claude Code..."
    if ! claude mcp add --scope user gabb -- gabb mcp-server; then
        add_warning "Failed to register Gabb MCP server. Run manually: claude mcp add --scope user gabb -- gabb mcp-server"
    fi

    # Interactive setup — user must run manually
    echo ""
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║  IMPORTANT: Run 'gabb setup' to configure your workspace.   ║"
    echo "  ║  This is an interactive command that must be run manually.   ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    add_warning "Run 'gabb setup' manually to complete Gabb configuration (interactive)"
}

update_gabb() {
    echo "Updating gabb..."

    if ! command -v gabb &> /dev/null; then
        add_warning "gabb is not installed, skipping update"
        return 0
    fi

    brew upgrade gabb 2>/dev/null || echo "gabb already up to date"
    echo "gabb update complete"
}

uninstall_gabb() {
    echo "Removing gabb..."

    if ! command -v gabb &> /dev/null; then
        echo "gabb is not installed, nothing to remove"
        return 0
    fi

    # Remove Gabb MCP server from Claude Code
    echo "Removing Gabb MCP server from Claude Code..."
    claude mcp remove --scope user gabb 2>/dev/null || add_warning "Failed to remove Gabb MCP server. Run manually: claude mcp remove --scope user gabb"

    brew uninstall gabb 2>/dev/null || add_warning "Failed to uninstall gabb via Homebrew"
    # Remove the tap too
    brew untap gabb-software/homebrew-tap 2>/dev/null || true

    echo "gabb removal complete"
}
