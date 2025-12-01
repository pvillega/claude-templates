---
description: "Preview commit message without committing (dry run)"
allowed-tools:
  - Bash
---

# Preview Commit Message

Generate a commit message preview for staged changes WITHOUT executing the commit.

## When to Use

- **Preview before commit**: See what message would be generated
- **Manual workflows**: Generate message for `git commit -m "..."` usage
- **Dry run**: Validate changes without side effects

Use `/ct:commit` instead when you want to generate AND commit in one step with safety checks.

## Your Task

1. Run `git status` and `git diff --staged` to analyse staged changes
2. Run `git log -5 --oneline` to match project commit style
3. Generate conventional commit message following project conventions
4. Output message in copyable code block
5. **DO NOT** execute git commit

## Output Format

```
<type>: <summary in imperative mood>

- <change detail 1>
- <change detail 2>

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Type prefixes**: `feat:` | `fix:` | `chore:` | `refactor:` | `docs:` | `test:` | `style:`

## Notes

- Read-only operation, no git state changes
- Use `/ct:commit` for full workflow with safety checks and user confirmation
- Message can be used with `git commit -m "$(cat <<'EOF'...)"` format
