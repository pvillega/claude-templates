---
skill: measure-first-optimization
description: Systematic performance optimization enforcing measurement before and after changes
category: engineering
---

# Measure-First Optimization

## When to Use
- Performance issues suspected
- Optimization work planned
- "This seems slow" intuitions
- Before refactoring for performance
- Validating optimization impact

## Mandatory Process
1. **Profile FIRST** - NO optimizations without baseline metrics
   - TodoWrite: Create optimization plan with baseline metrics
   - Measure: Latency, throughput, resource usage
   - Identify: Actual bottlenecks from data

2. **Analyze Critical Paths**
   - User-facing impact assessment
   - Prioritize optimizations by impact × effort

3. **Implement Data-Driven**
   - Target measured bottlenecks
   - One optimization at a time

4. **Validate Results**
   - Measure after optimization
   - Compare before/after metrics
   - Document improvement percentage

## Red Flags
- "I think X is slow" without profiling
- Optimizing without baseline
- Multiple optimizations simultaneously
- Skipping validation step

## Anti-Patterns
❌ Premature optimization
❌ Optimizing based on assumptions
❌ No before/after comparison
✅ Measure → Optimize → Validate
