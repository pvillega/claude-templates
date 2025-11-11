---
skill: incremental-refactoring
description: Systematic code transformation through small, measurable, behavior-preserving changes
category: engineering
---

# Incremental Refactoring

## When to Use
- Code smells identified
- Technical debt reduction planned
- Complexity metrics exceed thresholds
- Preparing for feature addition
- Post-feature cleanup

## 5-Step Mandatory Process

### 1. Analyze Code Quality (Baseline)
- TodoWrite: Create refactoring plan with metrics
- Measure cyclomatic complexity
- Check maintainability index
- Identify code duplication percentage
- Document baseline metrics

### 2. Identify Refactoring Pattern
From refactoring catalog:
- Extract Method, Extract Class
- Move Method, Inline Method
- Replace Conditional with Polymorphism
- Introduce Parameter Object
- Consolidate Duplicate Conditional Fragments
Select ONE pattern per iteration
IMPORTANT: Complete the pattern fully OR commit partial result as separate iteration

### 3. Apply Transformation
- Make ONE small change
- Preserve existing behavior exactly
- No new features during refactoring
- Keep changes atomic

### 4. Validate Preservation (MANDATORY)
- Run ALL tests → MUST pass with zero changes
- If tests fail → Revert immediately
- Re-measure complexity metrics → Calculate improvement %
- Document before/after comparison

### 5. Document Change
- Pattern applied
- Rationale (why this pattern?)
- Before/after metrics
- Commit with descriptive message

## Red Flags & Anti-Patterns
| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Big rewrite refactoring | Small, single-pattern changes |
| Skipping tests between changes | Run ALL tests after each change |
| Mixing refactoring with features | Separate refactoring commits |
| No metric measurement | Before/after metrics always |
| "I'll refactor everything at once" | ONE pattern per iteration |
