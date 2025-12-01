---
description: "Save current session knowledge to Serena memory for future reference"
allowed-tools:
  - Task
  - AskUserQuestion
  - mcp__serena__write_memory
  - mcp__serena__list_memories
---

# Save Session Memory

Capture valuable knowledge from the current session and persist it as a Serena memory for future sessions.

## Your Task

### Step 1: Gather Session Content from User

Use `AskUserQuestion` to collect two pieces of information in a single call:

**Question 1: Focus Area**
```
Header: "Focus area"
Question: "What type of knowledge should this memory capture?"
Options:
  - label: "Decisions made", description: "Choices, trade-offs, and their rationale"
  - label: "Problems solved", description: "Issues encountered and how they were resolved"
  - label: "Both", description: "Capture both decisions and solutions"
multiSelect: false
```

**Question 2: Topic and Details**
```
Header: "Session topic"
Question: "Describe the main topic and what you want to remember from this session"
Options:
  - (User types custom response via "Other" option)
multiSelect: false
```

**Important**: The user's response to Question 2 is the primary content source. It should include:
- What feature/task was being worked on
- Key decisions or solutions to preserve
- Any context future sessions should know

If the user provides only a short topic (e.g., "auth refactor"), prompt them to elaborate:
- "Could you provide more details about what was decided or solved?"

### Step 2: Dispatch Subagent for Memory Formatting

Use the Task tool to format the user's input into a structured memory document:

```
Task Tool Parameters:
- subagent_type: "general-purpose"
- description: "Format session memory content"
- prompt: |
    You are creating a Serena memory document to preserve session knowledge.

    ## User's Input
    - **Focus**: {{focus_area - decisions/solutions/both}}
    - **Topic and Details**: {{user's description from Question 2}}

    ## Your Task

    Create a well-structured memory document based on the focus area.

    ### If focus is "Decisions made":

    ```markdown
    # {{Topic}} - Decisions

    ## Context
    [1-2 sentences explaining what prompted these decisions]

    ## Key Decisions
    - **{{Decision 1}}**: What was decided and why
    - **{{Decision 2}}**: What was decided and why
    [Add more as relevant from user's input]

    ## Rationale
    [Brief summary of trade-offs considered and reasoning]
    ```

    ### If focus is "Problems solved":

    ```markdown
    # {{Topic}} - Solutions

    ## Context
    [1-2 sentences explaining what problem was being addressed]

    ## Problems & Solutions

    ### {{Problem 1}}
    - **Issue**: Description of the problem
    - **Solution**: How it was resolved
    - **Key insight**: What to remember for next time

    [Add more problem/solution pairs as relevant]
    ```

    ### If focus is "Both":

    ```markdown
    # {{Topic}}

    ## Context
    [Brief background on the session's work]

    ## Decisions Made
    - **{{Decision 1}}**: What and why
    - **{{Decision 2}}**: What and why

    ## Problems Solved

    ### {{Problem 1}}
    - **Issue**: Description
    - **Solution**: Resolution
    - **Insight**: Key learning

    ## For Future Reference
    - Key things to remember when returning to this topic
    - Gotchas or pitfalls to avoid
    ```

    ## Guidelines
    - Output ONLY the formatted markdown content, no explanations
    - Be concise but preserve all important technical details from user's input
    - Include specific file paths, code patterns, or configurations if mentioned
    - Maximum 500 words
    - If user's input is vague, structure what's available meaningfully
```

### Step 3: Generate Memory Name

Auto-generate the memory name from the user's topic:

1. **Extract topic**: Take the main topic from user's response to Question 2
2. **Generate slug**:
   - Take first 30 characters of topic
   - Convert to lowercase
   - Replace spaces with hyphens
   - Remove special characters (keep only a-z, 0-9, hyphen)
   - Trim trailing hyphens
3. **Create full name**: `session-{{YYYY-MM-DD}}-{{topic-slug}}`
   - Example: `session-2025-11-25-auth-refactor`
   - Example: `session-2025-11-25-api-design`

4. **Check for collisions**:
   - Call `mcp__serena__list_memories` to get existing memory names
   - If generated name exists, append `-2`, `-3`, etc.
   - Example: `session-2025-11-25-auth-refactor-2`

### Step 4: Write Memory to Serena

Call `mcp__serena__write_memory` with:
- `memory_file_name`: The auto-generated name from Step 3
- `content`: The formatted markdown from Step 2 (subagent output)

### Step 5: Confirm Success

Display a completion message:

```
Memory Saved
════════════════════════════════════════════

Name:  {{memory_name}}
Focus: {{decisions/solutions/both}}

Preview:
────────────────────────────────────────────
{{First 300 characters of saved content}}...
────────────────────────────────────────────

Access this memory in future sessions:
  read_memory("{{memory_name}}")

List all memories:
  list_memories()
```

## Output Format

### Initial Prompt

```
📝 Save Session Memory
═══════════════════════════════════════════

This command captures session knowledge and saves it as a Serena memory
for future reference.

You'll be asked:
1. What type of knowledge to capture (decisions, solutions, or both)
2. Topic and details to remember

[AskUserQuestion appears here]
```

### Success Output

```
✅ Memory Saved
═══════════════════════════════════════════

Name:  session-2025-11-25-auth-refactor
Focus: Both (decisions and solutions)

Preview:
───────────────────────────────────────────
# Auth Refactor

## Context
Redesigned authentication flow to support OAuth2 providers...
───────────────────────────────────────────

Access in future sessions: read_memory("session-2025-11-25-auth-refactor")
```

## Edge Cases

| Case | Handling |
|------|----------|
| User provides minimal input | Subagent structures what's available; memory may be brief |
| User cancels question | Exit gracefully: "No memory saved. Run /ct:save-session-memory when ready." |
| Name collision exists | Auto-append `-2`, `-3`, etc. to generated name |
| Subagent returns empty | Display error: "Could not generate memory content. Please provide more details." |
| Very long user input | Truncate to 2000 chars before sending to subagent |

## Notes

- **Zero setup required**: Works immediately without any configuration
- **User-driven content**: You decide what's valuable to preserve
- **Fresh context for formatting**: Subagent has full token budget for clean output
- **Safe to run multiple times**: Each memory gets unique timestamped name
- **Memories persist**: Available via Serena tools in all future sessions
- **Edit later**: Use `edit_memory()` to update content if needed
