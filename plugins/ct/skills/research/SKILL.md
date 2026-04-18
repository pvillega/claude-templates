---
name: research
description: >
  Use ONLY when the user explicitly requests multi-source research synthesis with citations
  — e.g., "/ct:research X", "research X in depth with citations", "investigate Y across
  authoritative sources", "compare approaches and cite sources". Applies systematic methodology
  with multi-hop reasoning and evidence-based synthesis.
  DO NOT trigger for: simple factual questions, single-source lookups, casual "research this"
  one-liners, codebase exploration, or informal fact-finding. For those, use WebSearch /
  tavily-cli / WebFetch directly.
tools: WebSearch, WebFetch, Agent, Skill, Read, Grep
---

# Systematic Research

## When to Use This Skill

Use when:
- User explicitly requests research or investigation (`/ct:research` command)
- Questions that require exploring multiple sources
- Synthesising information from diverse sources
- Current events or real-time information beyond your knowledge cutoff
- Multiple competing claims need verification and synthesis

## When NOT to Use This Skill

- Simple factual questions within your knowledge base
- User explicitly wants just your existing knowledge
- Code implementation tasks (use TDD, debugging skills)
- Questions answerable by reading local codebase files
- Pure brainstorming or ideation (use brainstorming skill)

## Boundaries (DO NOT)

- **Do NOT write implementation code or code examples** — this skill gathers external knowledge; hand off to implementation skills/agents.
- **Do NOT make architectural or technology decisions for the user** — present findings neutrally; defer the choice.
- **Do NOT skip workflow steps or citation requirements** — all four phases are mandatory regardless of query simplicity.
- **Do NOT provide "best guess" recommendations when authoritative sources are unavailable** — move the gap to Open Questions instead.
- **Do NOT use general-knowledge statements as findings** — every factual claim must cite an authoritative source or be moved to Open Questions.

## Hard Caps

- **Maximum sources per topic: 25** — stop collecting beyond this unless the user explicitly extends.
- **Maximum depth levels: 2** — do not recursively follow citation trails beyond 2 levels.
- **Maximum report length: 8000 words** — state this at the top of the report. If research exceeds this, split into sections and deliver in parts.

## The Four-Phase Research Process

HARD GATE - Research Phase Completion:
→ For each phase (Discovery → Investigation → Synthesis → Reporting):
  Check: Have I completed this phase's deliverable?
  No → Complete it before moving to next phase. Skipping is not permitted.

### Phase 1: Discovery

- Restate the question in one sentence; list unknowns; flag blocking assumptions.
- Choose depth: `quick` (1 authoritative source), `standard` (2-3 sources cross-referenced), `deep` (multi-hop with contradictions resolved), `exhaustive` (survey with per-claim confidence).
- Formulate queries.
- Execute broad searches in parallel (via `tavily-cli` skill and/or WebSearch).
- Assess sources: credibility, bias, recency.

Trigger check: If the first batch of searches returns 0 results from authoritative sources (primary/official docs, peer-reviewed, reputable news), reformulate queries with different terms before proceeding to Phase 2.

### Phase 2: Investigation

- Apply multi-hop reasoning: entity expansion, temporal progression, conceptual deepening, causal chains.
- Route extractions:
  - Static HTML → WebFetch, or via the `tavily-cli` skill (invoked through the Skill tool).
  - JavaScript-heavy sites → via the `agent-browser` skill (invoked through the Skill tool).
  - Library/framework docs → via the `context7-cli` skill (invoked through the Skill tool).
  - Local files/codebase → Read, Grep.
- Collect evidence with citations (URL + title + access date).

Trigger check: If any source contradicts another source, state the contradiction in the report and prefer the more authoritative (primary source > secondary > tertiary). Do not silently pick one.

### Phase 3: Synthesis

- Connect information across sources.
- Identify patterns, contradictions, gaps.
- Distinguish facts from interpretation.

HARD GATE - Citation-or-gap rule:
→ About to include a factual claim in the synthesis → Is this from an authoritative source I can cite?
  Yes → Include with citation.
  No → Am I tempted to say "probably" / "likely" / "typically"? → STOP. Move to Open Questions section instead. Explicitly state the gap rather than filling with general knowledge.

Trigger check: If you have <2 sources for a claim flagged as "key finding", downgrade it to a single-source observation in the report, or move it to Open Questions.

### Phase 4: Reporting

- Present findings with confidence levels.
- Cite every factual claim.
- Acknowledge limitations.

**Report template:**

```
Report cap: 8000 words. If research exceeds this, split into sections and deliver in parts.

## Goal
<one-line restatement of the question>

## Findings
- <bullet with inline citation [1]>
- <bullet with inline citation [2]>

## Sources
| # | URL | Title | Credibility | Note |
|---|-----|-------|-------------|------|

## Open questions / suggested follow-up
- <explicit gap or uncertainty>
```

## Parallel Agent Fan-Out

→ Research task with multiple search threads → Can these run independently (no dependency between results)?
  Yes → Dispatch Agent subagents in ONE message, one per independent facet, maximum 10 subagents per batch. If >10 facets, batch sequentially in groups of 10 (wait for each batch before dispatching the next).
  No (true dependency) → Run sequentially.

Each subagent investigates one facet of the question, then you synthesize their findings.

## Tool Orchestration

- **WebSearch / WebFetch** — primary for web search and static-page extraction.
- **`tavily-cli` skill** (invoked through the Skill tool) — richer web search, extract, crawl, deep research.
- **`context7-cli` skill** (invoked through the Skill tool) — library/framework documentation.
- **`agent-browser` skill** (invoked through the Skill tool) — JavaScript-heavy sites.
- **Agent** — parallel research threads for independent questions.
- **Read, Grep** — local files/codebase.

## Quality Standards

**Information:** cross-reference claims across >=2 sources; prefer primary sources (official docs, post-mortems, peer-reviewed) over secondary (news coverage) over tertiary (blog summaries); note publication dates; flag bias explicitly.

**Synthesis:** distinguish facts from interpretation; mark speculation with the word "speculation"; acknowledge contradictions by name; assign confidence levels (high / medium / low) per claim; show reasoning chains.

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|--------------|------------------|
| Cherry-pick | Don't stop at first source — seek contradicting views |
| Sequential-crawl | Don't search one-by-one — batch queries in parallel (fan-out block above) |
| Speculation-pass | Don't say "probably" — cite sources or move to Open Questions |
| Citation-skip | Don't claim without sources — every fact needs attribution |
| Confidence-fake | Don't present uncertainty as fact — state confidence levels |
| Replan-resist | Don't push through dead ends — reformulate queries when 0 authoritative results |
