# Skills & Tools Reference

This is the complete inventory of every plugin, skill, agent, command, hook, MCP server, and CLI tool installed by claude-templates. It serves as the authoritative reference for what capabilities are available in any session bootstrapped from this project.

## Table of Contents

- [Plugins](#plugins)
  - [Superpowers](#superpowers-14-skills-1-agent-1-hook)
  - [Frontend Design](#frontend-design-1-skill)
  - [Code Review](#code-review-5-agents-1-command)
  - [Security Guidance](#security-guidance-1-hook)
  - [Commit Commands](#commit-commands-3-commands)
  - [Skill Creator](#skill-creator-1-skill-1-agent)
  - [Claude Code Setup](#claude-code-setup-1-skill)
  - [Hookify](#hookify-1-skill-1-agent-4-commands)
  - [CT](#ct-8-skills-5-agents-2-commands)
  - [Engram](#engram-1-skill-mcp-server)
- [Global Skills](#global-skills)
  - [Code Quality & Review](#code-quality--review-9-skills)
  - [Development Workflow](#development-workflow-15-skills)
  - [Web Research & Documentation](#web-research--documentation-11-skills)
  - [Browser Automation](#browser-automation-8-skills)
  - [Databases](#databases-4-skills)
  - [Knowledge Management](#knowledge-management-4-skills)
  - [UI Components](#ui-components-1-skill)
  - [Marketing & Growth](#marketing--growth-34-skills)
- [MCP Servers](#mcp-servers)
- [CLI Tools](#cli-tools)

---

## Plugins

### Superpowers (14 skills, 1 agent, 1 hook)

Structured dev workflows: TDD, debugging, brainstorming, planning, worktrees, code review.

**Source:** https://github.com/obra/superpowers

| Name                          | Type  | Description                                                      |
| ----------------------------- | ----- | ---------------------------------------------------------------- |
| brainstorming                 | skill | Before any creative work — explores intent, requirements, design |
| dispatching-parallel-agents   | skill | 2+ independent tasks without shared state                        |
| executing-plans               | skill | Execute implementation plan with review checkpoints              |
| finishing-a-development-branch| skill | Integration options after tests pass (merge, PR, cleanup)        |
| receiving-code-review         | skill | Before implementing review feedback — verify before agreeing     |
| requesting-code-review        | skill | After completing features, before merging                        |
| subagent-driven-development   | skill | Execute plans via fresh subagent per task                        |
| systematic-debugging          | skill | Before proposing bug fixes — diagnose first                      |
| test-driven-development       | skill | Before implementing features — tests first                       |
| using-git-worktrees           | skill | Start isolated feature work in a worktree                        |
| using-superpowers             | skill | Session startup — skill discovery and routing                    |
| verification-before-completion| skill | Before claiming work is done — evidence first                    |
| writing-plans                 | skill | Before touching code — create implementation plan from spec      |
| writing-skills                | skill | Creating or editing agent skills                                 |
| code-reviewer                 | agent | Senior code reviewer for major project step completions          |

### Frontend Design (1 skill)

Production-grade frontend UI generation with bold aesthetic choices.

**Source:** claude-plugins-official

| Name            | Type  | Description                                                  |
| --------------- | ----- | ------------------------------------------------------------ |
| frontend-design | skill | Create distinctive, production-grade frontend interfaces     |

### Code Review (5 agents, 1 command)

Automated PR analysis with five parallel agents and confidence-based scoring.

**Source:** claude-plugins-official

| Name         | Type    | Description                                                                                       |
| ------------ | ------- | ------------------------------------------------------------------------------------------------- |
| /code-review | command | Run 5 parallel review agents (CLAUDE.md compliance, bug detection, git history, previous PRs, code comments) |

### Security Guidance (1 hook)

Automatic security warnings on file edits.

**Source:** claude-plugins-official

| Name              | Type | Description                                                            |
| ----------------- | ---- | ---------------------------------------------------------------------- |
| security-reminder | hook | PreToolUse hook on Edit/Write — warns about injection, XSS, unsafe patterns |

### Commit Commands (3 commands)

Git workflow automation.

**Source:** claude-plugins-official

| Name             | Type    | Description                                                  |
| ---------------- | ------- | ------------------------------------------------------------ |
| /commit          | command | Create commit with auto-generated message from staged/unstaged changes |
| /commit-push-pr  | command | Branch + commit + push + PR in one step                      |
| /clean_gone      | command | Clean up local branches deleted on remote (handles worktrees)|

### Skill Creator (1 skill, 1 agent)

Create, evaluate, improve, and benchmark agent skills.

**Source:** claude-plugins-official

| Name          | Type  | Description                                            |
| ------------- | ----- | ------------------------------------------------------ |
| skill-creator | skill | Full skill authoring workflow with evals and benchmarks|
| eval-viewer   | agent | Skill performance evaluation                           |

### Claude Code Setup (1 skill)

Codebase analysis for Claude Code automation recommendations.

**Source:** claude-plugins-official

| Name                          | Type  | Description                                                       |
| ----------------------------- | ----- | ----------------------------------------------------------------- |
| claude-automation-recommender | skill | Analyze codebase, recommend MCP servers, skills, hooks, subagents |

### Hookify (1 skill, 1 agent, 4 commands)

Create custom hooks from natural language or conversation analysis.

**Source:** claude-plugins-official

| Name                   | Type    | Description                                                      |
| ---------------------- | ------- | ---------------------------------------------------------------- |
| writing-rules          | skill   | Hookify rule syntax and patterns                                 |
| conversation-analyzer  | agent   | Analyze conversation transcripts for behaviors to prevent        |
| /hookify               | command | Create hooks from conversation analysis or explicit instructions |
| /hookify:help          | command | Plugin help documentation                                        |
| /hookify:list          | command | List all configured hookify rules                                |
| /hookify:configure     | command | Enable/disable hookify rules                                     |

### CT (8 skills, 5 agents, 2 commands)

Code quality, security, refactoring, and development workflows.

**Source:** this repo (`plugins/ct/`)

| Name                      | Type    | Description                                                                    |
| ------------------------- | ------- | ------------------------------------------------------------------------------ |
| audit-skills              | skill   | Review installed skills for redundancy with model knowledge                    |
| bugmagnet                 | skill   | Discover edge cases and test coverage gaps through systematic analysis         |
| duplicate-code-detector   | skill   | Find duplicated code using jscpd, classify and plan refactoring                |
| fix-loop                  | skill   | Iterative review-fix cycle — code-reviewer, fixer, verify, repeat until clean  |
| incremental-refactoring   | skill   | Refactor one transformation at a time, high-impact focus                       |
| performance-optimization  | skill   | Baseline, profile, optimize backend/API/database performance                   |
| revise-claude-md          | skill   | Update CLAUDE.md with session learnings                                        |
| threat-modeling           | skill   | STRIDE framework threat analysis for auth, payments, APIs, webhooks            |
| code-reviewer             | agent   | Autonomous code review seeking disconfirmation — best practices, security, performance |
| code-simplifier           | agent   | Simplify code for clarity while preserving functionality                       |
| deep-research             | agent   | Structured research specialist for external knowledge gathering                |
| fixer                     | agent   | Targeted minimal fixes for critical review findings, verifies tests pass       |
| refactor-scan             | agent   | Code quality coach — guides refactoring decisions post-TDD                     |
| /ct:discover-aliases      | command | Scan shell aliases, generate Claude Code documentation                         |
| /ct:research              | command | Systematic research with scientific methodology                                |

### Engram (1 skill, MCP server)

Persistent memory across sessions via SQLite + FTS5. Disables built-in auto-memory.

**Source:** https://github.com/Gentleman-Programming/engram

| Name             | Type       | Description                                                                |
| ---------------- | ---------- | -------------------------------------------------------------------------- |
| engram-memory    | skill      | ALWAYS ACTIVE — saves decisions, conventions, bugs, discoveries automatically |
| engram MCP server| MCP server | ~14 tools (mem_save, mem_search, mem_context, mem_session_summary, mem_get_observation, mem_save_prompt, mem_update, mem_suggest_topic_key, mem_session_start, mem_session_end, mem_stats, mem_delete, mem_timeline, mem_capture_passive) |

---

## Global Skills

87 skills installed via `skills.sh`, organized into 8 categories.

### Code Quality & Review (9 skills)

| Name                  | Source          | Description                                                     |
| --------------------- | --------------- | --------------------------------------------------------------- |
| find-bugs             | getsentry/skills| Find bugs, security vulnerabilities, and code quality issues in branch changes |
| security-review       | getsentry/skills| Security-focused code review for vulnerabilities (OWASP)        |
| django-access-review  | getsentry/skills| Django IDOR and access control security review                  |
| django-perf-review    | getsentry/skills| Django N+1 queries and performance review                       |
| gha-security-review   | getsentry/skills| GitHub Actions workflow security review                         |
| skill-scanner         | getsentry/skills| Scan agent skills for security issues                           |
| code-review           | getsentry/skills| Code review for security, performance, testing, and design      |
| code-simplifier       | getsentry/skills| Simplify code for clarity, consistency, and maintainability     |
| claude-settings-audit | getsentry/skills| Analyze repo and recommend Claude Code settings.json permissions|

### Development Workflow (15 skills)

| Name                  | Source          | Description                                                     |
| --------------------- | --------------- | --------------------------------------------------------------- |
| commit                | getsentry/skills| Sentry-convention commit messages with proper format and issue refs |
| create-branch         | getsentry/skills| Create git branches following Sentry naming conventions          |
| pr-writer             | getsentry/skills| Sentry-convention PR titles, descriptions, and issue references  |
| create-pr             | getsentry/skills| Alias for pr-writer                                             |
| iterate-pr            | getsentry/skills| Iterate on a PR until CI passes — feedback-fix-push-wait cycle   |
| gh-review-requests    | getsentry/skills| Fetch pending GitHub PR review notifications                     |
| agents-md             | getsentry/skills| Create and maintain AGENTS.md documentation                      |
| doc-coauthoring       | getsentry/skills| Structured workflow for co-authoring documentation               |
| blog-writing-guide    | getsentry/skills| Write Sentry engineering blog posts following standards           |
| brand-guidelines      | getsentry/skills| Write copy following Sentry brand guidelines                     |
| presentation-creator  | getsentry/skills| Create data-driven slides with React, Vite, and Recharts         |
| skill-writer          | getsentry/skills| Create, synthesize, and improve agent skills                     |
| skill-creator         | getsentry/skills| Alias for skill-writer                                           |
| sred-project-organizer| getsentry/skills| Organize projects into SRED format for submission                |
| sred-work-summary     | getsentry/skills| Annual work summary grouped into SRED projects                   |

### Web Research & Documentation (11 skills)

| Name                 | Source              | Description                                                  |
| -------------------- | ------------------- | ------------------------------------------------------------ |
| tavily-search        | tavily-ai/skills    | Quick web search with LLM-optimized results                  |
| tavily-research      | tavily-ai/skills    | Comprehensive AI-powered research with citations             |
| tavily-extract       | tavily-ai/skills    | Extract clean content from specific URLs                     |
| tavily-crawl         | tavily-ai/skills    | Crawl websites and extract multi-page content                |
| tavily-map           | tavily-ai/skills    | Discover and list all URLs on a website                      |
| tavily-cli           | tavily-ai/skills    | Full Tavily CLI: search, extract, crawl, research            |
| tavily-best-practices| tavily-ai/skills    | Production Tavily integration patterns and reference          |
| context7-cli         | upstash/context7    | Fetch library docs via ctx7 CLI                              |
| context7-mcp         | upstash/context7    | Library/framework API references and code examples           |
| find-docs            | upstash/context7    | Retrieve up-to-date docs for any developer technology        |
| defuddle             | kepano/obsidian-skills | Extract clean markdown from web pages (saves tokens vs WebFetch) |

### Browser Automation (8 skills)

| Name             | Source                      | Description                                                    |
| ---------------- | --------------------------- | -------------------------------------------------------------- |
| agent-browser    | vercel-labs/agent-browser   | Browser automation CLI for AI agents (50+ commands)            |
| playwright-cli   | microsoft/playwright-cli    | Browser testing, form filling, screenshots, data extraction    |
| dogfood          | vercel-labs/agent-browser   | Systematically explore and test web apps for bugs/UX issues    |
| electron         | vercel-labs/agent-browser   | Automate Electron apps (VS Code, Slack, Discord, Figma, etc.) |
| slack            | vercel-labs/agent-browser   | Interact with Slack workspaces via browser automation          |
| agentcore        | vercel-labs/agent-browser   | Run agent-browser on AWS Bedrock AgentCore cloud browsers      |
| vercel-sandbox   | vercel-labs/agent-browser   | Browser automation inside Vercel Sandbox microVMs              |
| dev              | microsoft/playwright-cli    | playwright-cli repository maintenance workflows                |

### Databases (4 skills)

| Name     | Source                      | Description                                                     |
| -------- | --------------------------- | --------------------------------------------------------------- |
| postgres | planetscale/database-skills | PostgreSQL optimization, query tuning, and troubleshooting      |
| mysql    | planetscale/database-skills | MySQL/InnoDB schema, indexing, query tuning, and operations     |
| vitess   | planetscale/database-skills | Vitess best practices, sharding, and VSchema configuration      |
| neki     | planetscale/database-skills | Neki sharded Postgres product overview and scaling guidance     |

### Knowledge Management (4 skills)

| Name              | Source                  | Description                                                     |
| ----------------- | ----------------------- | --------------------------------------------------------------- |
| obsidian-cli      | kepano/obsidian-skills  | Obsidian vault interaction: read, create, search, manage notes  |
| obsidian-markdown | kepano/obsidian-skills  | Obsidian-flavored markdown: wikilinks, callouts, embeds, properties |
| obsidian-bases    | kepano/obsidian-skills  | Create Obsidian Bases (.base files) with views, filters, formulas |
| json-canvas       | kepano/obsidian-skills  | Create/edit JSON Canvas files (.canvas) for visual maps         |

### UI Components (1 skill)

| Name   | Source    | Description                                                    |
| ------ | --------- | -------------------------------------------------------------- |
| shadcn | shadcn/ui | Manage shadcn/ui components: search registries, add, debug, style |

### Marketing & Growth (34 skills)

All sourced from coreyhaines31/marketingskills.

| Name                      | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| ab-test-setup             | Plan and implement A/B tests and growth experiments              |
| ad-creative               | Generate ad headlines, descriptions, and creative variations     |
| ai-seo                    | Optimize content for AI search engines and LLM citations         |
| analytics-tracking        | Set up and audit analytics tracking (GA4, events, UTMs)          |
| churn-prevention          | Reduce churn with cancellation flows, save offers, retention strategies |
| cold-email                | Write B2B cold emails and follow-up sequences                    |
| competitor-alternatives   | Create competitor comparison and alternative pages               |
| content-strategy          | Plan content strategy and topic coverage                         |
| copy-editing              | Edit, review, and improve marketing copy                         |
| copywriting               | Write marketing copy for any page type                           |
| customer-research         | Conduct and synthesize customer research                         |
| email-sequence            | Create email drip campaigns and lifecycle flows                  |
| form-cro                  | Optimize lead capture and non-signup forms                       |
| free-tool-strategy        | Plan free tools for marketing (engineering as marketing)         |
| launch-strategy           | Plan product launches and feature announcements                  |
| lead-magnets              | Create and optimize lead magnets                                 |
| marketing-ideas           | 139+ marketing strategy ideas for SaaS                           |
| marketing-psychology      | Apply behavioral psychology to marketing                         |
| onboarding-cro            | Optimize post-signup activation and onboarding                   |
| page-cro                  | Optimize marketing page conversions                              |
| paid-ads                  | Manage Google Ads, Meta, LinkedIn campaigns                      |
| paywall-upgrade-cro       | Optimize in-app paywalls and upsell screens                      |
| popup-cro                 | Optimize popups, modals, and overlays                            |
| pricing-strategy          | Pricing, packaging, and monetization decisions                   |
| product-marketing-context | Product positioning and marketing context documents              |
| programmatic-seo          | Template-based SEO pages at scale                                |
| referral-program          | Create referral and affiliate programs                           |
| revops                    | Revenue operations and lead lifecycle management                 |
| sales-enablement          | Create sales collateral, pitch decks, one-pagers                 |
| schema-markup             | Add and optimize schema markup and structured data               |
| seo-audit                 | Audit and diagnose SEO issues                                    |
| signup-flow-cro           | Optimize registration and trial flows                            |
| site-architecture         | Plan website hierarchy, navigation, URL structure                |
| social-content            | Create and schedule social media content                         |

---

## MCP Servers

| Name   | Command                            | Description                              | Key Tools                              |
| ------ | ---------------------------------- | ---------------------------------------- | -------------------------------------- |
| gabb   | `/opt/homebrew/bin/gabb mcp-server`| Code indexing for semantic symbol search and file structure | gabb_symbol, gabb_structure            |
| engram | `engram mcp --tools=agent`         | Persistent memory across sessions        | mem_save, mem_search, mem_context, + 11 more |

---

## CLI Tools

| Tool                    | Description                                          | Install Method            |
| ----------------------- | ---------------------------------------------------- | ------------------------- |
| Claude Code             | Anthropic's AI coding assistant                      | Native installer          |
| jq                      | JSON processor for config merging                    | Homebrew                  |
| fd                      | Fast find alternative                                | Homebrew                  |
| ripgrep (rg)            | Fast grep alternative                                | Homebrew                  |
| rtk                     | Token-optimized CLI proxy (60-90% savings)           | Homebrew                  |
| gh                      | GitHub CLI for PR/issue management                   | Homebrew                  |
| Tavily CLI              | AI-optimized web search                              | Native installer          |
| jscpd                   | Copy/paste detection                                 | npm                       |
| Context7 CLI (ctx7)     | Library documentation fetcher                        | npm                       |
| agent-browser           | AI-first browser automation (50+ commands)           | npm + browser install     |
| Engram                  | Persistent memory for AI agents (SQLite + FTS5)      | Homebrew                  |
| Gabb                    | Local code indexer for semantic code understanding   | Homebrew                  |
