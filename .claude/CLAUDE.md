# Claude Code Instructions

<system_context>
Universal entrypoint for Claude Code across all projects and repositories. This file serves as the canonical reference for development practices, workflows, and standards that apply regardless of programming language or project type. All repository-specific CLAUDE.md files should inherit and extend these principles.
</system_context>

<meta_instructions>
**How to use this file:**

- This is your primary guidance system - consult before starting any task
- Follow the `<paved_path>` patterns religiously - they represent battle-tested approaches
- Use `<file_map>` to navigate to specific guidance for detailed implementation
- Apply `<core_principles>` to all work, regardless of language or domain
- Check `<critical_notes>` for zero-tolerance rules that cannot be broken
  </meta_instructions>

<paved_path>

## CANONICAL WORKFLOW

**Research → Plan → Implement → Validate**

1. **Research First** - "Let me research the codebase and create a plan before implementing"
2. **Test-Driven Development** - Every line of production code written in response to failing test
3. **Explicit Over Implicit** - Clear, readable code that expresses intent
4. **Security by Default** - Every decision considers security implications
5. **Documentation as Code** - Keep documentation current and accurate
   </paved_path>

<quick_start>
**When starting any new task:**

1. Read relevant sections from `<file_map>` below
2. Identify language-specific config file if applicable
3. Apply TDD workflow from @shared/coding-practices.md
4. Follow security practices from @shared/coding-practices.md
5. Use appropriate commands from `<commands>` section
6. Update documentation when changes are complete
   </quick_start>

<core_principles>

## UNIVERSAL TRUTHS

**Type Safety:**

- Never use dynamic/any types - always be explicit
- Runtime validation for all external data boundaries
- Fail fast with clear error messages

**Code Quality:**

- Functions do one thing well (single responsibility)
- Early returns to reduce nesting complexity
- No magic numbers or strings - use named constants
- Delete code, don't comment it out

**Security:**

- Validate all inputs, sanitize all outputs
- Never commit secrets or credentials
- Use parameterized queries, never string concatenation
- Apply least privilege principle

**Testing:**

- Behavior-driven testing with real dependencies when possible
- Test the public API, not internal implementation
- One assertion per test, clear test names
- Tests document expected business behavior
  </core_principles>

<file_map>

## Core Guidelines

- @shared/coding-practices.md - **Comprehensive development philosophy and practices**
- @shared/extraction-guidelines.md - **Task and feature extraction patterns**
- @shared/mcp-usage.md - **MCP server usage patterns and automation**

## Available Tools

- **Commands** - Available via `/` prefix, auto-loaded from @commands/
- **Agents** - Specialized agents for complex tasks, auto-loaded from @agents/
- **Language Guides** - Add to project-specific CLAUDE.md files as needed
  </file_map>

<language_guides>
Language guides should be added to project-specific CLAUDE.md files
</language_guides>

<workflow>
## STANDARD DEVELOPMENT FLOW

1. **Understand Requirements** - Ask clarifying questions for ambiguities
2. **Research Codebase** - Search for existing patterns and architecture
3. **Write Failing Test** - Define expected behavior first
4. **Implement Minimally** - Just enough code to make test pass
5. **Refactor If Valuable** - Improve code structure while keeping tests green
6. **Run Quality Checks** - Linters, formatters, type checkers
7. **Update Documentation** - Keep CLAUDE.md and docs current
8. **Commit Changes** - Clear commit messages following conventional format

**INCREMENTAL COMMIT STRATEGY:**

- **ALWAYS** make small, atomic commits after each working change
- Each commit should compile and pass all tests
- Use the `/commit` command for standard commits
- Commit after: tests pass, linters pass, single feature working
- This creates a clear, reviewable history for debugging and rollbacks

**For Complex Features:**

- Break into smaller, deliverable increments
- Use TodoWrite tool for progress tracking
- Consider parallel agents for independent work
- Validate end-to-end functionality
  </workflow>

<common_patterns>

## Language-Agnostic Patterns

**Error Handling:**

- Custom error types with context and error codes
- Result types for recoverable errors (Either/Option patterns)
- Exception chaining to preserve stack traces
- Validation at system boundaries

**Data Validation:**

- Schema-first development (Zod, Pydantic, etc.)
- Runtime type checking at API boundaries
- Early validation with clear error messages
- Separate DTOs from domain models

**Testing Patterns:**

- Factory functions for test data creation
- Test containers for real database testing
- Parameterized/table tests for edge cases
- Integration tests over unit tests when practical

**Code Organization:**

- Feature-based modules, not technical layers
- Clear separation of concerns
- Dependency injection for testability
- Pure functions in core business logic
  </common_patterns>

<anti_patterns>

## NEVER DO THIS

**Code Smells:**

- Functions longer than 20-30 lines
- Nested if/else statements (use early returns)
- Magic numbers or unclear variable names
- Commented-out code (delete it)

**Type/Safety Issues:**

- Using `any`, `interface{}`, `Object` types
- Ignoring compiler warnings or linter errors
- Catching exceptions without handling them
- Mutation of shared state

**Security Violations:**

- Hardcoded credentials or secrets
- SQL injection via string concatenation
- Trusting user input without validation
- Exposing internal error details to users

**Testing Mistakes:**

- Testing implementation instead of behavior
- Mocking what you don't own
- Ignoring test failures or flaky tests
- Writing tests after implementation (not TDD)
  </anti_patterns>

<critical_notes>

## ZERO-TOLERANCE RULES

**TDD Enforcement:**

- **NEVER** write production code without failing test first
- **NEVER** skip the refactor assessment step
- **NEVER** commit broken tests or ignore test failures

**Type Safety:**

- **NEVER** use dynamic/any types without explicit justification
- **NEVER** ignore TypeScript/mypy/compiler warnings
- **ALWAYS** validate external data at boundaries

**Security:**

- **NEVER** commit secrets, even to private repositories
- **NEVER** use dynamic SQL or command construction
- **ALWAYS** sanitize data before output/display

**Code Quality:**

- **NEVER** leave dead code or TODO comments in production
- **ALWAYS** run formatters and linters before committing
- **NEVER** suppress warnings without fixing root cause

**Workflow:**

- **ALWAYS** research before implementing
- **ALWAYS** update documentation with discoveries
- **NEVER** make breaking changes without migration strategy
  </critical_notes>

<mcp_usage>

## PROACTIVE MCP SERVER USAGE

**Context7 + DeepWiki** - For any library or framework mentioned:

- Auto-trigger documentation lookup for current best practices
- Use Context7 for official docs, DeepWiki for OSS project insights
- Store findings in Memory for future reference

**Sequential-Thinking** - For complex decisions or architecture:

- Multi-step problem analysis and solution design
- Algorithm design and optimization planning
- Systematic debugging of complex issues

**Memory** - For knowledge persistence:

- Store architectural decisions and rationale
- Record debugging insights and solutions
- Build cumulative project knowledge

**Playwright** - For UI validation (mandatory):

- Screenshot verification after any UI changes
- Visual regression testing for styling changes
- Proof of bug fixes through before/after captures

**Perplexity-Ask** - For current information:

- Latest library versions and breaking changes
- Recent security advisories and best practices
- Current compatibility and support status

_Note: Detailed MCP usage patterns are in @shared/mcp-usage.md_
</mcp_usage>
