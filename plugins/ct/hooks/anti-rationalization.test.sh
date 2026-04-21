#!/usr/bin/env bash
# Tests for the anti-rationalization PreToolUse hook.
# Runs the hook against canned JSONL transcripts and asserts exit codes.
# Exit 0 = all pass; exit 1 = one or more failures.

set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/anti-rationalization"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

PASS=0
FAIL=0

assert_exit() {
  local name=$1 expected=$2 actual=$3
  if [[ "$expected" == "$actual" ]]; then
    PASS=$((PASS+1))
    echo "  ok   - $name"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL - $name (expected exit $expected, got $actual)"
  fi
}

# Writes a line to a fixture transcript representing one JSONL entry.
# Args: fixture_path, role ("user"|"assistant"), content_json
add_entry() {
  local path=$1 role=$2 content=$3
  jq -cn \
    --arg role "$role" \
    --argjson content "$content" \
    '{type: $role, message: {role: $role, content: $content}, timestamp: "2026-04-21T16:04:05.317Z"}' \
    >> "$path"
}

# --- Test 1: Rationalization in preceding text block MUST block TaskUpdate completion ---
FIX1="$FIXTURE_DIR/1.jsonl"
add_entry "$FIX1" user '[{"type":"text","text":"Review the findings."}]'
add_entry "$FIX1" assistant '[{"type":"text","text":"Finding 1 is a pre-existing concern. Rejecting the fix as out of scope."}]'
add_entry "$FIX1" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"completed","title":"Review done"}}]'

INPUT=$(jq -cn --arg t "$FIX1" '{tool_input: {status: "completed"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "TaskUpdate completed + preceding 'pre-existing' text blocks" 2 $?

# --- Test 2: TodoWrite shape (todos array) with rationalization MUST block ---
FIX2="$FIXTURE_DIR/2.jsonl"
add_entry "$FIX2" user '[{"type":"text","text":"Go."}]'
add_entry "$FIX2" assistant '[{"type":"text","text":"Will skip for now — not a blocker."}]'
add_entry "$FIX2" assistant '[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"x","status":"completed","activeForm":"x"}]}}]'

INPUT=$(jq -cn --arg t "$FIX2" '{tool_input: {todos: [{status: "completed"}]}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "TodoWrite todos[].completed + preceding 'skip for now' blocks" 2 $?

# --- Test 3: Clean recent text — completion allowed ---
FIX3="$FIXTURE_DIR/3.jsonl"
add_entry "$FIX3" user '[{"type":"text","text":"Please finish the task."}]'
add_entry "$FIX3" assistant '[{"type":"text","text":"All tests pass and the code is reviewed. Marking complete."}]'
add_entry "$FIX3" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"completed"}}]'

INPUT=$(jq -cn --arg t "$FIX3" '{tool_input: {status: "completed"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "Clean text + completion passes" 0 $?

# --- Test 4: Non-completion status does not trigger the pattern check ---
FIX4="$FIXTURE_DIR/4.jsonl"
add_entry "$FIX4" assistant '[{"type":"text","text":"This is a pre-existing problem."}]'
add_entry "$FIX4" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"in_progress"}}]'

INPUT=$(jq -cn --arg t "$FIX4" '{tool_input: {status: "in_progress"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "in_progress status — no check, passes" 0 $?

# --- Test 5: Thinking/tool_use blocks between text and completion don't mask the text ---
FIX5="$FIXTURE_DIR/5.jsonl"
add_entry "$FIX5" assistant '[{"type":"text","text":"This is pre-existing, not fixing."}]'
add_entry "$FIX5" assistant '[{"type":"thinking","thinking":"Should mark done now."}]'
add_entry "$FIX5" assistant '[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]'
add_entry "$FIX5" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"completed"}}]'

INPUT=$(jq -cn --arg t "$FIX5" '{tool_input: {status: "completed"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "Thinking+tool_use lines between rationalization and completion — still blocks" 2 $?

# --- Test 6a: Multi-line text block with pattern on a non-first line (real-world shape) ---
FIX6A="$FIXTURE_DIR/6a.jsonl"
MULTILINE_TEXT='The reviewer raised two findings. Let me evaluate them.\n\n**Finding 1**: Pre-existing concern at line 42. Rejecting.\n\n**Finding 2**: Correct.'
add_entry "$FIX6A" assistant "[{\"type\":\"text\",\"text\":\"$MULTILINE_TEXT\"}]"
add_entry "$FIX6A" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"completed"}}]'

INPUT=$(jq -cn --arg t "$FIX6A" '{tool_input: {status: "completed"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "Multi-line text with 'pre-existing' on non-first line — still blocks" 2 $?

# --- Test 6: Case-insensitive match ---
FIX6="$FIXTURE_DIR/6.jsonl"
add_entry "$FIX6" assistant '[{"type":"text","text":"Pre-Existing Concern at line 42. Rejecting."}]'
add_entry "$FIX6" assistant '[{"type":"tool_use","name":"TaskUpdate","input":{"status":"completed"}}]'

INPUT=$(jq -cn --arg t "$FIX6" '{tool_input: {status: "completed"}, transcript_path: $t}')
echo "$INPUT" | "$HOOK" >/dev/null 2>&1
assert_exit "Case-insensitive: 'Pre-Existing' still matches" 2 $?

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
