---
description: "Generate commit message for all current changes (staged)"
allowed-tools:
  - Bash
---

# Generate Commit Message

Generate a commit message for all changes in the current session, including staged files.

## Your Task

1. **Gather information about changes**:
   - Run `git status` to see all changed files
   - Run `git diff --staged` to view staged changes
   - Run `git log -5 --oneline` to check recent commit message style

2. **Analyze the changes**:
   - Identify the nature of changes (new feature, enhancement, bug fix, refactoring, etc.)
   - Group related changes together
   - Note any new files, deleted files, or renamed files
   - Understand the purpose and impact of the changes

3. **Generate commit message** following this format:
   ```
   <type>: <Brief summary in imperative mood>

   - <Change detail 1>
   - <Change detail 2>
   - <Change detail 3>
   ...

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

4. **Commit message guidelines**:
   - **Type prefix**: Use conventional commit types:
     - `feat:` - new feature
     - `fix:` - bug fix
     - `chore:` - maintenance tasks, dependency updates
     - `refactor:` - code restructuring without behavior change
     - `docs:` - documentation changes
     - `test:` - test additions or modifications
     - `style:` - formatting, whitespace changes
   - **Summary**: Concise description focusing on "why" rather than "what"
   - **Bullet points**: List specific changes in a structured way
   - **Accuracy**: Ensure message accurately reflects the changes and their purpose

5. **Output the message**:
   - Display the generated commit message as plain text
   - DO NOT execute `git commit`
   - DO NOT stage or unstage any files
   - Only output the commit message that would be used

## Output Format

Present the commit message in a code block so it can be easily copied:

```
<type>: <summary>

- <detail 1>
- <detail 2>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Notes

- This command is read-only and makes no changes to git state
- The message can be used with `git commit -m "$(cat <<'EOF'...)"` format
- Analyze both staged and unstaged changes together
- Consider the overall context and purpose of all changes
