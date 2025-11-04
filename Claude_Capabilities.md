# Claude Configuration

This file explains some of the tools included in this configuration. This file may become outdated as plugins used evolve, so take it as a weak reference of what is included, but verify yourself.

## MCP Servers

This configuration includes the following MCP (Model Context Protocol) servers, each providing specialized capabilities:

- **Context7** (`@upstash/context7-mcp`): Solves outdated documentation problems by dynamically injecting up-to-date, version-specific documentation and code examples directly into AI context. Fetches the latest official documentation and integrates it seamlessly, preventing broken code from old docs. Provides tools to resolve library IDs and retrieve current documentation with code snippets.

- **Sequential-Thinking** (`@modelcontextprotocol/server-sequential-thinking`): Enables dynamic, reflective problem-solving through structured step-by-step thinking. Allows breaking down complex problems, adjusting thought counts dynamically, and revising previous thinking or branching into alternatives. Ideal for analysis tasks requiring course correction and deep reflection.

- **Tavily** (`tavily-mcp@0.1.2`): Integrates Tavily's advanced search and data extraction, providing real-time web search, information retrieval, and content extraction. Offers scalable Search, Extract, Map, and Crawl APIs built to enrich AI with instant, cleaned, structured web content. Ideal for current information needs and web content analysis.

- **Chrome-DevTools** (`chrome-devtools-mcp@latest`): Allows AI assistants to see and interact with live Chrome browsers using Chrome's DevTools Protocol. Enables autonomous page navigation, clicking, DOM/CSS reading, performance metrics capture, console log analysis, and screenshots. With 25+ tools for browser manipulation and debugging, it's ideal for web development and performance optimization.

- **Playwright** (`@playwright/mcp@latest`): Provides comprehensive browser automation using Playwright across Chromium, WebKit, and Firefox. Offers 24+ tools for navigation, clicking, form filling, screenshot capture, JavaScript execution, and data extraction without complex coding. Ideal for web scraping, test automation, and dynamic website interaction.

- **Serena** (`git+https://github.com/oraios/serena`): A powerful coding agent toolkit providing semantic code retrieval and editing with multi-language support. Offers advanced code analysis, symbol finding, pattern searching, and intelligent modifications that understand code structure. Features customizable prompts, language server integration, and context-aware code editing.

- **Perplexity-Ask** (`server-perplexity-ask`): Official MCP implementation for Perplexity's Sonar API, providing real-time web-wide research capabilities. Integrates Perplexity's search engine for live web searches, reasoning, and research without outdated training data. Ideal for current information needs and comprehensive answer generation with cited sources.

- **DeepWiki** (`https://mcp.deepwiki.com/mcp`): Free remote MCP server providing programmatic access to documentation and search for GitHub repositories indexed on DeepWiki.com. Offers tools for reading wiki structure, retrieving documentation, and asking questions about repositories. Ideal for code understanding, architecture exploration, and technical Q&A on open-source projects.

