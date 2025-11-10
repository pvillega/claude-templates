---
name: research
description: "Conduct systematic research with adaptive strategies and evidence-based synthesis"
category: analysis
complexity: enhanced
mcp-servers: [tavily, playwright, context7]
personas: []
---

# /sc:research - Systematic Research and Investigation

## Triggers
- Explicit research or investigation requests
- Complex information synthesis needs requiring multiple sources
- Current events or real-time information requests
- Academic or technical research contexts
- Questions beyond AI knowledge cutoff requiring verification
- Multiple competing claims needing verification and synthesis

## Usage
```
/sc:research [query] [--depth quick|standard|comprehensive] [--format summary|detailed|academic]
```

## Behavioral Flow

I'm using the **systematic-research** skill to investigate your question.

This command applies a rigorous 4-phase research methodology:

1. **Discovery**: Map the information landscape with parallel searches
2. **Investigation**: Deep dive using multi-hop reasoning and evidence collection
3. **Synthesis**: Build coherent understanding from diverse sources
4. **Reporting**: Present findings with citations and confidence levels

## Key Behaviors

- **Scientific Methodology**: Systematic approach with self-reflection checkpoints
- **Adaptive Planning**: Strategy adjusts based on query complexity and findings
- **Multi-Hop Reasoning**: Follow entity, temporal, conceptual, and causal chains
- **Parallel Optimization**: Never search sequentially when concurrent is possible
- **Evidence-Based**: All claims supported by citations with credibility assessment
- **Critical Analysis**: Question sources, detect bias, resolve contradictions
- **Transparent Confidence**: Explicit confidence levels and limitation acknowledgment

## MCP Integration

- **Tavily**: Broad landscape mapping and initial source discovery
- **Playwright**: JavaScript-heavy site extraction and dynamic content
- **Context7**: Technical documentation and library-specific research

## Tool Coordination

- **WebSearch/Tavily**: Primary research tool for landscape mapping
- **WebFetch**: Source extraction and detailed content retrieval
- **Playwright**: Browser automation for complex site navigation
- **Context7**: Technical documentation retrieval
- **Read/Grep**: Local codebase and file analysis when applicable

## Key Patterns

- **Adaptive Strategy Selection**: Query complexity → appropriate planning approach
- **Multi-Source Verification**: Cross-reference claims → credibility assessment
- **Evidence Chain Building**: Individual findings → coherent synthesis
- **Quality Gate Enforcement**: Self-reflection checkpoints → replanning triggers

## Anti-Patterns to Avoid

❌ **Cherry-Picking**: Finding one supporting source and stopping
✅ **Comprehensive View**: Searching for contradicting views and weighing evidence

❌ **Sequential Crawling**: One search → wait → next search
✅ **Parallel Execution**: Batch related queries concurrently

❌ **Speculation**: "This probably means..." without evidence
✅ **Evidence-Based**: "Based on [Source], this suggests... However, [limitation]"

❌ **Citation Skipping**: Factual claims without attribution
✅ **Full Attribution**: Every fact cited or marked unverified

❌ **Confidence Faking**: Presenting uncertainty as certainty
✅ **Honest Assessment**: "Based on available evidence (confidence: 70%)..."

## Examples

### Current Events Research
```
/sc:research "What are the latest developments in AI regulation?"
# Executes comprehensive current events research
# Synthesizes multiple news sources with credibility assessment
```

### Technical Investigation
```
/sc:research "How do companies handle distributed tracing at scale?" --depth comprehensive
# Deep technical research with architecture patterns
# Includes case studies and implementation examples
```

### Academic Research
```
/sc:research "Recent breakthroughs in quantum error correction" --format academic
# Structured academic research with peer-reviewed sources
# Formal citations and methodology transparency
```

### Quick Fact-Finding
```
/sc:research "When was the last AWS outage?" --depth quick
# Rapid research for straightforward questions
# Concise summary with key sources
```

## Report Structure

All research reports include:

1. **Executive Summary**: Brief answer with key findings
2. **Methodology**: Research approach and tools used
3. **Key Findings**: Main discoveries with inline citations
4. **Analysis & Synthesis**: How findings relate and what they mean
5. **Confidence Assessment**: Overall confidence with reasoning
6. **Limitations & Gaps**: What remains unknown or uncertain
7. **Sources**: Complete source list with access dates

## Success Criteria

Research is complete when:
- ✅ Original question answered (or clearly stated why not)
- ✅ Multiple authoritative sources consulted
- ✅ Contradictions acknowledged and addressed
- ✅ Confidence levels explicitly stated
- ✅ All factual claims have citations
- ✅ Limitations and gaps identified
- ✅ Methodology is transparent and reproducible
- ✅ Reader can assess credibility independently

## Boundaries

**Will:**
- Conduct comprehensive research using multiple authoritative sources
- Apply systematic methodology with evidence-based reasoning
- Provide transparent confidence assessments and source attribution
- Identify and resolve contradictions through critical analysis
- Adapt strategy based on findings and information availability

**Will Not:**
- Bypass paywalls or access restricted content
- Access private or confidential data
- Make speculative claims without evidence and disclosure
- Present biased views as objective research
- Provide medical, legal, or financial advice requiring professional credentials
