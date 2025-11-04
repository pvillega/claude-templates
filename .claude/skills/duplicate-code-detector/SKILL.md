---
name: duplicate-code-detector
description: Use when asked about code quality, refactoring, technical debt, or duplicate code detection - runs jscpd automated analysis with subagents to provide quantitative duplication metrics and generate TDD refactoring plans instead of manual subjective code review
---

# Duplicate Code Detector

## Overview

Use jscpd (copy-paste detector) with subagents to systematically detect code duplication, provide quantitative metrics, and generate TDD refactoring plans. Automated analysis is faster, more accurate, and more comprehensive than manual code review.

**Core principle:** Systematic automated duplicate detection > manual subjective code review

## When to Use

**Trigger keywords from user:**
- "code quality" / "code review"
- "refactor" / "refactoring"
- "technical debt"
- "duplicate code" / "duplicates" / "duplication"
- "where should I start"
- "biggest problems"
- "clean up the code"

**When NOT to use:**
- User explicitly requests manual code review only
- Codebase has no source code files (config-only repos)
- User asks about specific non-duplication issues (e.g., "fix this bug")

## Quick Reference - jscpd Commands

| Task | Command |
|------|---------|
| Basic scan | `jscpd /path/to/code` |
| Specific formats | `jscpd --format "javascript,typescript" /path` |
| Min lines threshold | `jscpd --min-lines 5 /path` |
| Min tokens threshold | `jscpd --min-tokens 50 /path` |
| JSON output | `jscpd --format "javascript" --reporters json /path` |
| Ignore patterns | `jscpd --ignore "**/node_modules/**,**/*.test.js" /path` |
| Store mode | `jscpd --store /path` (creates .jscpd.json cache) |

**Common options:**
- `--min-lines N` - Minimum duplicate lines (default: 5)
- `--min-tokens N` - Minimum duplicate tokens (default: 50)
- `--threshold N` - Fail if duplication > N% (for CI)
- `--ignore "pattern"` - Exclude files/directories
- `--reporters html,json,console` - Multiple output formats

## Implementation Workflow

### Step 1: Run jscpd Analysis

**ALWAYS use TodoWrite** to track the workflow:

```
1. [ ] Run jscpd on target directory
2. [ ] Review duplication metrics
3. [ ] Dispatch subagents for top duplicates
4. [ ] Consolidate findings
5. [ ] Generate TDD refactoring plan
```

Run jscpd first:
```bash
jscpd --min-lines 5 --reporters json,console /path/to/code
```

### Step 2: Analyze Results

Extract key metrics:
- **Duplication percentage** - % of codebase that's duplicated
- **Total duplicated lines** - absolute number
- **Number of clones** - how many duplicate blocks
- **Files with most duplication** - where to focus

### Step 3: Dispatch Subagents (Context Preservation)

For each high-priority duplicate group:

```markdown
Dispatch subagent to analyze duplicate in:
- File A: path/to/file.js:lines X-Y
- File B: path/to/file2.js:lines M-N

Task: Read both instances, identify why duplicated, propose refactoring approach (extract function/class/module), estimate impact.
```

**Why subagents:** Preserves main context, enables parallel analysis of multiple duplicate groups.

### Step 4: Generate TDD Refactoring Plan

Based on subagent reports, create numbered plan:

```markdown
## Refactoring Plan (TDD Approach)

### Priority 1: [Duplicate Group Name] (X lines, Y% of codebase)
1. Write test for current behavior
2. Extract [function/class/module]
3. Replace duplicates with extraction
4. Verify tests pass
5. Refactor if needed

### Priority 2: ...
```

**Prioritize by:**
1. Lines duplicated (highest impact first)
2. Number of instances (more instances = more benefit)
3. Complexity (simpler extractions first)

### Step 5: Present to User

Format:
```markdown
## Duplication Analysis Results

**Metrics:**
- X% of codebase is duplicated
- Y total duplicated lines across Z clone groups
- Top files: [list with percentages]

**Top 3 Priorities:**
[Numbered list with impact estimates]

**Refactoring Plan:**
[Complete TDD plan for top priorities]

Would you like me to start with Priority 1?
```

## Common Rationalizations - STOP

If you catch yourself thinking any of these, STOP and use jscpd:

| Rationalization | Reality |
|----------------|---------|
| "Manual analysis is appropriate for this task" | jscpd is faster, more accurate, and comprehensive |
| "I'll examine the code directly" | Manual review misses cross-file duplication patterns |
| "User wants quick results, manual is fastest" | jscpd runs in seconds, manual takes minutes/hours |
| "User only wants summary, skip full workflow" | Metrics take 10 seconds, provide objective data |
| "User said 'scan', meaning manual review" | "Scan" = systematic analysis = jscpd |
| "Only need obvious duplicates" | "Obvious" is subjective; jscpd finds ALL duplicates |
| "Automated tools not mentioned/necessary" | Professional code review includes automated analysis |
| "Too simple to need TodoWrite" | Complex workflow requires tracking |

## Red Flags - Use jscpd Instead

- Starting manual file-by-file review
- Reading full files to "look for patterns"
- Asking user "what duplicates do you see?"
- Providing subjective assessment without metrics
- Skipping TodoWrite for analysis workflow
- Not using subagents for multiple duplicate groups
- Generating refactoring suggestions without duplication data

**All of these mean: Run jscpd first, then analyze results.**

## Common Mistakes

### ❌ Mistake 1: Skip jscpd, do manual review
```markdown
Let me read through your files to find duplicates...
[Proceeds to read files manually]
```

**Why bad:** Slow, incomplete, misses cross-file patterns, no metrics

**✅ Correct:**
```bash
jscpd --min-lines 5 --reporters json,console ./src
```

### ❌ Mistake 2: Run jscpd but ignore results
```markdown
I'll run jscpd... [runs it]
Now let me manually review the code...
```

**Why bad:** Wastes jscpd analysis, defaults to subjective review

**✅ Correct:** Use jscpd results to prioritize and guide refactoring

### ❌ Mistake 3: No TodoWrite for complex workflow
```markdown
I'll just quickly check for duplicates...
[Skips tracking, loses track of progress]
```

**Why bad:** Complex analysis without tracking leads to incomplete results

**✅ Correct:** Create TodoWrite checklist for all steps

### ❌ Mistake 4: No subagents for multiple duplicates
```markdown
[Reads 10 different duplicate blocks in main context]
```

**Why bad:** Burns context, slows analysis, can't parallelize

**✅ Correct:** Dispatch subagent per duplicate group, consolidate results

### ❌ Mistake 5: Provide findings without refactoring plan
```markdown
Here are the duplicates I found:
- File A and B have similar code
- File C and D also look similar
```

**Why bad:** User still doesn't know what to DO about it

**✅ Correct:** Generate complete TDD refactoring plan with priorities

## Example Workflow

**User:** "I want to refactor this codebase to reduce technical debt. Where should I start?"

**✅ Good response:**

1. Create TodoWrite checklist
2. Run jscpd:
```bash
jscpd --min-lines 5 --reporters json,console .
```
3. Parse results:
   - "15.3% duplication detected"
   - "1,247 duplicated lines across 23 clone groups"
   - "Top files: auth.js (34%), utils.js (28%), handlers.js (19%)"
4. Dispatch 3 subagents for top duplicate groups
5. Generate TDD refactoring plan:
```markdown
## Priority 1: Error handling pattern (412 lines, 8 instances)
1. Write test for current error handling
2. Extract ErrorHandler class
3. Replace 8 instances
4. Tests pass
5. Refactor for clarity

## Priority 2: Validation logic (298 lines, 5 instances)
...
```
6. Present metrics + plan to user

**Time:** 2-3 minutes with jscpd + subagents
**vs.** 30+ minutes manual review with incomplete results

## Real-World Impact

**Without skill:**
- 30+ minutes manual review
- Subjective assessment ("looks like some duplication")
- Misses cross-file patterns
- No prioritization data
- No actionable plan

**With skill:**
- 2-3 minutes automated analysis
- Objective metrics ("15.3% duplication, 1,247 lines")
- Comprehensive detection including cross-file
- Data-driven priorities
- Complete TDD refactoring plan

**Savings:** 90% time reduction, 10x accuracy improvement
