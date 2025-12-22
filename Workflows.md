# Claude Code Workflows

This guide outlines how to effectively use the Claude Code setup, organizing workflows by Commands, Agents, and Skills.

## 1. First Session Setup

Use this workflow when opening a project for the first time.

1.  **Initialise Project**
    *   **Command:** `/ct:init`
    *   **Action:** Analyses codebase structure, generates `.claude/CLAUDE.md`, sets up Serena onboarding, and creates project memories.
2.  **Index Codebase (Optional)**
    *   **Command:** `/ct:repo-index`
    *   **Action:** Creates `PROJECT_INDEX.md`. Recommended for repositories with 1000+ files for token-efficient context.
3.  **Setup Shell Aliases (Optional)**
    *   **Command:** `/ct:discover-aliases`
    *   **Action:** Detects tool replacements (e.g., `cat` → `bat`, `grep` → `rg`) and generates documentation for Claude to bypass them.

*Note: After initialisation, Serena automatically loads relevant memories at the start of every session.*

## 2. Feature Development Workflow

When building a feature, use the [Superpowers](https://github.com/obra/superpowers) commands in sequence.

### The Lifecycle
1.  **Planning:** in `planning` mode run either `/superpowers:brainstorm "ultrathink, <prompt>"` or `/superpowers:write-plan "ultrathink, use tdd, use context 7, use parallel subagents: <prompt>"`
2.  **Context Clearing:** `/clear` (Recommended before implementation)
3.  **Implementation:** in `bypass permissions` mode `/superpowers:execute-plan "use parallel agents to implement @<path>, use context 7, use tdd"`

NOTE: agents miss things. After development, asking them to review if everything from the plan is implemented is a good idea. Asking it to "Review the code" may discover areas to improve.

### Decision Guide

| Current State | Recommended Action |
| :--- | :--- |
| **Rough idea**, need to explore | `/superpowers:brainstorm` |
| **Clear requirements**, need a plan | `/superpowers:write-plan` |
| **Have a plan**, ready to code | `/superpowers:execute-plan` |
| **Quick fix**, no plan needed | Describe the change directly (Natural Language) |

### Scheduling work

One issue with working with agents is context switching. While the agent works, we may be in a situation in which we need to wait for a while until we need to answer questions or review code. This means we often run multiple agents in parallel.

Some recommendations:
- keep track of prompts. I personally keep a file with all the different prompts pending to run, so that I know where am I and what comes next after context switching. Also helps if agents crash.
- worktrees are useful if you can ensure no overlap. If not, may be better to run 2 separate projects that 2 agents in the same project.
- for loosely coupled work, you can have 1 agent generating plan files while another is implementing something.


## 3. Memory Management

### Session Memory (Short-term)
Save valuable insights from the current session to persistent storage.
*   **Command:** `/ct:save-session-memory`
*   **Prompts:** Focus area (Decisions/Problems), Topic, and Details.
*   **Action:** Persists to Serena memory (accessible via `read_memory()` in future).

### Serena Memory System (Long-term)
Interact with project-level knowledge using natural language.

*   **To Create Memory:**
    > "Write a memory called 'authentication_flow' describing how auth works..."
    > "Write a memory about this refactoring for future reference..."
*   **To Read Memory:**
    > "Read the authentication_flow memory before we modify the login system..."

## 4. Investigation & Research

### Systematic Debugging
Trigger specific debugging skills using these natural language phrases.

*   **General Debugging:**
    *   **Trigger:** "I have a bug..." or "This test is failing..."
    *   **Loads:** `superpowers:systematic-debugging`
*   **Deep Stack Errors:**
    *   **Trigger:** "Trace this error back..."
    *   **Loads:** `superpowers:root-cause-tracing`
*   **Timing/Flakiness:**
    *   **Trigger:** "This test is flaky..." or "Race condition..."
    *   **Loads:** `superpowers:condition-based-waiting`
*   **Verification:**
    *   **Trigger:** "I think it's fixed..."
    *   **Loads:** `superpowers:verification-before-completion`

### Research & Discovery

| Goal | Approach | Action |
| :--- | :--- | :--- |
| **Methodology Guide** | Command | `/ct:research` |
| **Deep External Research** | Agent | `@agent-deep-research` (structured, multi-source, citations) |
| **Codebase Exploration** | Subagent | Use `Explore` subagent via Task tool |

*Examples for Exploration:*
*   "Explore how authentication works in this codebase"
*   "Find all usages of the PaymentService"


## 5. Quality Assurance

### Code Review
Choose the right tool based on the complexity of the review.

*   **Quick Self-Check:**
    *   **Trigger:** "Review my code..." or "Before I merge..."
    *   **Loads:** `superpowers:requesting-code-review` (Skill)
*   **Feedback Integration:**
    *   **Trigger:** "I got this review feedback..."
    *   **Loads:** `superpowers:receiving-code-review` (Skill)
*   **Critical/Large PRs:**
    *   **Use:** `pr-review-assistant` (Agent)
    *   **When:** Multi-concern PRs.

### Refactoring Cycle
1.  **Discovery:** Use `duplicate-code-detector` skill or `refactor-scan` agent.
2.  **Implementation:**
    *   **Trigger:** "Refactor this..."
    *   **Loads:** `incremental-refactoring`
3.  **Assessment:** Run `refactor-scan` agent again.

### Performance Optimization
1.  **Trigger:** "This is slow...", "Optimise...", or "Improve latency..."
2.  **Loads:** `performance-optimization`
3.  **Workflow:** Profile $\rightarrow$ Optimise $\rightarrow$ Measure $\rightarrow$ Document.

## 6. Domain-Specific Workflows

Specific keywords trigger specialized enforcement skills to ensure safety and best practices.

### Backend & Infrastructure
*   **API Implementation:**
    *   **Trigger:** "Implement this API...", "REST endpoint...", "Backend integration..."
    *   **Loads:** `backend-reliability-enforcer`
*   **DevOps:**
    *   **Trigger:** "Deploy...", "CI/CD pipeline...", "Kubernetes..."
    *   **Loads:** `deployment-automation-enforcer`

### Frontend Development
*   **Quality Audit:**
    *   **Trigger:** "Accessibility audit...", "WCAG...", "Lighthouse..."
    *   **Loads:** `frontend-production-quality`
*   **Browser Automation:** Use Playwright MCP tools directly (`mcp__playwright__*`).

### Security & Compliance
*   **Threat Modeling :**
    *   **Trigger:** "Authentication...", "File upload...", "External API..."
    *   **Loads:** `threat-modeling`
*   **Audits:**
    *   **Trigger:** "SOC2 audit...", "GDPR compliance..."
    *   **Loads:** `security-compliance-audit`
*   **Validation:**
    *   **Trigger:** "Validate at every layer..."
    *   **Loads:** `superpowers:defense-in-depth`

## 7. Architecture & Design

*   **Architectural Decisions:**
    *   **Trigger:** "Design the architecture for..." or "Should we use X or Y..."
    *   **Loads:** `architecture-discipline`
*   **Edge Case Analysis:**
    *   **Trigger:** "What could break...", "All edge cases...", "Bulletproof..."
    *   **Loads:** `edge-case-discovery`

## 8. Meta-Workflows (Extending Claude)

### Creating New Capabilities
*   **Create Agent:**
    *   **Trigger:** "Create an agent for..." or "Automate this workflow..."
    *   **Loads:** `meta-agent` skill
*   **Create Skill:**
    *   **Trigger:** "Create a skill for..." or "Write a new skill..."
    *   **Loads:** `superpowers:writing-skills`

### Testing Capabilities
*   **List Skills:** `/ct:meta:skills-check`
*   **Test Skill:** `/ct:meta:test-skill <name>`
*   **Test Agent:** `/ct:meta:test-agent <name>`
*   **Test All:** `/ct:meta:test-all-skills`

### Confidence Check
*   **Trigger:** "Am I ready to..." or "Should I proceed..."
*   **Loads:** `confidence-check`


## 9. Completion Protocol

Before considering any task finished:

1.  **Verification (Mandatory):**
    *   **Trigger:** "I'm done..." or "This is complete..."
    *   **Loads:** `superpowers:verification-before-completion`
2.  **Testing:** Run `buildAll.sh` (or project equivalent).
3.  **Documentation:** `/ct:grammar-check`
4.  **Save Knowledge:** `/ct:save-session-memory`
5.  **Commit:** `/ct:commit`


## Appendix: Tool Reference Table

### Quick Reference: Common Tasks

| I want to... | Use This | Type |
| :--- | :--- | :--- |
| **Setup** | | |
| Initialise project | `/ct:init` | Command |
| Index large codebase | `repo-index` | Agent |
| **Feature Dev** | | |
| Brainstorm | `/superpowers:brainstorm` | Command |
| Plan | `/superpowers:write-plan` | Command |
| Execute | `/superpowers:execute-plan` | Command |
| **Investigation** | | |
| Fix a bug | "I have a bug..." | Skill |
| Explore codebase | `Explore` | Subagent |
| Research topic | `/ct:research` | Command |
| **Quality** | | |
| Code review | `superpowers:requesting-code-review` | Skill |
| Critical PR review | `pr-review-assistant` | Agent |
| Find refactors | `refactor-scan` | Agent |
| **Security** | | |
| Security analysis | "Authentication..." | Skill |
| Payment logic | "Payment..." | Skill |

### Serena Tools

| Tool | Purpose | Cost |
| :--- | :--- | :--- |
| `get_symbols_overview` | First step for any file | Low |
| `find_symbol` | Locating specific code | Low-Med |
| `find_referencing_symbols` | Pre-refactor check | Medium |
| `insert_after_symbol` | Adding new methods | Low |
| `replace_symbol_body` | Modifying code | Medium |
| `rename_symbol` | Global renaming | Med-High |
| `read_memory` | Retrieving context | Low |
| `write_memory` | Storing insights | Low |
