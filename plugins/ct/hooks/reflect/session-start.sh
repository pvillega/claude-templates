#!/usr/bin/env bash
# SessionStart hook: nudges user to review pending reflections.
# Checks .claude/REFLECTION.md for [PENDING] entries and injects a reminder.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

REFLECTION_FILE="${CWD}/.claude/REFLECTION.md"

# Exit silently if no reflection file exists
if [ ! -f "$REFLECTION_FILE" ]; then
  exit 0
fi

# Count [PENDING] entries
PENDING_COUNT=$(grep -c '\[PENDING\]' "$REFLECTION_FILE" 2>/dev/null || echo "0")

# Exit silently if no pending entries
if [ "$PENDING_COUNT" -eq 0 ]; then
  exit 0
fi

# Inject reminder
jq -n --arg ctx "You have ${PENDING_COUNT} pending reflection(s) to review. Run \`/reflect review\` to process them." '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
