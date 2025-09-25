#!/bin/bash

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

claude --dangerously-skip-permissions --append-system-prompt "$(cat "$SCRIPT_DIR/auto-plan-mode.txt")"
