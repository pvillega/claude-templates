#!/usr/bin/env bash

# Claude Templates Configuration
# Shared constants used by install.sh and update.sh.

# CLI tools to install (each entry maps to tools/<name>.sh with install_<name>/uninstall_<name> functions)
readonly TOOLS=(
    "claude_code"
    "jq"
    "fd"
    "rg"
    "rtk"
    "gh"
    "tavily"
    "jscpd"
    "ctx7"
    "agent_browser"
    "engram"
    "gabb"
)

# Skills to install globally via skills.sh
# Simple format: "owner/repo"
# With flags:    "https://github.com/owner/repo --skill skill-name"
readonly SKILLS=(
    "coreyhaines31/marketingskills"
    "https://github.com/upstash/context7 --skill context7-cli"
    "https://github.com/shadcn/ui --skill shadcn"
    "https://github.com/tavily-ai/skills"
    "https://github.com/planetscale/database-skills --skill postgres"
    "vercel-labs/agent-browser --skill agent-browser"
    "vercel-labs/agent-browser --skill dogfood"
    "getsentry/skills --skill security-review"
    "getsentry/skills --skill find-bugs"
    "getsentry/skills --skill gha-security-review"
    "getsentry/skills --skill skill-scanner"
    "https://github.com/kepano/obsidian-skills --skill obsidian-cli"
    "https://github.com/kepano/obsidian-skills --skill obsidian-markdown"
    "https://github.com/kepano/obsidian-skills --skill defuddle"
)

# Claude plugin marketplaces (format: "owner/repo:name")
readonly MARKETPLACES=(
    "pvillega/claude-templates:claude-templates"
)

# Claude plugins to install (format: "plugin@marketplace")
readonly PLUGINS=(
    "superpowers@claude-plugins-official"
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "commit-commands@claude-plugins-official"
    "skill-creator@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
    "hookify@claude-plugins-official"
    "ct@claude-templates"
)
