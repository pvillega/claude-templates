# Deepwiki MCP Server

**Purpose**: Repository documentation access and AI-powered search for GitHub projects

## Triggers
- Repository documentation exploration needs
- GitHub project structure understanding
- Technical documentation search within repos
- Framework or library implementation questions
- Need for context-grounded answers about codebases
- Requests for repository overview or architecture
- `/deepwiki` or `deepwiki fetch` commands

## Choose When
- **Over WebSearch**: When you need specific repository documentation, not general web results
- **Over Context7**: When exploring less common or custom repositories not in Context7
- **For exploration**: Understanding new codebases or repository structures
- **For documentation**: Accessing README files, guides, and project wikis
- **Not for**: Private repositories (unless using Devin account), general web content

## Works Best With
- **Context7**: Deepwiki for custom repos → Context7 for mainstream frameworks
- **Sequential**: Deepwiki provides repository context → Sequential analyzes architecture
- **Serena**: Deepwiki explores external repos → Serena manages local project understanding
- **Memory**: Deepwiki discovers patterns → Memory stores for future reference

## Configuration
- **Public Repositories**: No authentication required, free access
- **Private Repositories**: Requires Devin account and API key from devin.ai
- **Base URL**: https://mcp.deepwiki.com/
- **Protocols**: SSE at /sse and Streamable HTTP

## Examples
```
"explore vercel/next.js documentation" → Deepwiki (repository structure)
"how does authentication work in supabase/supabase" → Deepwiki (ask_question)
"read contributing guide for facebook/react" → Deepwiki (read_wiki_contents)
"understand architecture of langchain-ai/langchain" → Deepwiki (documentation exploration)
"what is React useEffect" → Context7 (mainstream framework docs)
"search for authentication libraries" → WebSearch (general discovery)
```
