#!/usr/bin/env bash
# PostToolUse hook: run semgrep on files after Edit/Write.
#
# Scans the edited file with semgrep OSS community rules.
# Exits 2 with findings to block Claude and force a fix.
# Exits 0 silently if no issues or semgrep not available.
#
# Environment:
#   SKIP_SEMGREP=1  — skip semgrep scanning for this session

set -euo pipefail

# Skip if disabled
if [ "${SKIP_SEMGREP:-}" = "1" ]; then
  exit 0
fi

# Skip if semgrep not installed
if ! command -v semgrep &> /dev/null; then
  exit 0
fi

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Skip if file doesn't exist (e.g. deleted)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Skip non-code files that semgrep can't scan
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.cfg|*.ini|*.csv|*.svg|*.png|*.jpg|*.gif|*.ico|*.lock|*.sum)
    exit 0
    ;;
esac

# Run semgrep on the single file with community rules
# --quiet suppresses status messages, --error exits non-zero on findings
FINDINGS=$(semgrep scan \
  --config auto \
  --quiet \
  --no-git-ignore \
  --error \
  "$FILE_PATH" 2>&1) || EXIT_CODE=$?

EXIT_CODE=${EXIT_CODE:-0}

if [ "$EXIT_CODE" -ne 0 ] && [ -n "$FINDINGS" ]; then
  # Output findings as hook context so Claude sees them
  # Use jq to safely encode findings into JSON string
  CONTEXT="Semgrep security scan found issues in ${FILE_PATH}. Fix these before proceeding:

${FINDINGS}"
  jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $ctx
    }
  }'
  exit 2
fi

exit 0
