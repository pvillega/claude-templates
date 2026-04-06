# Claude Templates

> **WARNING: This project is designed for use in sandboxed environments only.**

A curated setup for Claude Code combining **plugins** (from the Claude marketplace) and **skills** (from [skills.sh](https://skills.sh)) with sandbox safety guards. Designed for YOLO mode (`--dangerously-skip-permissions`).

## Quick Start

```bash
git clone https://github.com/pvillega/claude-templates.git
cd claude-templates

# Installs plugins, skills, and default settings
./install.sh

# Run Claude (added as an alias to your ~/.bashrc or ~/.zshrc)
cl
```

To update all installed plugins, skills, and tools to their latest versions:

```bash
./update.sh
```

To completely remove everything installed by this project:

```bash
./uninstall.sh
```

If you do not use Bash or Zsh, you can set up the alias manually:

```bash
alias cl='SLASH_COMMAND_TOOL_CHAR_BUDGET=30000 claude --dangerously-skip-permissions'
```

### Prerequisites

The installer requires the following to be available before running:

- **curl** — for downloading installers
- **npm** — for installing Node.js-based tools and skills
- **[Homebrew](https://brew.sh)** — package manager for CLI tools (macOS and Linux)

Homebrew is available on both macOS and Linux. To install:

```bash
# macOS and Linux
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

For Linux-specific instructions, see [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux).

## About Safety

Using agents without restrictions on tools poses some dangers. It could impact files outside your workspace, potentially damaging your system. Or it can [exfiltrate](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) data.

As a consequence, using Claude Code from your local environment by itself is risky. At this point in time there are multiple alternatives, so this template doesn't enforce any preferences.

What it does, though, it to restrict very dangerous commands (like `git push --force`)

## Setup

The [install.sh](install.sh) script installs plugins, skills, sandbox settings, and marketplace configuration. Run it from the repository root:

```bash
./install.sh
```

Use `--clean` for a fresh install when you want to remove stale configuration that might not be properly overridden. The `--dry-run` flag lets you preview what would be deleted before committing.

### API Keys

Tavily requires an API key. You can configure it via:

- **Tavily CLI login** (recommended): Run `tvly login --api-key $(echo $TAVILY_API_KEY)` to authenticate using your API key.
- **Shell export**: Add `export TAVILY_API_KEY=...` to your shell profile.

## Plugins

Plugins are installed from the [Claude marketplace](https://claude.com/plugins). They provide commands, agents, skills, and MCP server configurations.

| Plugin | Description | Trigger |
|--------|-------------|---------|
| [Superpowers](https://claude.com/plugins/superpowers) | Structured software development: TDD, debugging, brainstorming, subagent code review | `/brainstorming`, `/execute-plan` |
| [Frontend Design](https://claude.com/plugins/frontend-design) | Generates production-grade frontend interfaces with bold aesthetic choices | Automatic |
| [Code Review](https://claude.com/plugins/code-review) | PR analysis with five specialized agents checking compliance, bugs, and git history | `/code-review` |
| [CLAUDE.md Management](https://claude.com/plugins/claude-md-management) | Audits and improves CLAUDE.md files, captures learnings from sessions | `audit my CLAUDE.md`, `/revise-claude-md` |
| [Security Guidance](https://claude.com/plugins/security-guidance) | Warns about security vulnerabilities when editing files (injection, XSS, etc.) | Automatic (pre-tool hook) |
| [Skill Creator](https://claude.com/plugins/skill-creator) | Create, evaluate, improve, and benchmark skills | `/skill-creator` |
| [Commit Commands](https://claude.com/plugins/commit-commands) | Automates commit messages, pushing, and PR creation with style analysis | `/commit`, `/commit-push-pr` |
| [Claude Code Setup](https://claude.com/plugins/claude-code-setup) | Recommends tailored automations (MCP servers, skills, hooks, subagents) | `recommend automations for this project` |
| [PR Review Toolkit](https://claude.com/plugins/pr-review-toolkit) | Code quality analysis with six specialized agents for comments, tests, types, etc. | Natural language PR review requests |
| [Hookify](https://claude.com/plugins/hookify) | Create custom hooks from natural language — regex pattern matching, no coding required | `/hookify Warn me when...` |
| [Engram](https://github.com/Gentleman-Programming/engram) | Persistent memory for AI coding agents — survives session ends and compactions via SQLite + FTS5. **Note:** the installer disables Claude's built-in auto-memory (`autoMemoryEnabled: false`) to avoid duplication — engram's selective retrieval and automatic decay make it the better choice. Re-evaluate once Claude's planned "dream" consolidation feature ships. | `mem_save`, `mem_search`, `mem_context` (MCP tools) |

Additionally, the **ct** plugin (from this repo) provides custom skills and agents:

### ct Skills

| Skill | Description | Trigger |
|-------|-------------|---------|
| bugmagnet | Systematic test coverage analysis and edge case discovery using a comprehensive checklist | `"find holes in my tests"`, `"what could go wrong"`, `"edge cases"` |
| fix-loop | Iterative review-fix cycle: runs code-reviewer, fixes critical findings, verifies tests, repeats until clean (max 5 iterations) | `"review and fix"`, `"find and fix bugs"` |
| duplicate-code-detector | Detects copy-paste duplication in codebases | Automatic |
| incremental-refactoring | Guided refactoring in small, testable steps | Refactoring tasks |
| performance-optimization | Performance analysis and optimization guidance | Performance tasks |
| threat-modeling | STRIDE-based threat modeling for security analysis | Security review tasks |
| audit-skills | Audits all installed skills for redundancy with built-in model knowledge | `/audit-skills` (manual only) |

### ct Agents

| Agent | Description |
|-------|-------------|
| code-reviewer | Autonomous code review agent focused on seeking disconfirmation — analyses for best practices, security, performance, FP patterns, and test coverage gaps. Invokes bugmagnet for edge case discovery. |
| fixer | Applies targeted minimal fixes for critical code review findings, verifies tests pass, reverts on failure. Used by the fix-loop skill. |
| code-simplifier | Reviews code for simplification opportunities |
| deep-research | Deep codebase research and analysis |
| refactor-scan | Scans for refactoring opportunities |

Some skills and agents were adapted from [channingwalton/dotfiles](https://github.com/channingwalton/dotfiles).

## CLI Tools

The installer sets up the following CLI tools, used by Claude Code for enhanced capabilities:

| Tool | Description | Install Method |
|------|-------------|----------------|
| [Claude Code](https://claude.ai) | Anthropic's AI coding assistant | Native installer |
| [jq](https://jqlang.github.io/jq/) | JSON processor for config merging | Homebrew |
| [fd](https://github.com/sharkdp/fd) | Fast `find` alternative (aliased as `find`) | Homebrew |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast `grep` alternative (aliased as `grep`) | Homebrew |
| [rtk](https://github.com/rtk-ai/rtk) | Token-optimized CLI proxy (60-90% savings) | Homebrew |
| [gh](https://cli.github.com/) | GitHub CLI for PR/issue management | Homebrew |
| [Tavily CLI](https://cli.tavily.com/) | AI-optimized web search | Native installer |
| [jscpd](https://github.com/kucherenko/jscpd) | Copy/paste detection | npm |
| [Context7 CLI](https://github.com/upstash/context7) | Library documentation fetcher | npm |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | AI-first browser automation (50+ commands) | npm + browser install |
| [Engram](https://github.com/Gentleman-Programming/engram) | Persistent memory for AI agents (SQLite + FTS5) | Homebrew |
| [Gabb](https://github.com/gabb-software/gabb-cli) | Local code indexer for semantic code understanding (MCP server) | Homebrew |

Tools are configured in the `TOOLS` array in [config.sh](config.sh). Each tool has an install, update, and uninstall script in the [tools/](tools/) directory.

## Skills

Skills are installed globally from [skills.sh](https://skills.sh) using the `skills` CLI. They provide reusable capabilities that enhance Claude's behavior.

| Skill | Description | Trigger |
|-------|-------------|---------|
| [context7-cli](https://skills.sh/upstash/context7/context7-cli) | Fetches up-to-date library documentation and manages AI coding skills | `ctx7 library <name> <query>`, `ctx7 docs <id> <query>` |
| [shadcn](https://skills.sh/shadcn/ui/shadcn) | Manages shadcn/ui components: search registries, add components, view docs, preview changes | Component lifecycle commands |
| [tavily-ai/skills](https://skills.sh/tavily-ai/skills) | Collection of 11 skills: search, research, extract, crawl, map, and best practices for Tavily web search | `search`, `research`, `extract`, `crawl` |
| [marketingskills](https://skills.sh/coreyhaines31/marketingskills) | Collection of 33 marketing skills: SEO audit, copywriting, content strategy, pricing, analytics, ads, email sequences, CRO, and more | Skill-specific triggers (e.g., `seo-audit`, `copywriting`) |
| [postgres](https://skills.sh/planetscale/database-skills/postgres) | PostgreSQL database management, queries, schema design, and optimization | Database-related tasks |
| [agent-browser](https://skills.sh/vercel-labs/agent-browser/agent-browser) | AI-first browser automation for navigation, form filling, screenshots, and data extraction | `agent-browser open <url>`, `agent-browser snapshot` |
| [dogfood](https://skills.sh/vercel-labs/agent-browser/dogfood) | Internal testing skill for agent-browser | Automatic |
| [security-review](https://skills.sh/getsentry/skills/security-review) | Security-focused code review | Security review tasks |
| [find-bugs](https://skills.sh/getsentry/skills/find-bugs) | Bug detection and analysis | Bug hunting tasks |
| [gha-security-review](https://skills.sh/getsentry/skills/gha-security-review) | GitHub Actions security review | GHA workflow tasks |
| [skill-scanner](https://skills.sh/getsentry/skills/skill-scanner) | Scans and evaluates installed skills | Skill management tasks |
| [obsidian-cli](https://skills.sh/kepano/obsidian-skills/obsidian-cli) | Obsidian vault interaction via the official CLI (v1.12+) — file ops, search, daily notes, tags, properties, sync | `obsidian` CLI tasks |
| [obsidian-markdown](https://skills.sh/kepano/obsidian-skills/obsidian-markdown) | Obsidian-flavored markdown conventions — wiki links, callouts, embeds, block references | Writing Obsidian markdown |
| [defuddle](https://skills.sh/kepano/obsidian-skills/defuddle) | Clean content extraction from web pages using Obsidian's web clipper engine | Web content extraction |

Skills are installed globally (`-g`) so they are available in all projects. To add more skills, edit the `SKILLS` array in [config.sh](config.sh) or install manually:

```bash
npx skills add <owner/repo> -g --all
```

Browse available skills at [skills.sh](https://skills.sh).

## LSP Integration

Claude Code supports Language Server Protocol for code intelligence (go-to-definition, find-references, diagnostics, etc.). **This is highly recommended** for effective code navigation and analysis.

Install the plugin and language server for each language you use:

### Official Plugins (claude-plugins-official)

| Language | Plugin Install | Language Server Install |
|----------|---------------|------------------------|
| TypeScript/JS | `claude plugin install typescript-lsp@claude-plugins-official` | `npm install -g typescript-language-server typescript` |
| Python | `claude plugin install pyright-lsp@claude-plugins-official` | `npm install -g pyright` |
| Go | `claude plugin install gopls-lsp@claude-plugins-official` | `go install golang.org/x/tools/gopls@latest` |
| Rust | `claude plugin install rust-analyzer-lsp@claude-plugins-official` | `rustup component add rust-analyzer` |
| C/C++ | `claude plugin install clangd-lsp@claude-plugins-official` | `brew install llvm` (or `sudo apt install clangd`) |
| Java | `claude plugin install jdtls-lsp@claude-plugins-official` | `brew install jdtls` (requires JDK 21+) |
| C# | `claude plugin install csharp-lsp@claude-plugins-official` | `dotnet tool install --global csharp-ls` |
| Ruby | `claude plugin install ruby-lsp@claude-plugins-official` | `gem install ruby-lsp` (requires Ruby 3.0+) |
| PHP | `claude plugin install php-lsp@claude-plugins-official` | `npm install -g intelephense` |
| Kotlin | `claude plugin install kotlin-lsp@claude-plugins-official` | `brew install kotlin-language-server` |
| Lua | `claude plugin install lua-lsp@claude-plugins-official` | `brew install lua-language-server` |
| Swift | `claude plugin install swift-lsp@claude-plugins-official` | Included with Xcode (or `brew install swift`) |

### Community / Third-Party Plugins

These languages have LSP servers but no official Claude plugin. Use third-party marketplaces or community plugins instead.

| Language | Plugin Source | Language Server Install | Notes |
|----------|-------------|------------------------|-------|
| Scala | [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps) (Metals) | `cs install metals` | Requires [Coursier](https://get-coursier.io): `brew install coursier/formulas/coursier && cs setup`. JDK 11+ needed. |
| Haskell | [m4dc4p/claude-hls](https://github.com/m4dc4p/claude-hls) (community) | `ghcup install hls` | Requires [GHCup](https://www.haskell.org/ghcup/): `curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org \| sh`. HLS must match your GHC version. |
| OCaml | [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps) or [boostvolt/claude-code-lsps](https://github.com/boostvolt/claude-code-lsps) | `opam install ocaml-lsp-server` | Requires [opam](https://opam.ocaml.org): `brew install opam && opam init`. Install in the same opam switch as your project. |
| Unison | No plugin available yet | `brew install unisonweb/unison/ucm` | LSP is built into UCM. Run `ucm lsp` to start the language server. Feature coverage is still evolving. |

To use third-party marketplaces, add them first:

```bash
claude plugin marketplace add Piebald-AI/claude-code-lsps
claude plugin marketplace add boostvolt/claude-code-lsps
```

After installing, restart Claude Code. Verify with: check `~/.claude/debug/latest` for `Total LSP servers loaded: N`.

## Agent Teams

The sandbox settings enable the experimental **Agent Teams** feature (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`), which allows Claude to coordinate multiple agents working together on complex tasks.

## Status Line

A custom status line script (`templates/statusline.sh`) is installed to `~/.claude/statusline.sh` and configured via `sandbox-settings.json`. It displays up to three lines:

| Line | Content | Details |
|------|---------|---------|
| 1 | `📁 folder │ 🌿 branch │ 💭 mode` | Current directory, git branch, thinking mode |
| 2 | `Model │ ▓▓▓░░░░░ 15% [1M] │ 5h: 12% │ 7d: 8%` | Model name, context usage bar, 5-hour and 7-day rate limits |
| 3 | `🤖 agent │ 🌳 worktree (branch)` | Only shown when an agent or worktree is active |

The context bar and rate limits are color-coded: green (< 70%), yellow (70–89%), red (90%+).

## Shell Alias Awareness

A `SessionStart` hook in `~/.claude/settings.json` automatically loads your shell aliases into Claude's context at the start of every session. This prevents issues where Claude uses a command (e.g., `grep`) that is aliased to a different tool (e.g., `rg`) with incompatible flags.

The `install.sh` script adds a line to your `~/.bashrc` and/or `~/.zshrc` that exports aliases to `~/.claude/shell-aliases.txt` on every new shell. The hook then reads this file at session start.

**If you use a different shell** (fish, nushell, etc.), add the equivalent of `alias > ~/.claude/shell-aliases.txt` to your shell's config file so the aliases are kept up to date.

## Other Contents

- **[install.sh](install.sh)** - Setup script (marketplace, plugins, skills, sandbox settings)
- **[update.sh](update.sh)** - Updates all installed plugins, skills, and npm packages
- **[uninstall.sh](uninstall.sh)** - Removes all plugins, skills, tools, settings, and shell aliases
- **[plugins/ct/](plugins/ct/)** - The local Claude Code plugin (skills, commands, agents)
- **[templates/CLAUDE.md](templates/CLAUDE.md)** - Template project instructions
- **[templates/statusline.sh](templates/statusline.sh)** - Custom status line (folder, branch, model, context, rate limits, agent/worktree)
- **[sandbox-settings.json](sandbox-settings.json)** - Sandbox security configuration
- **[mise.toml.example](mise.toml.example)** - Environment variable template for API keys

## Acknowledgements

This repository was inspired by and incorporates patterns from:

- **[SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)**: A comprehensive framework for enhanced Claude Code capabilities
- **[Superpowers](https://github.com/obra/superpowers/)**: A comprehensive skills library of proven techniques, patterns, and workflows for AI coding assistants
- **[channingwalton/dotfiles](https://github.com/channingwalton/dotfiles)**: Code review, fixer, and fix-loop agent/skill patterns
- **[gojko/bugmagnet-ai-assistant](https://github.com/gojko/bugmagnet-ai-assistant)**: Edge case discovery and test coverage gap analysis methodology (bugmagnet skill)
