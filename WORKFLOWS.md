# Workflows

Task-driven guide for finding the right tool, skill, or command. Organized by what you're trying to do. For the complete inventory, see [SKILLS.md](SKILLS.md).

## Starting Work

| When I need to... | Use | How |
|---|---|---|
| Plan a new feature or change | superpowers:brainstorming → writing-plans | `/brainstorming`, or ask to plan/design a feature |
| Start isolated feature work | superpowers:using-git-worktrees | Auto-activated when executing plans |
| Find available tools/skills | SKILLS.md + this file | Reference docs at repo root |

**HINT**: you can use `hookify` (see [Meta](#meta--setup) section) to add hooks to control behaviors specific to your project. Hooks always execute, unlike `CLAUDE.md` statements, and can be useful if you use non-default build tools or settings.

**NOTE:** Repository-specific optimization dramatically outperforms general optimization. It is a good idea to run `/claude-automation-recommender` on a project if you haven't done it, and cherry-pick ideas. Just beware it may recommend MCP for which you already have a skill, like Context7.

## Writing Code

| When I need to... | Use | How |
|---|---|---|
| Implement a feature with tests | superpowers:test-driven-development | Auto-activated when implementing features or fixing bugs |
| Build a frontend UI | frontend-design skill | Auto-activated when asked to build web components, pages, or apps |
| Add shadcn components | shadcn skill | Mention `shadcn`, or ask to add/search/fix shadcn components |
| Look up library docs | context7-cli | Say `use context7 for <library>`, or mention `ctx7`/`context7` |
| Search the web | tavily-cli | `search for X`, `look up X`, or `research X in depth` |
| Extract content from a URL | defuddle | Auto-activated when a URL is provided to read or analyze |
| Build with Claude API/SDK | claude-api | Auto-activated when code imports `anthropic` or `@anthropic-ai/sdk` |

**HINT**: On the `CLAUDE.md` of the project, explain how to run the project, which test users to use, etc. so the agent can run and verify the changes itself.
**HINT**: When working on CSS changes, encourage the agent to take screenshots when it needs to check if the change it made had the desired effect.

## Reviewing & Fixing Code

| When I need to... | Use | How |
|---|---|---|
| Review a PR | code-review plugin | `/code-review` |
| Autonomous code review | ct:code-reviewer agent | Auto-dispatched after major implementation steps |
| Find and fix all issues | ct:fix-loop | Say `review and fix`, `find and fix bugs`, or `clean up code` |
| Find edge cases and test gaps | ct:bugmagnet | Say `find holes in my tests`, `what could go wrong`, or `hunt for edge cases` |
| Security review | security-review + security-guidance | Say `security review`, `find vulnerabilities`, or `audit security`; hook auto-warns on edits |
| Find bugs in branch changes | find-bugs | Say `find bugs in my changes` or `review changes` |
| GHA workflow security | gha-security-review | Say `review my GitHub Actions` or `audit workflows` |
| Audit accessibility | ct:wcag-audit | `check accessibility` — static analysis + axe-core runtime audit |
| Check test quality with mutations | ct:mutation-testing | `run mutation testing` — diff-scoped, auto-detects language |
| Set up complexity linting | ct:lint-guard | `set up linting` — 17-language detection, strict complexity rules, Stop hook |
| Quick cleanup of changed code | simplify | `/simplify` — reviews for reuse, quality, efficiency and fixes issues |

## Refactoring & Performance

| When I need to... | Use | How |
|---|---|---|
| Refactor safely in small steps | ct:incremental-refactoring | Say `refactor`, `extract method`, `reduce nesting`, or `restructure` |
| Find duplicate code | ct:duplicate-code-detector | Say `find duplicates`, `check for copy-paste`, or `detect code clones` |
| Scan for refactoring opportunities | ct:refactor-scan agent | Auto-dispatched after TDD green phase |
| Optimize performance | ct:performance-optimization | Say `optimize performance`, `API is slow`, or `tune queries` |
| Simplify code | ct:code-simplifier agent | Say `simplify this code` or `clean up for clarity` |

## Git & Collaboration

| When I need to... | Use | How |
|---|---|---|
| Commit changes | /commit | `/commit` |
| Commit + push + open PR | /commit-push-pr | `/commit-push-pr` |
| Clean up merged branches | /clean_gone | `/clean_gone` |

## Security & Threat Modeling

| When I need to... | Use | How |
|---|---|---|
| Threat model a feature | ct:threat-modeling | Auto-activated for auth, payments, webhooks, OAuth; or say `threat model this` |
| Scan running app for vulnerabilities | ct:dast-scan | `scan for vulnerabilities` — Nuclei fast scan + ZAP deep scan |
| SAST scan on every edit | semgrep-on-edit hook | Automatic — runs after every Edit/Write, blocks on findings. Skip: `SKIP_SEMGREP=1` |
| Detect secrets before commit | gitleaks git hook | Automatic — runs on `git commit`. Skip: `SKIP_GITLEAKS=1` |

## Research & Browser

| When I need to... | Use | How |
|---|---|---|
| Deep codebase research | ct:deep-research agent | Dispatched for complex multi-file investigations |
| Systematic research | ct:research | Say `research X` — scientific methodology with evidence-based synthesis |
| Map a website's URLs | tavily-map | Say `list URLs on <domain>` or `find pages on <site>` |
| Automate browser tasks | agent-browser | Say `open <url>`, `click`, `fill form`, or any browser interaction |
| Visual UI testing / regression | agent-browser | `diff screenshot --baseline before.png`, `diff url <staging> <prod>`, viewport testing across breakpoints |
| Test a web app (QA) | dogfood | Say `dogfood this app`, `QA this`, or `exploratory test` |
| Test local web app with Playwright | webapp-testing | Say `test this page`, `take a screenshot`, or `check browser logs` |

## Memory & Context

| When I need to... | Use | How |
|---|---|---|
| Save a decision or learning | engram | `mem_save` — auto via hooks, or manual |
| Recall previous work | engram | `mem_search` — searches across all sessions |
| Reflect on session learnings | /reflect | `/reflect` — generate structured proposals, `/reflect review` — approve into CLAUDE.md, `/reflect consolidate` — CLAUDE.md health audit and pruning |
| Run a command on a schedule | loop | `/loop 5m /foo` — repeats a prompt or slash command at an interval |
| Schedule remote agents | schedule | `/schedule` — create cron-scheduled agents that run automatically |
| Navigate code semantically | gabb MCP | Say `find symbol X` or `show structure of file`; auto-used for code navigation |

## Meta / Setup

| When I need to... | Use | How |
|---|---|---|
| Scan skill for security issues | skill-scanner | Say `scan this skill`, `audit skill security`, or `check skill for injection` |
| Recommend project automations | claude-code-setup | Say `recommend automations` or `optimize my Claude Code setup` |
| Create hooks from patterns | hookify | `/hookify` or say `create a hook to prevent X` |
| Audit installed skills | ct:audit-skills | `/audit-skills` |
| Configure settings.json | update-config | Say `configure hooks`, `update settings`, or `add automation` |
| Customize keyboard shortcuts | keybindings-help | Say `rebind keys`, `change shortcuts`, or `customize keybindings` |
| Create or modify skills | skill-creator | Say `create a skill` or `modify skill` — includes evals and benchmarking |
| Reflect on session learnings | /reflect | `/reflect` — generate proposals, `/reflect review` — approve into CLAUDE.md, `/reflect consolidate` — CLAUDE.md health audit |

## Other Domains

### Databases

PostgreSQL skill from PlanetScale. Triggered on any database-related task — schema design, query tuning, indexing, operations.

### Obsidian

CLI interaction and Obsidian-flavored markdown. Triggered when working with `.md` files in Obsidian vaults or using `obsidian` CLI commands. The `obsidian-markdown` skill activates for syntax-specific tasks (wikilinks, callouts, embeds, properties).
