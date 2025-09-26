# Perplexity MCP Server

**Purpose**: Real-time web search via Perplexity's Sonar API for current information and research

## Triggers
- Real-time information needs: "latest", "current", "today", "this week"
- Web search requirements with citations
- Research tasks requiring multiple perspectives
- Fact-checking and verification needs
- Current events and breaking news
- Market trends and competitive intelligence
- When Tavily is unavailable or for alternative search perspective

## Choose When
- **Over Tavily**: When you need Perplexity's specific ranking and citation format
- **Over WebSearch**: When you need structured results with source citations
- **Over WebFetch**: When you need multi-source search, not single page content
- **For real-time**: Breaking news, current events, today's information
- **For research**: Academic sources, verified information with citations
- **Not for**: Code generation, local file operations, historical facts in training data

## Works Best With
- **Tavily**: Use both for comprehensive research coverage
- **Sequential**: Perplexity searches → Sequential analyzes and synthesizes
- **Memory**: Perplexity finds information → Memory stores key insights
- **Deepwiki**: Perplexity for web search → Deepwiki for repository docs

## Configuration
- **API Key Required**: PERPLEXITY_API_KEY environment variable from https://www.perplexity.ai/

## Examples
```
"latest AI announcements today" → Perplexity (real-time news)
"current stock market trends" → Perplexity (financial data)
"recent research on quantum computing" → Perplexity (academic search)
"fact-check this claim about climate change" → Perplexity (verification)
"explain how recursion works" → Native Claude (general knowledge)
"search GitHub for authentication libraries" → Tavily or Deepwiki
```

## Search Patterns

### Real-time Information
```
Query: "latest developments in [topic]"
→ perplexity_ask(query)
→ Returns: Recent results with timestamps and sources
```

### Fact Verification
```
Claim: "Statement to verify"
→ perplexity_ask("fact-check: [claim]")
→ Returns: Multiple sources confirming or refuting
```

### Research Query
```
Topic: "Complex research topic"
→ perplexity_ask(topic, model="research")
→ Returns: Comprehensive analysis with citations
```

## Message Format
```javascript
{
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful research assistant"
    },
    {
      "role": "user",
      "content": "Search query here"
    }
  ]
}
```
