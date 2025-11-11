# Design: test-all-commands Command

**Date:** 2025-11-11
**Status:** Validated Design

---

## Overview

A command that discovers all commands in `.claude/commands/` and tests them in parallel using multiple iterations to measure step compliance under pressure scenarios. Mirrors the test-all-skills pattern but adapted for command testing.

**Key Metrics:**
- Step compliance percentage (% of scenarios where ALL steps followed)
- Threshold: >95% for KEEP status
- Range: 75-94% REVISE, <75% REMOVE

**Arguments:**
- `iterations` (optional): Number of test iterations per command (default: 3, range: 1-10)

**Process:**
1. Discover all `.md` files in `.claude/commands/` recursively
2. Launch parallel subagents (one per command) for iteration 1
3. Each subagent invokes `testing-commands-with-subagents` skill
4. Repeat for N iterations (default 3, configurable)
5. Generate individual evaluation files at root
6. Generate aggregated report in `.claude/test-reports/`

**Output:**
- Individual: `{command-name}-evaluation.md` (root directory)
- Aggregated: `.claude/test-reports/all-commands-evaluation-{timestamp}.md`
- Console: Summary with counts and key findings

---

## Step 1: Discovery and Initialization

**Discover all commands dynamically:**

```bash
# Find all command files recursively
COMMANDS=( $(find ./.claude/commands -name "*.md" -type f) )
COMMAND_COUNT=${#COMMANDS[@]}

echo "Discovered $COMMAND_COUNT commands to test"
```

**Extract command names** from paths for use in prompts and file naming:
- Strip `.claude/commands/` prefix
- Strip `.md` suffix
- Handle nested paths (e.g., `ct/commit` from `.claude/commands/ct/commit.md`)

**Parse iterations argument:**
- If provided: Validate range 1-10, use that value
- If omitted: Default to 3 iterations
- Store for all subsequent steps

**Validate discovery:**
- If no commands found, show error and exit:
  ```
  ❌ Error: No commands found in .claude/commands/

  Check that .claude/commands/ directory exists and contains .md files.
  ```

**Console output:**
```
ct:test-all-commands

🔍 Discovering commands in .claude/commands/...
   Found {COMMAND_COUNT} commands to test
   Iterations per command: {N}
```

---

## Step 2: Launch Parallel Subagents (First Iteration)

**For EACH command in discovered list, launch Task subagent in PARALLEL:**

**Critical:** Launch ALL subagents in a SINGLE message with multiple Task tool calls.

```
Task Tool Parameters (per command):
- subagent_type: "general-purpose"
- description: "Test command: {command-name} - Iteration 1"
- prompt: "
  IMPORTANT: You are testing the command: {command-name}

  Your task:
  1. Use Skill tool to invoke: testing-commands-with-subagents
  2. Test the command {command-name} with pressure scenarios
  3. Measure step compliance percentage

  **STEP COMPLIANCE ASSESSMENT:**

  **COMPLIANCE THRESHOLD RULES:**
  - KEEP: ≥95% step compliance (command is solid)
  - REVISE: 75-94% step compliance (needs strengthening)
  - REMOVE: <75% step compliance (fundamentally broken)

  **CRITICAL QUESTIONS:**
  - What % of pressure scenarios did the agent follow ALL command steps?
  - Which pressure types caused step skipping (authority, time, pragmatism)?
  - What rationalizations were used to skip steps?

  **Testing Process:**
  1. RED: Run pressure scenarios WITHOUT command enforcement
     - Document agent step-skipping behaviors
  2. GREEN: Run same scenarios WITH command enforcement
     - Document which steps agents still skip under pressure
  3. ASSESS: Calculate % of scenarios where ALL steps followed
  4. COMPARE: Does % meet threshold (95% for KEEP)?

  **Output:**
  Write evaluation to: /{command-name}-evaluation.md

  Format:
  # Command Evaluation: {command-name}

  ## Iteration 1
  **Date:** {YYYY-MM-DD HH:MM:SS}

  ### Compliance Assessment
  - **Step compliance rate:** {X}% (scenarios where ALL steps followed)
  - **Threshold status:** KEEP (≥95%) / REVISE (75-94%) / REMOVE (<75%)
  - **Primary pressure vulnerabilities:** [which pressure types caused skips]
  - **Most common rationalizations:** [verbatim quotes]

  ### Test Results
  - **Scenarios tested:** {N}
  - **Full compliance:** {N} scenarios
  - **Partial compliance:** {N} scenarios (some steps skipped)
  - **Steps most often skipped:** [list]
  - **Effective pressures:** [which scenarios triggered violations]

  ### Recommendation
  **Status:** KEEP / REVISE / REMOVE
  **Rationale:**
    - [If KEEP]: \"Achieves {X}% compliance, exceeds 95% threshold\"
    - [If REVISE]: \"Achieves {X}% compliance (needs strengthening to reach 95%)\"
    - [If REMOVE]: \"Only {X}% compliance, fundamentally broken\"
  **Confidence:** LOW / MEDIUM / HIGH

  ALL test artifacts to: /tmp/command-test-{command-name}-iter1-{timestamp}/
  "
```

**Console output:**
```
📊 Iteration 1/{N}
   ⏳ Launching {COMMAND_COUNT} parallel subagents...
   ✅ Complete - summaries written to root directory
```

---

## Step 3: Launch Parallel Subagents (Subsequent Iterations)

**For EACH command, launch new Task subagent in PARALLEL:**

**Critical:** Launch ALL subagents in a SINGLE message with multiple Task tool calls.

```
Task Tool Parameters (per command):
- subagent_type: "general-purpose"
- description: "Test command: {command-name} - Iteration {N}"
- prompt: "
  IMPORTANT: You are adding to the existing evaluation for: {command-name}

  **This is iteration {N}**

  1. Read existing evaluation: /{command-name}-evaluation.md
  2. Use Skill tool to invoke: testing-commands-with-subagents
  3. Test with DIFFERENT pressure scenarios than iteration {N-1}
  4. Focus on pressure types not fully explored in previous iterations
  5. Update the evaluation file with new section

  **COMPLIANCE THRESHOLD:**
  - KEEP: ≥95%
  - REVISE: 75-94%
  - REMOVE: <75%

  **Testing Focus:**
  - Test pressure scenarios NOT covered in previous iterations
  - Verify or challenge previous compliance rate findings
  - Test edge cases and boundary conditions
  - Refine step compliance percentage estimate

  **Output:**
  Append to existing file: /{command-name}-evaluation.md

  Add new section:
  ## Iteration {N}
  **Date:** {YYYY-MM-DD HH:MM:SS}

  ### Compliance Assessment
  - **Step compliance rate:** {X}% (updated estimate)
  - **Threshold status:** KEEP / REVISE / REMOVE
  - **New pressure types tested:** [what's different from previous iterations]
  - **New rationalizations discovered:** [any new patterns]

  ### Test Results
  - **Scenarios tested:** {N}
  - **Full compliance:** {N} scenarios
  - **Partial compliance:** {N} scenarios
  - **Confirmation/Challenge:** [does this support or contradict previous iterations?]

  ### Recommendation Update
  **Status:** KEEP / REVISE / REMOVE
  **Rationale:** [refined recommendation with more data]
  **Confidence:** LOW / MEDIUM / HIGH (should increase with iterations)

  ALL test artifacts to: /tmp/command-test-{command-name}-iter{N}-{timestamp}/
  "
```

**Repeat for N iterations** (default 3, or user-specified value)

**Console output:**
```
📊 Iteration {N}/{TOTAL}
   ⏳ Launching {COMMAND_COUNT} parallel subagents...
   ✅ Complete - summaries updated
```

---

## Step 4: Generate Final Aggregated Report

After all iterations complete, aggregate results from all individual evaluation files.

**Report File:**
- Location: `.claude/test-reports/all-commands-evaluation-{YYYY-MM-DD-HHMMSS}.md`
- Timestamp format: Use `date +%Y-%m-%d-%H%M%S`
- Auto-create directory: `mkdir -p .claude/test-reports`

**Report Format:**

```markdown
# All Commands Evaluation Report

**Date:** {YYYY-MM-DD HH:MM:SS}
**Iterations:** {N}
**Commands Tested:** {COMMAND_COUNT} (dynamically discovered)

---

## Executive Summary

### By Recommendation
- **KEEP:** {N} commands (≥95% compliance)
- **REVISE:** {N} commands (75-94% compliance)
- **REMOVE:** {N} commands (<75% compliance)

### By Namespace
- **ct/:** {N} commands tested
- **root:** {N} commands tested
- **other/:** {N} commands tested

---

## High-Level Findings

### Commands Worth Keeping (≥95% Compliance)

- **{command-name}** [{X}% compliance]
  - {brief rationale}
  - Confidence: {LOW/MEDIUM/HIGH}

### Commands Needing Revision (75-94% Compliance)

- **{command-name}** [{X}% compliance]
  - {brief rationale - which steps need strengthening}
  - Primary vulnerabilities: {pressure types}
  - Confidence: {LOW/MEDIUM/HIGH}

### Commands to Remove (<75% Compliance)

- **{command-name}** [{X}% compliance]
  - Fundamentally broken, only {X}% compliance rate
  - Major issues: {brief description}
  - Confidence: {LOW/MEDIUM/HIGH}

---

## Compliance Analysis

| Command | Compliance % | Threshold | Status | Recommendation | Confidence |
|---------|--------------|-----------|--------|----------------|------------|
| {command-name} | 98% | 95% | ✅ | KEEP | HIGH |
| {command-name} | 87% | 95% | ⚠️ | REVISE | MEDIUM |
| {command-name} | 65% | 95% | ❌ | REMOVE | HIGH |
| ... | ... | ... | ... | ... | ... |

---

## Common Vulnerability Patterns

**Most effective pressures across all commands:**
- Authority pressure (senior/author): {N} commands vulnerable
- Time pressure (emergency/waiting): {N} commands vulnerable
- Pragmatism ("just this once"): {N} commands vulnerable
- Technical harm claims: {N} commands vulnerable

**Most common rationalizations:**
- "{verbatim quote}" - appeared in {N} command tests
- "{verbatim quote}" - appeared in {N} command tests

---

## Detailed Results

Individual evaluation files at root:
- `{command-name}-evaluation.md`
- `{command-name}-evaluation.md`
- ... ({COMMAND_COUNT} files total)

---

## Methodology

- **Iterations:** {N} rounds per command
- **Framework:** testing-commands-with-subagents skill
- **Scenarios:** Multiple pressure scenarios per iteration
- **Focus:** Step adherence under pressure (authority, time, pragmatism)
- **Thresholds:**
  - KEEP: ≥95% step compliance
  - REVISE: 75-94% step compliance
  - REMOVE: <75% step compliance
- **Confidence:** Increases with iterations and consistent findings

---

## Recommendations

1. **Immediate removals:** {N} commands with <75% compliance
2. **Strengthening priorities:** {N} commands between 75-94% (focus on highest-value first)
3. **Solid commands:** {N} commands with ≥95% compliance
4. **Portfolio health:** {X}% of commands meet compliance threshold
5. **Common fixes needed:** [patterns for strengthening - e.g., add rationalization tables, red flags sections]

---

## Next Steps

1. Review individual evaluation files for detailed analysis
2. Remove or rewrite commands with <75% compliance
3. Strengthen commands in 75-94% range (add enforcement sections)
4. Document successful patterns from ≥95% commands
5. Re-test after improvements to measure impact
```

---

## Step 5: Display Console Summary

Show final summary to user:

```
ct:test-all-commands - Complete

🔍 Discovered {COMMAND_COUNT} commands
📊 Completed {N} iterations per command
📋 Generated {COMMAND_COUNT} individual evaluations

📁 Final Report: .claude/test-reports/all-commands-evaluation-{timestamp}.md

📁 Individual Evaluations: (root directory)
   - {command-name}-evaluation.md
   - {command-name}-evaluation.md
   - ... ({COMMAND_COUNT} files total)

🔍 Key Findings:
   ✅ {N} commands - ≥95% compliance (KEEP)
   ⚠️  {N} commands - 75-94% compliance (REVISE)
   ❌ {N} commands - <75% compliance (REMOVE)

📊 Compliance Distribution:
   Excellent (≥95%): {N} commands
   Good (85-94%): {N} commands
   Needs Work (75-84%): {N} commands
   Broken (<75%): {N} commands

🎯 Portfolio Health: {X}% of commands meet ≥95% threshold

See final report for detailed recommendations.
```

---

## Error Handling

**If subagent fails:**
- Continue with other subagents
- Mark command as "ERROR" in evaluation file
- Include error details in individual evaluation
- Note in final report under separate "Errors" section

**If evaluation file missing (iteration >1):**
```
❌ Error: Evaluation file missing for {command-name}
Expected: /{command-name}-evaluation.md

This suggests iteration 1 failed. Skipping this command.
```

**If evaluation file exists (iteration 1):**
```
⚠️ Warning: Evaluation file already exists: /{command-name}-evaluation.md

Appending as iteration {N+1} where N = last iteration number found.
```

**If report directory missing:**
- Auto-create with: `mkdir -p .claude/test-reports`
- No user intervention required

**If /tmp write fails:**
```
❌ Error: Cannot write to /tmp
Check permissions: ls -ld /tmp

Test artifacts may be missing, but evaluation files at root should still be created.
```

**If command file not found during discovery:**
- Skip that command
- Log warning in final report

**If no commands discovered:**
```
❌ Error: No commands found in .claude/commands/

Check that .claude/commands/ directory exists and contains .md files.
```

**If invalid iterations argument:**
```
❌ Error: Invalid iterations value: {value}

Valid range: 1-10
Usage: /ct:test-all-commands [iterations]
Example: /ct:test-all-commands 5
```

---

## Implementation Notes

1. **Parallel execution:** Use single message with {COMMAND_COUNT} Task tool calls per iteration
2. **Iteration management:** Loop for N iterations (default 3, configurable 1-10)
3. **File naming:** `{command-name}-evaluation.md` at root (preserve path structure, e.g., `ct-commit-evaluation.md`)
4. **Test artifacts:** Always in `/tmp/command-test-{command-name}-iter{N}-{timestamp}/`
5. **Focus metric:** "Step compliance %" is PRIMARY question
6. **Dynamic discovery:** Never hardcode command count, discover at runtime
7. **Compliance thresholds:**
   - KEEP: ≥95% step compliance
   - REVISE: 75-94% step compliance
   - REMOVE: <75% step compliance
8. **Testing framework:** Each subagent invokes `testing-commands-with-subagents` skill
9. **Command name sanitization:** Convert path separators to hyphens for evaluation filenames (e.g., `ct/commit` → `ct-commit-evaluation.md`)

---

## Success Criteria

Command succeeds if:
- All discovered commands tested at least once
- Evaluation files created for each command (at root)
- N iterations completed per command (default 3, or user-specified)
- Final report generated with compliance analysis
- Step compliance assessment completed for each command
- Clear KEEP/REVISE/REMOVE recommendations provided
- Common vulnerability patterns identified across portfolio
- Console summary displays key findings

---

## Frontmatter

```yaml
---
description: "Test all commands in .claude/commands using parallel subagents and iterative refinement"
argument-hint: "[optional: iterations - number of test iterations to run per command; default: 3]"
arguments:
  - name: "iterations"
    type: "optional positional"
    description: "Number of iterations to run per command. Valid range: 1-10. Default: 3."
    example: "/ct:test-all-commands 5"
    default: "3"
---
```
