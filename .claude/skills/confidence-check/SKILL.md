---
name: confidence-check
description: Use before implementing when uncertainty exists. Weighted scoring across 5 checks (requires ≥80%). Triggers: "before implementing", "verify readiness", "should I proceed", "am I ready". If thinking "this is overkill" - use it.
---

# Confidence Check

Pre-implementation gate. Spend 100-200 tokens here to save 5,000-50,000 tokens on wrong-direction work.

## When to Use

**USE PROACTIVELY - before EVERY implementation, not just when uncertain:**
- Starting any feature, fix, or refactor
- About to write production code
- Architecture/stack decisions to make
- Integrating with unfamiliar code

**Especially critical when:**
- Stack is new or unfamiliar
- Requirements feel vague
- Codebase is large or complex
- User seems confident (overconfidence = highest risk)

**DO NOT use for:**
- Pure research/exploration tasks
- Reading/explaining existing code
- Documentation-only changes

## MANDATORY FIRST STEP

**TodoWrite:** Create 5 items (1 per check)
1. Search for duplicate implementations (Grep/Glob)
2. Verify architecture compliance (CLAUDE.md, patterns)
3. Check official documentation (Context7/WebFetch)
4. Find working OSS reference (Tavily/WebSearch)
5. Identify root cause (errors, logs, traces)

---

## 5 Checks (Weighted)

| Check | Weight | Pass Criteria |
|-------|--------|---------------|
| **No Duplicates** | 25% | No similar implementation exists |
| **Architecture Compliant** | 25% | Uses existing stack/patterns |
| **Official Docs Verified** | 20% | Official docs reviewed |
| **Working OSS Reference** | 15% | Proven implementation found |
| **Root Cause Identified** | 15% | Root cause clear |

**Task-specific variants:**
- **Bug Fix:** Root cause (40%) + Docs (30%) + OSS (30%)
- **New Feature:** Duplicates (40%) + Architecture (30%) + Docs (30%)
- **Refactor:** Architecture (50%) + Duplicates (30%) + OSS (20%)

---

## Decision Thresholds

| Score | Action |
|-------|--------|
| ≥80% | ✅ Proceed to implementation |
| 70-79% | ⚠️ Present alternatives, ask clarifying questions |
| <70% | ❌ STOP - Request more context from user |

---

## Output Format

```
Confidence Checks:
   [✅/❌] No duplicate implementations found
   [✅/❌] Uses existing tech stack
   [✅/❌] Official documentation verified
   [✅/❌] Working OSS implementation found
   [✅/❌] Root cause identified

Confidence: X.XX (XX%)
Decision: [Proceed/Ask Questions/Stop]
```

---

## Response Templates

**"Skip the check, this is straightforward"**
> Straightforward tasks fail 40% of the time from duplicate implementations or architecture mismatches. Confidence check takes 2 minutes. Which checks did you already complete?

---

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is too simple to check" | 40% of "simple" tasks duplicate existing code |
| "I already know the architecture" | Assumptions cause 30% of rework |
| "Official docs take too long" | 5 min reading saves 3 hours debugging |
