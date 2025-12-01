---
name: systematic-research
description: Use when conducting comprehensive research - applies scientific methodology with adaptive strategies, multi-hop reasoning, and evidence-based synthesis
argument-hint: "[none - provides methodology guidance for user-driven research queries]"
allowed-tools:
  - WebSearch
  - WebFetch
  - mcp__tavily__*
  - mcp__perplexity__*
  - mcp__playwright__*
  - mcp__context7__*
  - Read
  - Grep
---

# Systematic Research

## When to Use This Skill

Use when:
- User explicitly requests research or investigation (`/ct:research` command)
- Encountering questions that require exploring multiple sources
- Needing to synthesize information from diverse sources
- Current events or real-time information requests
- Academic or technical research contexts
- Complex information needs that go beyond your knowledge cutoff
- Multiple competing claims need verification and synthesis

**Examples:**
- "Research the latest developments in quantum computing"
- "Investigate what caused the recent market volatility"
- "Find out how other companies have solved this architectural problem"
- "What are the current best practices for X?"

## When NOT to Use This Skill

Don't use when:
- Simple factual questions within your knowledge base
- User explicitly wants just your existing knowledge
- Code implementation tasks (use other skills like TDD, debugging)
- The question can be answered by reading local codebase files
- Pure brainstorming or ideation (use brainstorming skill)

## Core Approach

Think like a research scientist crossed with an investigative journalist:

- **Apply systematic methodology**, not random searching
- **Follow evidence chains**, don't cherry-pick convenient results
- **Question sources critically**, check for bias and credibility
- **Synthesize findings coherently**, resolve contradictions
- **Adapt your approach** based on what you discover

**Research is iterative, not linear.** Be prepared to replan based on findings.

## The Four-Phase Research Process

### Phase 1: Discovery
- Formulate query (choose planning strategy: Planning-Only, Intent-Planning, or Unified)
- Execute broad searches in parallel (use Tavily)
- Assess sources (credibility, bias, recency)
- Self-reflect: confidence level, need to adjust?

### Phase 2: Investigation
- Apply multi-hop reasoning (entity expansion, temporal progression, conceptual deepening, causal chains)
- Route extractions (HTML→Tavily, JS→Playwright, docs→Context7, local→native)
- Collect evidence with citations
- Self-reflect: answering core question? Gaps? Confidence? Replan if needed.

### Phase 3: Synthesis
- Connect information across sources
- Identify patterns, contradictions, gaps
- Distinguish facts from interpretation
- Self-reflect: synthesis coherent? Evidence sufficient?

### Phase 4: Reporting
- Present findings with confidence levels
- Cite all sources
- Acknowledge limitations
- Provide actionable insights

## Tool Orchestration Guidelines

### Search Strategy

1. **Start broad**: Use Tavily for initial landscape mapping
2. **Identify patterns**: Look for recurring authoritative sources
3. **Go deep**: Extract detailed information from promising sources
4. **Follow leads**: Investigate interesting connections discovered

### Parallel Optimization

**NEVER search sequentially when you can search in parallel**

✅ **Good**: Search multiple queries concurrently
```
Search for: "quantum computing 2025", "quantum supremacy recent", "quantum algorithms practical"
All at once in parallel
```

❌ **Bad**: Search → wait → search → wait → search
```
Search "quantum computing" → wait for results → read → search "quantum algorithms" → wait...
```

### Extraction Routing

- **Static HTML** → Tavily extraction
- **JavaScript-heavy sites** → Playwright
- **Technical documentation** → Context7
- **Local files/codebase** → Native tools (Read, Grep, etc.)

### Learning Integration

- Track successful query formulations
- Note effective extraction methods
- Identify reliable source types
- Apply patterns from similar past research
- Use memory tools to store valuable findings

## Quality Standards

**Information:** Cross-reference claims | Prefer primary sources | Note publication dates | Assess credibility | Detect bias

**Synthesis:** Distinguish facts from interpretation | Mark speculation explicitly | Acknowledge contradictions | Assign confidence levels | Show reasoning chains

## Anti-Patterns to Avoid

| Anti-Pattern | Correct Approach |
|--------------|------------------|
| **Cherry-pick** | Don't stop at first source → Seek contradicting views |
| **Sequential-crawl** | Don't search one-by-one → Batch queries in parallel |
| **Speculation-pass** | Don't say "probably" → Cite sources or state uncertainty |
| **Citation-skip** | Don't claim without sources → Every fact needs attribution |
| **Confidence-fake** | Don't present uncertainty as fact → State confidence levels |
| **Replan-resist** | Don't push through dead ends → Reassess when stuck |

## Example Research Flow

**Query:** "What caused the AWS US-EAST-1 outage on December 7, 2021?"

**Phase 1: Discovery**
- Parallel searches: "AWS outage December 2021", "US-EAST-1 December 7 2021", "AWS post-mortem December 2021"
- Identified key sources: AWS status page, AWS post-mortem blog, tech news coverage
- Initial confidence: Medium (event is well-documented)

**Phase 2: Investigation**
- Entity expansion: AWS → US-EAST-1 → Affected services → Customer impact
- Temporal progression: Outage timeline → Immediate response → Root cause → Resolution
- Extracted from: AWS official post-mortem, Ars Technica analysis, Hacker News discussion
- Evidence: Root cause was internal network congestion during scaling event

**Phase 3: Synthesis**
- Integrated timeline from multiple sources
- Identified contradiction: Initial reports blamed "network device issues" vs actual "automated capacity scaling issue"
- Resolved via AWS official post-mortem (authoritative source)
- Insight: Shows importance of controlled capacity scaling

**Phase 4: Reporting**
- Executive summary: Automated network scaling triggered congestion
- Key findings with citations from AWS blog, tech coverage
- Confidence: 90% (official post-mortem + corroborating coverage)
- Limitations: Some customer impact details not publicly available

## Success Criteria

You've done systematic research well when:

- ✅ Original question is answered (or clearly stated why it can't be)
- ✅ Multiple authoritative sources consulted
- ✅ Contradictions acknowledged and addressed
- ✅ Confidence levels explicitly stated
- ✅ All factual claims have citations
- ✅ Limitations and gaps clearly identified
- ✅ Methodology is transparent and reproducible
- ✅ Reader can assess credibility of findings
- ✅ Evidence chains are traceable
- ✅ Balanced representation of viewpoints

## Performance Tips

- **Cache results**: Reuse successful searches for related queries
- **Batch operations**: Run parallel searches whenever possible
- **Prioritize sources**: Focus on high-value authoritative sources first
- **Balance depth**: Don't over-investigate tangential points
- **Use memory**: Store valuable patterns and findings for future research
