---
description: "Test a skill using the testing-skills-with-subagents framework"
arguments:
  - name: "skill_name"
    type: "required positional"
    description: "The skill to test in namespace format (e.g., superpowers:brainstorming). Must include a namespace prefix."
    example: "/ct:test-skill superpowers:brainstorming"
argument-hint: "<namespace:skill-name>"
---

# Test Skill Command

Test the skill: **{{skill_name}}**

---

## Step 1: Validate Skill Name

**Critical:** Validate before proceeding.

1. Check skill name format:
   - ❌ REJECT if no namespace (e.g., "brainstorming")
   - ✅ ACCEPT if has namespace (e.g., "superpowers:brainstorming")

2. If missing namespace, show error:
   ```
   ❌ Error: Skill name must include namespace

   Example: /ct:test-skill superpowers:brainstorming
   ```
   STOP HERE. Do not proceed.

3. If no skill name provided, show error:
   ```
   ❌ Error: Skill name required

   Usage: /ct:test-skill <namespace:skill-name>
   ```
   STOP HERE. Do not proceed.

4. Verify skill exists:
   - List available skills by checking:
     * Use the Skill tool's available skills list (check your context)
     * OR check plugin skills directory if needed
   - If {{skill_name}} not in available skills list, show error with available skills
   - If not found, show error with available skills list:
   ```
   ❌ Error: Skill '{{skill_name}}' not found

   Available skills:
   [List all available skills here]
   ```
   STOP HERE. Do not proceed.

**Only proceed to Step 2 if validation passes.**

---

## Step 2: Execute Skill Test

Use the **superpowers:testing-skills-with-subagents** skill to test: **{{skill_name}}**

**Critical Requirements:**

1. **Invoke via Skill tool:**
   ```
   Skill: superpowers:testing-skills-with-subagents
   Task: Test the skill {{skill_name}}
   ```

2. **Enforce /tmp usage:**
   - Explicitly instruct: "ALL test artifacts MUST be written to /tmp"
   - Suggested location: `/tmp/skill-test-{{timestamp}}/`
   - NO test files in project directories (except final report)

3. **Monitor test execution:**
   - Capture test scenarios executed
   - Collect pass/fail results
   - Note any warnings or issues
   - Record /tmp artifact locations

---

## Step 3: Generate Report

Create timestamped report file.

**Report File:**
- Location: `.claude/test-reports/{{skill_name}}-{{YYYY-MM-DD-HHMMSS}}.md`
- Timestamp format: Use current date/time in format YYYY-MM-DD-HHMMSS (e.g., 2025-11-09-143022)
- Generate with: `date +%Y-%m-%d-%H%M%S` if needed
- Auto-create directory if missing: `mkdir -p .claude/test-reports`

**Report Format:**

```markdown
# Skill Test Report: {{skill_name}}

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Status:** ✅ PASS / ❌ FAIL
**Test Artifacts:** {{/tmp directory path}}

---

## Summary

[2-3 sentence overview of test results]

---

## Test Scenarios

[List scenarios tested by subagent]

---

## Findings

### ✅ Passed
- [Items that worked correctly]

### ❌ Failed
- [Items that failed or need improvement]

### ⚠️ Warnings
- [Non-critical issues]

---

## Test Artifacts

**Location:** {{/tmp path}}
**Files:**
- [List test files created]

---

## Conclusion

[Final assessment and recommendations]
```

---

## Step 4: Display Console Summary

Show **moderate detail** summary to user:

```
Testing skill: {{skill_name}}

{{✅ Test completed successfully / ❌ Test failed}}

Key Findings:
  ✅ {{N}} scenarios passed
  ❌ {{N}} scenarios failed: [brief descriptions]
  ⚠️  {{N}} warnings: [brief descriptions]

Report saved: .claude/test-reports/{{filename}}
Test artifacts: {{/tmp path}}
```

**Include:**
- Overall pass/fail status
- Count of passed/failed/warning items
- Brief description of key issues
- Report file path
- /tmp artifacts location

**Do NOT:**
- Flood console with full test logs
- Include detailed stack traces (those go in report file)

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

---

## Notes

- Test files remain in /tmp for manual review/cleanup
- Each test run gets unique timestamp (no conflicts)
- Report files accumulate in `.claude/test-reports/`
- Skill name must include full namespace (e.g., `superpowers:brainstorming`)
