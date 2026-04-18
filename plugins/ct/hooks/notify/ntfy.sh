#!/usr/bin/env bash
# Remote notification hook — POSTs to ntfy.sh on Claude Stop/Notification events.
# Delivery: phone app (ntfy iOS/Android) OR browser (https://ntfy.sh/app) OR CLI
# subscriber — topic is identifier-based, any subscriber to the topic receives.
#
# Config via env (set in ~/.claude/settings.json "env" block or shell profile):
#   NTFY_TOPIC    (REQUIRED — script no-ops silently if unset)
#                 Secret topic, e.g. "claude-pvillega-9f3a". Generate with:
#                 `openssl rand -hex 8` prefixed by a personal identifier.
#                 Anyone with the topic can subscribe, so keep it unguessable.
#   NTFY_URL      (optional) — default https://ntfy.sh. Set to self-hosted URL
#                 if you run your own ntfy server.
#   NTFY_PRIORITY (optional) — default 4 (high). 1=min, 5=max. Notification
#                 events always override to 5 (user is blocked).
#   NTFY_TAGS     (optional) — default "robot". Comma-separated ntfy tag names
#                 for icon/emoji rendering (see https://ntfy.sh/docs/emojis/).
set -euo pipefail

# Silent no-op when NTFY_TOPIC is unset — hook fires on every Stop event, so
# noisy stderr would pollute logs for anyone who hasn't configured a topic.
# The `${VAR:?msg}` idiom aborts the shell with exit 1 and writes to stderr
# before `||` can catch it, so we pre-check explicitly.
if [[ -z "${NTFY_TOPIC:-}" ]]; then
  exit 0
fi

NTFY_URL="${NTFY_URL:-https://ntfy.sh}"
NTFY_PRIORITY="${NTFY_PRIORITY:-4}"
NTFY_TAGS="${NTFY_TAGS:-robot}"

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // "unknown"')
CWD=$(printf '%s' "$INPUT"   | jq -r '.cwd // empty')
MSG=$(printf '%s' "$INPUT"   | jq -r '.message // empty')   # Notification event only
PROJECT=$(basename "${CWD:-unknown}")

case "$EVENT" in
  Notification)
    TITLE="Claude waiting — ${PROJECT}"
    BODY="${MSG:-Claude needs input}"
    PRIO=5
    TAGS="bell,warning"
    ;;
  Stop)
    TITLE="Claude done — ${PROJECT}"
    BODY="Turn complete."
    PRIO="${NTFY_PRIORITY}"
    TAGS="${NTFY_TAGS},white_check_mark"
    ;;
  *)
    exit 0 ;;
esac

curl -fsS --max-time 3 \
  -H "Title: ${TITLE}" \
  -H "Priority: ${PRIO}" \
  -H "Tags: ${TAGS}" \
  -d "${BODY}" \
  "${NTFY_URL}/${NTFY_TOPIC}" > /dev/null 2>&1 || true

exit 0
