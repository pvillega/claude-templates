# Claude Templates

Tools and templates for new Claude Code repos. To be copied to other repositories to facilitate Claude Code tasks.

## Requirements

- Some environment variables must be defined for Claude Code MCP to work. See envrc.example for the list.
- You must provide a valid build bash script `buildAll.sh`. This script is supported to run all relevant build steps: build, lint, test, security scan, formatting, etc. It will be used by Claude Code to verify changes.
-Running **sync-claude-folders.sh** requires `jq` installed


NOTE: By default MCP that require Env vars are disabled, to both avoid errors and to preserve context. Enable them as needed.


## Contents

The repository has the following files:

- **sync-claude-folders.sh** - A bash script for syncing .claude folders between repositories using rsync. Features colorized output, dry-run mode, error handling, and automatic creation of destination directories.
- **.devcontainer/** - VS Code devcontainer configuration for setting up a complete development environment
- **.claude/** - Claude Code configuration and MCP server documentation
- **.mcp.json** - Default MCP servers configured

## Language-Specific Tools

The `.devcontainer/` directory contains modular setup scripts for additional language-specific development tools:

- **setup-python.sh** - Installs Python `uv` package manager via pipx
- **setup-rust.sh** - Installs Rust cargo tools (cargo-binstall, cargo-edit, difftastic, etc.)
- **setup-go.sh** - Installs GolangCI-Lint for Go code quality checking

These scripts can be run after initial devcontainer setup to install additional tools for your specific language needs

## How to Use

Use the included `sync-claude-folders.sh` script to copy configuration files from this repository to your target repository:

```bash
# Basic usage
./sync-claude-folders.sh /path/to/claude-templates /path/to/your-repo

# Dry-run mode (preview changes without applying)
./sync-claude-folders.sh -d /path/to/claude-templates /path/to/your-repo

# Show help
./sync-claude-folders.sh --help
```

**What gets synced:**
- `.claude/` directory (Claude Code configuration and MCP documentation)
- `.devcontainer/` directory (VS Code devcontainer and language setup scripts)
- `.envrc.example` file (environment variable template)
- `.mcp.json` file (MCP config, merged via jq with destination)

## Acknowledgements

This repository was inspired by and incorporates patterns from:

- **[SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)**: A comprehensive framework for enhanced Claude Code capabilities
- **[ClaudeLog](https://claudelog.com)**: community-driven best practices and patterns
