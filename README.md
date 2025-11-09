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
- **devbranch** - Automated branch management for parallel feature development. Creates isolated git clones for each branch in sibling directories.
- **.devcontainer/** - VS Code devcontainer configuration for setting up a complete development environment
- **.claude/** - Claude Code configuration and MCP server documentation
- **.mcp.json** - Default MCP servers configured

## Language-Specific Tools

The `.devcontainer/` directory contains modular setup scripts for additional language-specific development tools:

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

## Parallel Branch Development

The `devbranch` script enables working on multiple branches simultaneously in isolated directories, perfect for parallel feature development without interference.

### Quick Start

```bash
# Create a branch directory
./devbranch feature-authentication

# List all branch directories
./devbranch --list

# Clean up when done
./devbranch --clean feature-authentication
```

### How It Works

- Creates sibling directories: `/path/to/project-<branch>/`
- Full git clone per branch (complete isolation)
- Automatic branch checkout (creates new branch if needed)
- Opens in VS Code automatically
- No security concerns (agents cannot access other branches)

### Requirements

- git (required)
- VS Code CLI (`code` command, optional but recommended)

Run `./devbranch --help` to verify dependencies and see all available options.

## Relevant Claude Configuration

Read [Claude_Capabilities.md](./Claude_Capabilities.md) for a list of capabilities added to Claude with this tool.

## Manual Setup (Without Devcontainer)

If you prefer not to use devcontainer, you can set up the Claude development environment directly on your macOS or Linux machine.

**NOTE:** This is **NOT** recommended, as you risk your environment to be compromised, or data to be exfiltrated. But if you are using an isolated VM or similar, this may be safe, and simpler to use across repositories.

### Prerequisites

**macOS:**
- [Homebrew](https://brew.sh) (required)
- Node.js and npm
- Python 3.8+ (for pipx)

**Linux:**
- Node.js and npm
- Python 3.8+ (for pipx)
- sudo access for package installation

### Running the Setup

From the repository root, run:

```bash
bash .devcontainer/setup-claude-dev.sh
```

This script will:
- Detect your OS (macOS or Linux) and install appropriate system packages
- Install and configure direnv (adds hooks to `~/.bashrc` and `~/.zshrc`)
- Auto-allow `.envrc` in the current directory
- Install pipx and uv
- Install Claude Code globally
- Install jscpd (copy-paste detector)
- Install Claude Code plugins (superpowers, playwright-skill)
- Configure `~/.claude.json` settings

### Optional Language-Specific Tools

After running the main setup, you can optionally install language-specific development tools:

```bash
# For Rust development
bash .devcontainer/setup-rust.sh

# For Go development
bash .devcontainer/setup-go.sh
```

**Note:** You may need to restart your shell or source your shell configuration file (e.g., `source ~/.zshrc`) for direnv and other changes to take effect.

**Note:** You still need to use `sync-claude-folders.sh` to sync files to your repository, so that you get the relevant `.claude` files. But doing this, you don't need to start a devcontainer to develop.

## Acknowledgements

This repository was inspired by and incorporates patterns from:

- **[SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)**: A comprehensive framework for enhanced Claude Code capabilities
- **[Superpowers](https://github.com/obra/superpowers/)**: A comprehensive skills library of proven techniques, patterns, and workflows for AI coding assistants
- **[ClaudeLog](https://claudelog.com)**: community-driven best practices and patterns
