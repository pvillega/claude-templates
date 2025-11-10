---
name: performance-optimization
description: Use when optimizing system performance - enforces measurement-driven analysis and bottleneck elimination before implementing optimizations
---

# Performance Optimization

## ⚠️ MANDATORY FIRST STEP - READ THIS NOW

### 🚨 CRITICAL: Anti-Rationalization Warning

**Time pressure, sprint deadlines, and "obvious" solutions are NOT exceptions to this skill.**

This skill exists BECAUSE of pressure. Performance shortcuts under pressure create:
- Wasted optimization effort on non-bottlenecks (90% of "obvious" optimizations provide <5% improvement)
- Performance regressions from unmeasured changes (40% of optimizations without measurement make things worse)
- Premature optimization technical debt (complex code optimizing irrelevant paths)
- User experience degradation focusing on wrong metrics (backend latency vs frontend render time)

**Common rationalizations that mean you're about to fail:**
- "The bottleneck is obvious, no need to profile" → No, 70% of "obvious" bottlenecks are NOT the actual problem
- "We'll measure after implementing the optimization" → No, measure BEFORE to establish baseline and AFTER to validate
- "This optimization is low-risk" → 40% of optimizations without measurement introduce regressions
- "Profiling takes too long" → Profiling takes 15 minutes. Debugging wrong optimizations takes 3 days
- "Being pragmatic not dogmatic" → These requirements ARE pragmatic (prevent wasted effort on wrong optimizations)
- "This is an emergency, users are complaining" → User complaints don't identify root cause. Profiling does.

**If you're thinking any of these thoughts, STOP. Re-read the skill requirements.**

---

**STOP. Before proceeding with performance optimization, you MUST:**

1. **CREATE TodoWrite** with these 5 sections (DO NOT SKIP):
   - **Baseline Measurement**: Minimum 4 items
   - **Bottleneck Analysis**: Minimum 4 items
   - **Optimization Strategy**: Minimum 4 items
   - **Implementation**: Minimum 4 items
   - **Validation**: Minimum 4 items

2. **VERIFY TodoWrite quality** using standards below (MANDATORY - see verification checkpoint)

3. **CONFIRM section completeness** using checklist below

**Do not optimize, refactor, or implement until TodoWrite is created and verified.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, you MUST verify EVERY item meets quality standards BEFORE proceeding.**

**Complete this checklist and output the results:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO (examples: "P95 < 500ms", "LCP < 2.5s", "queries < 100ms", "CPU < 70%")
    - Names specific tools/technologies? YES/NO (examples: "Chrome DevTools Profiler", "New Relic", "Lighthouse", "pg_stat_statements")
    - States measurable outcome? YES/NO (examples: "P95 latency reduces from 800ms to 400ms", "LCP improves from 4.2s to 2.1s")
[ ] Item 2: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO
    - Names specific tools/technologies? YES/NO
    - States measurable outcome? YES/NO
[ ] Item 3: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO
    - Names specific tools/technologies? YES/NO
    - States measurable outcome? YES/NO

RESULT: All 9 checks must be YES. If any NO, revise items and re-verify.
```

**DO NOT PROCEED WITH OPTIMIZATION until all 9 checks pass.**

---

**Minimum total: 20 specific items** covering all 5 categories.

---

## Section Completion Confirmation

**After creating TodoWrite, output this checklist to confirm all sections present:**

```
SECTION COMPLETION:
[ ] Baseline Measurement: 4+ items
[ ] Bottleneck Analysis: 4+ items
[ ] Optimization Strategy: 4+ items
[ ] Implementation: 4+ items
[ ] Validation: 4+ items

TOTAL: ___ items (must be 20+)
```

**If any section is unchecked or total < 20, STOP and add missing items now.**

**Why this matters:** 45% of performance work skips baseline measurement. 60% skip validation after optimization. Without measurement, you don't know if optimization worked or caused regressions.

---

## TodoWrite Quality Standards

After creating TodoWrite, verify EVERY item meets these criteria:

- [ ] Names specific tool/metric/technology (e.g., "Chrome DevTools Profiler", "Lighthouse", "pg_stat_statements", "Redis GET latency")
- [ ] Includes concrete values/thresholds (e.g., "P95 < 500ms", "LCP < 2.5s", "query time < 100ms", "cache hit rate > 90%")
- [ ] States measurable outcome (e.g., "latency reduces from 800ms to 400ms", "LCP improves from 4.2s to 2.1s")

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

### What Makes an Item Specific?

Must include ALL three:
1. **Concrete numbers/thresholds**: "P95 < 500ms", "LCP < 2.5s", "query time < 100ms", "CPU usage < 70%", "cache hit rate > 90%"
2. **Specific tools/technologies**: "Chrome DevTools Profiler", "Lighthouse", "New Relic", "pg_stat_statements", "Redis INFO"
3. **Measurable outcome**: "P95 latency reduces from 800ms to 400ms", "LCP improves from 4.2s to 2.1s", "query time reduces from 250ms to 50ms"

### Test Examples

❌ **FAILS TEST**: "Optimize database queries"
- Engineer asks: Which queries? How measured? What's slow? What's the target?

✅ **PASSES TEST**: "Profile database queries using pg_stat_statements. Identify queries with mean_exec_time > 100ms. Current: getUserProfile query = 250ms P95. Target: < 100ms P95 via query optimization or caching."
- Engineer knows: Tool (pg_stat_statements), threshold (100ms), specific query (getUserProfile), current baseline (250ms P95), target (< 100ms P95), approaches (query optimization or caching)

❌ **FAILS TEST**: "Improve page load time"
- Engineer asks: Which page? Which metric? Current value? Target value? How measured?

✅ **PASSES TEST**: "Measure homepage LCP using Lighthouse on 3G throttle. Current baseline: LCP = 4.2s (hero image load). Target: LCP < 2.5s via image optimization (WebP format, responsive srcset, lazy loading below fold)."
- Engineer knows: Page (homepage), metric (LCP), tool (Lighthouse), connection (3G), baseline (4.2s), bottleneck (hero image), target (< 2.5s), strategies (WebP, srcset, lazy loading)

### Apply This Test

Before proceeding, select 3 random items from your TodoWrite and test them. If any fail, revise before proceeding.

---

### Examples of Quality Items

**❌ BAD (too generic):**
- "Optimize performance"
- "Speed up queries"
- "Improve load time"
- "Reduce latency"
- "Cache more things"

**✅ GOOD (specific):**
- "Baseline: Run Lighthouse on homepage with 3G throttle. Measure LCP, FID, CLS. Current: LCP = 4.2s, FID = 180ms, CLS = 0.15"
- "Profile: Chrome DevTools Performance tab, record 6s of homepage load. Identify long tasks > 50ms. Current: Main thread blocked 2.8s by Chart.js rendering"
- "Optimize: Lazy load Chart.js (current: 85KB gzipped loaded on page load). Target: Defer until user scrolls to chart section. Expected savings: 2.3s main thread time"
- "Validate: Re-run Lighthouse after optimization. Target: LCP < 2.5s (improvement from 4.2s = 40% faster), FID < 100ms (improvement from 180ms = 44% faster)"
- "Database: pg_stat_statements shows getRecentOrders query = 450ms P95 (N+1 query pattern). Add LEFT JOIN to eliminate N+1. Target: < 100ms P95 (78% improvement)"

---

## ❌ Failed Examples (What NOT To Do)

**These items would FAIL verification. If your items look like these, revise them immediately.**

### Too Generic (No Tool Names)

❌ "Measure performance"
- **Why it fails**: Measure what? How? With what tool?
- **Engineer asks**: Frontend? Backend? Which metric? Lighthouse? DevTools? APM?

❌ "Find bottleneck"
- **Why it fails**: Where? How? With what tool?
- **Engineer asks**: Profile CPU? Memory? Network? Database? With what?

❌ "Optimize code"
- **Why it fails**: Which code? How? Based on what measurement?
- **Engineer asks**: Which function? Which file? What's slow? How verified?

### Missing Concrete Numbers

❌ "Improve load time"
- **Why it fails**: From what to what? Which page? Which metric?
- **Engineer asks**: LCP? FCP? TTI? Current value? Target value? Which page?

❌ "Speed up queries"
- **Why it fails**: Which queries? By how much? Measured how?
- **Engineer asks**: Which queries? Current latency? Target latency? Which tool?

❌ "Reduce latency"
- **Why it fails**: Which latency? From what to what? How measured?
- **Engineer asks**: API latency? Database? Frontend render? P50? P95? P99?

### Missing Verification Method

❌ "Cache frequently accessed data"
- **Why it fails**: Which data? How verify it's frequently accessed? What's the hit rate?
- **Engineer asks**: Which endpoints? How measure frequency? Redis? In-memory? What hit rate target?

❌ "Optimize images"
- **Why it fails**: Which images? How verify improvement?
- **Engineer asks**: Which pages? Current size? Target size? WebP? Lazy load? How measure LCP impact?

**If 3+ of your TodoWrite items match these ❌ patterns, STOP. Your TodoWrite needs major revision before proceeding.**

---

## Section Completeness Check

Before proceeding, confirm ALL mandatory sections present in your TodoWrite:

- [ ] **Baseline Measurement**: 4+ items (current metrics, profiling tools, connection conditions, user journey) ✓
- [ ] **Bottleneck Analysis**: 4+ items (identify slowest operations, profile critical path, analyze resource usage, root cause) ✓
- [ ] **Optimization Strategy**: 4+ items (prioritize by impact, select approach, estimate improvement, consider trade-offs) ✓
- [ ] **Implementation**: 4+ items (specific code changes, configuration updates, infrastructure changes, rollout plan) ✓
- [ ] **Validation**: 4+ items (re-measure metrics, compare before/after, verify no regressions, document results) ✓

**If any section is missing or below minimum items, STOP and add them now.**

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

**⚠️ CRITICAL: Optimizing without baseline measurement wastes 70% of optimization effort on non-bottlenecks.**

- [ ] **Identify performance target**: Which metric matters? (LCP < 2.5s, API P95 < 500ms, query time < 100ms, CPU < 70%)
- [ ] **Measure current performance**: Use specific tool (Lighthouse, Chrome DevTools, APM, pg_stat_statements, Redis INFO)
- [ ] **Identify user journey**: Which flow is slow? (homepage load, checkout process, search results, dashboard render)
- [ ] **Record baseline conditions**: Connection speed (3G, 4G, WiFi), load level (concurrent users, requests/sec), data volume

**Template for baseline measurement:**
```
Performance Target: [Metric] < [Threshold]
- Current: [Metric] = [Value] (measured with [Tool])
- Connection: [3G / 4G / WiFi throttle]
- User journey: [Specific flow or page]
- Baseline conditions: [Load level, data volume]

Example:
Performance Target: Homepage LCP < 2.5s
- Current: LCP = 4.2s (measured with Lighthouse on 3G throttle)
- Connection: 3G (DevTools Network throttling)
- User journey: Homepage load for first-time visitor
- Baseline conditions: 0 cached resources, 100KB data fetched
```

### Bottleneck Analysis

**⚠️ CRITICAL: Optimizing the wrong thing provides 0% improvement and wastes engineering time.**

- [ ] **Profile critical path**: Use profiler (Chrome DevTools Performance, New Relic, DataDog APM) to record execution
- [ ] **Identify slowest operation**: What takes the most time? (render, network request, database query, CPU computation)
- [ ] **Analyze resource usage**: CPU %, memory MB, network KB, database query count
- [ ] **Determine root cause**: Why is it slow? (N+1 queries, large bundle, blocking render, inefficient algorithm)

**Template for bottleneck analysis:**
```
Bottleneck: [Specific operation or component]
- Tool: [Profiler used]
- Time: [Duration] (% of total [X%])
- Resource: [CPU / Memory / Network / Database]
- Root cause: [Specific technical reason]

Example:
Bottleneck: Chart.js rendering on homepage
- Tool: Chrome DevTools Performance tab
- Time: 2.8s (67% of total 4.2s LCP)
- Resource: CPU (main thread blocked)
- Root cause: Synchronous rendering of 85KB Chart.js library on page load
```

### Optimization Strategy

**⚠️ CRITICAL: Multiple optimization approaches exist. Choose based on impact vs effort analysis.**

- [ ] **Prioritize by impact**: Which bottleneck, if fixed, provides largest improvement? (2.8s → 0.5s = 55% faster)
- [ ] **Evaluate approaches**: List 2-3 options (lazy load, reduce bundle size, cache, optimize algorithm)
- [ ] **Estimate improvement**: Expected metric improvement (LCP from 4.2s to 2.1s = 50% faster)
- [ ] **Consider trade-offs**: Development effort (2 hours), complexity increase (low), risk (low - progressive enhancement)

**Template for optimization strategy:**
```
Priority: [Bottleneck] → [Approach]
- Impact: [Current value] → [Target value] ([% improvement])
- Approach: [Specific technique]
- Effort: [Hours or days]
- Trade-offs: [Complexity, risk, maintainability]

Example:
Priority: Chart.js lazy loading
- Impact: LCP from 4.2s to 2.1s (50% improvement)
- Approach: Defer Chart.js load until user scrolls to chart section (Intersection Observer)
- Effort: 2 hours (add Intersection Observer, dynamic import)
- Trade-offs: Low complexity, low risk (progressive enhancement), charts load on-demand
```

### Implementation

- [ ] **Code changes**: Specific files and functions to modify (src/components/Chart.tsx: add dynamic import())
- [ ] **Configuration updates**: Infrastructure or build config changes (webpack code splitting, CDN cache headers)
- [ ] **Testing approach**: How to verify locally (DevTools Network tab, Lighthouse before/after)
- [ ] **Rollout plan**: Deployment strategy (feature flag, gradual rollout, monitor metrics)

### Validation

**⚠️ CRITICAL: 40% of optimizations without validation introduce regressions or provide no improvement.**

- [ ] **Re-measure performance**: Use same tool and conditions as baseline (Lighthouse on 3G throttle)
- [ ] **Compare before/after**: Document improvement (LCP: 4.2s → 2.1s = 50% faster ✓)
- [ ] **Verify no regressions**: Check other metrics didn't degrade (FID, CLS, functionality)
- [ ] **Document results**: Record in performance log (ADR, wiki, runbook)

**Template for validation:**
```
Validation Results:
- Tool: [Same as baseline]
- Before: [Metric] = [Value]
- After: [Metric] = [Value]
- Improvement: [% or absolute improvement]
- Regressions: [None or list degraded metrics]

Example:
Validation Results:
- Tool: Lighthouse on 3G throttle
- Before: LCP = 4.2s, FID = 180ms, CLS = 0.15
- After: LCP = 2.1s, FID = 170ms, CLS = 0.12
- Improvement: LCP 50% faster ✓, FID 6% faster ✓, CLS 20% better ✓
- Regressions: None (all metrics improved)
```

---

## Non-Negotiable Rules

### Measure First, Optimize Second

**NEVER optimize without measuring baseline first.**

Before proposing any optimization, answer:
- **"What is the current performance metric value?"**
- **"What tool measured it?"**
- **"What is the target value?"**

If you can't answer these, you haven't done sufficient measurement.

### Profile to Find Bottleneck

**NEVER assume where the bottleneck is.**

Use profilers to identify the actual bottleneck:
- **Frontend**: Chrome DevTools Performance tab, Lighthouse
- **Backend**: New Relic, DataDog APM, pg_stat_statements
- **Database**: Query logs, EXPLAIN ANALYZE, pg_stat_statements
- **Infrastructure**: CloudWatch, Prometheus, Grafana

### Validate Improvements

**NEVER claim optimization worked without re-measuring.**

After implementing optimization:
- **Re-run same profiling tool** with same conditions
- **Compare before/after metrics** (absolute and percentage improvement)
- **Check for regressions** (other metrics didn't degrade)
- **Document results** (performance log, ADR, commit message)

---

## 🚩 Red Flags - STOP

**If you find yourself thinking or saying ANY of these, you are about to violate the skill:**

- "The bottleneck is obvious" → No, profile to confirm. 70% of "obvious" bottlenecks are wrong.
- "We'll measure after implementing" → No, measure BEFORE to establish baseline and AFTER to validate.
- "This optimization is low-risk" → 40% of unmeasured optimizations introduce regressions.
- "Profiling takes too long" → Profiling takes 15 minutes. Debugging wrong optimizations takes 3 days.
- "Users are complaining, we need to act fast" → User complaints don't identify root cause. Profiling does.
- "This is an obvious win" → Obvious != measured. Measure to confirm.
- "We can skip validation for simple changes" → Simple changes can have unexpected side effects. Always validate.
- "Performance is fine, just needs a little optimization" → "Fine" = unmeasured = unknown. Measure first.
- "We'll optimize everything" → Prioritize by impact. Optimize the slowest 20% first (Pareto principle).
- "Code review will catch issues" → Code review validates implementation. Profiling validates effectiveness.

**When you notice a red flag, STOP. Re-read the specific skill requirement you're about to skip.**

---

## When Asked to Skip Requirements

Use these EXACT response templates:

### "The Bottleneck is Obvious, No Need to Profile"

❌ **BLOCKED**: I cannot optimize without profiling to identify the actual bottleneck.

**Why "obvious" fails:**
- 70% of "obvious" bottlenecks are NOT the actual problem
- Profiling reveals unexpected bottlenecks (e.g., CSS recalc, garbage collection, synchronous I/O)
- Assumptions waste engineering time optimizing irrelevant code
- Profiling takes 15 minutes. Wrong optimizations cost 3 days.

**Required**: Profile with appropriate tool:
- Frontend: Chrome DevTools Performance tab (record 6s of user journey)
- Backend: APM tool (New Relic, DataDog) or pg_stat_statements for database
- Network: Chrome DevTools Network tab with throttling

**To override**: Not recommended. If you insist, document assumption and risk of wasted effort if wrong.

### "We'll Measure After Implementing the Optimization"

❌ **BLOCKED**: I cannot implement optimization without baseline measurement first.

**Why baseline matters:**
- Without baseline, you don't know if optimization worked (no before/after comparison)
- Can't quantify improvement (is 500ms good? Depends on baseline)
- Risk introducing regressions without noticing (other metrics degrade)
- Can't validate optimization effectiveness

**Required**: Measure baseline with specific tool:
- Frontend: Lighthouse (LCP, FID, CLS), DevTools Performance
- Backend: APM (P50/P95/P99 latency), database query logs
- Record: Current value, tool used, conditions (3G throttle, load level)

**To override**: Not acceptable. Baseline measurement is 5 minutes. Skipping it makes validation impossible.

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

## Verification

Before claiming performance optimization complete:

### 1. Baseline Check
   - [ ] Documented current performance metric (with tool name, value, conditions)
   - [ ] Identified target performance metric (with threshold)
   - [ ] Recorded user journey or workload (which flow or page)

### 2. Bottleneck Analysis
   - [ ] Profiled critical path (with specific profiler)
   - [ ] Identified slowest operation (with time and % of total)
   - [ ] Determined root cause (specific technical reason)

### 3. Optimization Strategy
   - [ ] Prioritized by impact (largest bottleneck first)
   - [ ] Evaluated 2-3 approaches (with trade-offs)
   - [ ] Estimated improvement (before → after values)

### 4. Implementation
   - [ ] Made specific code or config changes
   - [ ] Tested locally (with same profiler and conditions)

### 5. Validation
   - [ ] Re-measured performance (same tool, same conditions)
   - [ ] Compared before/after (absolute and % improvement)
   - [ ] Verified no regressions (checked other metrics)
   - [ ] Documented results (performance log, ADR, commit message)

**If any verification item is missing, do not mark task complete. Add blocking TodoWrite items.**

---

## Final Self-Grading

**Before claiming performance optimization complete, grade your own TodoWrite:**

```
SELF-GRADING CHECKLIST:
[ ] Minimum 20 items across 5 sections (Baseline 4+, Bottleneck 4+, Strategy 4+, Implementation 4+, Validation 4+)
[ ] 80%+ of items have concrete numbers/thresholds (P95 < 500ms, LCP < 2.5s, query < 100ms, CPU < 70%)
[ ] 80%+ of items name specific tools/technologies (Lighthouse, DevTools, pg_stat_statements, New Relic)
[ ] 100% of items have measurable outcomes ("P95 reduces from 800ms to 400ms", "LCP improves from 4.2s to 2.1s")
[ ] Zero items use vague verbs without specifics ("optimize performance", "speed up" without baseline/target)
[ ] Tested 3 random items with Specificity Test - all passed (can engineer implement without questions?)
[ ] Baseline measurement present with tool, current value, and target value
[ ] Validation present with before/after comparison and regression check

GRADE YOURSELF:
- All 8 checkboxes passed: 9-10/10 (Excellent - ready to proceed)
- 6-7 checkboxes passed: 7-8/10 (Good - minor revisions needed)
- 4-5 checkboxes passed: 5-6/10 (Needs revision - improve specificity)
- 0-3 checkboxes passed: 1-4/10 (Failed - major revision required)
```

**If you graded yourself below 7/10, you MUST revise TodoWrite before proceeding with optimization.**

**If baseline measurement or validation is missing, BLOCKED. Cannot optimize without measurement.**

**Why this matters**: 45% skip baseline measurement. 60% skip validation. Without measurement, you don't know if optimization worked or caused regressions.

---

## Integration with Other Skills

- Use BEFORE `superpowers:test-driven-development` to optimize based on measured bottlenecks
- Use WITH `architecture-discipline` to design for performance at scale (10x load)
- Use AFTER `frontend-production-quality` to validate Core Web Vitals targets met
- Use WITH `backend-reliability-enforcer` to ensure optimizations don't compromise reliability

---

**Remember**: Performance optimization without measurement is guesswork. Measure first, optimize second. Validate improvements with before/after metrics. Focus optimization effort on the slowest 20% (Pareto principle) for 80% of improvement.
