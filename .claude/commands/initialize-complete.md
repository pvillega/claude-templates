---
name: initialize-complete
description: Complete project documentation initialization - enriches root CLAUDE.md, creates module documentation, then commits all changes
usage: /initialize-complete
---

Orchestrates a complete project documentation initialization by sequentially running project enrichment, module documentation creation, and committing all changes. This command provides a comprehensive setup for Claude Code project documentation.

## Process Overview

This command executes three sequential phases using specialized subagents:

1. **Phase 1**: Project enrichment and root CLAUDE.md optimization
2. **Phase 2**: Module-specific documentation creation
3. **Phase 3**: Comprehensive commit of all documentation changes

Each phase must complete successfully before proceeding to the next.

## Phase 1: Project Enrichment

### Objective

Update and optimize the root CLAUDE.md file with current project analysis, patterns, and configurations.

### Execution

Uses the Task tool to invoke a `general-purpose` subagent that executes the `/enrich-project` command:

```
Execute the /enrich-project command
```

## Phase 2: Module Documentation

### Objective

Create concise, targeted CLAUDE.md files for each semantically relevant module in the project.

### Execution

Uses the Task tool to invoke a `general-purpose` subagent that executes the `/init-modules` command:

```
Execute the /init-modules command
```

## Phase 3: Comprehensive Commit

### Objective

Commit all changes made during the enrichment and module documentation phases.

### Execution

Uses the Task tool to invoke a `general-purpose` subagent that executes the `/commit` command:

```
Execute the /commit command
```

## Integration Notes

### Command Dependencies

This command depends on the availability of:

- `/enrich-project` command functionality
- `/init-modules` command functionality
- `/commit` command functionality

### Best Practices

- **Run in clean repository**: Ensure no major uncommitted changes before running
- **Review generated documentation**: Check outputs after completion for accuracy
- **Follow up with team**: Share new documentation structure with collaborators
- **Update regularly**: Re-run when project structure or tech stack changes significantly

### Performance Considerations

- **Large codebases**: May take several minutes to analyze and document
- **Complex projects**: Module detection and documentation creation scales with project size
- **Resource usage**: Requires reading and analyzing entire codebase structure

## Important Notes

- **This is a comprehensive operation**: Touches many files and may take time
- **Not reversible easily**: Creates significant documentation structure
- **Team coordination**: Notify team members about new documentation approach
- **Maintenance required**: Documentation should be updated as project evolves
- **Quality over quantity**: Focus is on useful, actionable documentation, not comprehensive coverage

Remember: This command establishes the documentation foundation for effective Claude Code usage across your entire project. The investment in setup pays dividends in improved development velocity and team collaboration.
