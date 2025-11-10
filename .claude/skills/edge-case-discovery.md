---
skill: edge-case-discovery
description: Systematically identify boundary conditions, failure modes, and edge cases through structured analysis
category: quality
---

# Edge Case Discovery

Systematically identifying boundary conditions prevents runtime failures and improves system resilience. Use this skill when designing APIs, writing defensive code, planning tests, threat modeling, or building fault-tolerant systems.

## 5-Step Process

### 1. Boundary Value Analysis
Identify boundaries for each input/parameter:

| Input Type | Boundaries to Test |
|------------|-------------------|
| **Numeric** | Min, max, zero, negative, overflow |
| **Strings** | Empty, null, very long, special chars, encoding |
| **Collections** | Empty, single item, max size, duplicates |
| **Time** | Past, future, now, range edges, leap years, timezones |
| **State** | Initial, final, transitional |

### 2. Equivalence Partitioning
Group inputs into classes, test one representative from each:
- Valid inputs (happy path)
- Invalid inputs (expected errors)
- Boundary inputs (edge of valid/invalid)

### 3. State Transition Analysis
Map all state transitions:
- Valid transitions
- Invalid transitions (should reject)
- Edge states (init, cleanup)
- Concurrent access scenarios

### 4. Error Condition Enumeration
For each operation, identify failure modes:
- Network failures, timeouts
- Resource exhaustion (memory, disk, connections)
- Concurrent access conflicts
- Partial failures (mixed success/failure)
- External dependency failures

### 5. Assumption Challenging
Question every assumption:
- "This will always be valid" - What if it's not?
- "Users won't do that" - What if they do?
- "The system guarantees X" - What if it doesn't?
- "This is impossible" - Under what conditions could it happen?

## Verification Checklist
- [ ] Numeric boundaries (min/max/zero/overflow)
- [ ] Empty/null cases
- [ ] Maximum sizes and resource limits
- [ ] State transitions (valid + invalid)
- [ ] Network/timeout failures
- [ ] Resource exhaustion scenarios
- [ ] Concurrent access patterns
- [ ] All assumptions challenged

## Output
Produce: boundary catalog, state transition diagram, error scenarios, challenged assumptions, edge case test plan
