# Skills & Tools Reference

This is the complete inventory of every plugin, skill, agent, command, hook, MCP server, and CLI tool installed by claude-templates. It serves as the authoritative reference for what capabilities are available in any session bootstrapped from this project.

## Table of Contents

- [Plugins](#plugins)
  - [Superpowers](#superpowers-14-skills-1-agent-1-hook)
  - [Frontend Design](#frontend-design-1-skill)
  - [Code Review](#code-review-5-agents-1-command)
  - [Security Guidance](#security-guidance-1-hook)
  - [Commit Commands](#commit-commands-3-commands)
  - [Claude Code Setup](#claude-code-setup-1-skill)
  - [Hookify](#hookify-1-skill-1-agent-4-commands)
  - [Skill Creator](#skill-creator-1-skill)
  - [CT](#ct-14-skills-6-agents)
  - [Engram](#engram-1-skill-mcp-server)
- [Global Skills](#global-skills)
  - [Code Quality & Review](#code-quality--review-4-skills)
  - [Web Research & Documentation](#web-research--documentation-9-skills)
  - [Browser Automation](#browser-automation-2-skills)
  - [Databases](#databases-1-skill)
  - [Knowledge Management](#knowledge-management-2-skills)
  - [UI Components](#ui-components-1-skill)
  - [Code Navigation](#code-navigation-1-skill)
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

### Skill Creator (1 skill)

Create, modify, and measure skill performance with evals and variance analysis.

**Source:** claude-plugins-official

| Name           | Type  | Description                                                              |
| -------------- | ----- | ------------------------------------------------------------------------ |
| skill-creator  | skill | Create new skills, modify existing ones, run evals, benchmark performance |

### CT (14 skills, 6 agents)

Code quality, security, refactoring, and development workflows.

**Source:** this repo (`plugins/ct/`)

| Name                      | Type    | Description                                                                    |
| ------------------------- | ------- | ------------------------------------------------------------------------------ |
| audit-skills              | skill   | Review installed skills for redundancy with model knowledge                    |
| bugmagnet                 | skill   | Discover edge cases and test coverage gaps through systematic analysis         |
| dast-scan                 | skill   | Dynamic security scanning — Nuclei (fast) + ZAP Docker (deep, opt-in)          |
| duplicate-code-detector   | skill   | Find duplicated code using jscpd, classify and plan refactoring                |
| fix-loop                  | skill   | Iterative review-fix cycle — code-reviewer, fixer, verify, repeat until clean  |
| incremental-refactoring   | skill   | Refactor one transformation at a time, high-impact focus                       |
| lint-guard                | skill   | Set up strict complexity linting — 17 languages, auto-detection, Stop hook     |
| mutation-testing          | skill   | Diff-scoped mutation testing — Stryker, mutmut, cargo-mutants, PIT             |
| performance-optimization  | skill   | Baseline, profile, optimize backend/API/database performance                   |
| reflect                   | skill   | Self-reflection after work sessions — structured proposals with review gate    |
| research                  | skill   | Systematic research with scientific methodology and evidence-based synthesis   |
| revise-claude-md          | skill   | Update CLAUDE.md with session learnings                                        |
| threat-modeling           | skill   | STRIDE framework threat analysis for auth, payments, APIs, webhooks            |
| wcag-audit                | skill   | WCAG accessibility auditing — static analysis + axe-core runtime               |
| code-reviewer             | agent   | Autonomous code review seeking disconfirmation — best practices, security, performance |
| code-simplifier           | agent   | Simplify code for clarity while preserving functionality                       |
| deep-research             | agent   | Structured research specialist for external knowledge gathering                |
| evaluator                 | agent   | Dynamic QA — runs the app, tests UX flows, scores criteria                     |
| fixer                     | agent   | Targeted minimal fixes for critical review findings, verifies tests pass       |
| refactor-scan             | agent   | Code quality coach — guides refactoring decisions post-TDD                     |

### Engram (1 skill, MCP server)

Persistent memory across sessions via SQLite + FTS5. Disables built-in auto-memory.

**Source:** https://github.com/Gentleman-Programming/engram

| Name             | Type       | Description                                                                |
| ---------------- | ---------- | -------------------------------------------------------------------------- |
| engram-memory    | skill      | ALWAYS ACTIVE — saves decisions, conventions, bugs, discoveries automatically |
| engram MCP server| MCP server | ~14 tools (mem_save, mem_search, mem_context, mem_session_summary, mem_get_observation, mem_save_prompt, mem_update, mem_suggest_topic_key, mem_session_start, mem_session_end, mem_stats, mem_delete, mem_timeline, mem_capture_passive) |

---

## Global Skills

**52 skills total** — 32 from plugins (see [Plugins](#plugins) above) and 20 from [skills.sh](https://skills.sh) + tools (below).

### Code Quality & Review (4 skills)

| Name                  | Source          | Description                                                     |
| --------------------- | --------------- | --------------------------------------------------------------- |
| find-bugs             | getsentry/skills| Find bugs, security vulnerabilities, and code quality issues in branch changes |
| security-review       | getsentry/skills| Security-focused code review for vulnerabilities (OWASP)        |
| gha-security-review   | getsentry/skills| GitHub Actions workflow security review                         |
| skill-scanner         | getsentry/skills| Scan agent skills for security issues                           |

### Web Research & Documentation (4 skills)

| Name                 | Source              | Description                                                  |
| -------------------- | ------------------- | ------------------------------------------------------------ |
| tavily-cli           | tavily-ai/skills    | Full Tavily CLI: search, extract, crawl, research            |
| tavily-map           | tavily-ai/skills    | Discover and list all URLs on a website                      |
| context7-cli         | upstash/context7    | Fetch library docs via ctx7 CLI                              |
| defuddle             | kepano/obsidian-skills | Extract clean markdown from web pages (saves tokens vs WebFetch) |

### Browser Automation (2 skills)

| Name             | Source                      | Description                                                    |
| ---------------- | --------------------------- | -------------------------------------------------------------- |
| agent-browser    | vercel-labs/agent-browser   | Browser automation CLI for AI agents (50+ commands)            |
| dogfood          | vercel-labs/agent-browser   | Systematically explore and test web apps for bugs/UX issues    |

### Databases (1 skill)

| Name     | Source                      | Description                                                     |
| -------- | --------------------------- | --------------------------------------------------------------- |
| postgres | planetscale/database-skills | PostgreSQL optimization, query tuning, and troubleshooting      |

### Knowledge Management (2 skills)

| Name              | Source                  | Description                                                     |
| ----------------- | ----------------------- | --------------------------------------------------------------- |
| obsidian-cli      | kepano/obsidian-skills  | Obsidian vault interaction: read, create, search, manage notes  |
| obsidian-markdown | kepano/obsidian-skills  | Obsidian-flavored markdown: wikilinks, callouts, embeds, properties |

### UI Components (1 skill)

| Name   | Source    | Description                                                    |
| ------ | --------- | -------------------------------------------------------------- |
| shadcn | shadcn/ui | Manage shadcn/ui components: search registries, add, debug, style |

### Code Navigation (1 skill)

| Name | Source        | Description                                                     |
| ---- | ------------- | --------------------------------------------------------------- |
| gabb | gabb-software | Teaches when to use gabb_structure for efficient file exploration |

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
