---
description: "Test an agent using the testing-agents-with-subagents framework"
---

# Test Agent Command

Test the agent: **{{agent_name}}**

---

## Step 1: Validate Agent Name

**Critical:** Validate before proceeding.

1. Check agent name format:
   - Agent can be:
     * Custom agent file name (e.g., "rust-expert" for .claude/agents/rust-expert.md)
     * Task tool subagent name (e.g., "code-reviewer", "Explore", "Plan", "general-purpose")

2. If no agent name provided, show error:
   ```
   ❌ Error: Agent name required

   Usage: /ct:test-agent <agent-name>

   Examples:
     /ct:test-agent rust-expert          (custom agent)
     /ct:test-agent code-reviewer        (Task tool subagent)
   ```
   STOP HERE. Do not proceed.

3. Verify agent exists:
   - Check custom agents: Look for `.claude/agents/{{agent_name}}.md`
   - OR check Task tool subagents: general-purpose, Explore, Plan, code-reviewer, rust-expert, statusline-setup
   - If {{agent_name}} not found in either location, show error:
   ```
   ❌ Error: Agent '{{agent_name}}' not found

   Custom agents in .claude/agents/:
   [List *.md files from .claude/agents/ directory]

   Task tool subagents:
   - general-purpose
   - Explore
   - Plan
   - code-reviewer
   - rust-expert
   - statusline-setup
   - superpowers:code-reviewer
   ```
   STOP HERE. Do not proceed.

**Only proceed to Step 2 if validation passes.**

---

## Step 2: Execute Agent Test

Use the **testing-agents-with-subagents** skill to test: **{{agent_name}}**

**Critical Requirements:**

1. **Invoke via Skill tool:**
   ```
   Skill: testing-agents-with-subagents
   Task: Test the agent {{agent_name}}
   ```

2. **Enforce /tmp usage:**
   - Explicitly instruct: "ALL test artifacts MUST be written to /tmp"
   - Suggested location: `/tmp/agent-test-{{timestamp}}/`
   - NO test files in project directories (except final report)

3. **Monitor test execution:**
   - Capture test scenarios executed
   - Collect pass/fail results (agent stayed in scope vs drifted)
   - Note drift patterns observed
   - Record boundary violations if any
   - Record /tmp artifact locations

---

## Step 3: Generate Report

Create timestamped report file.

**Report File:**
- Location: `.claude/test-reports/agent-{{agent_name}}-{{YYYY-MM-DD-HHMMSS}}.md`
- Timestamp format: Use current date/time in format YYYY-MM-DD-HHMMSS (e.g., 2025-11-09-143022)
- Generate with: `date +%Y-%m-%d-%H%M%S` if needed
- Auto-create directory if missing: `mkdir -p .claude/test-reports`

**Report Format:**

```markdown
# Agent Test Report: {{agent_name}}

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Agent Type:** Custom Agent / Task Tool Subagent
**Status:** ✅ PASS / ❌ FAIL
**Test Artifacts:** {{/tmp directory path}}

---

## Summary

[2-3 sentence overview of test results - did agent maintain boundaries under pressure?]

---

## Test Scenarios

[List drift scenarios tested by subagent with pressure types]

---

## Findings

### ✅ Boundaries Maintained
- [Scenarios where agent stayed in scope]
- [Sections cited (Will Not, Red Flags, Behavioral Mindset)]

### ❌ Drift Patterns Observed
- [Scenarios where agent drifted]
- [Specific justifications used for drift]
- [Boundary violations]

### ⚠️ Warnings
- [Non-critical issues]
- [Areas that could be strengthened]

---

## Drift Pattern Analysis

| Drift Type | Observed? | Justifications Used |
|------------|-----------|-------------------|
| Scope creep | Yes/No | [Verbatim quotes] |
| Methodology abandonment | Yes/No | [Verbatim quotes] |
| Boundary violation | Yes/No | [Verbatim quotes] |
| Output quality drift | Yes/No | [Verbatim quotes] |
| Integration failure | Yes/No | [Verbatim quotes] |

---

## Test Artifacts

**Location:** {{/tmp path}}
**Files:**
- [List test files created]

---

## Recommendations

[If agent drifted: Specific suggestions for tightening agent definition]
[If agent maintained boundaries: Note which sections were most effective]

---

## Conclusion

[Final assessment: Is agent definition bulletproof or needs REFACTOR iteration?]
```

---

## Step 4: Display Console Summary

Show **moderate detail** summary to user:

```
Testing agent: {{agent_name}}

{{✅ Agent maintained boundaries / ❌ Agent drifted under pressure}}

Key Findings:
  ✅ {{N}} scenarios - boundaries maintained
  ❌ {{N}} scenarios - drift observed: [brief descriptions]
  ⚠️  {{N}} warnings: [areas to strengthen]

Drift Patterns:
  [List specific drift patterns if any]

Report saved: .claude/test-reports/{{filename}}
Test artifacts: {{/tmp path}}
```

**Include:**
- Overall pass/fail status (boundaries maintained vs drift)
- Count of passed/failed scenarios
- Brief description of drift patterns observed
- Report file path
- /tmp artifacts location

**Do NOT:**
- Flood console with full test logs
- Include detailed drift justifications (those go in report file)

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

**If agent file not found:**
- Show error from Step 1 validation
- List available agents (custom + Task tool subagents)

---

## Notes

- Test files remain in /tmp for manual review/cleanup
- Each test run gets unique timestamp (no conflicts)
- Report files accumulate in `.claude/test-reports/`
- Agent can be either custom agent (.claude/agents/*.md) or Task tool subagent
- Tests follow RED-GREEN-REFACTOR cycle from testing-agents-with-subagents skill
