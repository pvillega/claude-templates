---
name: bugmagnet
description: Discover edge cases and test coverage gaps through systematic analysis. Use when analysing test coverage, finding bugs, hunting for edge cases, reviewing code for robustness, or when code-reviewer identifies test gaps. Also use when the user says things like "what could go wrong", "is this well tested", "find holes in my tests", "what am I missing", or asks about edge cases for any function or module.
credit: "Adapted from channingwalton/dotfiles (https://github.com/channingwalton/dotfiles)"
---

# BugMagnet

Systematic test coverage analysis and bug discovery.

Based on [gojko/bugmagnet-ai-assistant](https://github.com/gojko/bugmagnet-ai-assistant).

## Workflow

```
🔍 ANALYSE  → Understand code and existing tests
📊 GAP      → Identify missing coverage
✍️ WRITE    → Implement tests iteratively
🔬 ADVANCED → Deep edge case exploration (optional)
📋 SUMMARY  → Document findings and bugs
```

**Interactive mode (default):** STOP and wait for user confirmation between phases.
**Autonomous mode:** When invoked by another agent (e.g. code-reviewer), skip all STOP points and proceed through all phases automatically. Present the full summary at the end instead of pausing for input.

---

## Phase 1: Analysis (🔍 ANALYSE)

1. Detect language and testing conventions
2. Read implementation — public API, parameters, state, dependencies
3. Locate test file — if none exists, ask user about creating one
4. Run baseline coverage if tools available
5. Read existing tests — understand current coverage and patterns
6. Ask user: "Are there additional files I should review?"

**STOP** — Wait for user input. *(Skip in autonomous mode.)*

---

## Phase 2: Gap Analysis (📊 GAP)

Evaluate missing coverage using [edge-cases.md](references/edge-cases.md):

- Boundary conditions, error paths, state transitions
- Complex interactions, domain-specific edge cases
- Violated domain constraints

Categorise: **High** (core, errors, boundaries) → **Medium** (interactions, state) → **Low** (rare, performance). Present analysis with specific examples.

**STOP** — Ask user which tests to implement. *(Skip in autonomous mode — implement all high-priority tests.)*

---

## Phase 3: Test Implementation (✍️ WRITE)

For each test, highest priority first: write single test (or 2-3 related), name describes outcome ("returns X when Y"), run immediately. **Maximum 3 attempts per test** — document and move on.

**When bug found:** create minimal reproduction, explore surrounding territory (bugs cluster), document in skipped test — **DO NOT FIX, only document.** Include: brief description, root cause, code location, expected vs actual, proposed fix.

**STOP** — Ask user if they want advanced coverage. *(Skip in autonomous mode — proceed to advanced if high-priority gaps remain.)*

---

## Phase 4: Advanced Coverage (🔬 ADVANCED)

Create separate test suite: "bugmagnet session \<date\>"

Work through [edge-cases.md](references/edge-cases.md) comprehensively — complex interactions, error handling, numeric/date/string/collection edge cases, state transitions, domain-specific cases.

---

## Phase 5: Summary (📋 SUMMARY)

```markdown
## Test Coverage Summary

**Tests Added:** X total (Y passing, Z skipped/bugs)

**Bugs Discovered:**
1. Bug name — file:line — root cause — proposed fix
```

## Reference Files

- [Edge Case Checklist](references/edge-cases.md)
