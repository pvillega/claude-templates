# Workflows

Task-driven guide for finding the right tool, skill, or command. Organized by what you're trying to do. For the complete inventory, see [SKILLS.md](SKILLS.md).

## Starting Work

| When I need to... | Use | How |
|---|---|---|
| Plan a new feature or change | superpowers:brainstorming → writing-plans | `/brainstorming` — explores intent, proposes approaches, writes spec, then creates plan |
| Start isolated feature work | superpowers:using-git-worktrees | Auto-activated when executing plans; creates isolated worktree |
| Find available tools/skills | SKILLS.md + this file | Reference docs at repo root |

## Writing Code

| When I need to... | Use | How |
|---|---|---|
| Implement a feature with tests | superpowers:test-driven-development | Auto-activated — writes tests first, then implementation |
| Build a frontend UI | frontend-design skill | Auto-activated for UI work — bold aesthetic, production-grade |
| Add shadcn components | shadcn skill | Ask to search registries or add components |
| Look up library docs | context7-cli or find-docs | `ctx7 library <name> <query>` or ask about a specific library |
| Search the web | tavily-search or tavily-research | `search for X` or `research X` for deep research with citations |
| Extract content from a URL | defuddle | Preferred over WebFetch — cleaner extraction, saves tokens |

## Reviewing & Fixing Code

| When I need to... | Use | How |
|---|---|---|
| Review a PR | code-review plugin | `/code-review` — 5 parallel agents check compliance, bugs, history |
| Autonomous code review | ct:code-reviewer agent | Auto-dispatched by superpowers after major steps |
| Find and fix all issues | ct:fix-loop | `review and fix` — iterates code-reviewer → fixer until clean |
| Find edge cases and test gaps | ct:bugmagnet | `find holes in my tests` or `what could go wrong` |
| Security review | security-review + security-guidance | Hook warns on edits; skill for deeper OWASP analysis |
| Find bugs in branch changes | find-bugs | `find bugs in my changes` |
| GHA workflow security | gha-security-review | `review my GitHub Actions` |

## Refactoring & Performance

| When I need to... | Use | How |
|---|---|---|
| Refactor safely in small steps | ct:incremental-refactoring | One transformation at a time, verify tests between each |
| Find duplicate code | ct:duplicate-code-detector | Uses jscpd under the hood |
| Scan for refactoring opportunities | ct:refactor-scan agent | Invoked after TDD green phase |
| Optimize performance | ct:performance-optimization | Baseline → profile → optimize cycle |
| Simplify code | ct:code-simplifier agent | `simplify this code` — clarity without changing behavior |

## Git & Collaboration

| When I need to... | Use | How |
|---|---|---|
| Commit changes | /commit | Analyzes changes, generates conventional commit message |
| Commit + push + open PR | /commit-push-pr | Full workflow: branch → commit → push → PR in one command |
| Create a branch | /create-branch | Follows naming conventions |
| Write/update a PR | /create-pr | Convention-based PR title and description |
| Iterate PR until CI passes | iterate-pr | `fix CI` — push-wait-fix loop until green |
| Clean up merged branches | /clean_gone | Removes local branches deleted on remote |
| Check pending reviews | gh-review-requests | `what PRs need my review` |

## Security & Threat Modeling

| When I need to... | Use | How |
|---|---|---|
| Threat model a feature | ct:threat-modeling | STRIDE analysis for auth, payments, APIs, webhooks |
| Django access control review | django-access-review | IDOR and authorization review |
| Django performance review | django-perf-review | N+1 queries, queryset optimization |

## Research & Browser

| When I need to... | Use | How |
|---|---|---|
| Deep codebase research | ct:deep-research agent | Complex multi-file investigations |
| Automate browser tasks | agent-browser | `agent-browser open <url>` — 50+ automation commands |
| Test a web app (QA) | dogfood | `dogfood this app` — systematic bug and UX issue hunting |
| Automate Electron apps | electron | VS Code, Slack, Discord, Figma automation |
| Interact with Slack | slack | Browser-based Slack workspace automation |

## Memory & Context

| When I need to... | Use | How |
|---|---|---|
| Save a decision or learning | engram | `mem_save` — auto via hooks, or manual |
| Recall previous work | engram | `mem_search` — searches across all sessions |
| Reflect on session learnings | /reflect | `/reflect` — generate structured proposals, `/reflect review` — approve into CLAUDE.md |
| Navigate code semantically | gabb MCP | `gabb_symbol` for definitions, `gabb_structure` for file layout |

## Meta / Setup

| When I need to... | Use | How |
|---|---|---|
| Create a new skill | /skill-creator or skill-writer | Full skill authoring workflow with evals |
| Scan skill for security issues | skill-scanner | `scan this skill` |
| Recommend project automations | claude-code-setup | `recommend automations for this project` |
| Create hooks from patterns | /hookify | Analyzes conversation for behaviors to prevent |
| Update CLAUDE.md with learnings | /revise-claude-md | End-of-session ad hoc updates |
| Audit installed skills | /audit-skills | Check for redundancy with model knowledge |

## Other Domains

### Databases

PostgreSQL, MySQL, Vitess, and Neki (sharded Postgres) skills from PlanetScale. Triggered on any database-related task — schema design, query tuning, indexing, operations.

### Obsidian

CLI interaction, Obsidian-flavored markdown, Bases database views, and JSON Canvas. Triggered when working with `.md` files in Obsidian vaults or using `obsidian` CLI commands.

### Marketing & Growth

34 skills covering SEO, copywriting, CRO, pricing, ads, email, analytics, and more from coreyhaines31/marketingskills. Each skill is triggered by name (e.g., `seo-audit`, `copywriting`, `pricing-strategy`). See [SKILLS.md](SKILLS.md) for the full list.
