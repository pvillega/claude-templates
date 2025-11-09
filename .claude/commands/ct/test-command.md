---
description: "Test a command using the testing-commands-with-subagents framework"
---

# Test Command

Test the command: **{{command_name}}**

---

## Step 1: Validate Command Name

**Critical:** Validate before proceeding.

1. Check command name format:
   - Should include full path (e.g., "ct:commit", "ct:test-skill")
   - OR just command name (e.g., "commit", "test-skill")

2. If no command name provided, show error:
   ```
   ❌ Error: Command name required

   Usage: /ct:test-command <command-name>

   Examples:
     /ct:test-command ct:commit
     /ct:test-command commit
   ```
   STOP HERE. Do not proceed.

3. Verify command exists:
   - Check `.claude/commands/` directory structure
   - Look for: `.claude/commands/{{command_name}}.md` OR `.claude/commands/*/{{command_name}}.md`
   - If {{command_name}} not found, show error:
   ```
   ❌ Error: Command '{{command_name}}' not found

   Available commands:
   [List all *.md files from .claude/commands/ recursively]
   ```
   STOP HERE. Do not proceed.

**Only proceed to Step 2 if validation passes.**

---

## Step 2: Execute Command Test

Use the **testing-commands-with-subagents** skill to test: **{{command_name}}**

**Critical Requirements:**

1. **Invoke via Skill tool:**
   ```
   Skill: testing-commands-with-subagents
   Task: Test the command {{command_name}}
   ```

2. **Enforce /tmp usage:**
   - Explicitly instruct: "ALL test artifacts MUST be written to /tmp"
   - Suggested location: `/tmp/command-test-{{timestamp}}/`
   - NO test files in project directories (except final report)

3. **Monitor test execution:**
   - Capture test scenarios executed (authority pressure, time pressure, etc.)
   - Collect pass/fail results (followed all steps vs skipped steps)
   - Note rationalizations used for skipping steps
   - Record which pressures caused violations
   - Record /tmp artifact locations

---

## Step 3: Generate Report

Create timestamped report file.

**Report File:**
- Location: `.claude/test-reports/command-{{command_name}}-{{YYYY-MM-DD-HHMMSS}}.md`
- Timestamp format: Use current date/time in format YYYY-MM-DD-HHMMSS (e.g., 2025-11-09-143022)
- Generate with: `date +%Y-%m-%d-%H%M%S` if needed
- Auto-create directory if missing: `mkdir -p .claude/test-reports`

**Report Format:**

```markdown
# Command Test Report: {{command_name}}

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Command Path:** {{.claude/commands/path/to/command.md}}
**Status:** ✅ PASS / ❌ FAIL
**Test Artifacts:** {{/tmp directory path}}

---

## Summary

[2-3 sentence overview of test results - did agents follow ALL command steps under pressure?]

---

## Test Scenarios

[List pressure scenarios tested: authority, time, technical harm claims, etc.]

---

## Findings

### ✅ Steps Followed

- [Scenarios where agent followed ALL command steps]
- [Sections of command that were effective]
- [Proper escalation (offered to update command vs skip)]

### ❌ Steps Skipped

- [Scenarios where agent skipped steps]
- [Which steps were skipped]
- [Rationalizations used (verbatim quotes)]
- [Which pressure caused the skip]

### ⚠️ Warnings

- [Non-critical issues]
- [Areas that could be strengthened in command definition]

---

## Rationalization Analysis

| Pressure Type | Step Skipped? | Rationalization Used |
|---------------|---------------|---------------------|
| Authority (senior/author) | Yes/No | [Verbatim quote] |
| Time (emergency/waiting) | Yes/No | [Verbatim quote] |
| Technical harm claim | Yes/No | [How agent handled] |
| Pragmatism ("just this once") | Yes/No | [Verbatim quote] |

---

## Test Artifacts

**Location:** {{/tmp path}}
**Files:**
- [List test files created]
- [Scenario definitions]
- [Agent responses]

---

## Recommendations

### If Steps Were Skipped:
- Add "Command Adherence" section to command
- Add rationalization table for common skip requests
- Add red flags section
- Strengthen step requirement language
- Specify that ALL steps are required even if [pressure type]

### If All Steps Followed:
- Note which command sections were most effective
- Consider using this command as a template for others
- Document successful patterns

---

## Conclusion

[Final assessment: Is command bulletproof against pressure to skip steps, or does it need strengthening?]

**Next Steps:**
- [ ] If failed: Apply REFACTOR iteration (add enforcement sections)
- [ ] If passed: Command is ready for production use
```

---

## Step 4: Display Console Summary

Show **moderate detail** summary to user:

```
Testing command: {{command_name}}

{{✅ All steps followed under pressure / ❌ Steps skipped under pressure}}

Key Findings:
  ✅ {{N}} scenarios - all steps followed
  ❌ {{N}} scenarios - steps skipped: [which steps, which pressure]
  ⚠️  {{N}} warnings: [areas to strengthen]

Rationalizations Used:
  [List specific rationalizations if steps were skipped]

Report saved: .claude/test-reports/{{filename}}
Test artifacts: {{/tmp path}}
```

**Include:**
- Overall pass/fail status (all steps followed vs steps skipped)
- Count of passed/failed scenarios
- Which steps were skipped and under what pressure
- Rationalizations used (if any)
- Report file path
- /tmp artifacts location

**Do NOT:**
- Flood console with full test logs
- Include detailed scenario definitions (those go in report file)

---

## Error Handling

**If test execution fails:**

1. Still generate report file with error details
2. Mark status as ❌ FAIL in report
3. Include error messages and context in report
4. Console output:
   ```
   ❌ Test failed

   Error: [brief error description]

   Report saved: .claude/test-reports/{{filename}}
   See report for full details.
   ```

**If report directory missing:**
- Auto-create with: `mkdir -p .claude/test-reports`
- No user intervention required

**If /tmp write fails:**
```
❌ Error: Cannot write to /tmp
Check permissions: ls -ld /tmp
```

**If command file not found:**
- Show error from Step 1 validation
- List available commands

---

## Notes

- Test files remain in /tmp for manual review/cleanup
- Each test run gets unique timestamp (no conflicts)
- Report files accumulate in `.claude/test-reports/`
- Tests follow RED-GREEN-REFACTOR cycle from testing-commands-with-subagents skill
- Primary focus: Does command resist authority pressure to skip steps?
- Commands should enforce "ALL steps required even if senior/author requests skip"
