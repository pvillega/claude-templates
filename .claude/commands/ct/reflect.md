---
description: "Task reflection and validation using Serena MCP analysis capabilities"
argument-hint: "[optional: scope - 'task'|'info'|'done'|'full']"
allowed-tools:
  - mcp__serena__think_about_task_adherence
  - mcp__serena__think_about_collected_information
  - mcp__serena__think_about_whether_you_are_done
  - mcp__serena__read_memory
  - mcp__serena__write_memory
  - mcp__serena__list_memories
  - TodoRead
  - TodoWrite
---

# Task Reflection and Validation

Perform comprehensive task reflection and validation using Serena MCP analysis tools.

---

## When to Use This Command

### ✅ HIGH VALUE Scenarios

**1. Ambiguous or Incomplete Requirements** ⭐⭐⭐⭐⭐
- User request is vague or open-ended
- Scope could be interpreted multiple ways
- Missing critical specifications
- **Use**: `/ct:reflect info` BEFORE planning or implementing
- **Example**: "Add authentication" (could mean many things)

**2. Complex Multi-Phase Tasks** ⭐⭐⭐⭐⭐
- Task has planning → implementation → verification phases
- Multiple deliverables or components
- Risk of missing pieces across phases
- **Use**: `/ct:reflect` at START, MIDDLE, and END checkpoints
- **Example**: "Refactor monolith to microservices"

**3. High Risk of Assumption-Based Work** ⭐⭐⭐⭐⭐
- Technical decisions not specified
- UX flows unclear
- Integration points undefined
- **Use**: `/ct:reflect info` during planning phase
- **Example**: "Implement webhook handler" (many assumptions possible)

**4. Before Declaring "Done"** ⭐⭐⭐⭐
- Implementation seems complete
- About to commit/deploy
- Need production-readiness validation
- **Use**: `/ct:reflect done` before completion
- **Example**: Reviewing rate limiting implementation

**5. Scope Creep Risk** ⭐⭐⭐
- Task has "interesting" tangential improvements
- Original goal could get lost
- Perfectionism could take over
- **Use**: `/ct:reflect task` mid-implementation
- **Example**: Fixing bug in code with poor architecture

### ⏸️ SKIP Reflection If

- Requirements are crystal clear and well-specified
- Simple single-step task (one file, one change)
- Already asking clarifying questions naturally
- Task has obvious implementation with no decision points

---

## Scope Selection Guide

**Quick Reference**:

| Scope | When to Use | Purpose | Timing |
|-------|-------------|---------|--------|
| `info` | Requirements unclear | Identify missing information and gaps | **START** (before planning) |
| `task` | During implementation | Validate alignment with goals | **MIDDLE** (during work) |
| `done` | Before declaring complete | Check production readiness | **END** (before completion) |
| `full` | Complex tasks | Comprehensive validation across all dimensions | Any checkpoint |

**Optimal Timing Pattern**:
1. **START** (`/ct:reflect info`) - Highest value ⭐⭐⭐⭐⭐ - Prevents wrong direction
2. **MIDDLE** (`/ct:reflect task`) - High value ⭐⭐⭐⭐ - Course correction
3. **END** (`/ct:reflect done`) - Medium-high value ⭐⭐⭐ - Verification

---

## Your Task

Execute task reflection based on the scope argument (defaults to 'full' if not specified):

### Scope: task (`/ct:reflect task`)
1. Use `mcp__serena__think_about_task_adherence` to validate current approach against project goals
2. Analyze:
   - Current approach alignment with stated objectives
   - Deviation identification and root causes
   - Course correction recommendations
3. Report findings with specific action items

### Scope: info (`/ct:reflect info`)
1. Use `mcp__serena__think_about_collected_information` to analyze information gathering completeness
2. Assess:
   - Information gathering thoroughness
   - Gaps in understanding or context
   - Quality of collected data
3. Identify missing information and recommend next research steps

### Scope: done (`/ct:reflect done`)
1. Use `mcp__serena__think_about_whether_you_are_done` to evaluate task completion
2. Evaluate:
   - Task completion criteria met/unmet
   - Remaining work identification
   - Quality gates passed/failed
3. Provide completion assessment with next steps or sign-off

### Scope: full (default - `/ct:reflect` or `/ct:reflect full`)
1. Execute all three reflection tools in sequence:
   - `think_about_task_adherence` - validate approach
   - `think_about_collected_information` - assess completeness
   - `think_about_whether_you_are_done` - evaluate completion

2. Synthesize findings across all three dimensions:
   - **Task Adherence**: Alignment and deviation summary
   - **Information Quality**: Completeness and gaps
   - **Completion Status**: Progress and remaining work

3. Generate comprehensive reflection report:
   ```
   ## Reflection Summary

   ### Task Adherence
   [Key findings from think_about_task_adherence]

   ### Information Completeness
   [Key findings from think_about_collected_information]

   ### Completion Assessment
   [Key findings from think_about_whether_you_are_done]

   ### Recommendations
   [Prioritized action items]

   ### Next Steps
   [Specific tasks to proceed]
   ```

4. **Optional**: If significant insights discovered, offer to persist learnings:
   - Use `list_memories` to check existing memories
   - Use `write_memory` to capture cross-session insights
   - Name memories descriptively (e.g., `reflection-session-YYYY-MM-DD-feature-name.md`)

---

## Examples

### Example 1: Using `/ct:reflect info` to Catch Ambiguous Requirements

**Scenario**: User requests "Implement Stripe webhook handler"

**Without reflection**:
- Agent makes assumptions (event types, status values, error handling)
- Implements with 60% underspecified requirements
- **Result**: 2-4 hours of rework when requirements clarified

**With `/ct:reflect info`**:
- Identifies 9 categories of missing information:
  - Which Stripe events to handle?
  - Order status field values?
  - Error handling strategy?
  - Database migration approach?
  - (and 5 more critical questions)
- Asks 7 clarifying questions BEFORE implementing
- **Result**: Correct implementation first time, prevents rework

**Time saved**: 2-4 hours
**ROI**: 200:1 (2 hours saved / 30 seconds reflection)

---

### Example 2: Using `/ct:reflect task` to Prevent Scope Creep

**Scenario**: Fixing 500 errors in endpoint with poorly implemented caching

**Without reflection**:
- Risk: Agent drifts into optimizing entire caching system
- Scope expands from "fix 500 errors" to "refactor caching layer"
- **Result**: Hours spent on out-of-scope improvements

**With `/ct:reflect task`** (mid-implementation):
- Validates scope: "Fix 500 errors ONLY, not optimize caching"
- Agent recognizes drift risk and stays focused
- Implements minimal fix (removes problematic session caching)
- **Result**: Bug fixed efficiently, no scope creep

**Time saved**: 1-2 hours
**ROI**: 100:1

---

### Example 3: Using `/ct:reflect done` to Catch Missing Production Requirements

**Scenario**: Rate limiting implementation appears complete after manual testing

**Without reflection**:
- Agent declares "done" after basic testing works
- Ships to production missing:
  - Redis error handling (app crashes if Redis fails)
  - Health check exemption
  - Automated tests
  - Configuration management
  - Monitoring/logging
- **Result**: Production incident likely

**With `/ct:reflect done`**:
- Systematic completeness check identifies 7 missing categories
- Catches critical blocker: no Redis error handling
- Recommends: Do not ship, address blockers first
- **Result**: Prevents production incident

**Time saved**: 1-2 hours of incident response + reputation damage
**ROI**: 100:1+

---

## Output Format

### Standard Output (When Issues Identified)

- Be concise but thorough
- Highlight critical issues or blockers
- Provide actionable recommendations
- Use clear section headers for readability
- Include specific file references and line numbers when relevant

### Concise Output (For Low-Value Scenarios)

**If reflection analysis shows**:
- Task is well-defined and aligned ✅
- Requirements are complete ✅
- No gaps or blockers identified ✅
- Work is production-ready ✅

**Then provide concise response**:
```
✅ Reflection Check Complete

**Task Adherence**: Aligned with goals
**Information**: Requirements complete
**Completion**: Ready to proceed

No critical issues identified. Continue with confidence.
```

---

## Actionable Items Tracking (TodoWrite Integration)

After reflection analysis, **automatically create TodoWrite todos** for actionable items:

### 1. Questions to Ask
When missing information identified:
```markdown
- [ ] Ask user: Which Stripe events should be handled?
- [ ] Ask user: What are valid order status values?
- [ ] Ask user: Password reset flow needed?
```

### 2. Gaps to Address
When missing implementation identified:
```markdown
- [ ] Address: Redis error handling (blocker)
- [ ] Address: Health check endpoint exemption
- [ ] Address: Automated test coverage
```

### 3. Blockers to Fix
When critical issues found:
```markdown
- [ ] Fix blocker: No error handling for Redis failures
- [ ] Fix blocker: Missing email verification
- [ ] Fix blocker: Hardcoded configuration
```

**Example Output with TodoWrite**:
```
Reflection identified 7 missing requirements.

Creating 7 actionable todos:
- [ ] Ask user: Which Stripe events to handle?
- [ ] Ask user: Order status field values?
- [ ] Ask user: Error handling strategy?
- [ ] Ask user: Database migration approach?
- [ ] Address: CSRF protection approach
- [ ] Address: Idempotency handling
- [ ] Address: Webhook signature verification
```

---

## Proactive Reflection Suggestions (Optional)

When appropriate context detected, suggest reflection at optimal times:

### After Receiving Complex/Ambiguous Task
```
💡 Tip: This task has unclear requirements. Consider `/ct:reflect info`
to identify gaps before planning.
```

**Trigger conditions**:
- User request <20 words OR lacks specifics
- Multiple possible interpretations
- Technical details missing

### Before Large Implementation
```
💡 Tip: About to implement significant code. Consider `/ct:reflect task`
to validate your plan aligns with goals.
```

**Trigger conditions**:
- About to create/modify >3 files
- Multi-phase implementation planned
- Complex architecture changes

### When About to Declare "Done"
```
💡 Tip: Before completing, consider `/ct:reflect done` to validate
production readiness and catch missing work.
```

**Trigger conditions**:
- Agent about to say "complete", "finished", "done"
- Implementation phase ending
- About to recommend deployment

---

## Scope Optimization Recommendations

If scope appears suboptimal based on context, suggest alternative:

**Example**: User runs `/ct:reflect task` but requirements are unclear (60% underspecified)

```
⚠️ Scope Recommendation

You used: `/ct:reflect task` (alignment validation)

Analysis suggests: Requirements are unclear (60% underspecified)

💡 Better approach: Use `/ct:reflect info` to identify missing requirements
BEFORE validating task alignment.

This will prevent building on incorrect assumptions.
```

**Optimization triggers**:
- `task` used but requirements ambiguous → suggest `info`
- `info` used but task crystal clear → suggest proceed without reflection
- `done` used mid-implementation → suggest `task` first, then `done`

---

## Cross-Session Learning (Memory Integration)

If reflection reveals **significant recurring patterns**:

```
💡 Pattern Detected

This project frequently has:
- Ambiguous authentication requirements
- Underspecified rate limiting needs
- Production checks that miss monitoring setup

This pattern has appeared in 3+ reflections.

Save this insight for future tasks? (y/n)
```

**If yes**, use `write_memory`:
- Filename: `reflection-insights-YYYY-MM-DD.md`
- Content: Pattern description, affected areas, recommendations

**Example patterns worth saving**:
- Recurring requirement gaps (auth, rate limiting, error handling)
- Common production omissions (monitoring, logging, tests)
- Project-specific conventions often overlooked

---

## Notes

- This command bridges TodoWrite task management with advanced Serena reflection
- All Serena think_* tools are read-only analysis operations
- Memory operations are optional and should only be used for valuable insights
- Scope argument is case-insensitive
- **ROI**: Typical 100:1 to 200:1 (prevents hours of work with minutes of reflection)
- **Best for**: Ambiguous requirements, complex tasks, production readiness validation
- **Use proactively**: Reflection at START prevents more issues than reflection at END
