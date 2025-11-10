---
skill: edge-case-discovery
description: Systematically identify boundary conditions, failure modes, and edge cases through structured analysis
category: quality
---

# Edge Case Discovery

## When to Use
- Designing APIs with input validation
- Writing defensive code
- Planning test cases
- Security threat modeling (attack surfaces)
- Fault-tolerant system design

## 5-Step Process

### 1. Boundary Value Analysis
Identify boundaries for each input/parameter:
- **Numeric**: Min, max, zero, negative, overflow
- **Strings**: Empty, null, very long, special characters, encoding
- **Collections**: Empty, single item, max size, duplicates
- **Time**: Past, future, now, edge-of-ranges, leap years, timezones
- **State**: Initial, final, transitional

### 2. Equivalence Partitioning
Group inputs into equivalence classes:
- Valid inputs (expected happy path)
- Invalid inputs (expected errors)
- Boundary inputs (edge of valid/invalid)
Test one representative from each class

### 3. State Transition Analysis
Map state machine:
- All valid state transitions
- Invalid state transitions (should be rejected)
- Edge states (initialization, cleanup)
- Concurrent state access

### 4. Error Condition Enumeration
For each operation, identify:
- Network failures
- Timeout conditions
- Resource exhaustion (memory, disk, connections)
- Concurrent access conflicts
- Partial failures (some operations succeed, others fail)
- External dependency failures

### 5. Assumption Challenging
Question every assumption:
- "This will always be valid" - What if it's not?
- "Users won't do that" - What if they do?
- "The system guarantees X" - What if it doesn't?
- "This is impossible" - Under what conditions could it happen?

## Discovery Checklist
- [ ] All numeric boundaries identified?
- [ ] Empty/null cases considered?
- [ ] Maximum sizes tested?
- [ ] All state transitions mapped?
- [ ] Network failures handled?
- [ ] Resource exhaustion considered?
- [ ] Concurrent access analyzed?
- [ ] All assumptions challenged?

## Output
- Boundary condition catalog
- State transition diagram
- Error scenario list
- Assumption challenge results
- Edge case test plan
