#!/usr/bin/env bash

# Exports current shell aliases to ~/.claude/shell-aliases.txt
# Run this after installing new tools/aliases to keep Claude Code's alias list up to date.

mkdir -p "$HOME/.claude"
alias > "$HOME/.claude/shell-aliases.txt" 2>/dev/null || true
echo "Generated ~/.claude/shell-aliases.txt"
