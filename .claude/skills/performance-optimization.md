---
name: performance-optimization
description: Use when optimizing system performance - enforces measurement-driven analysis and bottleneck elimination before implementing optimizations
---

# Performance Optimization

## 🚨 Anti-Rationalization Warning

**Never skip measurement because:**
- 70% of "obvious" bottlenecks are wrong → Profile first
- 40% of optimizations without baseline cause regressions → Measure before/after
- User complaints ≠ root cause → Data identifies the problem

**Common rationalizations = Failure signals:**
- "Bottleneck is obvious" | "Too urgent to profile" | "Low-risk change"

→ **STOP. Measure first, optimize second.**

---

## TodoWrite Requirements Checklist

**Before proceeding, verify ALL items:**

### Completeness (5 sections, 20+ total items)
- [ ] Baseline Measurement: 4+ items
- [ ] Bottleneck Analysis: 4+ items
- [ ] Optimization Strategy: 4+ items
- [ ] Implementation: 4+ items
- [ ] Validation: 4+ items

### Quality (Each item must have)
- [ ] Specific tool/technology (e.g., "Lighthouse", "pg_stat_statements")
- [ ] Concrete numbers/thresholds (e.g., "P95 < 500ms", "LCP < 2.5s")
- [ ] Measurable outcome (e.g., "reduces from 800ms to 400ms")

### Specificity Test
Select 3 random items and ask: "Can engineer implement without clarification?"
If NO → Item needs more specificity.

---

## Examples

**❌ Generic (fails test):**
"Optimize database queries" → Engineer asks: Which? How measured? Target?

**✅ Specific (passes test):**
"Profile queries with pg_stat_statements. Identify queries >100ms. Current: getUserProfile=250ms P95. Target: <100ms via optimization or caching."

**Common failures:**
- No tool names → "Measure performance" (with what?)
- No numbers → "Improve load time" (from/to what?)
- No verification → "Cache data" (how verify improvement?)

---

## Trigger Conditions

Activate this skill when:
- User requests performance optimization, speed improvements, or latency reduction
- Core Web Vitals scores failing (LCP > 2.5s, FID > 100ms, CLS > 0.1)
- API response times exceeding SLAs (P95 latency targets)
- Database queries slow (query time > 100ms)
- High resource utilization (CPU > 80%, memory > 85%)
- User complaints about slow page load or interactions
- Load testing reveals bottlenecks
- Performance regression detected in monitoring

---

## Mandatory Requirements

Create TodoWrite items for all categories below. Refer to Quality Standards and Completeness Check sections above.

### Baseline Measurement

- [ ] **Identify performance target**: Which metric? (LCP < 2.5s, API P95 < 500ms, query < 100ms)
- [ ] **Measure current performance**: Tool + value (Lighthouse: LCP = 4.2s on 3G)
- [ ] **Identify user journey**: Which flow? (homepage load, checkout, search)
- [ ] **Record conditions**: Connection (3G/4G/WiFi), load (concurrent users), data volume

### Bottleneck Analysis

- [ ] **Profile critical path**: Tool (Chrome DevTools, New Relic, DataDog APM)
- [ ] **Identify slowest operation**: What + time (Chart.js render = 2.8s, 67% of total)
- [ ] **Analyze resource usage**: CPU %, memory MB, network KB, query count
- [ ] **Determine root cause**: Why? (N+1 queries, large bundle, blocking render)

### Optimization Strategy

- [ ] **Prioritize by impact**: Largest improvement first (2.8s → 0.5s = 82% faster)
- [ ] **Evaluate approaches**: 2-3 options (lazy load, reduce bundle, cache)
- [ ] **Estimate improvement**: Expected change (LCP: 4.2s → 2.1s = 50% faster)
- [ ] **Consider trade-offs**: Effort (2 hours), complexity (low), risk (low)

### Implementation

- [ ] **Code changes**: Files + functions (src/components/Chart.tsx: dynamic import())
- [ ] **Configuration**: Infrastructure/build (webpack splitting, CDN cache headers)
- [ ] **Testing**: Local verification (DevTools Network, Lighthouse before/after)
- [ ] **Rollout**: Strategy (feature flag, gradual, monitor)

### Validation

- [ ] **Re-measure**: Same tool + conditions (Lighthouse on 3G throttle)
- [ ] **Compare before/after**: Document improvement (LCP: 4.2s → 2.1s = 50% faster)
- [ ] **Verify no regressions**: Check other metrics (FID, CLS, functionality)
- [ ] **Document results**: Record (ADR, wiki, runbook)

---

## Non-Negotiable Rules

1. **Measure First**: Answer these before optimizing: Current value? Tool used? Target?
2. **Profile to Find Bottleneck**: Use Chrome DevTools, New Relic, pg_stat_statements, etc.
3. **Validate After**: Re-run same tool, compare before/after, check regressions, document

---

## Red Flags - STOP When You Think:

| Thought | Why It Fails | Correct Action |
|---------|--------------|----------------|
| "Bottleneck is obvious" | 70% of assumptions wrong | Profile to confirm |
| "We'll measure after" | Can't validate improvement | Baseline required |
| "Profiling takes too long" | 15 min vs 3 days debugging | Profile first |

**If asked to skip requirements:** Politely decline, cite evidence for why measurement-first prevents wasted effort.

---

## Common Failure Prevention

### Anti-Pattern: Optimizing Without Profiling
```
❌ BAD: "Database queries are slow, let's add caching"
✅ GOOD: "Profile with pg_stat_statements. Identify queries > 100ms.
         Analysis shows getUserProfile = 250ms P95 (N+1 pattern).
         Options: 1) Fix N+1 with JOIN, 2) Add caching.
         Profile shows option 1 reduces to 50ms (80% improvement).
         Implement option 1, validate with pg_stat_statements."
```

### Anti-Pattern: Optimizing Without Baseline
```
❌ BAD: "Homepage is slow, let's optimize images"
✅ GOOD: "Baseline: Lighthouse shows LCP = 4.2s on 3G throttle.
         Bottleneck analysis: Hero image = 2.8s (67% of LCP).
         Strategy: Convert to WebP, add responsive srcset.
         Implementation: hero.jpg (450KB) → hero.webp (180KB, 60% smaller).
         Validation: Re-run Lighthouse → LCP = 2.1s (50% improvement) ✓"
```

### Anti-Pattern: Assuming Impact Without Measurement
```
❌ BAD: "This code is inefficient, let's refactor it"
✅ GOOD: "Profile shows processOrder() = 15ms (3% of total 500ms).
         Other functions: getInventory() = 420ms (84% of total).
         Priority: Optimize getInventory() first (84% impact).
         processOrder() optimization deferred (3% impact, not worth effort)."
```

### Anti-Pattern: Optimizing Everything
```
❌ BAD: "Let's optimize all database queries"
✅ GOOD: "pg_stat_statements shows 47 queries.
         Prioritize by impact: Top 5 queries = 80% of total query time.
         Focus optimization on top 5 (Pareto principle).
         Other 42 queries deferred (20% impact, not worth effort now)."
```


---

## Integration with Other Skills

- Use BEFORE `superpowers:test-driven-development` to optimize based on measured bottlenecks
- Use WITH `architecture-discipline` to design for performance at scale (10x load)
- Use AFTER `frontend-production-quality` to validate Core Web Vitals targets met
- Use WITH `backend-reliability-enforcer` to ensure optimizations don't compromise reliability

---

**Remember**: Performance optimization without measurement is guesswork. Measure first, optimize second. Validate improvements with before/after metrics. Focus optimization effort on the slowest 20% (Pareto principle) for 80% of improvement.
