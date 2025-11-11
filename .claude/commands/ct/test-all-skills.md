---
description: "Test all skills in .claude/skills using parallel subagents and iterative refinement"
argument-hint: "[optional: iterations - number of test iterations to run; if omitted, continues until context limit or completion criteria]"
arguments:
  - name: "iterations"
    type: "optional positional"
    description: "Number of iterations to run per skill. If omitted, the command runs up to the context limit (stops before 180K tokens used) with a minimum of 2 iterations guaranteed. Valid range: 1-10."
    example: "/ct:test-all-skills 3"
    default: "dynamic (context-dependent, minimum 2)"
---

# Test All Skills Command

Tests all skills in `.claude/skills/` using parallel subagents with multiple iterations.

---

## Overview

This command:
1. Discovers all skill files in `.claude/skills/` dynamically
2. Spawns parallel subagents (one per skill)
3. Each subagent tests the skill using `testing-skills-with-subagents`
4. Each writes an evaluation summary to root directory
5. Repeats for multiple iterations to refine results

**Focus:** Determine if skills add sufficient value vs. token cost

**Value Thresholds:**
- SMALL skills (<2.5K tokens): Must add value in >10% of cases
- LARGE skills (≥2.5K tokens): Must add value in >20% of cases

---

## Step 1: Discover Skills Dynamically

Find all skill files and count them:

```bash
# Discover all skills
SKILLS=( $(find ./.claude/skills -maxdepth 1 -name "*.md" -type f; \
          find ./.claude/skills -maxdepth 2 -name "SKILL.md") )
SKILL_COUNT=${#SKILLS[@]}

echo "Discovered $SKILL_COUNT skills to test"
```

Extract skill names from paths for use in prompts and file naming.

Store skill list and count for all subsequent steps.

Console output:
```
ct:test-all-skills

🔍 Discovering skills in .claude/skills/...
   Found {SKILL_COUNT} skills to test
```

---

## Step 2: Launch Parallel Subagents (First Iteration)

**For EACH skill in discovered list, launch Task subagent in PARALLEL:**

**Critical:** Launch ALL subagents in a SINGLE message with multiple Task tool calls.

```
Task Tool Parameters (per skill):
- subagent_type: "general-purpose"
- description: "Test skill: {skill-name} - Iteration 1"
- prompt: "
  IMPORTANT: You are testing the skill: {skill-name}

  Your task:
  1. Use Skill tool to invoke: testing-skills-with-subagents
  2. Test the skill {skill-name} with pressure scenarios
  3. Assess token cost and value-add threshold

  **TOKEN COST ASSESSMENT:**
  First, estimate skill token cost:
  - Read the skill file: {skill-file-path}
  - Count approximate tokens (characters ÷ 4)
  - Classify as:
    * SMALL: <2.5K tokens
    * LARGE: ≥2.5K tokens

  **VALUE THRESHOLD RULES:**
  - SMALL skills (<2.5K): Must add value in >10% of cases to justify keeping
  - LARGE skills (≥2.5K): Must add value in >20% of cases to justify keeping

  **CRITICAL QUESTIONS:**
  - Does default Claude Code already handle most cases well?
  - What % of realistic scenarios does this skill improve outcomes?
  - Does the skill meet its value threshold based on token cost?

  **Testing Process:**
  1. RED: Run pressure scenarios WITHOUT {skill-name} skill
     - Document agent failures and rationalizations
  2. GREEN: Run same scenarios WITH {skill-name} skill
     - Document compliance improvements
  3. ASSESS: Calculate % of scenarios where skill added meaningful value
  4. COMPARE: Does % exceed threshold (10% or 20% based on token cost)?

  **Output:**
  Write evaluation to: /{skill-name}-evaluation.md

  Format:
  # Skill Evaluation: {skill-name}

  ## Iteration 1
  **Date:** {YYYY-MM-DD HH:MM:SS}

  ### Value Assessment
  - **Default behavior quality:** {1-10}/10
  - **Skill adds value in:** {X}% of cases
  - **Skill token cost:** SMALL (<2.5K) / LARGE (≥2.5K)
  - **Actual token count:** ~{N} tokens
  - **Value threshold met:** {Yes/No}
    - Standard skills (SMALL): Must add value in >10% of cases
    - Large skills (LARGE): Must add value in >20% of cases
  - **Token cost justified:** {Yes/No/Maybe}
  - **Primary use cases:** [where skill is most valuable]

  ### Test Results
  - **Scenarios tested:** {N}
  - **RED (without skill):** [agent failures observed]
  - **GREEN (with skill):** [agent compliance observed]
  - **Most effective pressures:** [which scenarios triggered violations]

  ### Recommendation
  **Status:** KEEP / REVISE / REMOVE
  **Rationale:**
    - [If REMOVE due to threshold]: \"Adds value in only {X}% of cases (threshold: {10% or 20%})\"
    - [If KEEP]: \"Adds value in {X}% of cases, exceeds {10% or 20%} threshold\"
    - [If REVISE]: \"Close to threshold, potential for improvement\"
  **Confidence:** LOW / MEDIUM / HIGH

  ALL test artifacts to: /tmp/skill-test-{skill-name}-iter1-{timestamp}/
  "
```

Console output:
```
📊 Iteration 1/N
   ⏳ Launching {SKILL_COUNT} parallel subagents...
   ✅ Complete - summaries written to root directory
```

---

## Step 3: Monitor and Wait

Wait for all subagents to complete first iteration.

Check that all evaluation files were created at root.

---

## Step 4: Launch Parallel Subagents (Subsequent Iterations)

**For EACH skill file, launch new Task subagent in PARALLEL:**

**Critical:** Launch ALL subagents in a SINGLE message with multiple Task tool calls.

```
Task Tool Parameters (per skill):
- subagent_type: "general-purpose"
- description: "Test skill: {skill-name} - Iteration {N}"
- prompt: "
  IMPORTANT: You are adding to the existing evaluation for: {skill-name}

  **This is iteration {N}**

  1. Read existing evaluation: /{skill-name}-evaluation.md
  2. Use Skill tool to invoke: testing-skills-with-subagents
  3. Test with DIFFERENT pressure scenarios than iteration {N-1}
  4. Focus on areas not covered in previous iterations
  5. Update the evaluation file with new section

  **TOKEN COST:**
  Use token cost classification from Iteration 1 (already calculated).

  **VALUE THRESHOLD:**
  - If SMALL (<2.5K): needs >10% value
  - If LARGE (≥2.5K): needs >20% value

  **Testing Focus:**
  - Test scenarios NOT covered in previous iterations
  - Verify or challenge previous findings
  - Test edge cases and boundary conditions
  - Refine value-add percentage estimate

  **Output:**
  Append to existing file: /{skill-name}-evaluation.md

  Add new section:
  ## Iteration {N}
  **Date:** {YYYY-MM-DD HH:MM:SS}

  ### Value Assessment
  - **Skill adds value in:** {X}% of cases (updated estimate)
  - **Value threshold met:** {Yes/No}
  - **Token cost justified:** {Yes/No/Maybe}
  - **New insights:** [what this iteration revealed]

  ### Test Results
  - **Scenarios tested:** {N}
  - **RED (without skill):** [new findings]
  - **GREEN (with skill):** [new findings]
  - **Confirmation/Challenge:** [does this support or contradict previous iterations?]

  ### Recommendation Update
  **Status:** KEEP / REVISE / REMOVE
  **Rationale:** [refined recommendation with more data]
  **Confidence:** LOW / MEDIUM / HIGH (should increase with iterations)

  ALL test artifacts to: /tmp/skill-test-{skill-name}-iter{N}-{timestamp}/
  "
```

Console output:
```
📊 Iteration {N}/N
   ⏳ Launching {SKILL_COUNT} parallel subagents...
   ✅ Complete - summaries updated
```

---

## Step 5: Iterate Until Context Limit

Repeat Step 4 for as many iterations as context allows.

**Before each iteration:**
```
1. Check token usage: If > 180K, stop and go to Step 6
2. If < 180K, continue with next iteration
3. Minimum 2 iterations guaranteed before checking
```

**Stopping criteria:**
- Context usage > 180K tokens (leave buffer for final report)
- OR minimum 2 iterations completed
- OR all skills reach "HIGH confidence" status

---

## Step 6: Generate Final Report

After all iterations complete, aggregate results from all individual evaluation files.

**Report File:**
- Location: `.claude/test-reports/all-skills-evaluation-{YYYY-MM-DD-HHMMSS}.md`
- Timestamp format: Use `date +%Y-%m-%d-%H%M%S`
- Auto-create directory: `mkdir -p .claude/test-reports`

**Report Format:**

```markdown
# All Skills Evaluation Report

**Date:** {YYYY-MM-DD HH:MM:SS}
**Iterations:** {N}
**Skills Tested:** {SKILL_COUNT} (dynamically discovered)

---

## Executive Summary

### By Recommendation
- **KEEP:** {N} skills (meet value threshold)
- **REVISE:** {N} skills (close to threshold, need improvement)
- **REMOVE:** {N} skills (below threshold, not worth token cost)

### By Token Cost
- **SMALL (<2.5K tokens):** {N} skills (10% value threshold)
- **LARGE (≥2.5K tokens):** {N} skills (20% value threshold)

---

## High-Level Findings

### Skills Worth Keeping (Exceed Value Threshold)

- **{skill-name}** [SMALL cost, {X}% value-add, exceeds 10% threshold]
  - {brief rationale}
  - Confidence: {LOW/MEDIUM/HIGH}

- **{skill-name}** [LARGE cost, {X}% value-add, exceeds 20% threshold]
  - {brief rationale}
  - Confidence: {LOW/MEDIUM/HIGH}

### Skills Needing Revision (Close to Threshold)

- **{skill-name}** [SMALL cost, {X}% value-add, below 10% threshold]
  - {brief rationale - potential improvements}
  - Confidence: {LOW/MEDIUM/HIGH}

### Skills to Remove (Below Threshold)

- **{skill-name}** [LARGE cost, {X}% value-add, below 20% threshold]
  - High token cost (≥2.5K) not justified by {X}% value-add
  - Confidence: {LOW/MEDIUM/HIGH}

- **{skill-name}** [SMALL cost, {X}% value-add, below 10% threshold]
  - Default behavior sufficient in {100-X}% of cases
  - Confidence: {LOW/MEDIUM/HIGH}

---

## Threshold Analysis

| Skill | Token Cost | Value % | Threshold | Met? | Recommendation | Confidence |
|-------|------------|---------|-----------|------|----------------|------------|
| {skill-name} | SMALL | 15% | 10% | ✅ | KEEP | HIGH |
| {skill-name} | LARGE | 25% | 20% | ✅ | KEEP | MEDIUM |
| {skill-name} | LARGE | 15% | 20% | ❌ | REMOVE | HIGH |
| {skill-name} | SMALL | 7% | 10% | ❌ | REMOVE | MEDIUM |
| ... | ... | ... | ... | ... | ... | ... |

---

## Token Savings Analysis

**If all REMOVE recommendations accepted:**
- Skills removed: {N}
- Total tokens saved: ~{X}K per invocation
- Context capacity freed: {Y}%

**High-Impact Removals (LARGE skills below threshold):**
- {skill-name}: ~{X}K tokens, only {Y}% value-add
- {skill-name}: ~{X}K tokens, only {Y}% value-add

---

## Detailed Results

Individual evaluation files at root:
- `{skill-name}-evaluation.md`
- `{skill-name}-evaluation.md`
- ... ({SKILL_COUNT} files total)

---

## Methodology

- **Iterations:** {N} rounds per skill
- **Scenarios:** Multiple pressure scenarios per iteration
- **Focus:** Default behavior vs. skill-enhanced behavior
- **Thresholds:**
  - SMALL skills (<2.5K): >10% value required
  - LARGE skills (≥2.5K): >20% value required
- **Confidence:** Increases with iterations and consistent findings

---

## Recommendations

1. **Immediate removals:** {N} skills clearly below threshold
2. **Revision candidates:** {N} skills close to threshold with improvement potential
3. **High-value skills:** {N} skills significantly exceeding threshold
4. **Total token optimization:** ~{X}K tokens saved by removing low-value skills
5. **Portfolio efficiency:** Removing {Y}% of skills while maintaining {Z}% of value

---

## Next Steps

1. Review individual evaluation files for detailed analysis
2. Consider REMOVE recommendations for low-value skills
3. Plan improvements for REVISE candidates
4. Monitor HIGH-value skills for continued effectiveness
5. Re-test after portfolio optimization to measure impact
```

---

## Step 7: Display Console Summary

Show final summary to user:

```
ct:test-all-skills - Complete

🔍 Discovered {SKILL_COUNT} skills
📊 Completed {N} iterations per skill
📋 Generated {SKILL_COUNT} individual evaluations

📁 Final Report: .claude/test-reports/all-skills-evaluation-{timestamp}.md

📁 Individual Evaluations: (root directory)
   - {skill-name}-evaluation.md
   - {skill-name}-evaluation.md
   - ... ({SKILL_COUNT} files total)

🔍 Key Findings:
   ✅ {N} skills - exceed value threshold (KEEP)
   ⚠️  {N} skills - near threshold (REVISE)
   ❌ {N} skills - below threshold (REMOVE)

💰 Potential Token Savings: ~{X}K tokens per invocation

📊 Threshold Analysis:
   SMALL skills (<2.5K): {N} tested, {M} above 10% threshold
   LARGE skills (≥2.5K): {N} tested, {M} above 20% threshold

See final report for detailed recommendations.
```

---

## Error Handling

**If subagent fails:**
- Continue with other subagents
- Mark skill as "ERROR" in evaluation file
- Include error details in individual evaluation
- Note in final report

**If context limit approaching mid-iteration:**
- Complete current iteration
- Skip further iterations
- Generate final report with available data
- Note incomplete iterations in report

**If evaluation file missing (iteration >1):**
```
❌ Error: Evaluation file missing for {skill-name}
Expected: /{skill-name}-evaluation.md

This suggests iteration 1 failed. Skipping this skill.
```

**If evaluation file exists (iteration 1):**
```
⚠️ Warning: Evaluation file already exists: /{skill-name}-evaluation.md

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

**If skill file not found:**
```
❌ Error: Skill file not found: {skill-path}

This skill will be skipped.
```

**If no skills discovered:**
```
❌ Error: No skills found in .claude/skills/

Check that .claude/skills/ directory exists and contains skill files.
```

---

## Implementation Notes

1. **Parallel execution:** Use single message with {SKILL_COUNT} Task tool calls per iteration
2. **Iteration management:** Loop until context limit or completion criteria met
3. **File naming:** `{skill-name}-evaluation.md` at root
4. **Test artifacts:** Always in `/tmp/skill-test-{skill-name}-iter{N}-{timestamp}/`
5. **Focus metric:** "Does skill meet value threshold based on token cost?" is PRIMARY question
6. **Dynamic discovery:** Never hardcode skill count, discover at runtime
7. **Token thresholds:**
   - SMALL (<2.5K tokens): >10% value required
   - LARGE (≥2.5K tokens): >20% value required

---

## Success Criteria

Command succeeds if:
- All discovered skills tested at least once
- Evaluation files created for each skill (at root)
- At least 2 iterations completed per skill
- Final report generated with threshold analysis
- Value assessment completed for each skill
- Token cost classification completed for each skill
- Clear KEEP/REVISE/REMOVE recommendations provided
- Token savings analysis included
