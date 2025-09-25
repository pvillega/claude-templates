---
name: commit
description: Commits changes
usage: /commit
---

Analyse ALL pending changes in the git repository (regardless of their source), generate a comprehensive commit message based on the actual changes, and commit everything without pushing.

## Phase 1: Gather Repository State

Use parallel Bash commands to collect comprehensive information about all pending changes:

1. **Check git status** to see all modified, added, and deleted files
2. **Run git diff HEAD** to see all changes (both staged and unstaged)
3. **Get recent commit history** with `git log --oneline -10` to understand commit style
4. **List all changed files** with `git diff --name-only HEAD`

**IMPORTANT: Do not commit binary files**: there may be binary files for the application as result of running build steps. Remove them before proceeding, so that they are not committed.

## Phase 2: Deep Change Analysis

Read all modified files and use Sequential-Thinking to analyse the changes:

1. **Read each modified file** to understand the full context of changes
   - For new files: understand their purpose and functionality
   - For modified files: compare changes to understand what was altered
   - For deleted files: note their removal

2. **Categorise changes** by type:
   - New features added
   - Bug fixes implemented
   - Refactoring performed
   - Documentation updates
   - Configuration changes
   - Test additions/modifications
   - Dependencies added/removed

3. **Understand the intention** behind changes:
   - What problem is being solved?
   - What functionality is being added or improved?
   - What architectural decisions were made?
   - How do the changes relate to each other?

4. **Identify the scope** of changes:
   - Which components/modules are affected?
   - Are there breaking changes?
   - Do changes follow a common theme?
   - What is the overall impact?

## Phase 3: Generate Commit Message

Create a detailed commit message following best practices:

### Message Structure

```text
<type>: <concise summary of what changed>

<detailed explanation of what changed and why>

Changes included:
- Key change 1: explanation
- Key change 2: explanation
- Key change 3: explanation

<any additional context, breaking changes, or notes>
```

### Commit Type Selection

Choose the most appropriate type based on the dominant change:

- `feat:` - New feature or functionality
- `fix:` - Bug fix or error correction
- `refactor:` - Code restructuring without changing behavior
- `docs:` - Documentation changes
- `test:` - Test additions or modifications
- `chore:` - Maintenance tasks, dependency updates
- `style:` - Code style/formatting changes
- `perf:` - Performance improvements
- `build:` - Build system or configuration changes

If multiple types apply, choose the most significant one and mention others in the body.

### Guidelines

- First line: 50 characters or less, imperative mood
- Blank line after first line
- Body: Wrap at 72 characters
- Explain WHAT changed and WHY, not HOW
- Include context about the problem being solved
- List all significant changes, grouped logically
- Mention any side effects or breaking changes
- Note if changes are from multiple sources/authors

## Phase 4: Commit Execution

Execute the commit with the generated message:

1. **Stage ALL changes** (both tracked and untracked):

   ```bash
   git add -A
   ```

2. **Verify what will be committed**:

   ```bash
   git status
   ```

3. **Create the commit** with the detailed message:

   ```bash
   git commit -m "$(cat <<'EOF'
   <generated commit message here>
   EOF
   )"
   ```

4. **Verify the commit** was created successfully:

   ```bash
   git log -1 --stat
   ```

## Important Notes

- **Commits ALL pending changes** regardless of their source or author
- **Does not discriminate** between user changes, tool changes, or automated changes
- **Includes everything**: staged, unstaged, and untracked files
- **Focus on actual changes** shown by git diff, not assumptions
- **Do not push** the commit - only create it locally
- **Comprehensive analysis**: Read actual file contents to understand changes thoroughly

## Edge Cases and Error Handling

Handle these scenarios gracefully:

- **No changes to commit**: Inform user there are no pending changes
- **Merge conflicts**: Alert user to resolve conflicts before committing
- **Binary file changes**: Note them in commit message without attempting to analyze
- **Large number of files**: Group related changes in the commit message
- **Mixed change types**: Identify primary change type and mention others
- **Uncommitted submodule changes**: Include note about submodule updates

## Execution Flow

1. Gather all repository information in parallel
2. Read and analyse all changed files
3. Use Sequential-Thinking to understand the overall change narrative
4. Generate a comprehensive, well-structured commit message
5. Stage and commit ALL changes
6. Provide confirmation of successful commit

Remember: This command commits EVERYTHING pending in the repository. The commit message should accurately reflect all changes, providing a complete picture of what was modified and why, regardless of who or what made the changes.
