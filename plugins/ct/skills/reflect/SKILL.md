---
name: reflect
description: >
  Self-reflection and memory lifecycle management. Generates structured reflections,
  reviews and applies them to CLAUDE.md, consolidates CLAUDE.md health, and maintains
  engram memory hygiene. Use when the user runs /reflect, /reflect review, or
  /reflect consolidate. Also triggers on "let's reflect", "what did we learn",
  "session learnings", "write a reflection", "consolidate", "prune CLAUDE.md".
user-invocable: true
tools: Read, Edit, Write, Glob, Bash, AskUserQuestion
---

# Reflect

Structured self-reflection that compounds learning into project-specific instructions and maintains memory health across CLAUDE.md and engram.

## Mode Detection

- No arguments or `/reflect` → **Generate mode**
- `/reflect review` → **Review mode**
- `/reflect consolidate` → **Consolidate mode**

---

## Generate Mode

Reflect on the current conversation and produce a structured entry.

### Step 1: Gather Context

Review the conversation for:
- Tool calls that failed or required multiple attempts
- Decisions made and their reasoning
- Errors encountered and how they were resolved
- Patterns that emerged during the work
- Assumptions that turned out to be wrong
- Bash commands discovered or environment quirks encountered
- Code style patterns or testing approaches that worked

### Step 2: Write the Reflection Entry

Determine the current branch and date:

```bash
git branch --show-current 2>/dev/null || echo "unknown"
date +%Y-%m-%d
```

Produce a reflection with **exactly four categories**. Each category has 1-3 items max. Every item must be specific and actionable — no generic platitudes like "always test your code" or "read documentation carefully."

**Bad example:** "Testing is important"
**Good example:** "The `stripe.webhooks.constructEvent` function throws if the raw body is parsed as JSON first — always pass the raw Buffer"

Format each item as: `- [PENDING] <specific, actionable observation>`

Append to `.claude/REFLECTION.md` using this format:

```
## YYYY-MM-DD — branch: <branch> — <one-line summary of work>

### Surprises
- [PENDING] <item>

### Patterns
- [PENDING] <item>

### Prompt improvements
- [PENDING] <item>

### Mistakes
- [PENDING] <item>
```

If the file doesn't exist yet, create it with a `# Reflections` header first.

If a category has nothing worth noting, write `- [SKIPPED] Nothing notable this session` — do not omit the category.

### Step 3: Add @REFLECTION.md to CLAUDE.md

Check if the project has `.claude/CLAUDE.md`:

```bash
test -f .claude/CLAUDE.md && echo "exists" || echo "missing"
```

If it exists, check if `@REFLECTION.md` is already referenced. If not, add it:

```
@REFLECTION.md
```

If `.claude/CLAUDE.md` does not exist, inform the user:
> "Note: No `.claude/CLAUDE.md` found in this project. When you create one, add `@REFLECTION.md` to it so reflections are loaded as context."

### Step 4: Confirm

Show the user the reflection entry that was written. Done.

---

## Review Mode

Walk through pending reflections, apply approved ones to CLAUDE.md, then review engram memories.

### Step 1: Find Pending Entries

Read `.claude/REFLECTION.md` and find all lines matching `- [PENDING]` (case-insensitive).

If none found, report "No pending reflections to review." but **still proceed to Step 4** (engram review).

### Step 2: Present Each Entry

For each `[PENDING]` entry, present it to the user with these options:
- **Approve** — will be rewritten as a directive and added to CLAUDE.md
- **Reject** — will be marked [REJECTED] and skipped
- **Edit** — user provides revised text, then approve. Edited entries follow the same approve flow — the edited text replaces the original in REFLECTION.md before tagging `[APPROVED]`.

Present ONE entry at a time. Wait for the user's response before proceeding to the next.

### Step 3: Apply Approved Entries

For each approved entry:

1. Change `[PENDING]` to `[APPROVED]` in `.claude/REFLECTION.md`
2. Rewrite the entry into directive form — a concise instruction, not a reflection. Examples:
   - Reflection: "The OAuth library silently swallows 403 errors instead of throwing"
   - Directive: "Always wrap OAuth library callbacks in try/catch — it silently swallows 403 errors"
3. Append the directive to `.claude/CLAUDE.md` under a `## Learnings` section. Create the section if it doesn't exist.

For each rejected entry:

1. Change `[PENDING]` to `[REJECTED]` in `.claude/REFLECTION.md`

Report: "Reflection review complete: N approved, N rejected, N remaining."

<HARD-GATE>

### Step 4: Engram Memory Review

This step is MANDATORY. It runs every time review mode is invoked, even if there were no pending reflections. Do not skip this step.

> "Before we finish, let's review your engram memories for this project. This keeps your cross-session memory accurate."

**4a.** Call `mem_search` with a broad query (e.g., the project name or "*") for this project, limit 20.

If `mem_search` fails (engram unavailable), report: "Engram is not reachable — skipping memory review." and end.

If no results, report: "No engram observations found for this project." and end.

**4b.** Filter out any observations whose title starts with `[STALE]` — these were already marked in a previous review.

**4c.** Present each non-stale observation to the user, showing title, type, and a content preview. For each, offer three options:
- **Keep** — no change
- **Update** — user provides revised text, apply via `mem_update` using the observation's ID
- **Mark Stale** — call `mem_update` with the observation's ID, prepending `[STALE] ` to the title

**4d.** After reviewing individual observations, look for duplicates or overlapping observations. If found, propose merging: `mem_update` one observation to contain the consolidated content, mark the others stale.

**4e.** Report summary: "Engram review: N kept, N updated, N marked stale, N merged."

</HARD-GATE>

---

## Consolidate Mode

Periodic CLAUDE.md health maintenance. Use when CLAUDE.md feels bloated or monthly as hygiene.

### Step 1: Audit CLAUDE.md

1. Read `.claude/CLAUDE.md` (or project root `CLAUDE.md` — check both, prefer `.claude/` if both exist)
2. Count total directive lines (excluding headers, blank lines, comments, and `@` imports)
3. Flag issues in four categories:
   - **Duplicates** — entries that say the same thing differently
   - **Contradictions** — entries that conflict with each other (newer entry wins)
   - **Discoverable** — entries that restate what's obvious from the codebase (e.g., "this project uses TypeScript" when `tsconfig.json` exists). Check the codebase before flagging.
   - **Verbose** — multi-line entries or paragraphs that could be extracted into a reference file
4. Report health assessment:
   - Under 30 directives: "Healthy — no action needed unless you see specific issues"
   - 30-50 directives: "Getting dense — review recommended"
   - Over 50 directives: "Bloated — pruning strongly recommended"

### Step 2: Propose Changes

Present all proposed changes grouped by type:
- **Merge:** "Lines X and Y both say [summary] — combine into: [merged directive]"
- **Remove:** "Line X restates [discoverable fact] / contradicts newer line Y — remove"
- **Extract:** "Lines X-Y are a verbose [topic] section — extract to `.claude/references/[topic].md` and replace with `@references/[topic].md`"

Present as a batch. Ask the user to approve, reject, or edit each proposed change. Then apply all approved changes.

### Step 3: Apply Changes

Apply all approved changes to CLAUDE.md. For extractions:
1. Create the reference file at the proposed path
2. Write the extracted content into it
3. Replace the verbose section in CLAUDE.md with the `@path` import

<HARD-GATE>

### Step 4: Engram Consolidation

This step is MANDATORY — the same hard gate as Review Mode Step 4 applies. Do not skip.

Run the same engram review as Review Mode Step 4: call `mem_search` broadly, filter `[STALE]` observations, present each to user (Keep/Update/Mark Stale), propose merging duplicates, report summary.

</HARD-GATE>
