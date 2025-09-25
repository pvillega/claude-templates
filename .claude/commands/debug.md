---
name: debug
description: Systematic bug analysis through evidence gathering for complex debugging scenarios
usage: /debug <bug-description>
---

Analyze complex bugs through systematic evidence gathering using the debugger agent. This command delegates comprehensive investigation to the specialized debugger agent that focuses on collecting concrete debug evidence before forming hypotheses.

## When to Use

Use for complex debugging scenarios including:

- Memory issues (segfaults, leaks, use-after-free)
- Concurrency bugs (race conditions, deadlocks)
- Performance problems (bottlenecks, slow queries)
- Intermittent failures (flaky tests, timing issues)
- Integration issues (API failures, data corruption)
- Complex state bugs (incorrect transitions)

## Examples

```
/debug Intermittent auth failures - users report random logouts in UserManager.cpp
/debug Memory leak in image processing pipeline after 1000+ operations
/debug Race condition in order processing causing duplicate charges
/debug Performance degradation in API after recent database migration
/debug Flaky test failure in payment integration tests
```

The debugger agent will handle the complete investigation workflow including evidence collection, root cause analysis, and cleanup, storing the final report in the `debug/` folder with format `{yyyy-mm-dd}-{name}`.
