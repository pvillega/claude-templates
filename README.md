# Claude Templates

The repository provides a series of scripts to help set up a tested configuration of Claude Code tools, including commands, skills, etc.

The aim of the repository is to use Claude Code in YOLO mode (`--dangerously-skip-permissions`) for a better agentic experience. All the configuration and safety guards are aimed to work with this mode enabled, although they can be used without the flag.

**IMPORTANT:** I may modify this project while trying new approaches with Claude. This may break things. I recommend forking or obtaining a local copy for stability.

### Quick Start

```bash
./setup.sh

./check-config.sh /path/to/your/repo
```

## About Safety

Using agents without restrictions on tools poses some dangers. It could impact files outside your workspace, potentially damaging your system. Or it can [exfiltrate](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) data.

As a consequence, using Claude Code from your local environment by itself is risky. Currently, there are three popular ways of using Claude Code to combat these issues:

- [DevContainers](https://containers.dev): these sandbox the codebase and agent in a Docker container. This safeguards your computer if you do not use privileged mode or mount external volumes. Restricting traffic can be more complicated, depending on your needs. They can be used in [GitHub Codespaces](https://github.com/features/codespaces) for extra isolation. The downside is that you need to re-authenticate on each new container, and they take a long time to start. Not ideal if you want to use many branches in parallel.
- [Claude Code for Web](https://claude.com/blog/claude-code-on-the-web): it provides an isolated sandbox environment to run your code, and reads your local `.claude` folder. It doesn't support `plugins` and doesn't work well with `mcp`, unless you have them deployed remotely via some gateway.
- [Claude Code for Desktop](https://code.claude.com/docs/en/desktop): it provides an isolated sandbox environment to run your code, using a worktree to isolate changes from the code, and it runs on your local machine. This means that it reads your `~/.claude` folder and settings.
- A [Sandbox runtime](https://github.com/anthropic-experimental/sandbox-runtime): like the linked one, this is an experimental tool provided by Anthropic. It provides the advantages of using a container, without the drawbacks. Unfortunately, this tool is not fully compatible with Claude as it stands, because it denies file operations to `/dev/ttys*`, breaking `raw mode` necessary for Claude Code.
- Use [Claude Sandbox](https://code.claude.com/docs/en/sandboxing), which is a more limited version of the [Sandbox runtime](https://github.com/anthropic-experimental/sandbox-runtime), but it is provided by Claude itself.

This project uses the `Claude Sandbox` approach. Ideally, we could use the full sandbox but, as mentioned, it is not compatible with Claude Code. The advantage of doing this is that it also seamlessly works for [Claude Code for Desktop](https://code.claude.com/docs/en/desktop), as they will share configuration.

Please note this approach mitigates some risks, but not all. `Claude Sandbox` doesn't restrict domains by whitelisting, unlike some of the alternatives. Use of Docker, MCPs, and third-party libraries means there is a risk of data exfiltration if they are compromised. Claude can still read your environment variables and share keys.

This means that the sandbox will protect you from some issues (a process reading your SSH configuration or AWS credentials on disk), but good practices are still necessary: do not use production credentials or data in your development environments. Do not use unknown or unsafe Docker images. Do not run random MCP servers.

## Setup

To use the project, run the command [setup.sh](setup.sh). This will configure your Claude instance with some extra plugins, commands, and other helpers. Use `--clean` for a fresh install when you want to remove stale configuration that might not be properly overridden. The `--dry-run` flag lets you preview what would be deleted before committing.

After running the command, you will need to configure a couple of environment variables with your own keys, so that some MCP servers work.

**NOTE**: For proper Serena MCP use with the programming language in your codebase, check [this list](https://oraios.github.io/serena/01-about/020_programming-languages.html) to see if you need a specific LSP available.

### In a project

When you want to work with Claude in a project, use [check-config.sh](check-config.sh) to verify it has all the necessary setup. It will list any changes needed for compliance with the assumptions in this configuration (more on this below).

Once the checks report all is ready, navigate to the project folder and run `cl.sh` (a file added to your PATH by the setup step). This will start a Claude Code agent inside the sandbox, with the flag `--dangerously-skip-permissions` set.

The first time you open a project, you should run `/ct:init` to properly initialise Claude and Serena. This will create some memories in Serena, like:
- `project_overview` - Tech stack, architecture summary
- `code_style_conventions` - Naming patterns, formatting rules
- `suggested_commands` - Build, test, deploy commands

For each new session, a hook will ensure that Serena initialises itself and loads relevant memories automatically.

### Git Worktrees

When using [git worktrees](https://git-scm.com/docs/git-worktree) for parallel development, gitignored files (like `.claude/`, `.serena/`, `.env`) are not shared between worktrees. Use `sync-worktree.sh` to copy these files:

```bash
# From any directory
./sync-worktree.sh ../feature-branch

# Or with absolute path
./sync-worktree.sh /path/to/worktree
```

The script:
- Detects main worktree automatically
- Shows preview of files to sync (new, identical, conflicts)
- Prompts before overwriting existing files
- Creates backups when overwriting conflicts

**Custom patterns**: Create `.worktreeinclude` in your project root to add patterns beyond the defaults (.claude/, .serena/, .env*, .envrc, .tool-versions, etc.).

### Required configuration

The following is assumed when working with a project:

- There is a valid build bash script `buildAll.sh`. This script runs all relevant build steps: build, lint, test, security scan, formatting, etc. It will be used by Claude Code to verify changes work.

- Claude Code has autocompact disabled and sandbox enabled

- (Optional) Any environment keys needed by MCP (for example, Tavily) are present. If that is not the case, it is better to remove the MCP servers from `~/.claude.json`, to avoid them causing errors.

## Contents

The repository has the following files:

- **setup.sh** - Main setup script that installs Claude Code, plugins, and dependencies system-wide (macOS/Linux).
- **check-config.sh** - Validates that a project folder is properly configured for Claude Code usage, checking for required tools and optional API keys.
- **sync-worktree.sh** - Syncs gitignored development files (.claude/, .serena/, .env*, etc.) from main worktree to target worktrees.
- **bin/** - Executable directory containing cl.sh launcher script.
- **.claude/** - Claude Code configuration directory containing instructions, MCP documentation, custom agents, skills, and slash commands.
- **.mcp.json** - Default MCP server configuration.
- **sandbox-settings.json** - Claude Code sandbox security configuration that blocks access to sensitive directories and environment files.
- **[Claude_Capabilities.md](./Claude_Capabilities.md)** - Comprehensive guide to available commands, agents, skills, and tool integrations provided by this configuration.
- **[Workflows.md](./Workflows.md)** - Recommended workflows for common tasks

## Acknowledgements

This repository was inspired by and incorporates patterns from:

- **[SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)**: A comprehensive framework for enhanced Claude Code capabilities
- **[Superpowers](https://github.com/obra/superpowers/)**: A comprehensive skills library of proven techniques, patterns, and workflows for AI coding assistants
- **[ClaudeLog](https://claudelog.com)**: Community-driven best practices and patterns
