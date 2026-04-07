# Workflows

Task-driven guide for finding the right tool, skill, or command. Organized by what you're trying to do. For the complete inventory, see [SKILLS.md](SKILLS.md).

## Starting Work

| When I need to... | Use | How |
|---|---|---|
| Plan a new feature or change | superpowers:brainstorming → writing-plans | `/brainstorming`, or ask to plan/design a feature |
| Start isolated feature work | superpowers:using-git-worktrees | Auto-activated when executing plans |
| Find available tools/skills | SKILLS.md + this file | Reference docs at repo root |

## Writing Code

| When I need to... | Use | How |
|---|---|---|
| Implement a feature with tests | superpowers:test-driven-development | Auto-activated when implementing features or fixing bugs |
| Build a frontend UI | frontend-design skill | Auto-activated when asked to build web components, pages, or apps |
| Add shadcn components | shadcn skill | Mention `shadcn`, or ask to add/search/fix shadcn components |
| Look up library docs | context7-cli | Say `use context7 for <library>`, or mention `ctx7`/`context7` |
| Search the web | tavily-search or tavily-research | `search for X`, `look up X`, or `research X in depth` |
| Extract content from a URL | defuddle | Auto-activated when a URL is provided to read or analyze |

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

## Research & Browser

| When I need to... | Use | How |
|---|---|---|
| Deep codebase research | ct:deep-research agent | Dispatched for complex multi-file investigations |
| Automate browser tasks | agent-browser | Say `open <url>`, `click`, `fill form`, or any browser interaction |
| Test a web app (QA) | dogfood | Say `dogfood this app`, `QA this`, or `exploratory test` |

## Memory & Context

| When I need to... | Use | How |
|---|---|---|
| Save a decision or learning | engram | `mem_save` — auto via hooks, or manual |
| Recall previous work | engram | `mem_search` — searches across all sessions |
| Reflect on session learnings | /reflect | `/reflect` — generate structured proposals, `/reflect review` — approve into CLAUDE.md |
| Navigate code semantically | gabb MCP | Say `find symbol X` or `show structure of file`; auto-used for code navigation |

## Meta / Setup

| When I need to... | Use | How |
|---|---|---|
| Scan skill for security issues | skill-scanner | Say `scan this skill`, `audit skill security`, or `check skill for injection` |
| Recommend project automations | claude-code-setup | Say `recommend automations` or `optimize my Claude Code setup` |
| Create hooks from patterns | hookify | `/hookify` or say `create a hook to prevent X` |
| Update CLAUDE.md with learnings | ct:revise-claude-md | `/revise-claude-md` |
| Audit installed skills | ct:audit-skills | `/audit-skills` |

## Other Domains

### Databases

PostgreSQL skill from PlanetScale. Triggered on any database-related task — schema design, query tuning, indexing, operations.

### Obsidian

CLI interaction and Obsidian-flavored markdown. Triggered when working with `.md` files in Obsidian vaults or using `obsidian` CLI commands.

