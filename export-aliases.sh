#!/usr/bin/env bash

# Exports current shell aliases to ~/.claude/shell-aliases.txt.
# The ct plugin's SessionStart hook reads this file on startup|clear.
# Lives outside the plugin so it survives plugin updates/reinstalls.
# Run this after adding new aliases.

set -euo pipefail

mkdir -p "$HOME/.claude"
TARGET="$HOME/.claude/shell-aliases.txt"
# Aliases are shell-local: this script's bash subshell has none of the user's.
# Spawn the user's login shell in interactive mode so rc files define aliases.
"${SHELL:-zsh}" -ic 'alias' >"$TARGET" 2>/dev/null || true
echo "Generated $TARGET"
