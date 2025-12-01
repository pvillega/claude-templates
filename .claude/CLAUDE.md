# Instructions

## Working with Code

<read_first>
ALWAYS read files before proposing changes. Verify patterns exist.
</read_first>

<minimal_changes>
Only changes directly requested or clearly necessary.
Avoid refactoring, features, or "improvements" beyond scope.
</minimal_changes>

<keep_clean>
After your changes: remove code YOUR changes made unused.
Prefer reusing existing patterns over creating duplicates.
Do not clean up unrelated code.
</keep_clean>

## Task Management

**TodoWrite granularity**: Specific steps, not vague tasks
- Bad: "style navbar"
- Good: "navbar: height 60->80px, padding-top 16->12px"

## Context Preservation via Subagents

**Default stance:** When uncertain, prefer subagent delegation.

### When to Dispatch Subagent

**Preserve main context when:**
- Current conversation has valuable context (requirements, decisions, architecture)
- Task involves reading/exploring code (file contents pollute context)
- Task might expand beyond initial scope
- You're mid-discussion and need to investigate a tangent
- Task would benefit from fresh perspective (no anchoring to prior discussion)
- Both research AND implementation needed (separate concerns)
- Review/validation needed (unbiased reviewer = separate context)

**Enable parallelism when:**
- 2+ independent subtasks identified
- Investigation can happen while main thread continues
- Multiple files/subsystems need independent analysis

### Red Flags → Stop and Delegate

If thinking ANY of these, dispatch subagent instead:

- "I'll just quickly..." → Scope will expand; bounded subagent handles it
- "While I'm looking at this..." → Tangent; separate subagent
- "Simple enough to handle inline" → Complexity hides; fresh context adapts
- "Already have the context I need" → Sunk cost; fresh eyes catch more
- "Faster without subagent overhead" → False economy; context pollution costs more later
- "Let me check a few things first" → Exploration pollutes; use Explore subagent

### Parallel Dispatch

When 2+ independent tasks exist, dispatch in **single message** with multiple Task calls.
Sequential dispatch when tasks have dependencies.

## Code Quality

After code changes:
1. Run `buildAll.sh` -> verify build and tests pass
2. Resolve ALL issues found

## Skills Integration

<trigger_skills>
Before complex work, check if a skill applies.
</trigger_skills>

## Git Operations

**File Operations**:
- Delete: your changes allowed | others' work -> ask first
- Before deleting for type/lint errors -> ask (may break other agents)
- Revert: your changes allowed | others' -> coordinate
- `.env` files: read-only, ask before changes

**Destructive Operations**:
- `git reset --hard`, `checkout` to old commits -> require explicit approval
- When unsure -> ask first

**Commit Discipline**:
- Atomic commits: only files you touched, explicit paths
- Tracked: `git commit -m "msg" -- path/file1 path/file2`
- New files: `git restore --staged :/ && git add "path/file1" && git commit`
- Quote paths with `[]()` chars
- `git rebase`: use `GIT_EDITOR=:` `GIT_SEQUENCE_EDITOR=:` (or `--no-edit`)
- Amend: only with explicit approval

## Security

<sensitive>
Never commit: .env, credentials.json, *.key, *.pem, API keys
</sensitive>

## Serena MCP Usage

<serena_tools>
Use for: cross-file refactoring, find references, get_symbols_overview, precise symbol edits, large codebases (1000+ files)
</serena_tools>

<native_tools>
Use for: small file reads/writes, simple line edits, new files from scratch, trivial fixes
</native_tools>

<serena_priority>
1. get_symbols_overview before diving in
2. find_symbol with include_body=False first
3. find_referencing_symbols before rename/refactor
4. read_memory to check for project context
</serena_priority>

<serena_notes>
Refer to tools by name, not "Serena's tools". Don't read bodies unnecessarily. Break large tasks into steps.
</serena_notes>
