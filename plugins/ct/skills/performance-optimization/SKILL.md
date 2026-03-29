---
name: performance-optimization
description: >
  Use when optimizing backend, API, database, or system performance. Also use when
  response times are slow, queries need tuning, throughput is degraded, or someone says
  "just add caching." Triggers on: optimize API, backend slow, API latency, database
  performance, query optimization, server response time, connection pooling, N+1 queries,
  cache strategy, load testing. For frontend/UI performance (Core Web Vitals, Lighthouse
  accessibility), use frontend-production-quality instead.
---

# Performance Optimization

## The Iron Law

**No optimization without baseline measurement. No exceptions.**

Skipped baseline? You cannot validate improvement. Period.
Already started without measuring? STOP. Measure NOW before continuing.
Already finished without measuring? Roll back to old code, measure, then re-apply changes and measure again.

**Violating the letter of this process IS violating the spirit.**

---

## MANDATORY FIRST STEP

**TodoWrite:** Create items for each phase below.

**Never skip measurement:**
- 70% of "obvious" bottlenecks are wrong — Profile first
- 40% of optimizations without baseline cause regressions
- Production monitoring dashboards are NOT a substitute for a controlled baseline

---

## Process: BASELINE → PROFILE → STRATEGY → IMPLEMENT → VALIDATE

### 1. Baseline Measurement (BEFORE any code changes)

Measure with a **reproducible tool under controlled conditions**:
- **Tool + metric + value** (e.g., "k6 load test: p95 = 4.2s at 100 req/s")
- **Target metric** (e.g., "p95 < 500ms at 100 req/s")
- **Conditions recorded** (concurrency, dataset size, environment, time)

A `curl` wall-clock time is NOT a baseline. Use:
- **API latency:** k6, wrk, vegeta, or hey with defined concurrency and duration
- **Database:** `pg_stat_statements`, `EXPLAIN ANALYZE`, slow query log
- **Application:** APM traces (DataDog, NewRelic, OpenTelemetry), `cProfile`, `perf`

### 2. Bottleneck Analysis (PROFILE, don't guess)

- Profile with appropriate tool (see above)
- Identify slowest operation with **specific timing and % of total**
  - e.g., "orders query = 3.1s, 78% of total request time"
- Determine root cause (N+1 queries, missing index, blocking I/O, serialization)

**If profiling contradicts your assumption, trust the profiler.**

### 3. Optimization Strategy

- Prioritize by measured impact (e.g., "3.1s → 0.2s = 94% reduction in query time")
- Evaluate 2-3 approaches with tradeoffs (complexity, maintainability, cache invalidation cost)
- State expected improvement with rationale

### 4. Implementation

- Describe the specific change (e.g., "replace N+1 loop with single JOIN query", "add composite index on (user_id, created_at)")
- Show before/after code or configuration
- Local verification against same dataset/conditions as baseline
- Keep the change minimal — fix the measured bottleneck, don't refactor the neighborhood

### 5. Validation

- **Re-measure with same tool, same conditions, same environment** as step 1
- Compare before/after with specific numbers (e.g., "p95: 4.2s → 380ms, throughput: 85 → 620 req/s")
- Check no regressions in other endpoints, error rates, or resource usage
- Record results in PR description with tool, conditions, and numbers

---

## Verification Checkpoint

Before marking complete, ALL must be true:
1. Baseline measured with specific tool + value BEFORE code changes
2. Profile identifies bottleneck with timing and % of total
3. Strategy evaluated 2+ approaches
4. Validation re-measured with same tool/conditions as baseline
5. Before/after numbers recorded in PR description

---

## Red Flags — STOP If You Think Any of These

| Thought | Reality |
|---------|---------|
| "Bottleneck is obvious, skip profiling" | 70% wrong without data. Profile first. |
| "We'll measure after" | Can't validate without before. Measure NOW. |
| "Manual testing / curl is enough" | Need reproducible metrics, not feelings. |
| "Production dashboards = baseline" | Different conditions, not controlled. Measure directly. |
| "Senior dev says cache everything" | That's a hypothesis, not a diagnosis. Profile first. |
| "Already changed the code, too late" | Roll back, measure old code, re-apply, measure again. |
| "No time to profile" | 15 min profiling saves hours of wrong-direction work. |
| "I've seen this pattern before" | This system is different. Measure THIS system. |

---

## What To Do When You Skipped Baseline

If you already made changes without measuring:

1. **Do NOT rationalize retroactive baselines** (production dashboards, "estimates")
2. **Git stash or branch** your changes
3. **Measure the old code** with proper tooling under controlled conditions
4. **Re-apply your changes**
5. **Measure again** with identical tool + conditions
6. **Now** you have a valid before/after comparison

This costs 30-60 minutes. Shipping unvalidated "performance improvements" costs trust, debugging time, and potential regressions.
