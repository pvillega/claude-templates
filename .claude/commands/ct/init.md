---
description: "Initialize Claude and Serena for a project (always regenerates everything)"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - mcp__serena__initial_instructions
  - mcp__serena__onboarding
  - mcp__serena__list_memories
  - mcp__serena__write_memory
  - mcp__serena__activate_project
---

# Initialize Project

Initialize Claude and Serena for the current project. Always regenerates CLAUDE.md and Serena memories.

## Your Task

### Step 0: Initialize CLAUDE.md

Analyze the codebase and generate/update `.claude/CLAUDE.md` with project-specific instructions.

1. **Analyze Codebase Structure**:
   - Use `Glob` to scan for common patterns: `**/*.{ts,js,py,go,rs,java}`, `**/package.json`, `**/Cargo.toml`, `**/go.mod`, etc.
   - Identify: primary language(s), frameworks, build system, test framework

2. **Detect Code Patterns**:
   - Look for existing style guides, linter configs (`.eslintrc`, `prettier.config`, `ruff.toml`)
   - Check for CI/CD configs (`.github/workflows/`, `Jenkinsfile`, `.gitlab-ci.yml`)
   - Note any existing `CONTRIBUTING.md` or `DEVELOPMENT.md`

3. **Generate CLAUDE.md**:
   - Write to `.claude/CLAUDE.md` with:
     * Tech stack summary (languages, frameworks, key dependencies)
     * Build commands (detected from package.json scripts, Makefile, etc.)
     * Code style conventions (from linter configs or observed patterns)
     * Testing commands and patterns
     * Any project-specific instructions found in documentation
   - Format using clear sections with XML-style tags for structure

4. **Report**:
   - Note what was detected and written
   - Continue to Step 1

### Step 1: Initialize Serena

1. **Load Serena Instructions**:
   - Call `mcp__serena__initial_instructions`

2. **Run Onboarding**:
   - Call `mcp__serena__onboarding`
   - Follow the returned instructions

3. **Verify Memories**:
   - Call `mcp__serena__list_memories`

### Step 2: Report Status

Display initialization summary:

```
Project Initialization Complete
================================

CLAUDE.md:
  [x] Generated .claude/CLAUDE.md

Serena:
  [x] Onboarding complete

Memories:
  - project_overview
  - code_style_conventions
  - suggested_commands

Ready to work!
```

## Notes

- **Always regenerates**: Both CLAUDE.md and Serena memories are regenerated every run. Safe to run anytime to refresh.

- **Memory persistence**: Serena memories persist in `.serena/memories/` across sessions.

- **Manual trigger**: This command is manually invoked, not automatic at session start.
