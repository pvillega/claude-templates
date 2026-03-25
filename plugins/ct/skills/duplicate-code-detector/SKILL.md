---
name: duplicate-code-detector
description: >
  Runs jscpd static analysis to find duplicated and copy-pasted code with precise metrics (duplication percentages, line counts, clone groups) that cannot be derived by reading files manually. TRIGGER when the user mentions any of these words or concepts - duplicated, duplicate, copy-paste, copy-pasted, copied code, code clones, repeated code, similar code across files, same code in multiple places, overlapping implementations, code quality audit, code smells, technical debt involving repeated or duplicated code, or refactoring preparation where identifying duplication targets comes first. This includes cross-language or cross-platform duplication checks, CI duplication warnings, and any request to scan or analyze a codebase for redundancy. DO NOT TRIGGER when user wants to implement refactoring changes (use incremental-refactoring instead), fix a specific bug, write tests, add features, or do code review.
---

# Duplicate Code Detector

Automated duplicate detection produces significantly better results than manual review — tools like jscpd perform token-level comparison across every file pair, catching duplicates that are easy to miss when reading code by eye. This skill runs that analysis and turns the raw output into a prioritized, actionable refactoring plan.

## Detection vs Implementation

This skill **finds** duplicates. To **refactor** them, hand off to `incremental-refactoring` afterward.

Typical flow:
1. This skill → identify and prioritize duplicate code
2. `incremental-refactoring` → implement the changes with tests

If the user says something like "refactor technical debt" or "clean up this codebase", start here to find concrete targets first.

---

## Workflow

### Step 1: Install and run jscpd

Check whether jscpd is available, and install it if not:

```bash
which jscpd || npm install -g jscpd
```

If npm isn't available or installation fails, fall back to a grep-based approach: search for identical or near-identical multi-line blocks using `grep -rn` with context flags, or use `awk` to find repeated sequences. This won't be as thorough as jscpd but still surfaces obvious copy-paste patterns. Note this limitation to the user.

Run the analysis, excluding common non-source directories:

```bash
jscpd --min-lines 10 --min-tokens 50 \
  --ignore "node_modules,dist,build,vendor,.git,__pycache__,*.min.js" \
  --reporters json,console \
  /path/to/code
```

**Tuning guidance:**
- `--min-lines 10` is a reasonable default that avoids noise from short common patterns (imports, boilerplate). Lower to 5 for small codebases or raise to 15-20 for large/verbose ones.
- `--min-tokens 50` filters out trivially short matches. Adjust alongside min-lines.
- For specific languages, you can scope with `--format "javascript,typescript"` etc.
- jscpd writes JSON output to `report/` by default — read `report/jscpd-report.json` for structured data.

### Step 2: Extract metrics

From the jscpd JSON report, pull out:
- Overall duplication percentage
- Total duplicated lines
- Number of clone groups
- Files with the most duplication (sorted by duplicated lines)

Present a quick summary to the user before diving into details — this gives them a sense of scale.

### Step 3: Analyze top duplicates

For the top 3-5 duplicate groups (by lines x instances), dispatch subagents to analyze each one in parallel. Each subagent should:

```
Analyze this duplicate code group:
- Source A: <file_a> lines <X-Y>
- Source B: <file_b> lines <M-N>
- (additional instances if any)

Read the duplicated code and its surrounding context. Then:
1. Describe what the duplicated code does (1-2 sentences)
2. Identify the appropriate refactoring pattern:
   - Extract Function: for duplicated logic that can become a shared helper
   - Extract Class/Module: for larger chunks with shared state
   - Template Method: for similar-but-not-identical sequences with variation points
   - Configuration/parameterization: for code that differs only in literal values
3. Note any subtle differences between the instances (these affect refactoring strategy)
4. Estimate impact: how many lines would be saved, how many files touched
5. Flag any risks (e.g., instances that look the same but have different side effects)

Save your analysis to: <output_path>
```

### Step 4: Generate TDD refactoring plan

Prioritize duplicates by impact: `duplicated_lines x number_of_instances`, breaking ties by complexity.

For each priority item, produce a plan like:

```markdown
## Priority 1: [Descriptive name] (X lines across Y instances)
**Pattern:** Extract Function / Extract Class / etc.
**Files affected:** list of files

1. Write a test that captures the current behavior of one instance
2. Extract the shared code into [function/class/module] with [parameters for variation points]
3. Replace each instance with a call to the extracted code
4. Run tests after each replacement to catch subtle differences
5. Remove any dead code left behind
```

The test-first approach matters here because duplicated code often has slight behavioral differences between instances that only surface when you try to unify them.

### Step 5: Present findings

Summarize everything for the user:

```
## Duplicate Code Analysis

**Metrics:** X% duplication (Y duplicated lines across Z clone groups)

**Top priorities:**
1. [Name] — X lines, Y instances → [refactoring pattern]
2. [Name] — X lines, Y instances → [refactoring pattern]
3. [Name] — X lines, Y instances → [refactoring pattern]

**Refactoring plan:** [TDD steps for each priority]

Want to start refactoring Priority 1? (I'll hand off to incremental-refactoring)
```

---

## Before finishing

Verify:
1. jscpd ran successfully (or fallback was used) with metrics extracted
2. Each priority item has a concrete TDD refactoring plan
3. Priorities are ranked by impact, not just by which appeared first in the report
