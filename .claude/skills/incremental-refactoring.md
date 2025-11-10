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

## 6-Step Mandatory Process

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

### 3. Apply Transformation
- Make ONE small change
- Preserve existing behavior exactly
- No new features during refactoring
- Keep changes atomic

### 4. Validate Preservation (MANDATORY)
- Run ALL tests
- Tests MUST pass with zero changes
- If tests fail: Revert immediately
- No behavior changes allowed

### 5. Measure Improvement
- Re-measure complexity metrics
- Calculate improvement percentage
- Document metrics comparison
- Confirm improvement achieved

### 6. Document Change
- Pattern applied
- Rationale (why this pattern?)
- Before/after metrics
- Commit with descriptive message

## Red Flags
- "I'll refactor everything at once"
- Skipping tests between changes
- Mixing refactoring with features
- No metric measurement
- Large, non-atomic changes

## Anti-Patterns
❌ Big rewrite refactoring
❌ "Improving" code without tests
❌ Mixing refactoring with new features
❌ No before/after measurement
✅ Small steps with continuous validation
