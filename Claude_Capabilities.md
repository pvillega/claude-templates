# Claude Configuration

This file explains some of the tools included in this configuration. This file may become outdated as plugins used evolve, so take it as a weak reference of what is included, but verify yourself.

## Commands

This configuration includes the following commands, which are basically triggers for certain skills:

### Core Commands

- **/ct:commit**: commits the current changes, generating an appropriate message for them. Validates commit readiness, automatically excludes `.env` files, requires user confirmation before committing, and executes atomic commits with explicit file paths. Usage: `/ct:commit [optional: file paths]`

- **/ct:commit-msg**: generates a commit message for the changes in staging and displays it in a copyable code block, but doesn't commit the changes themselves. Useful for previewing what commit message would be generated.

- **/ct:grammar-check**: checks the grammar and spelling of markdown files using British English standards (-ise, -our, -re endings). Creates safety backups before making changes. If no file specified, scans git-modified markdown files. Usage: `/ct:grammar-check [optional: file.md]`

- **/ct:init**: initialises Claude and Serena for a project. Analyses codebase structure to detect language, frameworks, and build systems. Generates/updates `.claude/CLAUDE.md` with project-specific instructions and initialises Serena onboarding. Safe to run anytime to refresh configuration. Usage: `/ct:init`

- **/ct:research**: applies scientific methodology with adaptive strategies, multi-hop reasoning, and evidence-based synthesis for comprehensive research. Uses systematic four-phase process: Discovery, Investigation, Synthesis, and Reporting. Integrates with WebSearch, Tavily, Perplexity, and Context7 MCPs for optimal information gathering. Usage: `/ct:research`

- **/ct:discover-aliases**: discovers shell aliases and generates Claude Code documentation for tool replacements (cat→bat, ls→eza, grep→rg, find→fd, etc.). Creates `~/.claude/Aliases.md` with replacement documentation and bypass instructions. Usage: `/ct:discover-aliases`

- **/ct:save-session-memory**: saves current session knowledge to Serena memory for future reference. Prompts for focus area (Decisions Made, Problems Solved, or Both) and persists structured markdown to Serena memory. Usage: `/ct:save-session-memory`

- **/ct:repo-index**: runs repository indexing to create or update PROJECT_INDEX.md with compressed codebase context. Inspects directory structure, surfaces recently changed or high-risk files, and generates token-efficient summaries. Use at session start or when the codebase changes substantially. Usage: `/ct:repo-index`

### Meta Commands

- **/ct:meta:skills-check**: lists all skills currently available and loaded in the session, showing names, descriptions, and any sandbox restrictions enabled.

- **/ct:meta:test-agent**: tests an agent using functional quality comparison (A/B testing). Validates agent names (custom `.claude/agents/*.md` or Task tool subagent), runs baseline vs specialised agent comparison, and generates timestamped reports in `.claude/test-reports/`. Usage: `/ct:meta:test-agent <agent-name>`

- **/ct:meta:test-all-skills**: tests all skills in `.claude/skills/` using parallel subagents with A/B quality comparison. Discovers skills dynamically, classifies by type, generates type-appropriate test tasks, and produces comprehensive reports with effect size rankings. Usage: `/ct:meta:test-all-skills [optional: iterations (1-5, default: 3)]`

- **/ct:meta:test-skill**: tests a skill using functional quality comparison (A/B testing with quality metrics). Classifies skill type, generates real-world test tasks, runs baseline vs skill-enhanced comparison, and calculates statistics (Cohen's d, effect size). Usage: `/ct:meta:test-skill <skill-name>`

### Commands from Superpowers

The commands below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin

- **/superpowers:brainstorm**: triggers the brainstorming skill. It triggers the interactive design refinement process where Claude asks structured questions to transform rough ideas into fully-formed designs. It guides Claude through a conversational process of exploring alternatives, asking clarifying questions one at a time, and ultimately presenting a design in 200-300 word sections with validation steps.

- **/superpowers:execute-plan**: activates the planning skill. This creates structured implementation plans for development work. It guides Claude to break down features into concrete, testable steps with clear verification criteria. The skill emphasises creating plans that can be executed in batches and includes specifics on how to verify each step is complete before moving forward.

- **/superpowers:write-plan**: launches the plan execution skill. This systematically works through implementation plans created by write-plan, executing each step with proper testing and verification. It follows a batch-based approach where Claude works through logical chunks of the plan, and validates completion at each stage.

## Agents

### Local Agents

This configuration includes the following locally-defined agents in `.claude/agents/`:

- **repo-index**: Repository indexing and codebase briefing assistant. Inspects directory structure, surfaces recently changed or high-risk files, and generates/updates `PROJECT_INDEX.md` when stale (>7 days) or missing. Use at session start or when the codebase changes substantially for token-efficient context compression.

- **deep-research**: Structured research specialist for external knowledge gathering. Clarifies research questions and depth levels, drafts lightweight research plans, executes parallel searches using approved tools (Tavily, WebFetch, Context7), and delivers concise synthesis with citation tables. Does NOT write implementation code or make architectural decisions.

- **refactor-scan**: Refactoring guidance and assessment agent. Proactively guides refactoring decisions and comprehensively assesses code after tests pass (TDD's third step). Analyses naming clarity, structural simplicity, knowledge duplication, and abstraction opportunities. Classifies findings into Critical, High Value, Nice to Have, and Skip categories.

- **pr-review-assistant**: Comprehensive pull request reviewer for critical PRs. Identifies logic errors, performance problems, security vulnerabilities (auth, injection, data exposure), and maintainability concerns. Provides structured findings with severity ratings (Critical, High, Medium, Low). Use for critical PRs (authentication, payments, data handling, external APIs) requiring compliance documentation.

### Agents from Superpowers

The agents below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin

- **code-reviewer (from superpowers)**: An agent configuration file that defines a Senior Code Reviewer persona for Claude Code's sub-agent system. This agent activates when a major project step has been completed and needs review against the original plan and coding standards. It uses the Sonnet model.

## Skills

This configuration includes the following skills in `.claude/skills/`:

- **architecture-discipline**: use when designing or modifying system architecture or evaluating technology choices. Enforces 7-section TodoWrite with 22+ items. Triggers: "design architecture", "system design", "should we use [tech]", "compare [A] vs [B]", "database choice", "API design".

- **backend-reliability-enforcer**: use when implementing backend APIs, data persistence, or external integrations. Enforces TodoWrite with 25+ items covering error handling, validation, logging, and resilience patterns.

- **confidence-check**: use before implementing when uncertainty exists. Weighted scoring across 5 checks (requires ≥80% to proceed). Triggers: "before implementing", "verify readiness", "should I proceed". Essential when stack is unfamiliar or codebase is complex.

- **deployment-automation-enforcer**: use when designing deployment pipelines, CI/CD, Kubernetes, or Terraform. Enforces rollback checkpoint then TodoWrite with 19+ items. Triggers: "deploy", "CI/CD", "kubernetes", "terraform".

- **duplicate-code-detector**: uses jscpd (copy-paste detector) to find duplicate code with quantitative metrics. Triggers: "duplicate code", "code quality", "find clones", "copy-paste detection". Use BEFORE incremental-refactoring to identify targets.

- **edge-case-discovery**: systematically identifies boundary conditions, failure modes, and edge cases. Enforces TodoWrite with 15+ items across 5 categories: Boundary Values, Equivalence Partitioning, State Transitions, Error Conditions, and Assumption Challenging. Triggers: "all edge cases", "what could break", "bulletproof", "failure modes".

- **frontend-production-quality**: enforces WCAG 2.1 AA accessibility and Core Web Vitals as non-negotiable requirements. Creates TodoWrite with 18+ items across Accessibility (8+), Performance (6+), and Evidence Collection (4+) categories. Triggers: "accessibility audit", "WCAG", "Lighthouse", "screen reader", "a11y", "keyboard navigation". For frontend UI context; use performance-optimization for backend.

- **incremental-refactoring**: use when IMPLEMENTING refactoring changes. Enforces metrics-driven protocol with before/after measurements. 5-step process: Baseline → Select Pattern → Apply → Validate → Document. Triggers: "implement refactor", "apply refactoring pattern", "clean up code smell", "extract method".

- **meta-agent** (agent-creator): use when creating agents or automating workflows. Routes to Simple (30-55 lines), Standard (100-300 lines), or Full (500+ lines) path based on complexity. Includes marketplace.json for installation, validators, and comprehensive test suite (25+ tests for Full path).

- **performance-optimization**: use when creating performance optimisation plan for backend, API, or general system performance. Enforces BASELINE → PROFILE → OPTIMISE → VALIDATE sequence. Triggers: "optimise API", "backend slow", "API latency", "database performance", "query optimisation". For backend context; use frontend-production-quality for UI.

- **security-compliance-audit**: use for formal compliance audits requiring documentation (SOC2, PCI-DSS, HIPAA, GDPR, ISO 27001). Enforces TodoWrite with 20+ items including OWASP Top 10 checklist. NOT for casual PR security checks. Triggers: "compliance audit", "regulatory assessment", "auditor documentation".

- **threat-modeling**: use when implementing auth, file uploads, payments, or external APIs. Applies STRIDE framework (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) systematically. Includes quick-start templates for Authentication, File Upload, and Multi-Tenant API scenarios.

### Skills from Superpowers

The skills below are included, and originate from the [Superpowers](https://github.com/obra/superpowers/) plugin:

- **brainstorming**: transforms rough ideas into fully-formed designs through natural conversation and exploration using Socratic method.

- **condition-based-waiting**: eliminates flaky tests by replacing arbitrary timeouts with condition polling. Waits for actual state changes instead of timing guesses.

- **defense-in-depth**: validates data at multiple system layers to make bugs structurally impossible. Use when invalid data causes failures deep in execution.

- **dispatching-parallel-agents**: investigates 3+ independent failures concurrently by dispatching multiple Claude agents. Use when problems can be investigated without shared state or dependencies.

- **executing-plans**: works through plans created by writing-plans skill with disciplined focus and verification.

- **finishing-a-development-branch**: guides the final steps of completing development work by presenting clear options after implementation.

- **receiving-code-review**: handles receiving and implementing code review feedback with technical rigor and verification, not performative agreement or blind implementation.

- **requesting-code-review**: manages the workflow of requesting code review after completing a significant implementation step.

- **subagent-driven-development**: effective delegation to sub-agents for parallelisation and specialisation while maintaining quality.

- **systematic-debugging**: methodical approach to debugging that replaces "try random things until it works" with systematic investigation. Activates when encountering bugs, test failures, or unexpected behaviour.

- **test-driven-development**: foundational TDD skill that enforces the discipline of writing tests before implementation. This skill activates automatically when implementing features.

- **testing-skills-with-subagents**: use sub-agents to validate that skills work as intended before sharing them.

- **using-git-worktrees**: skill for managing Git worktrees to enable parallel development without switching branches.

- **verification-before-completion**: activates automatically before Claude declares work complete. Prevents premature "done" declarations by enforcing a verification checklist.

- **writing-plans**: creates detailed, testable plans that break complex features into concrete, verifiable steps. Each plan is designed for systematic execution.

- **writing-skills**: complete reference for creating new skills following superpowers conventions.

### Skills from Playwright Skill

The skills below are included, and originate from the [Playwright Skill](https://github.com/lackeyjb/playwright-skill) plugin:

- **playwright-skill**: enables Claude to autonomously write and execute custom Playwright browser automation scripts on-demand for any testing or automation task. When triggered by browser-related requests, Claude auto-detects running dev servers on common ports (3000, 3001, 5173, etc.), writes parameterized test scripts to /tmp for automatic cleanup, and executes them with a visible browser by default. **NOTE:** asking for "test in the background" or "headless mode" will enable headless mode.

## MCP Servers

This configuration includes the following MCP (Model Context Protocol) servers, each providing specialised capabilities.

**Note:** Some MCP servers require API keys via environment variables. They are enabled if the environment variable is set.

### Core MCP Servers

- **Context7** (`@upstash/context7-mcp`): solves outdated documentation problems by dynamically injecting up-to-date, version-specific documentation and code examples directly into AI context. Fetches the latest official documentation and integrates it seamlessly, preventing broken code from old docs. Tools: `resolve-library-id`, `get-library-docs`.

- **Playwright** (`@playwright/mcp@latest`): provides comprehensive browser automation using Playwright across multiple browsers (Chromium, Firefox, WebKit). Offers 18+ tools for navigation, clicking, form filling, hovering, screenshot capture, accessibility snapshots, JavaScript execution, and data extraction. Ideal for web scraping, cross-browser testing, and dynamic website interaction.

- **Serena** (`git+https://github.com/oraios/serena`): a powerful coding agent toolkit providing semantic code retrieval and editing with multi-language support. Offers 20+ tools for code analysis, symbol finding, pattern searching, cross-file refactoring, and intelligent modifications that understand code structure. Features language server integration and context-aware code editing.

- **shadcn** (`shadcn@latest`): component discovery and management for the shadcn/ui library. Provides 8 tools for registry browsing and searching, component viewing and example retrieval, add command generation, and project auditing. Use for finding and installing UI components.

### API-Key Enabled MCP Servers

These servers require API keys via environment variables:

- **Perplexity-Ask** (`server-perplexity-ask`): official MCP implementation for Perplexity's Sonar API, providing real-time web-wide research capabilities. Integrates Perplexity's search engine for live web searches, reasoning, and research without outdated training data. Ideal for current information needs and comprehensive answer generation with cited sources. **Requires:** `PERPLEXITY_API_KEY`

- **Tavily** (`tavily-mcp@0.1.2`): integrates Tavily's advanced search and data extraction, providing real-time web search, information retrieval, and content extraction. Offers Search and Extract APIs built to enrich AI with instant, cleaned, structured web content. Ideal for current information needs and web content analysis. **Requires:** `TAVILY_API_KEY`
