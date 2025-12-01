---
description: "Generate commit message and perform atomic commit with safety checks"
argument-hint: "[optional: file paths - specific files to commit, or omit to use staged files]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# Commit Changes

Generate a conventional commit message and perform an atomic commit with comprehensive safety checks.

## Your Task

1. **Validate commit readiness**:
   - Run `git status` to check repository state and identify changed files
   - Detect special states:
     * Merge in progress (`.git/MERGE_HEAD` exists)
     * Clean working tree (no changes)
     * Detached HEAD or other unusual states
   - Exit gracefully if no changes to commit

2. **Determine files to commit**:
   - **If file paths provided as arguments**:
     * Validate each path exists
     * Verify each file has changes (`git status` shows it as modified/new)
     * Use these files as the commit target
   - **If no arguments but files are staged** (`git diff --staged` has content):
     * Use currently staged files
   - **If no arguments and nothing staged but unstaged changes exist**:
     * List all changed files
     * Use `AskUserQuestion` to ask which files to include
   - **Always exclude `.env` files**:
     * Check if any `.env` file is in target list
     * Remove it and display warning: "⚠️ Excluded .env file(s) from commit"

3. **Safety validation**:
   - Verify at least one file will be committed (exit if none)
   - Check for paths containing `[]()` characters → prepare proper quoting
   - Display file list with change types (modified/new/renamed/deleted)

4. **Generate commit message**:
   - Run `git diff` for unstaged target files (if any need staging)
   - Run `git diff --staged` for already-staged target files
   - Run `git log -5 --oneline` to check recent commit message style
   - Analyze all changes holistically:
     * Identify change type (feat, fix, chore, refactor, docs, test, style)
     * Understand purpose and impact
     * Group related changes
   - Generate message following this format:
     ```
     <type>: <Brief summary in imperative mood>

     - <Change detail 1>
     - <Change detail 2>
     - <Change detail 3>

     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```

5. **Review and confirm**:
   - Display the generated commit message in a clear code block
   - List all files that will be committed with their change types
   - List any excluded files (`.env`) with reasons
   - Use `AskUserQuestion` with options:
     * "Proceed with commit as shown"
     * "Cancel commit"
   - If user cancels, exit gracefully without making changes

6. **Execute commit**:
   - **Stage files if needed**:
     * If target files are unstaged, stage them explicitly
     * Use: `git add -- "path1" "path2" "path3"` with properly quoted paths
   - **Execute atomic commit**:
     * Use HEREDOC for message (handles multiline properly)
     * Use explicit file paths (enforces atomic commit)
     * Command format:
       ```bash
       git commit -m "$(cat <<'EOF'
       <generated-message>
       EOF
       )" -- "path1" "path2" "path3"
       ```
   - **Handle failures**:
     * If commit returns non-zero exit code, capture error output
     * Display error message to user
     * Preserve staged state (don't unstage)
     * Exit with failure status

7. **Verify and report**:
   - Run `git status` to verify commit succeeded and working tree is clean
   - Run `git log -1 --stat` to show the commit details
   - Display success report with:
     * ✅ Commit successful indicator
     * Commit hash (short form)
     * Commit message summary (first line)
     * File change statistics
     * Current branch name
     * Working tree status

## Output Format

### Review Stage (before commit)

```
📋 Commit Preview
═══════════════════════════════════════════

Files to commit (3):
  M  path/to/file1.ts
  M  path/to/file2.md
  A  src/new-file.ts

Excluded (1):
  ⚠️  .env (automatically excluded - never commit secrets)

Generated commit message:
───────────────────────────────────────────
feat: Add new authentication flow

- Implement OAuth2 provider integration
- Add user session management
- Create login/logout endpoints

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
───────────────────────────────────────────

Ready to commit?
```

### Success Report (after commit)

```
✅ Commit Successful
═══════════════════════════════════════════

Commit:  a1b2c3d
Message: feat: Add new authentication flow
Branch:  main

Changes:
  3 files changed, 147 insertions(+), 23 deletions(-)

  path/to/file1.ts     |  89 +++++++++++++++++++++
  path/to/file2.md     |  34 ++++++--
  src/new-file.ts      |  47 +++++++++++

Status: Clean working tree
```

## Safety Checks

This command implements multiple safety layers per CLAUDE.md requirements:

### Pre-commit Validation
- ✅ Always run `git status` before commit
- ✅ Verify files exist and have actual changes
- ✅ Automatically exclude `.env` files with warning
- ✅ Use explicit file paths (never `git add .` or `git commit -a`)
- ✅ Properly quote paths containing `[]()` characters

### User Confirmation
- ✅ Display complete commit message before committing
- ✅ Show all files that will be included
- ✅ Require explicit user approval via `AskUserQuestion`
- ✅ Allow cancellation without making changes

### Atomic Commit Enforcement
- ✅ Only commit explicitly specified or staged files
- ✅ Use `git commit -- path1 path2` syntax for atomic commits
- ✅ Never use blanket `git commit -a` flag
- ✅ Each file path is validated before inclusion

### Error Handling
- ✅ Detect commit failures (pre-commit hooks, conflicts, etc.)
- ✅ Display clear error messages
- ✅ Preserve staged state on failure for manual recovery
- ✅ Provide debugging guidance for common issues

### Prohibited Operations
- ❌ Never use `git commit --amend` (requires explicit approval)
- ❌ Never commit `.env` or other secrets files
- ❌ Never use `git add .` or `git commit -a` (violates atomic commits)
- ❌ Never commit without running `git status` first

## Notes

- **Relationship with `/ct:commit-msg`**: This command combines message generation + commit. Use `/ct:commit-msg` first if you only want to preview the message without committing.

- **Commit message format**: Uses conventional commit types (feat, fix, chore, refactor, docs, test, style) matching project history.

- **Claude Code attribution**: All commits include Claude co-author attribution as per project conventions.

- **Idempotent**: Safe to run multiple times - will detect nothing to commit and exit gracefully.

- **Path quoting**: Follows CLAUDE.md requirement to quote paths with `[]()` characters using double quotes in all git commands.

- **No amend**: This command never amends commits. It always creates new commits per CLAUDE.md safety requirements.

- **Staged vs unstaged**:
  * Prioritises currently staged files if present
  * Can stage additional files if specified as arguments
  * Never stages all changes automatically

- **Merge commits**: If a merge is in progress, the command will detect it and handle appropriately (may use MERGE_MSG).
