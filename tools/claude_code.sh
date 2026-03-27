#!/usr/bin/env bash

# Claude Code - install, update, and uninstall functions
# Requires: critical_error, add_warning functions from parent script

_run_claude_code_installer() {
    curl -fsSL https://claude.ai/install.sh | bash
}

install_claude_code() {
    echo "Checking for Claude Code..."

    if command -v claude &> /dev/null; then
        echo "Claude Code already installed: $(claude --version)"
        return 0
    fi

    echo "Claude Code not found. Installing..."
    if ! _run_claude_code_installer; then
        critical_error "Failed to install Claude Code"
    fi

    if ! command -v claude &> /dev/null; then
        critical_error "Claude Code installation appeared to succeed but claude command is still not available"
    fi

    echo "Claude Code installed successfully"
}

update_claude_code() {
    echo "Updating Claude Code..."

    if ! command -v claude &> /dev/null; then
        add_warning "Claude Code is not installed, skipping update"
        return 0
    fi

    if _run_claude_code_installer; then
        echo "Claude Code updated successfully"
    else
        add_warning "Failed to update Claude Code"
    fi
}

uninstall_claude_code() {
    echo "Removing Claude Code..."

    if ! command -v claude &> /dev/null; then
        echo "Claude Code is not installed, nothing to remove"
        return 0
    fi

    # Native install places the binary at ~/.claude/local/claude
    local claude_bin="$HOME/.claude/local/claude"
    if [ -f "$claude_bin" ]; then
        rm -f "$claude_bin" 2>/dev/null || add_warning "Failed to remove $claude_bin (may need elevated privileges)"
    fi

    # Remove the symlink (typically /usr/local/bin/claude)
    local claude_link
    claude_link=$(command -v claude 2>/dev/null)
    if [ -n "$claude_link" ] && [ -L "$claude_link" ]; then
        rm -f "$claude_link" 2>/dev/null || add_warning "Failed to remove symlink $claude_link (may need elevated privileges)"
    fi

    if command -v claude &> /dev/null; then
        add_warning "Claude Code may still be installed. Remove it manually if needed."
    else
        echo "Claude Code removed successfully"
    fi
}
