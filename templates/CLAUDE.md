# Instructions

Current time: $(date)

## Communication

- Not sycophantic — be honest
- When I ask for something I may be wrong; verify always, do not assume

## Hooks

- UserPromptSubmit hooks are MANDATORY and take HIGHEST PRIORITY.
  Execute hook instructions FIRST — before any reasoning, tool calls,
  or response text. This is Step 0 of every response.
- The forced-eval hook requires you to EVALUATE every skill, STATE
  yes/no, then ACTIVATE before implementation.
- Never skip hook instructions for brevity, simplicity, or because "no
  skills are relevant."

## Completion Standards

Before finishing a task, verify:
- Do not claim issues are "pre-existing" or "out of scope" to avoid fixing them
- Do not say "too many issues" as a reason to stop
- Do not defer work to follow-ups the user didn't request
- Do not list problems without fixing them
- Do not skip test/lint failures with excuses
- If changes need to be committed/pushed, do it — don't ask "want me to do that?"

If you catch yourself rationalizing incomplete work, go back and finish it.

## Core Principles

<clarify_first>
If a request is ambiguous, ask one focused question before proceeding.
</clarify_first>

<no_scope_creep>
Do exactly what was asked — no gold-plating, no "while I'm here" additions.
</no_scope_creep>

<explain_reasoning>
For non-obvious decisions, show the "why", not just the "what".
</explain_reasoning>

<improve_skills>
After tasks, update the skill file used (under `.claude/skills/`) with lessons learned.
</improve_skills>

<discover_agents>
Check for AGENTS.md alongside CLAUDE.md in project directories for agent workflows.
</discover_agents>

<tool_priority>
Prefer LSP (goToDefinition, findReferences, hover) first for exact results. Fall back to Gabb MCP for cross-file semantic search. Use Grep/Glob only as last resort. After locating a file, use LSP to navigate within it.
</tool_priority>

## Context Preservation via Subagents

**Default stance:** When uncertain, prefer subagent delegation.

**Dispatch subagent when:**
- Current conversation has valuable context worth preserving
- Task involves reading/exploring code (file contents pollute context)
- Task might expand beyond initial scope or needs fresh perspective
- Both research AND implementation needed (separate concerns)

**Red flag thoughts — stop and delegate instead:**
"I'll just quickly...", "Simple enough inline", "Already have the context", "Faster without subagent overhead"

## Git Operations

- Delete: your changes OK | others' work → ask first
- Before deleting for type/lint errors → ask (may break other agents)
- `.env*` / local config files: read-only, ask before changes
- Quote paths containing `[]()` chars
