---
name: systematic-research
description: Use when conducting comprehensive research - applies scientific methodology with adaptive strategies, multi-hop reasoning, and evidence-based synthesis
category: analysis
---

# Systematic Research

## When to Use This Skill

Use when:
- User explicitly requests research or investigation (`/sc:research` command)
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

### Phase 1: Discovery (Map the Landscape)

**Objective:** Understand the information landscape before diving deep.

**Steps:**

1. **Initial Query Formulation**
   - Analyze the research question for scope and clarity
   - Choose adaptive planning strategy:
     - **Planning-Only**: Simple/clear queries → Direct execution
     - **Intent-Planning**: Ambiguous queries → Clarify scope first
     - **Unified Planning**: Complex queries → Present investigation plan for approval

2. **Landscape Mapping**
   - Execute broad initial searches (use Tavily)
   - Run searches **in parallel** when possible
   - Identify recurring themes, patterns, and authoritative sources
   - Map knowledge boundaries and information availability

3. **Source Assessment**
   - Evaluate source credibility and authority
   - Check for potential bias or conflicts of interest
   - Assess information recency and relevance
   - Identify knowledge gaps

4. **Self-Reflection Checkpoint**
   - Do I understand what I'm looking for?
   - Have I identified the key areas to investigate?
   - What's my initial confidence level? (track: low/medium/high)
   - Do I need to adjust my approach?

### Phase 2: Investigation (Deep Dive)

**Objective:** Extract detailed information and build evidence chains.

**Steps:**

1. **Multi-Hop Reasoning**
   Apply appropriate reasoning pattern:

   - **Entity Expansion**: Person → Affiliations → Related work
   - **Temporal Progression**: Current state → Recent changes → Historical context
   - **Conceptual Deepening**: Overview → Details → Examples → Edge cases
   - **Causal Chains**: Observation → Immediate cause → Root cause

   Maximum hop depth: 5 levels. Track hop genealogy for coherence.

2. **Deep Extraction**
   Route extractions based on content type:
   - Static HTML → Tavily extraction
   - JavaScript-heavy sites → Playwright
   - Technical documentation → Context7
   - Local files/codebase → Native tools

3. **Evidence Collection**
   - Extract relevant information with citations
   - Note source URLs and access dates
   - Track evidence quality and reliability
   - Identify contradictions or inconsistencies

4. **Self-Reflection Checkpoint**
   - Am I answering the core question?
   - What gaps remain in my understanding?
   - Is my confidence improving? (update: low/medium/high)
   - Should I adjust my investigation strategy?

   **Replanning Triggers:**
   - Confidence below 60%
   - Contradictory information >30%
   - Dead ends encountered
   - Time/resource constraints

### Phase 3: Synthesis (Build Understanding)

**Objective:** Integrate findings into a coherent understanding.

**Steps:**

1. **Information Integration**
   - Build coherent narrative from evidence
   - Create logical connections between findings
   - Resolve contradictions with evidence-based reasoning
   - Identify patterns and themes

2. **Gap Analysis**
   - Clearly identify what remains unknown
   - Distinguish verified facts from interpretations
   - Note limitations in available information
   - Identify areas requiring more investigation

3. **Insight Generation**
   - Draw evidence-based conclusions
   - Generate actionable recommendations
   - Assign confidence levels to claims
   - Trace reasoning chains for transparency

4. **Self-Reflection Checkpoint**
   - Have I addressed the original question?
   - Are my conclusions supported by evidence?
   - Have I acknowledged contradictions and limitations?
   - Is my synthesis balanced and objective?

### Phase 4: Reporting (Communicate Findings)

**Objective:** Present research results clearly and credibly.

**Required Report Structure:**

1. **Executive Summary**
   - Brief answer to the research question
   - Key findings (3-5 bullet points)
   - Overall confidence assessment

2. **Methodology**
   - Research approach taken
   - Tools and sources used
   - Any limitations or constraints

3. **Key Findings** (with citations)
   - Main discoveries organized logically
   - Each claim supported by source citation
   - Include access dates for web sources

4. **Analysis & Synthesis**
   - How findings relate to each other
   - Patterns, trends, or insights
   - Resolution of contradictions
   - Evidence chains for major conclusions

5. **Confidence Assessment**
   - Overall confidence level (e.g., 75%)
   - What increases confidence
   - What decreases confidence

6. **Limitations & Gaps**
   - What remains unknown or uncertain
   - Areas requiring further research
   - Potential biases or constraints

7. **Sources**
   - Complete list of sources consulted
   - URLs with access dates
   - Source credibility notes if relevant

**Citation Requirements:**
- Use inline citations: [Source Name, Date]
- Include access dates for web content
- Distinguish between primary and secondary sources
- Note when claims couldn't be verified

**Quality Checks:**
- Have I presented multiple viewpoints?
- Are contradictions acknowledged?
- Is speculation clearly marked?
- Can readers assess credibility themselves?

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

### Information Quality

**Verification:**
- Cross-reference key claims across multiple sources
- Prefer primary sources over secondary when available
- Note when claims cannot be verified

**Recency:**
- Prioritize recent information for current topics
- Note publication/update dates
- Track temporal context

**Credibility:**
- Assess source authority and expertise
- Check for conflicts of interest
- Prefer peer-reviewed or authoritative sources

**Bias Detection:**
- Look for multiple perspectives
- Identify potential conflicts of interest
- Note when coverage is one-sided
- Balance representation of viewpoints

### Synthesis Requirements

**Fact vs Interpretation:**
- Clearly distinguish verified facts from analysis
- Mark speculation explicitly: "This suggests..." not "This proves..."
- Separate observation from inference

**Contradictions:**
- Acknowledge conflicting information
- Present evidence for competing views
- Explain how you resolved contradictions (if possible)
- Note when contradictions remain unresolved

**Confidence:**
- Assign explicit confidence levels (e.g., 60%, 85%)
- Explain what increases/decreases confidence
- Update confidence as evidence accumulates

**Reasoning Chains:**
- Show how you reached conclusions
- Make logical connections explicit
- Allow readers to verify reasoning
- Trace from evidence to conclusion

## Anti-Patterns

### Don't Cherry-Pick

❌ Finding one source that supports your hypothesis and stopping
✅ Searching for contradicting views and weighing the evidence

**Why it fails:** Confirmation bias leads to incomplete understanding

### Don't Sequential-Crawl

❌ Searching one query, reading result, then next query
✅ Batch related queries and run them in parallel

**Why it fails:** Wastes time and prevents holistic view of landscape

### Don't Speculation-Pass

❌ "This probably means..." without evidence
✅ "Based on [Source], this suggests... However, [limitation]"

**Why it fails:** Undermines credibility and misleads readers

### Don't Citation-Skip

❌ Making factual claims without source attribution
✅ Every fact gets a citation or "I could not verify this claim"

**Why it fails:** Readers can't assess credibility or verify claims

### Don't Confidence-Fake

❌ Presenting uncertain findings as definitive
✅ "Based on available evidence (confidence: 70%), ..."

**Why it fails:** Misleads readers about reliability of information

### Don't Replan-Resist

❌ Pushing forward when hitting dead ends or contradictions
✅ Reassessing approach when confidence drops or gaps emerge

**Why it fails:** Wastes effort on unproductive paths

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
