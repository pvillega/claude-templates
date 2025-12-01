---
description: "Test a skill using functional quality comparison (A/B testing with quality metrics)"
arguments:
  - name: "skill_name"
    type: "required positional"
    description: "The skill to test. Can be namespaced (superpowers:brainstorming) or local (edge-case-discovery)"
    example: "/ct:meta:test-skill-v2 edge-case-discovery"
argument-hint: "<skill-name>"
---

# Test Skill Command (v2 - Functional Quality Testing)

Test the skill: **{{skill_name}}**

**Philosophy:** Don't test "will agent comply under pressure?" - test "does skill improve output quality?"

---

## Overview

This command tests skills by measuring OUTPUT QUALITY improvement, not process compliance.

**The fundamental question:** Does using this skill produce BETTER results than not using it?

**Method:**
1. Classify skill type → determines appropriate test scenarios
2. Generate functional test tasks → real work the skill should help with
3. A/B comparison → same task with/without skill
4. Quality evaluation → rubric-based scoring by LLM judge
5. Statistical analysis → is improvement significant?

---

## Step 1: Validate and Classify Skill

### 1.1 Validate Skill Exists

**If namespaced (contains ':'):** Check Skill tool's available skills list
**If local (no ':'):** Check `.claude/skills/{{skill_name}}.md` exists

If not found, show error and STOP.

### 1.2 Read and Parse Skill

Read the skill file and extract:

```markdown
SKILL ANALYSIS:
- Name: {{skill_name}}
- Description: [from frontmatter]
- Triggers: [when to use, from description]
- Claims: [what it promises to improve]
- Framework: [methodology/process it provides]
- Output type: [what it produces - analysis, code, plan, etc.]
- Success criteria: [from verification checkpoints if present]
```

### 1.3 Classify Skill Type

Based on skill content, classify as ONE of:

| Type | Characteristics | Example Skills |
|------|-----------------|----------------|
| **ANALYTICAL** | Provides framework for analysis/discovery | edge-case-discovery, threat-modeling |
| **PROCESS** | Enforces sequence of steps | performance-optimization, confidence-check |
| **DISCIPLINE** | Prevents shortcuts/ensures rigor | TDD, verification-before-completion |
| **CREATIVE** | Improves ideation/design quality | brainstorming |
| **META** | Creates other artifacts (agents, skills) | meta-agent, testing-agents-with-subagents |

**Output classification:**
```
SKILL CLASSIFICATION:
- Type: [ANALYTICAL | PROCESS | DISCIPLINE | CREATIVE | META]
- Rationale: [why this classification]
```

---

## Step 2: Generate Test Tasks

Based on skill type, generate 3-5 FUNCTIONAL test tasks.

**Key principle:** Test tasks should be REAL WORK the skill claims to help with, not artificial pressure scenarios.

### For ANALYTICAL skills (edge-case-discovery, threat-modeling):

Generate tasks that require the type of analysis the skill provides:

```markdown
TEST TASKS FOR: {{skill_name}}

Task 1: [Domain: Authentication]
"Generate comprehensive edge case analysis for a user authentication
endpoint that handles login, signup, password reset, and OAuth integration."

Task 2: [Domain: Payments]
"Identify all edge cases for a payment processing system that handles
credit cards, refunds, partial payments, and currency conversion."

Task 3: [Domain: File Handling]
"Enumerate edge cases for a file upload feature supporting images up to
10MB, with virus scanning, metadata extraction, and cloud storage."
```

### For PROCESS skills (performance-optimization, confidence-check):

Generate tasks that benefit from the process:

```markdown
TEST TASKS FOR: {{skill_name}}

Task 1: "The dashboard page loads slowly. Optimize it."

Task 2: "API response times are above SLA. Improve performance."

Task 3: "Mobile app startup is sluggish. Speed it up."
```

### For DISCIPLINE skills (TDD, verification):

Generate tasks where discipline matters for quality:

```markdown
TEST TASKS FOR: {{skill_name}}

Task 1: "Implement an email validation function"

Task 2: "Add a caching layer with TTL expiration"

Task 3: "Build a retry mechanism with exponential backoff"
```

### For CREATIVE skills (brainstorming):

Generate tasks requiring creative output:

```markdown
TEST TASKS FOR: {{skill_name}}

Task 1: "Design a notification system for a social app"

Task 2: "Propose architecture for real-time collaboration features"

Task 3: "Create onboarding flow for complex B2B product"
```

### For META skills (meta-agent, testing-skills):

Generate artifact creation tasks:

```markdown
TEST TASKS FOR: {{skill_name}}

Task 1: "Create an agent for code review"

Task 2: "Build an agent for database optimization"

Task 3: "Design an agent for security auditing"
```

---

## Step 3: Define Quality Rubric

Create a scoring rubric based on what the skill CLAIMS to improve.

### Rubric Template

```markdown
QUALITY RUBRIC FOR: {{skill_name}}

Scoring: 1-5 scale per dimension (5 = excellent, 1 = poor)

## Dimension 1: [Primary skill claim]
- 5: [description of excellent]
- 3: [description of adequate]
- 1: [description of poor]

## Dimension 2: [Secondary skill claim]
...

## Dimension 3: [Tertiary skill claim]
...

## Overall Quality
Weighted average: D1 (X%) + D2 (Y%) + D3 (Z%) = Total Score
```

### Example Rubric: edge-case-discovery

```markdown
QUALITY RUBRIC FOR: edge-case-discovery

## D1: Quantity (20%)
- 5: 20+ distinct edge cases identified
- 3: 10-19 edge cases identified
- 1: <10 edge cases identified

## D2: Category Coverage (25%)
- 5: All 5 categories covered (boundary, equivalence, state, error, assumptions)
- 3: 3-4 categories covered
- 1: 1-2 categories covered

## D3: Specificity (25%)
- 5: All cases have specific input + expected behavior + test scenario
- 3: Most cases are specific, some vague
- 1: Mostly vague, generic cases

## D4: Non-Obviousness (15%)
- 5: Includes cases typical developer would miss
- 3: Mix of obvious and non-obvious
- 1: Only obvious/common cases

## D5: Actionability (15%)
- 5: All cases can be directly converted to tests
- 3: Most cases are testable
- 1: Cases too vague to test
```

### Example Rubric: threat-modeling

```markdown
QUALITY RUBRIC FOR: threat-modeling

## D1: STRIDE Coverage (30%)
- 5: All 6 STRIDE categories addressed with specific threats
- 3: 4-5 categories addressed
- 1: <4 categories addressed

## D2: Threat Specificity (25%)
- 5: Threats are specific to the system (not generic)
- 3: Mix of specific and generic
- 1: Mostly generic/boilerplate threats

## D3: Risk Prioritization (20%)
- 5: Clear risk scores with justified prioritization
- 3: Some prioritization present
- 1: No prioritization or random

## D4: Mitigation Quality (25%)
- 5: Specific, implementable mitigations for high-risk threats
- 3: General mitigation suggestions
- 1: Missing or vague mitigations
```

---

## Step 4: Run A/B Comparison

### 4.1 Baseline Testing (WITHOUT skill)

For each test task, spawn a subagent WITHOUT the skill:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- description: "Baseline test: {{task_domain}} - Run {{run_number}}"
- prompt: "
  IMPORTANT: Complete this task using your best judgment.
  Do NOT load any skills. Work from your baseline capabilities.

  TASK: {{task_description}}

  Provide your complete output.
  "
```

**Run 3 times per task** for variance analysis.

### 4.2 Skill Testing (WITH skill)

For each test task, spawn a subagent WITH the skill:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- description: "Skill test: {{task_domain}} - Run {{run_number}}"
- prompt: "
  IMPORTANT: Complete this task using the {{skill_name}} skill.

  First, use the Skill tool to load: {{skill_name}}
  Then follow the skill's guidance to complete the task.

  TASK: {{task_description}}

  Provide your complete output.
  "
```

**Run 3 times per task** for variance analysis.

### 4.3 Collect Outputs

Store all outputs:
```
/tmp/skill-test-{{skill_name}}-{{timestamp}}/
  ├── task1/
  │   ├── baseline_run1.md
  │   ├── baseline_run2.md
  │   ├── baseline_run3.md
  │   ├── skill_run1.md
  │   ├── skill_run2.md
  │   └── skill_run3.md
  ├── task2/
  │   └── ...
  └── task3/
      └── ...
```

---

## Step 5: Quality Evaluation (LLM-as-Judge)

### 5.1 Blind Evaluation

For each output pair (baseline vs skill), spawn evaluation subagent:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- model: "sonnet" (or ideally different model family)
- description: "Quality evaluation: {{task_domain}}"
- prompt: "
  You are a quality evaluator. Score these two outputs on the provided rubric.
  You do NOT know which output used a skill - evaluate purely on quality.

  TASK THAT WAS GIVEN:
  {{task_description}}

  OUTPUT A:
  {{output_a}}

  OUTPUT B:
  {{output_b}}

  RUBRIC:
  {{quality_rubric}}

  EVALUATION:
  For each dimension, score BOTH outputs 1-5 with brief justification.
  Then calculate weighted total for each.

  Format:
  ## Dimension 1: [name]
  - Output A: X/5 - [reason]
  - Output B: X/5 - [reason]

  ## Dimension 2: [name]
  ...

  ## TOTAL SCORES
  - Output A: X.XX / 5.00
  - Output B: X.XX / 5.00

  ## QUALITY DELTA
  - Difference: +/- X.XX (A vs B)
  - Better output: A / B / Tie
  "
```

**Note:** Randomize which output is A/B to prevent position bias.

### 5.2 Aggregate Scores

Collect all evaluation scores:

```markdown
EVALUATION RESULTS:

| Task | Run | Baseline Score | Skill Score | Delta |
|------|-----|----------------|-------------|-------|
| Task 1 | 1 | 3.2 | 4.1 | +0.9 |
| Task 1 | 2 | 3.0 | 4.3 | +1.3 |
| Task 1 | 3 | 3.4 | 3.9 | +0.5 |
| Task 2 | 1 | 2.8 | 4.0 | +1.2 |
| ... | ... | ... | ... | ... |
```

---

## Step 6: Statistical Analysis

### 6.1 Calculate Statistics

```markdown
STATISTICAL ANALYSIS:

## Summary Statistics
- Baseline Mean: X.XX (SD: Y.YY)
- Skill Mean: X.XX (SD: Y.YY)
- Mean Improvement: +X.XX (XX% improvement)

## Confidence Analysis
- 95% Confidence Interval for improvement: [X.XX, Y.YY]
- All runs improved: Yes/No (X/N runs)
- Worst case improvement: X.XX
- Best case improvement: X.XX

## Effect Size
- Cohen's d: X.XX (small < 0.5 < medium < 0.8 < large)

## Statistical Significance
- If CI excludes 0: "Statistically significant improvement"
- If CI includes 0: "Improvement not statistically significant"
```

### 6.2 Determine Recommendation

| Condition | Recommendation |
|-----------|----------------|
| Mean improvement > 0.5, CI excludes 0 | **KEEP** - Significant quality improvement |
| Mean improvement > 0.3, CI barely includes 0 | **KEEP (WEAK)** - Likely helps, needs more testing |
| Mean improvement 0-0.3, high variance | **REVISE** - Inconsistent benefit |
| Mean improvement ≤ 0 | **REMOVE** - No quality improvement |

---

## Step 7: Generate Report

Create timestamped report:

**Location:** `.claude/test-reports/{{skill_name}}-{{YYYY-MM-DD-HHMMSS}}.md`

```markdown
# Skill Quality Test Report: {{skill_name}}

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Test Type:** Functional Quality Comparison (A/B)
**Skill Classification:** {{type}}

---

## Executive Summary

**Recommendation:** KEEP / KEEP (WEAK) / REVISE / REMOVE
**Confidence:** HIGH / MEDIUM / LOW

**Key Finding:** [1-2 sentence summary of whether skill improves output quality]

---

## Quality Metrics

| Metric | Value |
|--------|-------|
| Baseline Mean Score | X.XX / 5.00 |
| With-Skill Mean Score | X.XX / 5.00 |
| Mean Improvement | +X.XX (XX%) |
| 95% CI | [X.XX, Y.YY] |
| Effect Size (Cohen's d) | X.XX |
| Statistically Significant | Yes/No |

---

## Test Tasks

1. **{{task1_name}}:** [brief description]
2. **{{task2_name}}:** [brief description]
3. **{{task3_name}}:** [brief description]

---

## Detailed Results

### Per-Dimension Analysis

| Dimension | Baseline | With Skill | Improvement |
|-----------|----------|------------|-------------|
| {{D1}} | X.X | X.X | +X.X |
| {{D2}} | X.X | X.X | +X.X |
| ... | ... | ... | ... |

**Strongest improvement:** {{dimension}} (+X.X)
**Weakest improvement:** {{dimension}} (+X.X)

### Per-Task Analysis

| Task | Baseline | With Skill | Improvement |
|------|----------|------------|-------------|
| Task 1 | X.X | X.X | +X.X |
| Task 2 | X.X | X.X | +X.X |
| Task 3 | X.X | X.X | +X.X |

---

## Qualitative Observations

### Where Skill Helped Most
- [specific observation from evaluation]
- [specific observation from evaluation]

### Where Skill Helped Least
- [specific observation from evaluation]
- [specific observation from evaluation]

### Potential Improvements
- [if REVISE recommended: specific suggestions]

---

## Methodology

- **Test type:** Functional A/B comparison
- **Tasks per skill:** {{N}}
- **Runs per task:** 3 (baseline) + 3 (with skill)
- **Total comparisons:** {{N}}
- **Evaluation:** LLM-as-Judge with rubric (blind comparison)
- **Statistical method:** Mean comparison with 95% CI

---

## Test Artifacts

Location: `/tmp/skill-test-{{skill_name}}-{{timestamp}}/`

- Task outputs (baseline and skill-enhanced)
- Individual evaluation scores
- Raw statistical data
```

---

## Step 8: Display Console Summary

```
Testing skill: {{skill_name}} (Functional Quality Comparison)

Classification: {{ANALYTICAL | PROCESS | DISCIPLINE | CREATIVE | META}}

Test Tasks:
  1. {{task1}} - {{baseline_score}} → {{skill_score}} (+{{delta}})
  2. {{task2}} - {{baseline_score}} → {{skill_score}} (+{{delta}})
  3. {{task3}} - {{baseline_score}} → {{skill_score}} (+{{delta}})

Quality Improvement:
  Baseline: {{X.XX}} / 5.00
  With Skill: {{X.XX}} / 5.00
  Improvement: +{{X.XX}} ({{XX}}%)
  95% CI: [{{X.XX}}, {{Y.YY}}]
  Effect Size: {{X.XX}} ({{small|medium|large}})

Recommendation: {{KEEP | KEEP (WEAK) | REVISE | REMOVE}}
Confidence: {{HIGH | MEDIUM | LOW}}

Report: .claude/test-reports/{{filename}}
Artifacts: /tmp/skill-test-{{skill_name}}-{{timestamp}}/
```

---

## Key Differences from v1

| Aspect | v1 (Pressure Testing) | v2 (Quality Testing) |
|--------|----------------------|----------------------|
| **What it tests** | Compliance under pressure | Output quality improvement |
| **Test scenarios** | "CTO says skip this" | Real tasks skill should help with |
| **Success metric** | Did agent follow process? | Is output better with skill? |
| **Evaluation** | A/B/C choice compliance | Rubric-based quality scoring |
| **Statistics** | "100% value-add" claim | Confidence intervals, effect size |
| **Reproducibility** | Single-run, non-deterministic | Multiple runs, variance analysis |

---

## Error Handling

**If skill not found:** Show available skills, STOP

**If subagent fails:** Mark as N/A, continue with remaining runs

**If insufficient runs complete:** Report with reduced confidence

**If /tmp write fails:** Use alternative location, warn user

---

## Notes

- Test files remain in /tmp for review
- Each test run gets unique timestamp
- Rubrics are skill-specific (not one-size-fits-all)
- Multiple runs provide statistical validity
- Blind evaluation prevents bias
