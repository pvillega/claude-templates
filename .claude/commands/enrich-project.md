---
name: enrich-project
description: Analyze repository and create a concise, focused CLAUDE.md targeting 200-250 lines with project-specific patterns and deduplicated content
usage: /enrich-project
---

Analyze the current repository to detect programming languages, frameworks, and tools, then , IF NEEDED, create or update the CLAUDE.md file with a focused, deduplicated reference guide that captures project-specific patterns, conventions, and critical commands without redundancy or generic best practices.

## Process

### Phase 1: Repository Analysis

Analyze the project structure to detect:

1. **Programming Languages** - Scan file extensions and count usage
   - JavaScript/TypeScript (.js, .ts, .jsx, .tsx)
   - Python (.py, .pyx)
   - Go (.go)
   - Rust (.rs)
   - Java (.java)
   - Scala (.scala, .sc)
   - C/C++ (.c, .cpp, .h, .hpp)
   - And others based on file presence

2. **Configuration Files** - Identify tools and frameworks
   - package.json, yarn.lock, pnpm-lock.yaml (Node.js ecosystem)
   - requirements.txt, pyproject.toml, poetry.lock (Python)
   - go.mod, go.sum (Go)
   - Cargo.toml, Cargo.lock (Rust)
   - build.sbt, project/ (Scala)
   - pom.xml, build.gradle (Java/JVM)
   - Dockerfile, docker-compose.yml (Containerization)
   - .github/workflows/ (GitHub Actions)

3. **Development Tools** - Check for existing configurations
   - Linters: .eslintrc, .flake8, .golangci.yml, clippy.toml
   - Formatters: .prettierrc, .black, rustfmt.toml
   - Type checkers: tsconfig.json, mypy.ini
   - Testing: jest.config.js, pytest.ini, cargo test configs
   - Build tools: webpack.config.js, vite.config.ts, Makefile

### Phase 2: CLAUDE.md Assessment

Read the existing CLAUDE.md file from the repository root (create if missing) and assess:

1. **Current Content** - What sections already exist
2. **Missing Sections** - What should be added based on detected tech stack
3. **Outdated Information** - Commands or practices that may need updating
4. **Language Coverage** - Which detected languages lack proper documentation

### Phase 3: Content Creation (Target: around 200 Lines Total)

Create (or update) a focused CLAUDE.md with these concise sections:

#### Project Context (20-30 lines)

```xml
<system_context>
One paragraph: project purpose, domain, current status
</system_context>

<tech_stack>
## Core Stack (5-8 key items only)
- Language: Version and role (not generic description)
- Framework: Version and specific usage
- Database/Storage: Type and purpose
- Key Services: Only project-specific tools
</tech_stack>
```

#### Project-Specific Configuration (40-60 lines)

Focus ONLY on what's unique to this project:

#### Workflow & Commands (30-40 lines)

```xml
<workflow>
## Core Commands (deduplicated, 5-8 total)
- [project-specific commands only]

## Quality Gates
- [specific test command] + [lint command] + [typecheck]
- Pre-commit: [actual hooks if configured]
</workflow>
```

#### Quick Reference (40-60 lines)

```xml
<patterns>
## File Structure
/src/[key-directories] - [purpose]
/[config-files] - [specific settings]
/[important-folders] - [role in project]

## Critical Notes
- [Project-specific gotchas and warnings]
- [Non-obvious conventions used]
- [Important architectural decisions]
</patterns>
```

## CRITICAL RULES FOR CONCISENESS

### Deduplication Requirements

- **Commands appear ONLY ONCE** - Never repeat npm run dev, lint, test in multiple sections
- **No redundant sections** - Merge similar content, don't create separate "Build Commands", "Development Commands", "Quality Gates"
- **Reference, don't implement** - Point to existing files instead of showing full code examples
- **Project-specific only** - Skip generic best practices

### Content Guidelines

- **Target around 200 lines total** - Be ruthlessly concise
- **Only update if needed** - If the file already has what we need, don't add more data
- **Focus on uniqueness** - What makes THIS project different from a standard setup
- **Actionable content only** - Remove explanatory text and tutorials
- **Use file references** - "See /src/utils/auth.ts for pattern" vs full code blocks

### Phase 4: Validation and Cleanup

1. **Length Check** - Must be around 200 lines total, not 300+
2. **Deduplication Audit** - Each command/concept appears exactly once
3. **Reference Validation** - File paths and examples exist in the project
4. **Content Focus** - Only project-specific information, no generic advice

## Expected Outcomes

**Concise CLAUDE.md (around 200 lines) with:**

1. **Project-specific patterns** - Unique architecture and conventions
2. **Deduplicated commands** - Each command appears once, organized by workflow
3. **File references** - Points to actual code examples instead of generic templates
4. **Critical decisions** - Architectural choices and non-obvious conventions
5. **Working setup** - All commands tested and functional

**Length Target:**

- Project Context: ~25 lines
- Tech Stack: ~40 lines
- Commands/Workflow: ~35 lines
- Patterns/Structure: ~50 lines
- Critical Notes: ~30 lines
- **Total: around 200 lines maximum**

## Usage

```bash
/enrich-project  # Creates/updates concise CLAUDE.md for current project
```

**Integration:** Use after major tech stack changes or when CLAUDE.md becomes outdated. Follow with `/commit` to save changes.

**Result:** A focused reference guide that avoids redundancy and generic advice, targeting quick developer onboarding with project-specific insights.
