# Claude Templates

Tools and templates for new Claude Code repos. To be copied to other repositories to facilitate Claude Code tasks.

## Requirements

- Some environment variables must be defined for Claude Code MCP to work. See envrc.exmaple for the list. You should disable any MCP you haven't configured to avoid inconsistencies.
- You must provide a valid build bash script `buildAll.sh`. This script is supported to run all relevant build steps: build, lint, test, security scan, formatting, etc. It will be used by Claude Code to verify changes.

## Contents

The repository has the following files:

- **sync-claude-folders.sh** - A bash script for syncing .claude folders between repositories using rsync. Features colorized output, dry-run mode, error handling, and automatic creation of destination directories.

- **.devcontainer/** - VS Code devcontainer configuration for setting up a complete development environment:
  - **devcontainer.json** - Container configuration with Go, Rust, Node.js, Docker-in-Docker, Git, GitHub CLI, and various VS Code extensions for development
  - **postCreate.sh** - Post-creation setup script that installs additional tools including Claude Code CLI and GolangCI-Lint

## How to Use

There are several ways you can copy files from repository A (this repo) to your existing repository B:

### 1. **Manual Copy via Git (Recommended)**

```bash
# In your local copy of repo B
git remote add repoA https://github.com/yourusername/repoA.git
git fetch repoA
git checkout repoA/main -- path/to/files
# Or to get all files:
git checkout repoA/main -- .
git commit -m "Add files from repo A"
```

### 2. **Using Git Subtree**

If you want to maintain a connection to repo A:

```bash
# In repo B
git subtree add --prefix=subfolder/ https://github.com/yourusername/repoA.git main --squash
```

### 3. **Download and Copy**

- Download repo A as a ZIP file
- Extract and copy the files you need
- Add them to repo B and commit
