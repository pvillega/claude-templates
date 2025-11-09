# Claude Configuration

This file explains some of the tools included in this configuration. This file may become outdated as plugins used evolve, so take it as a weak reference of what is included, but verify yourself.

## Commands

This configuration includes the following commands, which are basically triggers for certain skills:

- **/ct:commit**: commits the current changes, generating an appropriate message for them.

- **/ct:commit-msg**: generates a commit message for the changes in staging and displays it, but doesn't commit the changes themselves.

- **/ct:grammar-check**: checks the grammar and spelling of a text file passed as a parameter. It follows British English rules and creates a backup of the file first.

- **/ct:skills-check**: lists skills available (and loaded) on this session. Claude seems ot be missing a command for this.


### Commands from Superpowers

The commands below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin

- **/superpowers:brainstorm**: triggers the brainstorming skill. It triggers the interactive design refinement process where Claude asks structured questions to transform rough ideas into fully-formed designs. It guides Claude through a conversational process of exploring alternatives, asking clarifying questions one at a time, and ultimately presenting a design in 200-300 word sections with validation steps.

- **/superpowers:execute-plan**: activates the planning skill. This creates structured implementation plans for development work. It guides Claude to break down features into concrete, testable steps with clear verification criteria. The skill emphasises creating plans that can be executed in batches and includes specifics on how to verify each step is complete before moving forward.

- **/superpowers:write-plan**: launches the plan execution skill. This systematically works through implementation plans created by write-plan, executing each step with proper testing and verification. It follows a batch-based approach where Claude works through logical chunks of the plan, and validates completion at each stage.

## Agents

This configuration includes the following agents:

### Agents from Superpowers

The agents below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin

- **code-reviewer (from superpowers)**: An agent configuration file that defines a Senior Code Reviewer persona for Claude Code's sub-agent system. This agent activates when a major project step has been completed and needs review against the original plan and coding standards. It uses the Sonnet model.

## Skills

This configuration includes the following skills:

- **architecture-discipline**: use when designing or modifying system architecture

- **backend-reliability-enforcer**: used when implementing backend systems, APIs, data persistence, or any server-side component

- **deployment-automation-enforcer**: use when designing or implementing deployment pipelines, CI/CD workflows, infrastructure provisioning, or any automation that touches production systems

- **duplicate-code-detector**: uses jscpd (copy-paste detector) to find duplicate code. Triggered when referring to code quality, refactoring, technical debt, or similar.





### Skills from Superpowers

The skills below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin:

- **brainstorming**: transforms rough ideas into fully-formed designs through natural conversation and exploration

- **executing-plans**: works through plans created by writing-plans skill with disciplined focus and verification.

- **finishing-a-development-branch**: guides the final steps of completing development work by presenting clear options after implementation.

- **requesting-code-review**: manages the workflow of requesting code review after completing a significant implementation step.

- **subagent-driven-development**: effective delegation to sub-agents for parallelization and specialization while maintaining quality.

- **systematic-debugging**: methodical approach to debugging that replaces "try random things until it works" with systematic investigation. Activates when encountering bugs, test failures, or unexpected behavior.

- **test-driven-development**: foundational TDD skill that enforces the discipline of writing tests before implementation. This skill activates automatically when implementing features.

- **testing-skills-with-subagents**: use sub-agents to validate that skills work as intended before sharing them.

- **using-git-worktrees**: skill for managing Git worktrees to enable parallel development without switching branches.

- **verification-before-completion**: activates automatically before Claude declares work complete. Prevents premature "done" declarations by enforcing a verification checklist.

- **writing-plans**: creates detailed, testable plans that break complex features into concrete, verifiable steps. Each plan is designed for systematic execution.

- **writing-skills**: complete reference for creating new skills following superpowers conventions.

### Skills from Playwrigth Skill

The skills below are included, and originate from the [Playwrigth Skill](https://github.com/lackeyjb/playwright-skill) plugin:

- **playwright-skill**: enables Claude to autonomously write and execute custom Playwright browser automation scripts on-demand for any testing or automation task. When triggered by browser-related requests, Claude auto-detects running dev servers on common ports (3000, 3001, 5173, etc.), writes parameterized test scripts to /tmp for automatic cleanup, and executes them with a visible browser by default. **NOTE:** asking for "test in the background" or "headless mode" will enable headless mode.

## MCP Servers

This configuration includes the following MCP (Model Context Protocol) servers, each providing specialised capabilities:

- **Chrome-DevTools** (`chrome-devtools-mcp@latest`): allows AI assistants to see and interact with live Chrome browsers using Chrome's DevTools Protocol. Enables autonomous page navigation, clicking, DOM/CSS reading, performance metrics capture, console log analysis, and screenshots. With 25+ tools for browser manipulation and debugging, it's ideal for web development and performance optimisation.

- **Context7** (`@upstash/context7-mcp`): solves outdated documentation problems by dynamically injecting up-to-date, version-specific documentation and code examples directly into AI context. Fetches the latest official documentation and integrates it seamlessly, preventing broken code from old docs. Provides tools to resolve library IDs and retrieve current documentation with code snippets.

- **DeepWiki** (`https://mcp.deepwiki.com/mcp`): free remote MCP server providing programmatic access to documentation and search for GitHub repositories indexed on DeepWiki.com. Offers tools for reading wiki structure, retrieving documentation, and asking questions about repositories. Ideal for code understanding, architecture exploration, and technical Q&A on open-source projects.

- **Perplexity-Ask** (`server-perplexity-ask`): official MCP implementation for Perplexity's Sonar API, providing real-time web-wide research capabilities. Integrates Perplexity's search engine for live web searches, reasoning, and research without outdated training data. Ideal for current information needs and comprehensive answer generation with cited sources.

- **Playwright** (`@playwright/mcp@latest`): provides comprehensive browser automation using Playwright across Chromium, WebKit, and Firefox. Offers 24+ tools for navigation, clicking, form filling, screenshot capture, JavaScript execution, and data extraction without complex coding. Ideal for web scraping, test automation, and dynamic website interaction.

- **Sequential-Thinking** (`@modelcontextprotocol/server-sequential-thinking`): enables dynamic, reflective problem-solving through structured step-by-step thinking. Allows breaking down complex problems, adjusting thought counts dynamically, and revising previous thinking or branching into alternatives. Ideal for analysis tasks requiring course correction and deep reflection.

- **Serena** (`git+https://github.com/oraios/serena`): a powerful coding agent toolkit providing semantic code retrieval and editing with multi-language support. Offers advanced code analysis, symbol finding, pattern searching, and intelligent modifications that understand code structure. Features customisable prompts, language server integration, and context-aware code editing.

- **Tavily** (`tavily-mcp@0.1.2`): integrates Tavily's advanced search and data extraction, providing real-time web search, information retrieval, and content extraction. Offers scalable Search, Extract, Map, and Crawl APIs built to enrich AI with instant, cleaned, structured web content. Ideal for current information needs and web content analysis.
