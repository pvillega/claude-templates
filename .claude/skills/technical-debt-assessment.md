---
skill: technical-debt-assessment
description: Systematically evaluate, quantify, and prioritize technical debt for strategic debt reduction
category: engineering
---

# Technical Debt Assessment

## When to Use
- Planning sprint/quarter technical work
- Evaluating codebase health
- Justifying refactoring investment
- Prioritizing tech debt reduction
- Onboarding to legacy codebase

## 6-Phase Process

### 1. Metric Collection
Gather quantitative data:
- **Complexity**: Cyclomatic complexity per function/class
- **Duplication**: Code duplication percentage
- **Maintainability**: Maintainability index (0-100)
- **Coverage**: Test coverage percentage
- **Dependencies**: Coupling metrics
- **Size**: Lines of code, function length

### 2. Pattern Identification
Identify qualitative issues:
- **Anti-patterns**: God objects, spaghetti code, cargo cult
- **Code smells**: Long method, large class, duplicate code
- **SOLID violations**: Which principles violated where?
- **Architecture issues**: Circular dependencies, wrong abstractions

### 3. Impact Analysis
For each debt item assess:
- **Velocity impact**: How much does this slow development?
- **Reliability impact**: Does this cause bugs?
- **Maintainability impact**: How hard is this to change?
- **Onboarding impact**: Does this confuse new developers?
- **Risk**: Could this cause production issues?

### 4. Priority Ranking
Create debt register with scores:
```
Debt Score = (Velocity Impact + Reliability Impact + Risk) / Effort to Fix

Priority:
- Critical (Score > 2.0): Address immediately
- High (Score 1.0-2.0): Address this quarter
- Medium (Score 0.5-1.0): Address when convenient
- Low (Score < 0.5): Monitor, may accept
```

### 5. Improvement Roadmap
Create phased plan:
- **Quick wins**: High impact, low effort (do first)
- **Strategic investments**: High impact, high effort (plan carefully)
- **Incremental improvements**: Medium impact, low effort (ongoing)
- **Accepted debt**: Low priority, documented trade-off

### 6. Progress Tracking
Establish monitoring:
- Metrics dashboard (track improvement over time)
- Debt register (living document)
- Monthly review (reprioritize based on changes)
- Velocity tracking (measure impact of debt reduction)

## Deliverables
- Technical Debt Register (prioritized list)
- Metrics Dashboard (quantitative view)
- Improvement Roadmap (phased plan)
- Cost/Benefit Analysis (justify investment)

## Anti-Patterns
❌ Subjective "this is bad" without metrics
❌ No prioritization (everything is critical)
❌ Assessment without action plan
❌ One-time assessment (debt tracking requires ongoing monitoring)
