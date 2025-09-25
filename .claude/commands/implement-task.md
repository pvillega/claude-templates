---
name: implement-task
description: Automated task implementation workflow with comprehensive quality gates and continuous improvement
usage: /implement-task
---

Orchestrates a complete task implementation workflow through systematic agent coordination, quality verification, and continuous learning. This command provides fully automated, high-quality task delivery from selection through deployment with comprehensive quality gates and Claude configuration optimization.

## Process Overview

This command executes a sophisticated three-phase workflow using specialized agents with safety verification and continuous improvement:

1. **Phase 1**: Intelligent task selection from docs/tasks using ultrathink analysis
2. **Phase 2**: Sequential agent orchestration with safety checks and retry logic
3. **Phase 3**: Task completion, file management, and final commit

Each phase must complete successfully before proceeding, with automatic retry mechanisms and comprehensive error handling.

## Phase 1: Intelligent Task Selection

### Objective

Use advanced reasoning to analyze all available tasks in `docs/tasks/` and select the optimal task for implementation based on priority, dependencies, and strategic value. Enhanced with parallel context gathering from related feature documentation and architectural decision records.

### Context Enrichment

Before final task selection, gather additional context using parallel subagents:

#### Parallel Subagent 1: Feature Context

```
Task: "Extract relevant feature documentation"
Subagent: general-purpose
Prompt: "Read all task files in docs/tasks/ and identify their Source and Related fields.
For each unique feature file referenced, read and summarize the key requirements,
dependencies, and architectural decisions that would affect task implementation."
```

#### Parallel Subagent 2: ADR Context (if docs/adr exists and contains files)

```
Task: "Extract relevant architectural decisions"
Subagent: general-purpose
Prompt: "If docs/adr/ directory exists and contains ADR files, identify and read
any ADRs that might be relevant to the pending tasks based on their titles and content.
Focus on decisions related to the technologies, patterns, or domains mentioned in the tasks."
```

### Execution

Uses the mcp**sequential-thinking**sequentialthinking tool with enriched context:

```
Analyze all tasks in docs/tasks/ directory with the following additional context:
[FEATURE_CONTEXT from parallel subagent 1]
[ADR_CONTEXT from parallel subagent 2 if applicable]

Select the most appropriate task to implement next considering:
- Task dependencies and prerequisites
- Priority levels and business value
- Implementation complexity and effort
- Team capacity and current sprint goals
- Risk factors and potential blockers
- Integration requirements with existing features
- Feature-level context and architectural constraints from related documentation
- Any relevant architectural decisions that might impact implementation approach

Return the selected task file path and comprehensive rationale for selection
including how the feature context and ADRs influenced the decision.
If no task is available, notify the user and terminate this process.
```

### Context Gathering Notes

The parallel subagents run ONLY when:

- There are pending tasks in docs/tasks/ to analyze
- The task files contain Source or Related field references to features
- The docs/adr directory exists and contains ADR files (optional)

This ensures minimal overhead while providing maximum context when needed for informed decision-making.

## Phase 2: Sequential Agent Orchestration with Quality Gates

### Objective

Execute a carefully orchestrated sequence of specialized agents with comprehensive safety verification and continuous learning integration.

### Agent Execution Pattern

For EACH agent in the sequence:

1. **Execute Agent** - Run the specialized agent with task-specific instructions
2. **Safety Verification** - Run safety-check-guardian to verify code integrity
3. **Retry Logic** - If safety-check-guardian detects issues, rerun the previous agent
4. **Configuration Learning** - Pass agent conversation to claude-config-optimizer
5. **Progress Validation** - Ensure successful completion before proceeding

### Sequential Agent Workflow

#### Agent 1: Task Implementation (Category-Based)

After task selection, read the task file to determine its **Category** field (UI/UX or BE).

**For Backend (BE) Tasks:**

```
Task: "Implement selected task using TDD methodology"
Subagent: tdd-code-expert
Prompt: "Implement the task from [SELECTED_TASK_FILE] following strict TDD principles and the project's CLAUDE.md guidelines.

Ensure all implementation follows project patterns and security best practices."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

**For Frontend (UI/UX) Tasks:**

```
Task: "Implement selected UI/UX task"
Subagent: ux-ui-expert
Prompt: "Implement the UI/UX task from [SELECTED_TASK_FILE] following the project's design patterns and accessibility guidelines.

Focus on creating responsive, accessible, and user-friendly interfaces that align with the project's visual design system and user experience requirements."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 2: Pre-Commit Quality Assurance

```
Task: "Comprehensive quality assurance and automated fixing"
Subagent: pre-commit-qa
Prompt: "Perform comprehensive pre-commit quality assurance on all changes made by the previous agent. Execute your complete validation workflow:

1. Run all available validation tools (linting, type checking, testing, formatting)
2. Automatically fix all issues that can be safely resolved
3. Document any issues requiring manual intervention in dated issues file
4. Ensure zero errors, warnings, or quality violations remain
5. Verify all tests pass and coverage meets requirements
"

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 3: Cynical Quality Review

```
Task: "Skeptical review demanding concrete proof of functionality"
Subagent: cynical-qa
Prompt: "Perform extremely skeptical review of all changes in the codebase. Demand concrete evidence that everything works correctly:

1. Verify all claimed functionality through testing and evidence
2. Challenge any assumptions about working features
3. Require screenshots, test outputs, and concrete proof
4. Test edge cases and failure scenarios
5. Validate that all error handling works properly
6. Ensure no functionality was broken by changes

Don't believe anything without concrete evidence. Take screenshots, run tests, examine outputs, and provide proof that the implementation actually works as claimed."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 4: Code Review and Security Analysis

```
Task: "Deep code review focusing on quality and security"
Subagent: code-review-expert
Prompt: "Perform comprehensive code review of all changes focusing on correctness, security, and maintainability."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 5: Test Enhancement and Coverage

```
Task: "Enhance test suite quality and coverage"
Subagent: test-improvement-specialist
Prompt: "Analyze and improve the test suite comprehensively.

Focus on behavior-driven testing with real dependencies and ensure comprehensive coverage of all business logic."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 6: Security Review and Documentation

```
Task: "Execute security review and document findings"
Subagent: general-purpose
Prompt: "Perform comprehensive security analysis of the codebase:

1. Execute the /security-review command to identify security vulnerabilities
2. Automatically fix all security issues that can be safely resolved
3. Create detailed documentation in docs/issues/ for any security concerns requiring manual intervention

Use the same issues file format: docs/issues/{yyyy-mm-dd}-security-review-issues.md for any items requiring manual security review."

Safety Check: Run safety-check-guardian after completion
```

#### Agent 7: Technical Documentation

```
Task: "Document changes and architectural decisions"
Subagent: technical-writer
Prompt: "Create comprehensive documentation for all changes made during task implementation.

Focus only on documenting the changes made during this implementation, not creating new documentation unnecessarily."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 8: Commit Changes

```
Task: "Commit all changes with comprehensive commit message"
Subagent: general-purpose
Prompt: "Execute the /commit command to commit all pending changes

The commit should capture the complete story of the task implementation including all fixes and improvements made."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

#### Agent 9: Merge Conflict Resolution

```
Task: "Ensure branch remains mergeable with main"
Subagent: merge-conflict-resolver
Prompt: "Ensure the current feature branch remains mergeable with the main branch.

Keep the branch in a clean, mergeable state without actually performing the merge."

Safety Check: Run safety-check-guardian after completion
Learning: Pass conversation to claude-config-optimizer
```

### Safety Check Integration

Between each agent execution:

```
Task: "Verify code integrity after agent execution"
Subagent: safety-check-guardian
Prompt: "Verify that the previous agent's changes maintain code quality and functionality.

If any issues are found, report them clearly so the previous agent can be rerun to fix them."

Retry Logic: If safety-check-guardian reports issues, rerun the previous agent with additional context about the problems found.
```

### Configuration Optimization Integration

After each agent (not safety-check-guardian):

```
Task: "Analyze agent performance and optimize configuration"
Subagent: claude-config-optimizer
Prompt: "Analyze the conversation with the [AGENT_NAME] agent and identify opportunities to improve Claude's configuration.

Create optimization recommendations in docs/claude/ directory for continuous improvement."
```

## Phase 3: Task Completion and Final Integration

### Objective

Complete the task implementation by organizing files, performing final commits, and providing comprehensive reporting.

### Execution Steps

#### Step 1: Task File Management

```
1. Create docs/tasks/implemented/ directory if it doesn't exist
2. Move the implemented task file from docs/tasks/ to docs/tasks/implemented/
3. Update any index files or references to reflect the new location
4. Preserve the original task file content and metadata
```

#### Step 2: Final Commit

```
Task: "Commit final file organization changes"
Subagent: general-purpose
Prompt: "Execute the /commit command one final time to commit all remaining changes."
```

#### Step 3: Success Reporting

Generate comprehensive success report including:

- Task implementation summary
- Total agents executed successfully
- Number of safety checks passed
- Issues documented for manual review
- Configuration optimization recommendations created
- Files modified and commits made
- Next steps and follow-up items

## Error Handling and Retry Logic

### Agent Failure Recovery

When an agent fails or safety-check-guardian detects issues:

1. **Capture Error Context** - Document specific failure details
2. **Rerun Previous Agent** - Execute with additional context about problems
3. **Maximum Retry Limit** - Maximum 3 retries per agent to prevent infinite loops
4. **Escalation Path** - Document unresolvable issues for manual intervention
5. **Safe Rollback** - Ability to revert changes if major issues occur

### Critical Failure Scenarios

Handle these scenarios gracefully:

- **Compilation Failures** - Fix automatically
- **Test Failures** - Rerun implementation agent with test failure context
- **Security Vulnerabilities** - Document in security issues file
- **Build System Issues** - Fix configuration
- **Git Conflicts** - Use merge-conflict-resolver

## Integration Notes

### Command Dependencies

This command depends on the availability of:

- `mcp__sequential-thinking__sequentialthinking` for task selection
- All specialized agents (tdd-code-expert, pre-commit-qa, etc.)
- Slash commands (/deep-review, /commit)
- Safety-check-guardian agent functionality
- Claude-config-optimizer agent functionality

### File System Requirements

- **docs/tasks/** directory with available tasks
- **docs/tasks/implemented/** directory (created if needed)
- **docs/issues/** directory for manual intervention items
- **docs/claude/** directory for optimization recommendations
- **Git repository** properly initialized and configured

### Best Practices

- **Clean repository**: Ensure no major uncommitted changes before running
- **Task readiness**: Verify selected task has clear requirements and acceptance criteria
- **Monitor progress**: Large tasks may take considerable time to complete
- **Review outputs**: Check generated issues files and optimization recommendations
- **Follow up**: Address manual intervention items promptly after completion

### Performance Considerations

- **Sequential execution**: Agents run one at a time for safety and learning
- **Comprehensive analysis**: Each phase includes deep analysis and verification
- **Multiple commits**: Creates logical commit history throughout implementation
- **Resource intensive**: May take significant time for complex tasks
- **Learning overhead**: Configuration optimization adds processing time but improves future performance

## Important Notes

- **This is a comprehensive, automated workflow**: Minimal manual intervention required
- **Quality first**: Safety checks prevent degradation of code quality
- **Continuous learning**: Each execution improves Claude's future performance
- **Full traceability**: Complete record of implementation process and decisions
- **Production ready**: All quality gates ensure deployment-ready code
- **Scalable process**: Works for tasks of varying complexity and scope

## Usage Examples

```
/implement-task
```

The command will:

1. Analyze all tasks in docs/tasks/ and select the best candidate
2. Execute the complete 9-agent workflow with safety verification
3. Document all issues requiring manual review
4. Move completed task to docs/tasks/implemented/
5. Generate comprehensive completion report

Remember: This command provides a fully automated, high-quality task implementation workflow that continuously improves while maintaining the highest standards of code quality and security. It represents the pinnacle of systematic, quality-driven development automation.
