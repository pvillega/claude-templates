---
name: extract-features-tasks
description: Extract features and tasks from requirements document - orchestrates feature extraction, then task extraction, then commits all changes
usage: /extract-features-tasks <file-path>
---

Orchestrates feature and task extraction from a requirements document by sequentially running feature extraction, task extraction for new files, and committing all changes. This command provides a streamlined workflow for decomposing requirements into actionable PRs and tasks.

## Process Overview

This command executes five sequential phases using specialized agents:

1. **Phase 1**: Capture initial state of docs/features directory
2. **Phase 2**: Feature extraction from input document
3. **Phase 3**: Identify newly created feature files
4. **Phase 4**: Task extraction from each new feature file
5. **Phase 5**: Commit all generated files

Each phase must complete successfully before proceeding to the next.

## Phase 1: Capture Initial State

### Objective

Record the current state of the docs/features directory to later identify new files created by the feature extraction process.

### Execution

Use the LS tool to capture the initial state:

```
List all files in docs/features/ directory (create if needed)
```

## Phase 2: Feature Extraction

### Objective

Extract features from the input requirements document and decompose them into independent, deliverable PR specifications.

### Execution

Uses the Task tool to invoke a `feature-extraction-expert` subagent:

```
Read the content of the specified file path and pass it to the feature-extraction-expert agent to extract features and create PR specifications under docs/features/
```

## Phase 3: Identify New Files

### Objective

Compare the current state of docs/features directory with the initial state to identify newly created PR specification files.

### Execution

Use the LS tool again to capture the new state and identify differences:

```
List all files in docs/features/ directory and compare with initial state to identify new files
```

## Phase 4: Task Extraction

### Objective

Extract implementation tasks from each newly created PR specification file.

### Execution

For each new PR specification file identified in Phase 3, use the Task tool to invoke a `task-extraction-agent` subagent:

```
Pass the content of each new PR specification file to the task-extraction-agent to extract tasks and create task files under docs/tasks/
```

## Phase 5: Commit All Changes

### Objective

Commit all files generated during the feature and task extraction processes.

### Execution

Uses the Task tool to invoke a `general-purpose` subagent that executes the `/commit` command:

```
Execute the /commit command to commit all generated files
```

## Integration Notes

### Command Dependencies

This command depends on the availability of:

- `feature-extraction-expert` agent functionality
- `task-extraction-agent` agent functionality
- `/commit` command functionality

### Input Requirements

- **File Path**: Must be a valid path to a requirements document
- **File Content**: Document should contain extractable features and requirements. Document may have markdown references to images in a folder, which must be accessible by the agents.
- **Directory Structure**: docs/ folder and/or relevant subfolders will be created if they don't exist

### Best Practices

- **Clean repository**: Ensure no major uncommitted changes before running
- **Valid requirements**: Input file should contain clear requirements or specifications
- **Review generated files**: Check outputs after completion for accuracy
- **Follow up**: Review PR specifications and tasks for completeness

### Performance Considerations

- **Large documents**: May take several minutes to process comprehensive requirements
- **Multiple features**: Processing time scales with number of features extracted
- **File operations**: Includes file system operations for state comparison

## Important Notes

- **This is a comprehensive operation**: Creates feature specifications and implementation tasks
- **Sequential execution**: Each phase depends on the previous phase completing successfully
- **Automatic commit**: All generated files are committed at the end
- **No manual intervention**: Fully automated from input to commit
- **Specific workflow**: Designed for this exact sequence with minimal flexibility

## Usage Examples

```
/extract-features-tasks requirements.md
/extract-features-tasks docs/product-spec.md
/extract-features-tasks planning/feature-requirements.txt
```

Remember: This command transforms a requirements document into actionable PR specifications and implementation tasks, then commits everything automatically. It's designed for efficiency and consistency in requirement decomposition workflows.
