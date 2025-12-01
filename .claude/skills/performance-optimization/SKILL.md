---
name: performance-optimization
description: Use when creating performance optimization plan for backend, API, or general system performance. Enforces BASELINE → PROFILE → OPTIMIZE → VALIDATE sequence. Triggers: "optimize API", "backend slow", "API latency", "database performance", "query optimization", "server response time". For "Core Web Vitals" in backend/API context, use this skill. For frontend UI accessibility + performance (WCAG, Lighthouse accessibility), use frontend-production-quality instead. If thinking "bottleneck is obvious" - profile first.
---

# Performance Optimization

## MANDATORY FIRST STEP

**TodoWrite:** Create 20+ items (5 sections × 4 items)
1. Baseline measurement (tool, current value, target, conditions)
2. Bottleneck analysis (profile, identify slowest, root cause)
3. Optimization strategy (prioritize, evaluate approaches, expected improvement)
4. Implementation (files, config, local verification)
5. Validation (re-measure, compare, check regressions)

**Never skip measurement:**
- 70% of "obvious" bottlenecks are wrong → Profile first
- 40% of optimizations without baseline cause regressions

---

## 5-Section Process

### 1. Baseline Measurement (BEFORE implementation)
- Tool + current value (e.g., "Lighthouse: LCP = 4.2s on 3G")
- Target metric (e.g., "LCP < 2.5s")
- Conditions recorded

### 2. Bottleneck Analysis
- Profile with tool (Chrome DevTools, pg_stat_statements, DataDog)
- Identify slowest operation + time (e.g., "Chart.js render = 2.8s, 67% of total")
- Root cause (N+1 queries, large bundle, blocking render)

### 3. Optimization Strategy
- Prioritize by impact (2.8s → 0.5s = 82% faster)
- Evaluate 2-3 approaches
- Expected improvement

### 4. Implementation
- Files + changes
- Configuration
- Local verification

### 5. Validation
- Re-measure same tool + conditions
- Compare before/after
- Check no regressions (FID, CLS, functionality)

---

## Verification Checkpoint

Before marking complete:
1. ✅ Baseline measured with specific tool + value
2. ✅ Profile identifies bottleneck with % of total time
3. ✅ Validation re-measures with same tool/conditions

---

## Red Flags

| Thought | Reality |
|---------|---------|
| "Bottleneck is obvious" | 70% wrong without profiling |
| "We'll measure after" | Can't validate improvement |
| "Manual testing is enough" | Need metrics, not feelings |
