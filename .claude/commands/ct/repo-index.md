---
description: "Run repository indexing to create/update PROJECT_INDEX.md"
allowed-tools:
  - Task
---

# Repository Indexing

Trigger the `repo-index` agent to scan and index the codebase.

## Your Task

1. Dispatch a Task to the `repo-index` subagent with the following prompt:

```
Index this repository following your standard procedure. Report what was done
```

2. Report the agent's findings to the user

## Notes

- The agent handles freshness detection automatically
- Creates or updates `PROJECT_INDEX.md` at project root
- Useful for large codebases to compress context
