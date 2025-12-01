---
description: "Test an agent using functional quality comparison (A/B testing with quality metrics)"
arguments:
  - name: "agent_name"
    type: "required positional"
    description: "Name of the agent to test. Can be a custom agent file name (e.g., 'rust-expert' for .claude/agents/rust-expert.md) or a Task tool subagent name (e.g., 'code-reviewer', 'Explore', 'Plan')"
    example: "/ct:meta:test-agent code-reviewer"
argument-hint: "<agent-name>"
---

# Test Agent Command (Functional Quality Testing)

Test the agent: **{{agent_name}}**

**Philosophy:** Don't test "will agent stay in scope under pressure?" - test "does specialized agent produce better results than general-purpose?"

---

## Overview

This command tests agents by measuring OUTPUT QUALITY improvement over a general-purpose baseline.

**The fundamental question:** Does using this specialized agent produce BETTER results than a general-purpose agent for the intended tasks?

**Method:**
1. Validate agent exists → load agent definition
2. Classify agent type → determines appropriate test scenarios
3. Generate functional test tasks → real work the agent should excel at
4. A/B comparison → same task with specialized agent vs general-purpose
5. Quality evaluation → rubric-based scoring by LLM judge
6. Statistical analysis → is improvement significant?

---

## Step 1: Validate and Load Agent

### 1.1 Validate Agent Exists

**If custom agent:** Check `.claude/agents/{{agent_name}}.md` exists
**If Task tool subagent:** Verify it's in the known list:
- general-purpose
- Explore
- Plan
- code-reviewer
- statusline-setup
- superpowers:code-reviewer

If not found, show error:
```
❌ Error: Agent '{{agent_name}}' not found

Custom agents in .claude/agents/:
[List *.md files from .claude/agents/ directory]

Task tool subagents:
- general-purpose, Explore, Plan, code-reviewer, statusline-setup, superpowers:code-reviewer
```
STOP HERE.

### 1.2 Read and Parse Agent

Read the agent definition and extract:

```markdown
AGENT ANALYSIS:
- Name: {{agent_name}}
- Type: Custom Agent / Task Tool Subagent
- Description: [from frontmatter or agent definition]
- Specialization: [what domain/task it's specialized for]
- Persona: [voice, tone, behavioral traits]
- Constraints: [what it should/shouldn't do]
- Tools available: [if specified]
- Expected outputs: [what it typically produces]
```

### 1.3 Classify Agent Type

Based on agent definition, classify as ONE of:

| Type | Characteristics | Example Agents |
|------|-----------------|----------------|
| **REVIEWER** | Evaluates code/content, provides feedback | code-reviewer, superpowers:code-reviewer |
| **EXPLORER** | Investigates codebases, gathers information | Explore |
| **PLANNER** | Creates plans, designs architectures | Plan |
| **SPECIALIST** | Deep expertise in specific domain | rust-expert, security-auditor |
| **OPERATOR** | Executes specific workflows/processes | statusline-setup |
| **GENERAL** | Broad capabilities, no specialization | general-purpose |

**Output classification:**
```
AGENT CLASSIFICATION:
- Type: [REVIEWER | EXPLORER | PLANNER | SPECIALIST | OPERATOR | GENERAL]
- Rationale: [why this classification]
```

---

## Step 2: Generate Test Tasks

Based on agent type, generate 3 FUNCTIONAL test tasks.

**Key principle:** Test tasks should be REAL WORK the agent is designed for, not artificial scenarios.

### For REVIEWER agents (code-reviewer, superpowers:code-reviewer):

```markdown
TEST TASKS FOR: {{agent_name}}

Task 1: [Code Quality Review]
"Review this authentication middleware for security issues, performance
problems, and code quality. Provide actionable feedback."
[Include sample code snippet]

Task 2: [PR Review Simulation]
"Review these changes to a payment processing module. Focus on correctness,
edge cases, and maintainability."
[Include sample diff]

Task 3: [Architecture Review]
"Evaluate this proposed database schema for a multi-tenant SaaS application.
Identify potential issues and suggest improvements."
[Include schema description]
```

### For EXPLORER agents (Explore):

```markdown
TEST TASKS FOR: {{agent_name}}

Task 1: [Codebase Understanding]
"Find all the places where user authentication is handled in this codebase
and explain how the auth flow works."

Task 2: [Pattern Discovery]
"Identify the error handling patterns used in this project and document
the different approaches found."

Task 3: [Dependency Analysis]
"Map out how the payment module interacts with other parts of the system.
What are its dependencies and dependents?"
```

### For PLANNER agents (Plan):

```markdown
TEST TASKS FOR: {{agent_name}}

Task 1: [Feature Planning]
"Create an implementation plan for adding real-time notifications
to this web application."

Task 2: [Migration Planning]
"Plan the migration from REST API to GraphQL for the user service."

Task 3: [Refactoring Planning]
"Design a plan to refactor the monolithic order processing into
separate microservices."
```

### For SPECIALIST agents (domain experts):

```markdown
TEST TASKS FOR: {{agent_name}}

Task 1: [Domain-Specific Task]
"[Task that requires the agent's specific expertise]"

Task 2: [Complex Domain Problem]
"[Harder problem in the agent's domain]"

Task 3: [Domain Best Practices]
"[Task requiring deep domain knowledge]"
```

### For OPERATOR agents (workflow executors):

```markdown
TEST TASKS FOR: {{agent_name}}

Task 1: [Standard Workflow]
"[Typical task the operator handles]"

Task 2: [Edge Case Workflow]
"[Less common but valid scenario]"

Task 3: [Complex Workflow]
"[Multi-step task requiring coordination]"
```

---

## Step 3: Define Quality Rubric

Create a scoring rubric with UNIVERSAL dimensions plus AGENT-SPECIFIC dimensions.

### Universal Dimensions (apply to all agents)

```markdown
UNIVERSAL DIMENSIONS:

## U1: Task Completion (20%)
- 5: Fully addresses all aspects of the task
- 3: Addresses main aspects, misses some details
- 1: Incomplete or misses key requirements

## U2: Output Quality (20%)
- 5: Clear, well-structured, professional output
- 3: Adequate structure, some clarity issues
- 1: Disorganized or unclear output

## U3: Actionability (15%)
- 5: Outputs are immediately actionable
- 3: Some interpretation needed
- 1: Vague or not actionable
```

### Agent-Specific Dimensions

**For REVIEWER agents:**
```markdown
## R1: Issue Detection (20%)
- 5: Catches subtle issues, not just obvious ones
- 3: Catches common issues
- 1: Misses important issues

## R2: Feedback Quality (15%)
- 5: Specific, constructive, explains why
- 3: Adequate feedback, some vague points
- 1: Generic or unhelpful feedback

## R3: Prioritization (10%)
- 5: Clear severity ranking, focuses on what matters
- 3: Some prioritization present
- 1: No prioritization or wrong priorities
```

**For EXPLORER agents:**
```markdown
## E1: Comprehensiveness (20%)
- 5: Finds all relevant code/information
- 3: Finds most relevant items
- 1: Misses significant relevant code

## E2: Accuracy (15%)
- 5: All findings are correct
- 3: Mostly correct, minor errors
- 1: Significant inaccuracies

## E3: Insight Quality (10%)
- 5: Provides meaningful insights beyond listing
- 3: Some analysis provided
- 1: Just lists without analysis
```

**For PLANNER agents:**
```markdown
## P1: Completeness (20%)
- 5: Plan covers all aspects, no gaps
- 3: Covers main aspects, some gaps
- 1: Significant planning gaps

## P2: Feasibility (15%)
- 5: Plan is realistic and implementable
- 3: Mostly feasible, some unclear parts
- 1: Unrealistic or unimplementable

## P3: Risk Awareness (10%)
- 5: Identifies risks and mitigation strategies
- 3: Some risk awareness
- 1: Ignores potential risks
```

**For SPECIALIST agents:**
```markdown
## S1: Domain Expertise (20%)
- 5: Demonstrates deep domain knowledge
- 3: Adequate domain knowledge
- 1: Lacks expected expertise

## S2: Best Practices (15%)
- 5: Applies domain best practices correctly
- 3: Some best practices applied
- 1: Ignores or violates best practices

## S3: Nuance (10%)
- 5: Handles domain nuances and edge cases
- 3: Handles common cases well
- 1: Misses important nuances
```

---

## Step 4: Run A/B Comparison

### 4.1 Baseline Testing (General-Purpose Agent)

For each test task, spawn a general-purpose agent:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- description: "Baseline test: {{task_domain}} - Run {{run_number}}"
- prompt: "
  Complete this task using your best judgment.

  TASK: {{task_description}}

  Provide your complete output.
  "
```

**Run 3 times per task** for variance analysis.

### 4.2 Specialized Agent Testing

For each test task, spawn the specialized agent:

**For custom agents:**
```
Task Tool Parameters:
- subagent_type: "general-purpose"
- description: "Agent test: {{agent_name}} - {{task_domain}} - Run {{run_number}}"
- prompt: "
  You are operating as the {{agent_name}} agent.

  [Include full agent definition from .claude/agents/{{agent_name}}.md]

  TASK: {{task_description}}

  Provide your complete output following your agent guidelines.
  "
```

**For Task tool subagents:**
```
Task Tool Parameters:
- subagent_type: "{{agent_name}}"
- description: "Agent test: {{agent_name}} - {{task_domain}} - Run {{run_number}}"
- prompt: "
  TASK: {{task_description}}

  Provide your complete output.
  "
```

**Run 3 times per task** for variance analysis.

### 4.3 Collect Outputs

Store all outputs:
```
/tmp/agent-test-{{agent_name}}-{{timestamp}}/
  ├── task1/
  │   ├── baseline_run1.md
  │   ├── baseline_run2.md
  │   ├── baseline_run3.md
  │   ├── agent_run1.md
  │   ├── agent_run2.md
  │   └── agent_run3.md
  ├── task2/
  │   └── ...
  └── task3/
      └── ...
```

---

## Step 5: Quality Evaluation (LLM-as-Judge)

### 5.1 Blind Evaluation

For each output pair (baseline vs agent), spawn evaluation subagent:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- model: "sonnet"
- description: "Quality evaluation: {{task_domain}}"
- prompt: "
  You are a quality evaluator. Score these two outputs on the provided rubric.
  You do NOT know which output used a specialized agent - evaluate purely on quality.

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

| Task | Run | Baseline Score | Agent Score | Delta |
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
- Agent Mean: X.XX (SD: Y.YY)
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
| Mean improvement ≤ 0 | **REMOVE** - No quality improvement over general-purpose |

---

## Step 7: Generate Report

Create timestamped report:

**Location:** `.claude/test-reports/agent-{{agent_name}}-{{YYYY-MM-DD-HHMMSS}}.md`

```markdown
# Agent Quality Test Report: {{agent_name}}

**Date:** {{YYYY-MM-DD HH:MM:SS}}
**Test Type:** Functional Quality Comparison (A/B)
**Agent Type:** {{Custom Agent | Task Tool Subagent}}
**Agent Classification:** {{REVIEWER | EXPLORER | PLANNER | SPECIALIST | OPERATOR}}

---

## Executive Summary

**Recommendation:** KEEP / KEEP (WEAK) / REVISE / REMOVE
**Confidence:** HIGH / MEDIUM / LOW

**Key Finding:** [1-2 sentence summary - does specialized agent outperform general-purpose?]

---

## Quality Metrics

| Metric | Value |
|--------|-------|
| General-Purpose Mean Score | X.XX / 5.00 |
| Specialized Agent Mean Score | X.XX / 5.00 |
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

| Dimension | Baseline | Agent | Improvement |
|-----------|----------|-------|-------------|
| Task Completion | X.X | X.X | +X.X |
| Output Quality | X.X | X.X | +X.X |
| Actionability | X.X | X.X | +X.X |
| {{Agent-specific 1}} | X.X | X.X | +X.X |
| {{Agent-specific 2}} | X.X | X.X | +X.X |
| {{Agent-specific 3}} | X.X | X.X | +X.X |

**Strongest improvement:** {{dimension}} (+X.X)
**Weakest improvement:** {{dimension}} (+X.X)

### Per-Task Analysis

| Task | Baseline | Agent | Improvement |
|------|----------|-------|-------------|
| Task 1 | X.X | X.X | +X.X |
| Task 2 | X.X | X.X | +X.X |
| Task 3 | X.X | X.X | +X.X |

---

## Qualitative Observations

### Where Agent Excelled
- [specific observation from evaluation]
- [specific observation from evaluation]

### Where Agent Showed No Advantage
- [specific observation from evaluation]
- [specific observation from evaluation]

### Potential Improvements
- [if REVISE recommended: specific suggestions for agent definition]

---

## Agent Definition Analysis

### Effective Elements
- [parts of agent definition that contributed to quality]

### Ineffective Elements
- [parts that didn't help or may have hindered]

### Suggested Refinements
- [specific changes to agent definition]

---

## Methodology

- **Test type:** Functional A/B comparison
- **Baseline:** general-purpose agent
- **Tasks per agent:** 3
- **Runs per task:** 3 (baseline) + 3 (agent)
- **Total comparisons:** 9
- **Evaluation:** LLM-as-Judge with rubric (blind comparison)
- **Statistical method:** Mean comparison with 95% CI

---

## Test Artifacts

Location: `/tmp/agent-test-{{agent_name}}-{{timestamp}}/`

- Task outputs (baseline and agent)
- Individual evaluation scores
- Raw statistical data
```

---

## Step 8: Display Console Summary

```
Testing agent: {{agent_name}} (Functional Quality Comparison)

Agent Type: {{Custom Agent | Task Tool Subagent}}
Classification: {{REVIEWER | EXPLORER | PLANNER | SPECIALIST | OPERATOR}}

Test Tasks:
  1. {{task1}} - {{baseline_score}} → {{agent_score}} (+{{delta}})
  2. {{task2}} - {{baseline_score}} → {{agent_score}} (+{{delta}})
  3. {{task3}} - {{baseline_score}} → {{agent_score}} (+{{delta}})

Quality Improvement:
  General-Purpose: {{X.XX}} / 5.00
  Specialized Agent: {{X.XX}} / 5.00
  Improvement: +{{X.XX}} ({{XX}}%)
  95% CI: [{{X.XX}}, {{Y.YY}}]
  Effect Size: {{X.XX}} ({{small|medium|large}})

Recommendation: {{KEEP | KEEP (WEAK) | REVISE | REMOVE}}
Confidence: {{HIGH | MEDIUM | LOW}}

Report: .claude/test-reports/agent-{{filename}}
Artifacts: /tmp/agent-test-{{agent_name}}-{{timestamp}}/
```

---

## Error Handling

**If agent not found:** Show available agents, STOP

**If subagent fails:** Mark as N/A, continue with remaining runs

**If insufficient runs complete:** Report with reduced confidence

**If /tmp write fails:** Use alternative location, warn user

**If agent definition unparseable:** Report error, suggest format fixes

---

## Notes

- Test files remain in /tmp for review
- Each test run gets unique timestamp
- Rubrics combine universal + agent-specific dimensions
- Multiple runs provide statistical validity
- Blind evaluation prevents bias
- Compares against general-purpose (not "no agent")
- Focus is on in-scope quality, not boundary/drift testing
