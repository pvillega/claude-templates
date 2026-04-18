#!/usr/bin/env bash

# Claude Templates Configuration
# Shared constants used by install.sh and update.sh.

# CLI tools to install (each entry maps to tools/<name>.sh with install_<name>/uninstall_<name> functions)
readonly TOOLS=(
    "agent_browser"
    "claude_code"
    "ctx7"
    "dast"
    "engram"
    "fd"
    "gabb"
    "gh"
    "gitleaks"
    "jq"
    "jscpd"
    "rg"
    "rtk"
    "semgrep"
    "tac"
    "tavily"
    "uv"
    "wcag"
)

# Skills to install globally via skills.sh
# Simple format: "owner/repo"
# With flags:    "https://github.com/owner/repo --skill skill-name"
readonly SKILLS=(
    "vercel-labs/agent-browser --skill agent-browser"
    "https://github.com/upstash/context7 --skill context7-cli"
    "vercel-labs/agent-browser --skill dogfood"
    "getsentry/skills --skill find-bugs"
    "getsentry/skills --skill gha-security-review"
    "https://github.com/kepano/obsidian-skills --skill obsidian-cli"
    "getsentry/skills --skill security-review"
    "https://github.com/shadcn/ui --skill shadcn"
    "getsentry/skills --skill skill-scanner"
    "https://github.com/tavily-ai/skills --skill tavily-cli"
    "https://github.com/tavily-ai/skills --skill tavily-map"
)

# Claude plugin marketplaces (format: "owner/repo:name")
readonly MARKETPLACES=(
    "anthropics/claude-plugins-official:claude-plugins-official"
    "pvillega/claude-templates:claude-templates"
)

# Claude plugins to install (format: "plugin@marketplace")
readonly PLUGINS=(
    "claude-code-setup@claude-plugins-official"
    "code-review@claude-plugins-official"
    "commit-commands@claude-plugins-official"
    "ct@claude-templates"
    "frontend-design@claude-plugins-official"
    "hookify@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "skill-creator@claude-plugins-official"
    "superpowers@claude-plugins-official"
)
