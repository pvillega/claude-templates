---
name: reflect
description: >
  CLAUDE.md + engram memory lifecycle management. Generates structured reflections,
  reviews and applies them to CLAUDE.md, consolidates CLAUDE.md health, and maintains
  engram memory hygiene.
  Triggers ONLY on: /reflect, /reflect review, /reflect consolidate, or explicit
  requests like "prune CLAUDE.md", "review my engram memories", "consolidate CLAUDE.md",
  "audit CLAUDE.md health", "write a session reflection for REFLECTION.md".
  DO NOT trigger on casual uses of "reflect on X", "let's reflect", or "what did we learn"
  outside the context of CLAUDE.md / REFLECTION.md / engram memory hygiene.
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

Produce a reflection with **exactly four categories**. Each category has 1-3 items max.

→ Before finalizing each item → Is this specific enough that a teammate could act on it without asking what I mean? Does it reference a concrete tool, error, function, or behavior?
  Yes → Keep it.
  No (e.g., "Testing is important", "Always test your code") → Reject and rewrite with concrete detail.

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

→ Presenting entries → Have I received the user's response to the previous entry?
  No → Wait for input. Do NOT batch multiple entries in one message.
  Yes → Present the next entry.

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

**4a.** → Before continuing engram review → Execute `mem_search` with a broad query (e.g., the project name or "*") for this project, limit 20. Did the call actually execute?
  No → STOP. You must call it, not assume results.

This `mem_search` call is the ENTIRE POINT of review mode. It runs even when no pending reflections exist, because stale engram observations accumulate independently of reflections. The mandate is load-bearing; do not skip for 'nothing to do' heuristics.

If `mem_search` fails (engram unavailable), report: "Engram is not reachable — skipping memory review." and end.

If no results, report: "No engram observations found for this project." and end.

**4b.** Filter out any observations whose title starts with `[STALE]` — these were already marked in a previous review.

**4c.** → Presenting observations → Have I received the user's response to the previous observation?
  No → Wait for input. Do NOT batch multiple observations in one message.
  Yes → Present the next observation.

If the search returns >20 observations, present the top 20 by last-updated timestamp and ask the user whether to continue through the remainder. Do not process >20 in one session without explicit confirmation.

For each non-stale observation, show title, type, and a content preview. Offer three options:
- **Keep** — no change
- **Update** — user provides revised text, apply via `mem_update` using the observation's ID
- **Mark Stale** — call `mem_update` with the observation's ID, prepending `[STALE] ` to the title

**4d.** → All observations reviewed → Scan titles and content for 2+ observations covering similar ground.
  Found duplicates → Propose merging: `mem_update` one to contain consolidated content, mark others stale.
  No duplicates → Report: "No duplicate observations found."
  Do NOT skip this scan by claiming "none obvious" — compare each pair.

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
   - **Discoverable** → Before flagging an entry as Discoverable: check if the fact is stated in codebase files (tsconfig.json, package.json, README, etc.) → Is it actually present in the codebase?
     Yes → Flag as Discoverable.
     No → Keep the entry.
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
