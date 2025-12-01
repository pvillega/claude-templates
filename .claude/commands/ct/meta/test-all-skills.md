---
description: "Test all skills using functional quality comparison (A/B with quality metrics)"
argument-hint: "[optional: iterations - runs per task for statistical validity; default: 3]"
arguments:
  - name: "iterations"
    type: "optional positional"
    description: "Number of runs per task for statistical validity. Default: 3. Valid: 1-5."
    example: "/ct:meta:test-all-skills-v2 5"
    default: "3"
---

# Test All Skills Command (v2 - Functional Quality Testing)

Tests all skills in `.claude/skills/` using functional quality comparison.

**Philosophy:** Measure OUTPUT QUALITY improvement, not process compliance.

---

## Overview

This command:
1. Discovers all skill files dynamically
2. Classifies each skill by type
3. Generates appropriate test tasks per skill type
4. Runs A/B comparison (baseline vs with-skill)
5. Evaluates quality using skill-specific rubrics
6. Calculates statistical significance
7. Generates comprehensive report with evidence-based recommendations

---

## Step 1: Discover and Classify Skills

### 1.1 Find All Skills

```bash
# Discover skills
SKILLS=$(find ./.claude/skills -maxdepth 1 -name "*.md" -type f)
SKILLS+=$(find ./.claude/skills -maxdepth 2 -name "SKILL.md")
SKILL_COUNT=$(echo "$SKILLS" | wc -l)
```

### 1.2 Classify Each Skill

For each skill, determine type:

| Type | Characteristics | Test Approach |
|------|-----------------|---------------|
| **ANALYTICAL** | Framework for analysis | Quality of analysis output |
| **PROCESS** | Step sequence | Outcome quality when process followed |
| **DISCIPLINE** | Prevents shortcuts | Output quality with discipline enforced |
| **CREATIVE** | Ideation/design | Quality/diversity of creative output |
| **META** | Creates artifacts | Quality of created artifacts |

Console output:
```
Discovering skills in .claude/skills/...

Found {{SKILL_COUNT}} skills:

| Skill | Type | Test Tasks |
|-------|------|------------|
| edge-case-discovery | ANALYTICAL | 3 |
| threat-modeling | ANALYTICAL | 3 |
| performance-optimization | PROCESS | 3 |
| confidence-check | PROCESS | 3 |
| ... | ... | ... |
```

---

## Step 2: Generate Test Tasks Per Skill Type

### Task Templates by Type

**ANALYTICAL skills:**
```markdown
Tasks requiring framework-guided analysis:
- Security analysis for auth system
- Edge case analysis for payment flow
- Threat analysis for file upload
```

**PROCESS skills:**
```markdown
Tasks benefiting from structured process:
- Performance issue investigation
- Pre-implementation readiness check
- Optimization planning
```

**DISCIPLINE skills:**
```markdown
Tasks where rigor affects outcome:
- Implement feature with tests
- Debug and verify fix
- Refactor with validation
```

**CREATIVE skills:**
```markdown
Tasks requiring creative output:
- Design system architecture
- Propose solution alternatives
- Plan feature implementation
```

**META skills:**
```markdown
Tasks creating artifacts:
- Create specialized agent
- Build automation workflow
- Design skill for new domain
```

---

## Step 3: Launch Parallel Testing

### 3.1 Phase 1: Baseline Collection

Launch parallel subagents to collect baseline outputs (WITHOUT skills):

**CRITICAL:** Launch in SINGLE message with multiple Task tool calls.

```
For each skill:
  For each task (3 per skill):
    For each run (3 per task):
      Task Tool:
        - subagent_type: "general-purpose"
        - description: "Baseline: {{skill}}/{{task}}/run{{N}}"
        - prompt: "
          Complete this task using baseline capabilities only.
          Do NOT load any skills.

          TASK: {{task_description}}

          Provide complete output.
          "
```

**Total baseline runs:** SKILL_COUNT × 3 tasks × 3 runs = 9 × SKILL_COUNT

### 3.2 Phase 2: Skill-Enhanced Collection

Launch parallel subagents WITH skills:

```
For each skill:
  For each task (3 per skill):
    For each run (3 per task):
      Task Tool:
        - subagent_type: "general-purpose"
        - description: "With skill: {{skill}}/{{task}}/run{{N}}"
        - prompt: "
          Complete this task using the {{skill_name}} skill.

          First, load the skill: {{skill_name}}
          Then follow its guidance.

          TASK: {{task_description}}

          Provide complete output.
          "
```

### 3.3 Phase 3: Quality Evaluation

Launch parallel evaluation subagents:

```
For each skill:
  For each task:
    For each run:
      Task Tool:
        - subagent_type: "general-purpose"
        - model: "sonnet"
        - description: "Evaluate: {{skill}}/{{task}}/run{{N}}"
        - prompt: "
          Evaluate these two outputs on the rubric.
          You do NOT know which used a skill.

          OUTPUT A: {{baseline_or_skill}}
          OUTPUT B: {{skill_or_baseline}}

          RUBRIC: {{skill_specific_rubric}}

          Score each 1-5 per dimension with justification.
          Calculate weighted totals.
          "
```

---

## Step 4: Statistical Analysis Per Skill

For each skill, calculate:

```markdown
STATISTICAL ANALYSIS: {{skill_name}}

## Raw Scores
| Task | Run | Baseline | With Skill | Delta |
|------|-----|----------|------------|-------|
| T1 | 1 | 3.2 | 4.1 | +0.9 |
| T1 | 2 | 3.0 | 4.3 | +1.3 |
| ... | ... | ... | ... | ... |

## Summary
- Baseline Mean: X.XX (SD: Y.YY)
- Skill Mean: X.XX (SD: Y.YY)
- Mean Improvement: +X.XX (XX%)
- 95% CI: [X.XX, Y.YY]
- Effect Size (d): X.XX
- Significant: Yes/No

## Recommendation
- Status: KEEP / KEEP (WEAK) / REVISE / REMOVE
- Confidence: HIGH / MEDIUM / LOW
```

---

## Step 5: Generate Final Report

**Location:** `.claude/test-reports/all-skills-quality-test-{{timestamp}}.md`

```markdown
# All Skills Quality Test Report

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Test Method:** Functional Quality Comparison (A/B)
**Skills Tested:** {{SKILL_COUNT}}
**Total Comparisons:** {{N}}

---

## Executive Summary

### Quality Impact by Recommendation

| Recommendation | Count | Avg Improvement | Evidence Strength |
|----------------|-------|-----------------|-------------------|
| **KEEP** | N | +X.XX (XX%) | High (CI excludes 0) |
| **KEEP (WEAK)** | N | +X.XX (XX%) | Medium (marginal CI) |
| **REVISE** | N | +X.XX (XX%) | Low (high variance) |
| **REMOVE** | N | +X.XX (XX%) | N/A (no improvement) |

### Key Findings

1. **Best performing skills:** [skills with largest effect size]
2. **Marginal skills:** [skills with inconsistent improvement]
3. **Ineffective skills:** [skills showing no quality improvement]

---

## Detailed Results by Skill

### {{skill_name}} - {{RECOMMENDATION}}

| Metric | Value |
|--------|-------|
| Type | {{ANALYTICAL/PROCESS/etc}} |
| Baseline Mean | X.XX |
| With-Skill Mean | X.XX |
| Improvement | +X.XX (XX%) |
| 95% CI | [X.XX, Y.YY] |
| Effect Size | X.XX |
| Confidence | HIGH/MEDIUM/LOW |

**Test Tasks:**
1. {{task1}} → +X.X improvement
2. {{task2}} → +X.X improvement
3. {{task3}} → +X.X improvement

**Strongest dimension:** {{dimension}} (+X.X)
**Weakest dimension:** {{dimension}} (+X.X)

---

[Repeat for each skill]

---

## Comparative Analysis

### Skills Ranked by Effect Size

| Rank | Skill | Effect Size | Improvement | Recommendation |
|------|-------|-------------|-------------|----------------|
| 1 | {{skill}} | X.XX | +XX% | KEEP |
| 2 | {{skill}} | X.XX | +XX% | KEEP |
| ... | ... | ... | ... | ... |

### Skills by Type Performance

| Type | Skills | Avg Improvement | Avg Effect Size |
|------|--------|-----------------|-----------------|
| ANALYTICAL | N | +XX% | X.XX |
| PROCESS | N | +XX% | X.XX |
| DISCIPLINE | N | +XX% | X.XX |
| CREATIVE | N | +XX% | X.XX |
| META | N | +XX% | X.XX |

---

## Methodology

### Test Design
- **Approach:** Functional A/B comparison
- **Tasks per skill:** 3 (type-appropriate)
- **Runs per task:** {{iterations}} (default 3)
- **Total runs:** {{SKILL_COUNT}} × 3 × {{iterations}} × 2 = {{N}}

### Quality Evaluation
- **Method:** LLM-as-Judge with skill-specific rubrics
- **Rubric source:** Derived from skill claims/success criteria
- **Evaluation:** Blind (judge doesn't know which is baseline)
- **Randomization:** A/B position randomized per evaluation

### Statistical Analysis
- **Mean comparison:** Baseline vs With-Skill
- **Confidence interval:** 95% CI for improvement
- **Effect size:** Cohen's d
- **Significance:** CI excludes 0

### Recommendation Criteria
| Mean Improvement | CI | Effect Size | Recommendation |
|------------------|-----|-------------|----------------|
| > 0.5 | Excludes 0 | > 0.5 | KEEP |
| > 0.3 | Barely includes 0 | 0.3-0.5 | KEEP (WEAK) |
| 0-0.3 | High variance | < 0.3 | REVISE |
| ≤ 0 | N/A | N/A | REMOVE |

---

## Recommendations

### Immediate Actions

**KEEP (High Confidence):**
{{list of skills with strong evidence}}

**REVISE (Needs Improvement):**
{{list of skills with specific suggestions}}

**REMOVE (No Quality Benefit):**
{{list of skills showing no improvement}}

### Portfolio Optimization

- Skills providing quality improvement: {{N}} ({{X}}%)
- Skills with marginal benefit: {{N}} ({{X}}%)
- Skills with no measurable benefit: {{N}} ({{X}}%)

---

## Appendix: Individual Skill Reports

Detailed reports for each skill saved to:
- `.claude/test-reports/{{skill1}}-{{timestamp}}.md`
- `.claude/test-reports/{{skill2}}-{{timestamp}}.md`
- ...

## Test Artifacts

All raw data in: `/tmp/skill-quality-test-{{timestamp}}/`
```

---

## Step 6: Console Summary

```
Testing all skills: Functional Quality Comparison

Skills discovered: {{SKILL_COUNT}}
Test iterations: {{N}} per task
Total comparisons: {{TOTAL}}

Results:

| Skill | Type | Baseline | With Skill | Δ | Sig? | Rec |
|-------|------|----------|------------|---|------|-----|
| edge-case-discovery | ANAL | 3.1 | 4.2 | +1.1 | ✅ | KEEP |
| threat-modeling | ANAL | 2.9 | 4.0 | +1.1 | ✅ | KEEP |
| performance-opt | PROC | 3.4 | 3.8 | +0.4 | ⚠️ | WEAK |
| confidence-check | PROC | 3.2 | 3.3 | +0.1 | ❌ | REVISE |
| ... | ... | ... | ... | ... | ... | ... |

Summary:
  ✅ KEEP (significant improvement): {{N}} skills
  ⚠️ KEEP (WEAK): {{N}} skills
  🔧 REVISE (inconsistent): {{N}} skills
  ❌ REMOVE (no improvement): {{N}} skills

Report: .claude/test-reports/all-skills-quality-test-{{timestamp}}.md
Artifacts: /tmp/skill-quality-test-{{timestamp}}/
```

---

## Key Differences from v1

| Aspect | v1 | v2 |
|--------|-----|-----|
| **Question asked** | "Will agent comply under pressure?" | "Does skill improve output quality?" |
| **Test scenarios** | Artificial pressure (CTO, sunk cost) | Real tasks skill should help with |
| **Success metric** | % of A/B/C compliance | Quality score improvement |
| **Evidence** | "100% value-add" | Effect size + confidence interval |
| **Statistics** | None (single pass) | Mean, SD, CI, Cohen's d |
| **Reproducibility** | Non-deterministic | Multiple runs, variance analysis |
| **Skill-specific** | Same test for all skills | Type-appropriate tests + rubrics |

---

## Error Handling

**Subagent failures:** Continue, mark as N/A, reduce confidence

**Insufficient data:** Report with caveats about reduced statistical power

**Context limits:** Complete current skill, generate partial report

---

## Notes

- Parallel execution maximized where possible
- Each skill gets type-appropriate testing
- Multiple runs provide statistical validity
- Blind evaluation prevents bias
- Evidence-based recommendations, not claims
