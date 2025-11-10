---
name: root-cause-analysis
description: Use for technical/system failures (bugs, incidents, performance issues) requiring systematic evidence-based analysis - enforces hypothesis testing, pattern recognition, and documentation of evidence chains before proposing solutions
---

# Root Cause Analysis

## When to Use This Skill

Activate this skill when:
- Encountering bugs or failures requiring systematic investigation
- Multiple symptoms suggest deeper underlying issues
- Problem recurs despite attempted fixes (band-aid solutions)
- Need to trace failures through multiple system components
- Investigating production incidents or system degradation
- User requests "debug", "investigate", "why is X failing", or "root cause"
- Error messages appear but cause is unclear
- System behavior is inconsistent or unexpected

## Behavioral Mindset

**Follow evidence, not assumptions.**

Look beyond symptoms to find underlying causes through systematic investigation. Test multiple hypotheses methodically and always validate conclusions with verifiable data. Never jump to conclusions without supporting evidence.

**Key principles:**
- Symptoms are not causes - dig deeper
- One hypothesis is not enough - test alternatives
- Correlation is not causation - verify with experiments
- Intuition guides investigation but evidence decides
- Document the journey from symptom to root cause

---

## Mandatory Process

### 1. Evidence Collection (FIRST)

**Before proposing ANY explanation, collect:**

- [ ] **Error messages**: Full stack traces, error codes, timestamps
- [ ] **Logs**: System logs, application logs, database logs (with timestamps)
- [ ] **System state**: Resource utilization (CPU, memory, disk, network)
- [ ] **Data patterns**: Input that triggers failure, successful vs failed requests
- [ ] **Timeline**: When did problem start? Frequency? Any pattern (time of day, specific users)?
- [ ] **Recent changes**: Deployments, config changes, dependency updates in last 24-48h

**Do not proceed to hypotheses until evidence is documented.**

---

### 2. Hypothesis Formation (SECOND)

**Generate MINIMUM 3 distinct hypotheses explaining the evidence.**

For each hypothesis, specify:
- [ ] **Theory**: What is the suspected root cause?
- [ ] **Supporting evidence**: Which collected evidence supports this theory?
- [ ] **Prediction**: If this is true, what else should we observe?
- [ ] **Test**: How can we validate or invalidate this hypothesis?

**Why minimum 3 hypotheses?**
- Prevents anchoring on first idea
- Forces consideration of alternative explanations
- Often the 2nd or 3rd hypothesis is correct
- Documents what was ruled out (valuable for future)

---

### 3. Systematic Testing (THIRD)

**Test hypotheses in order of likelihood (based on evidence strength).**

For each test:
- [ ] **Test method**: Exact steps to validate/invalidate hypothesis
- [ ] **Expected result if hypothesis is correct**: Specific outcome
- [ ] **Expected result if hypothesis is wrong**: Alternative outcome
- [ ] **Actual result**: What actually happened
- [ ] **Conclusion**: Hypothesis validated, invalidated, or needs more testing

**Testing approaches:**
1. Add instrumentation (logging, metrics, debug mode)
2. Reproduce in isolation (minimal case, test vs production)
3. Check correlations (X always with Y? deployment timing? user patterns?)
4. Eliminate variables (disable feature, rollback, turn off component)

---

### 4. Root Cause Documentation (FOURTH)

**Once root cause is identified through testing, document the evidence chain.**

---

### 5. Solution Path (FIFTH)

**Only after root cause is validated, define solution.**

---

## Templates (Quick Reference)

**Evidence:** Error + timestamp + frequency + pattern + recent changes + system state

**Hypothesis:** Theory + supporting evidence + prediction + test method (minimum 3 hypotheses)

**Test Results:** Method + expected if correct + expected if wrong + actual result + conclusion

**Root Cause Report:** Symptom → Root cause → Evidence chain → Hypotheses tested → Supporting data

**Solution:** Immediate fix + permanent fix + verification + prevention + rollback plan

---

## Anti-Patterns - STOP If You're Doing This

- ❌ "It's probably X" → That's a hypothesis, not conclusion. Test it.
- ❌ "Let's try Y" → Random debugging ≠ systematic investigation
- ❌ "Error says Z" → Error = symptom. Dig for cause.
- ❌ "This worked before" → Different case may have different cause
- ❌ "Just restart" → Hides symptom, doesn't fix root cause

---

## Common Investigation Patterns

| Pattern | Evidence Needed | Likely Hypotheses | Tests |
|---------|----------------|-------------------|-------|
| **Intermittent** | Frequency, timing, load, users | Race condition, resource exhaustion, dependency timeout, data edge case | Load testing, timing logs, resource metrics, request analysis |
| **Sudden Onset** | Timestamp, recent changes, deployments | Recent deployment, dependency breaking change, config side effect | Rollback test, check deployment logs, compare configs |
| **Data Corruption** | Affected data, timing, schema changes | Race condition in writes, migration bug, validation bypass | Trace data flow, check transactions, review migrations |

---

## Verification Checklist

Before claiming root cause is found:

- [ ] Collected comprehensive evidence (logs, metrics, timeline, changes)
- [ ] Generated minimum 3 distinct hypotheses
- [ ] Tested hypotheses systematically with documented results
- [ ] Validated root cause with reproducible test
- [ ] Can explain why symptom occurred (evidence chain)
- [ ] Proposed solution directly addresses validated root cause
- [ ] Defined prevention strategy (monitoring, tests, process)
- [ ] Documented investigation for future reference

**If any item is unchecked, investigation is incomplete. Continue testing.**

---

## When NOT to Use This Skill

Skip this systematic process for:
- Simple, obvious bugs with clear cause (typo in code, missing import)
- Already-understood patterns (know from error message what's wrong)
- Time-critical production incidents (use quick fix first, then investigate)

For production incidents: Fix first (stop bleeding), then use this skill to find root cause and prevent recurrence.

---

## Integration with Other Skills

- Use AFTER `superpowers:systematic-debugging` when initial debugging reveals complex issues
- Use WITH `superpowers:root-cause-tracing` when tracing through call stacks
- Use BEFORE `superpowers:test-driven-development` to write regression tests
- Combine with `superpowers:defense-in-depth` to prevent similar issues at multiple layers

---

## Output Requirements

Your analysis must include:

1. **Evidence Collection**: Documented logs, errors, metrics, timeline
2. **Hypothesis Generation**: Minimum 3 distinct theories with supporting evidence
3. **Test Results**: Documented validation/invalidation for each hypothesis
4. **Root Cause Report**: Evidence chain from symptom to validated cause
5. **Solution Path**: Remediation steps, prevention strategy, rollback plan

**Do not propose solutions without completing steps 1-4.**

---

## Example Investigation

```
SYMPTOM: API returning 500 errors intermittently

EVIDENCE COLLECTED:
- Error: "Database connection timeout after 5000ms"
- First seen: 2025-01-15 14:23 UTC
- Frequency: 20-30 per hour, peaks at 15:00 and 18:00 UTC
- Pattern: Only during high traffic periods
- Recent changes: Database connection pool increased from 50 to 100 on Jan 14
- System state: Database CPU 85%, connection count peaks at 95

HYPOTHESES:
A: Connection pool exhausted under load
   - Evidence: Timeouts during high traffic, connection count near limit
   - Prediction: Should see pool exhaustion metrics spike with errors
   - Test: Check connection pool metrics during error spikes

B: Long-running queries blocking connections
   - Evidence: High database CPU during errors
   - Prediction: Should see queries taking >5s in slow query log
   - Test: Review slow query log during error period

C: Database connection leak (not returning to pool)
   - Evidence: Connection count stays high even after traffic drops
   - Prediction: Connection count should grow over time, not drop during low traffic
   - Test: Monitor connection count over 24h period

TEST RESULTS:
Test A: Pool exhaustion metrics show 100% utilization during errors - VALIDATED
Test B: Slow query log shows some 8s queries, but not correlated with all timeouts - PARTIALLY VALIDATES
Test C: Connection count drops back to normal during low traffic - INVALIDATED

ROOT CAUSE: Connection pool too small for peak traffic, exacerbated by slow queries

EVIDENCE CHAIN:
1. Errors occur only during high traffic (15:00, 18:00 UTC)
2. Connection pool utilization hits 100% during these times
3. Slow queries (8s) hold connections longer than expected
4. New requests timeout waiting for available connection
5. Pool size 100 insufficient for (peak traffic + slow query duration)

SOLUTION:
- Immediate: Increase connection pool to 200
- Permanent: Optimize slow queries (add indexes), implement query timeout
- Prevention: Alert on pool utilization >80%, monitor slow query log
- Verification: Error rate should drop to zero after pool increase
```

---

**Remember**: The goal is not to fix problems quickly. The goal is to fix the RIGHT problem, permanently, with evidence to back your conclusions.
