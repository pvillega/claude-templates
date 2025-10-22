# Instructions

## Tasks

- **TodoWrite granularity**: Specific steps over vague tasks
  - ❌ "style navbar"
  - ✅ "navbar: height 60→80px, padding-top 16→12px"
- Use subagents & parallel agents where possible

## Code Quality

After code changes:
1. Run `buildAll.sh` → verify build ✅ & tests ✅
2. 🚨 MUST resolve all issues found

## Git Operations & Coordination

**File Operations**:
- Delete: obsolete files from your changes ✅ | others' work ❌ (ask first)
- ⚠️ Before deleting to fix type/lint errors → ask user (may break other agents' work)
- Revert: your changes ✅ | others' work ❌ (coordinate)
- Move/rename/restore: allowed ✅
- `.env` files: never edit ❌

**Destructive Operations 🚨**:
- `git reset --hard`, `git checkout/restore` to old commits → NEVER without explicit approval
- Treat as catastrophic → when unsure, ask first

**Commit Discipline**:
- `git status` before every commit
- Atomic commits: only files you touched, explicit paths
- Tracked: `git commit -m "msg" -- path/file1 path/file2`
- New: `git restore --staged :/ && git add "path/file1" && git commit -m "msg" -- path/file1`
- Quote paths with `[]()` chars
- `git rebase`: export `GIT_EDITOR=:` `GIT_SEQUENCE_EDITOR=:` (or `--no-edit`)
- Never amend without explicit approval

## MCP Documentation

@MCP_Context7
@MCP_ChromeDevTools
@MCP_Deepwiki
@MCP_Perplexity
@MCP_Playwright
@MCP_Serena
@MCP_Sequential
@MCP_Tavily
