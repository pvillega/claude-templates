---
skill: root-cause-mistake-analysis
description: Use for process/cognitive failures (why did I make this mistake? meta-learning) - systematic immediate analysis and documentation of mistakes to prevent recurrence
category: analysis
---

# Root-Cause Mistake Analysis

## When to Use
- When mistake/error detected
- After implementing incorrect solution
- When assumptions proved wrong
- When approach failed unexpectedly

## Immediate Protocol

### 1. STOP
- Halt current approach immediately
- Don't compound error with more work

### 2. Analyze Root Cause
- Why did this happen?
- What assumption was wrong?
- What signal was missed?
- What could have prevented it?

### 3. Document (6-Part Template)
```
## What Happened
[Describe the mistake objectively]

## Root Cause
[Why it happened - dig deep]

## Why It Was Missed
[What signal should have caught it?]

## Fix Applied
[How it was corrected]

## Prevention Checklist
- [ ] Check X before doing Y
- [ ] Verify Z assumption
- [ ] Review W pattern

## Lesson Learned
[Key takeaway for future work]
```

### 4. Update Global Knowledge
- If pattern: Update CLAUDE.md
- If project-specific: Update project docs
- Create prevention mechanism

### 5. Capture While Fresh
- Document IMMEDIATELY
- Context degrades rapidly
- Details matter for prevention

## Red Flags
- "I'll document later" (context will be lost)
- Fixing without root cause analysis
- Blaming instead of analyzing
- No prevention mechanism created
