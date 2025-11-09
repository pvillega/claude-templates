---
name: frontend-production-quality
description: Use BEFORE first commit of any frontend code, when committing frontend changes, creating PRs, OR making production changes - enforces WCAG 2.1 AA accessibility and Core Web Vitals as non-negotiable requirements with ZERO exceptions for WIP code, code reviews, or "I'll finish it later"
---

# Frontend Production Quality

## ⚠️ MANDATORY FIRST STEP - READ THIS NOW

### 🚨 CRITICAL: Anti-Rationalization Warning

**Time pressure, sprint deadlines, and design approval are NOT exceptions to this skill.**

This skill exists BECAUSE of pressure. Shortcuts under pressure create:
- Legal liability from accessibility violations (ADA lawsuits cost $20K-100K+)
- Exclusion of 15% of users (people with disabilities cannot use inaccessible UI)
- 32% bounce rate from slow page load (3+ second load time)
- 3-5x higher cost to retrofit accessibility than building it in

**Common rationalizations that mean you're about to fail:**
- "We'll add accessibility later/in v2/future sprint" → No, retrofitting costs 3-5x more and often never happens
- "Design is approved, just implement it" → Design approval doesn't override accessibility/performance requirements
- "Sprint ends Friday, no time" → Shipping inaccessible UI creates legal risk + rework delays
- "Just this once" → No, every inaccessible feature sets a precedent and accumulates legal risk
- "Internal tooling, accessibility less critical" → No, employees with disabilities have equal rights
- "Being pragmatic not dogmatic" → No, these requirements ARE pragmatic (WCAG 2.1 AA is a legal requirement)

**If you're thinking any of these thoughts, STOP. Re-read the skill requirements.**

---

## 🚨 CRITICAL: WIP Code is Not an Exception

**If you're thinking "I'll commit this now and finish accessibility before [code review/merge/deploy]", STOP. You're rationalizing.**

### Common WIP Rationalization (BLOCKED)

**You might think:**
> "The skill applies to production deployment, not to committing WIP code. The code isn't finished yet. I'll add accessibility before the code review / before merging / before deploying. I'm just saving my work."

**Reality:**

**This is the "we'll add it later" pattern in disguise.**

The data shows (from line 582):
- **80% of "I'll finish it Monday" items never get finished**
- Code reviews often approve incomplete work under time pressure
- "WIP" becomes "deployed" without completing deferred items
- Each deferral sets precedent for next deferral
- TODO comments accumulate indefinitely

### The Skill Applies to ALL Commits, Not Just Production

**The skill's requirements apply when you:**
- ✅ Commit code to version control (git commit)
- ✅ Push code to remote repository (git push)
- ✅ Create pull requests
- ✅ Mark work ready for review
- ✅ Deploy to ANY environment (staging, QA, production)
- ✅ Share code with team members

**There is no "WIP exception" where accessibility requirements don't apply.**

**If you haven't created TodoWrite with 18+ accessibility/performance items yet:**
- ❌ Do not commit
- ❌ Do not create PR with "I'll fix accessibility later" comments
- ❌ Do not mark work ready for review
- ❌ Do not deploy to any environment

### Personal Boundaries vs. Incomplete Work

**Scenario:** It's 6pm Friday, you have dinner plans at 6:30pm, code isn't finished.

**Your options:**

**✅ Option A: Stash changes, finish tomorrow with full requirements**
```bash
git stash push -m "WIP: UserSettingsModal - needs accessibility verification"
# Finish tomorrow morning fresh, with time to do it right
```

**✅ Option B: Complete requirements now (may miss dinner)**
- Reschedule dinner plans
- Implement full accessibility requirements
- Commit complete work
- Leave with clean conscience

**❌ NOT Option C: Commit partial work, promise to finish later**
```bash
# This is BLOCKED by the skill:
git commit -m "feat: UserSettingsModal (TODO: accessibility)"
```

### Work-Life Balance is Important, BUT...

**The skill acknowledges work-life balance matters:**
- Taking breaks is healthy
- Personal commitments are valid
- Burnout prevention is important
- Overtime shouldn't be routine

**However:**

**Work-life balance means "don't start what you can't finish", not "commit incomplete work".**

**Correct boundaries:**
- ✅ "It's 6pm, I'll start this feature tomorrow when I have time to do it right"
- ✅ "I'll work late tonight to finish properly, then take comp time tomorrow"
- ✅ "I'll stash my changes and finish Monday morning"

**Incorrect boundaries:**
- ❌ "It's 6pm, I'll commit this and finish accessibility Monday"
- ❌ "Code review will catch the missing accessibility"
- ❌ "I'll add TODO comments documenting what's missing"

**Why this matters:**

1. **Not starting >> Starting and not finishing**
   - Incomplete code creates technical debt
   - Other developers may build on incomplete foundation
   - "I'll finish Monday" becomes "I'll finish next sprint" becomes "never"

2. **Stashing >> Committing with TODOs**
   - Stashed work doesn't create dependencies for others
   - Stashed work doesn't accumulate in codebase
   - Stashed work must be completed before anyone else sees it

3. **Missing dinner once >> Accumulating accessibility debt indefinitely**
   - One rescheduled dinner: minor inconvenience
   - Inaccessible UI: legal liability ($20K-100K+ lawsuits), 15% of users excluded
   - Retrofit cost: 3-5x more expensive than doing it right now

### Code Review is NOT the Quality Gate - You Are

**Common rationalization:**
> "Code review Monday is the quality gate. I'll commit now, reviewer will ensure accessibility is added before merge."

**Why this fails:**

1. **Code reviewers face the same pressures you do**
   - Monday morning, reviewer sees "feature works, just needs accessibility"
   - Reviewer thinks "we can add accessibility later"
   - PR gets approved with TODO comments
   - Accessibility never gets added

2. **Code review is a backup check, not the primary verification**
   - YOU must verify code meets requirements before committing
   - Code review catches issues you missed, not issues you knowingly skipped
   - Passing responsibility to reviewer is abdicating your responsibility

3. **Committing incomplete work creates pressure to merge it**
   - Once code is committed, there's sunk cost
   - Team sees feature "works" in staging
   - Pressure to ship builds
   - Accessibility becomes "nice to have" not "blocker"

**The skill's standard:**

**Before you commit, YOU must verify the code meets ALL requirements.**

Code review is for catching mistakes you didn't see, not for finishing work you didn't do.

### When You Realize You Violated This

**Scenario:** You already committed code without accessibility verification.

**What to do:**

**Option A: Revert the commit immediately**
```bash
git revert HEAD
git commit -m "revert: UserSettingsModal - needs accessibility verification"
```

**Option B: Fix it NOW before anyone pulls**
```bash
# If you haven't pushed yet:
git reset --soft HEAD~1
# Implement full accessibility requirements
# Create proper commit with verification
```

**❌ NOT Option C: Leave it and "fix it in next commit"**

Each incomplete commit sets a precedent. Revert or fix immediately.

### Red Flags - WIP Code Rationalization

**If you're thinking ANY of these, you're about to violate the skill:**

- "I'll finish accessibility before code review" → **No, finish before committing**
- "Code review is the quality gate" → **No, YOU are the quality gate. Code review is backup.**
- "This is WIP, not production code" → **All commits must meet requirements**
- "I'll add TODO comments for what's missing" → **No, complete the work or don't commit**
- "Work-life balance means I can defer this" → **Work-life balance means don't start what you can't finish**
- "Personal commitment overrides skill" → **Personal commitment means stash changes and finish tomorrow**
- "It's just a commit, not a deploy" → **Commits become deploys. 80% of "later" items never get completed.**
- "I'm saving my work" → **Stash your work. Don't commit incomplete work.**
- "The code works, just needs polish" → **Accessibility isn't polish. It's a requirement.**

### Summary

**The skill has ZERO exceptions for:**
- WIP code
- "Before code review"
- "Before merge"
- "Before deploy"
- Personal time boundaries
- Exhaustion
- Dinner plans

**If you can't complete the work right now:**
1. Stash it (git stash)
2. Finish tomorrow
3. Commit only when complete

**If you already started and can't finish:**
1. Complete it now (miss dinner)
2. OR: Stash it and finish tomorrow (don't commit)

**Never commit incomplete work. Never.**

---

## 🚨 Production Emergencies: When Verification Matters MOST

**THIS SKILL APPLIES TO ALL PRODUCTION CHANGES, INCLUDING EMERGENCY FIXES.**

### Common Emergency Rationalization (BLOCKED)

**You might think:**
> "Production is down, we're losing $X/hour. This is an emergency - I need to skip verification and deploy fast."

**Reality:**
Emergencies are EXACTLY when verification matters most. Here's why:

**Why emergencies need MORE verification, not less:**
1. **You're under pressure** - mistakes are MORE likely (60% of emergency fixes introduce new bugs)
2. **Stakes are higher** - introducing bug #2 costs MORE than fixing bug #1 properly
3. **Visibility is maximum** - CEO/CTO watching, failure is public
4. **"We'll verify later" never happens** - 100% of deferred verification gets deprioritized

### The Correct Emergency Response

**❌ WRONG:**
1. Skip TodoWrite/verification
2. Deploy "quick fix"
3. Hope it works
4. "We'll verify tomorrow"

**✅ CORRECT:**
1. **First choice: ROLLBACK** - Restore to last known-good state (fastest, lowest risk)
2. **If rollback impossible: Minimum verification** (10 minutes - see below)
3. **Never skip verification entirely**

### Minimum Emergency Verification Protocol

**If rollback is truly impossible, run this 10-minute verification BEFORE deploying:**

```
Emergency Verification (10 minutes total):
1. Automated accessibility scan (2 min): axe CLI or Lighthouse accessibility audit
2. Manual functional test (3 min): Verify fix works, test with keyboard navigation
3. Lighthouse audit (2 min): Run full audit, check for regressions
4. Visual inspection (3 min): Check color contrast, focus indicators visible

If ANY of these find issues: DO NOT DEPLOY. Fix first or rollback.
```

**Post-deployment (MANDATORY within 24 hours):**
- Create TodoWrite documenting what was changed and what verification was skipped
- Run full accessibility audit (Lighthouse 100, screen reader testing)
- Measure Core Web Vitals on 3G
- Create incident ticket with findings
- Add regression test to prevent recurrence

**If 24-hour follow-up not completed:**
- Create blocking issue for next sprint
- Flag to engineering leadership
- Technical debt requiring remediation before next deploy

### Time Math: Verification is FASTER Than Fixing Your Fix

**"Emergency bypass" path:**
| Task | Time | Cumulative |
|------|------|------------|
| Deploy without verification | 5 min | 5 min |
| Discover it broke accessibility | +30 min | 35 min |
| Debug new issue | +45 min | 80 min |
| Fix again | +15 min | 95 min |
| **Total: 95 minutes** | | |

**Minimum verification path:**
| Task | Time | Cumulative |
|------|------|------------|
| Axe accessibility scan | 2 min | 2 min |
| Manual functional test | 3 min | 5 min |
| Lighthouse audit | 2 min | 7 min |
| Visual inspection | 3 min | 10 min |
| Deploy | 5 min | 15 min |
| **Total: 15 minutes** | | |

**Verification isn't the slow part. Fixing your fix is.**

### Emergency Scenarios: Red Flags

**If you're thinking ANY of these, you're about to create incident #2:**

- "Production is down, no time to verify" → Rollback or run 10-min minimum verification
- "This is a 1-line fix, low risk" → 60% of "simple" emergency fixes introduce new bugs
- "We'll verify during tomorrow's audit" → No. Create 24-hour SLA ticket or verify now
- "Emergency exception justified" → No exceptions. Rollback or minimum verification.
- "The skill is for development, not emergencies" → **The skill applies to ALL production changes**
- "Process serves business, not vice versa" → **This process IS serving business** (preventing incident #2, legal liability)
- "Deploy first, verify after" → **No. Verify first, deploy after. Or rollback.**
- "The skill's requirements are orthogonal to this fix" → Regression prevention applies to ALL changes
- "This is a documented exception" → **There are no exceptions.** Only rollback or minimum verification.

### When Truly Cannot Rollback AND Cannot Run Minimum Verification

**Escalate immediately:**
1. Document why rollback impossible (specific technical reasons)
2. Document why 10-minute verification impossible (time constraint + business impact calculation)
3. Escalate to engineering leadership for explicit written approval
4. Get approval WITH documented 24-hour remediation commitment
5. Create incident ticket tracking the shortcuts taken
6. Document in incident log for post-mortem

**Never silently skip verification, even in genuine emergencies.**

---

## 🚨 Rationalization Detection

**If you're thinking ANY of these thoughts, you're about to bypass this skill:**

### Development Rationalizations
- "The skill doesn't apply to [X type of change]" → **Yes it does. All production changes (features AND fixes).**
- "This is for prevention, not fixes" → **All production changes need verification to prevent regressions.**
- "I'll verify tomorrow" → **No. Verify now, run minimum verification, or rollback.**
- "This is a documented exception" → **There are no exceptions. Only rollback or minimum verification.**

### Emergency Rationalizations
- "The skill is for development, not emergencies" → **Skill applies to ALL production changes.**
- "Process serves business, not vice versa" → **This process IS serving business** (legal compliance, preventing incident #2).
- "Common sense vs. process orthodoxy" → **These requirements ARE common sense** (legal mandates, incident prevention).
- "The skill's protections are orthogonal to this change" → **Regression prevention applies to ALL changes.**
- "Emergency exception justified" → **No exceptions. Rollback first, minimum verification second, never skip entirely.**

### Authority Rationalizations
- "VP/CEO said skip it" → **Escalate with legal/compliance risks. Get written approval acknowledging liability.**
- "Design is approved" → **Design approval doesn't override legal requirements (WCAG 2.1 AA).**

### Scope Rationalizations
- "Internal tooling, accessibility less critical" → **ADA applies to employees. Discriminatory hiring is illegal.**
- "Small user base, low impact" → **Legal liability exists regardless of user count.**

**When you catch yourself rationalizing:**
1. **STOP**
2. Re-read the section you're about to violate
3. Ask: "Would I explain this rationalization in an incident review?"
4. If no → Don't do it. Rollback or run minimum verification.

### WIP Code and Deferral Rationalizations

| Excuse | Reality |
|--------|---------|
| "This is WIP code, I'll finish before code review" | 80% of "I'll finish later" items never get finished. Code review often approves incomplete work under pressure. |
| "I have dinner plans, can't stay late to finish" | Then don't commit. Stash changes (git stash), finish tomorrow. Committing incomplete work creates debt. |
| "Code review Monday is the quality gate" | YOU are the quality gate. Code review is a backup check, not primary verification. Don't commit code you know is incomplete. |
| "Minimal fixes + TODO comments = documented debt" | TODO comments accumulate. 80% never get completed. Either finish the work or don't commit. No middle ground. |
| "It's just a commit, not a deploy" | Commits become deploys. Once code is committed, pressure to merge/deploy builds. "WIP" becomes "production". |
| "I'm just saving my work" | Use git stash to save work. Don't commit incomplete work to shared repository. Commits are not backups. |
| "Work-life balance means I can defer this" | Work-life balance means don't start what you can't finish. Stash it and finish tomorrow. |
| "The code works, just needs accessibility" | Working without accessibility = broken. Accessibility is not "polish", it's a legal requirement. |

---

**STOP. Before proceeding with this frontend task, you MUST:**

1. **CREATE TodoWrite** with these 3 sections (DO NOT SKIP):
   - **Accessibility (WCAG 2.1 AA)**: Minimum 8 items
   - **Performance (Core Web Vitals)**: Minimum 6 items
   - **Evidence Collection**: Minimum 4 items

2. **VERIFY TodoWrite quality** using standards below (MANDATORY - see verification checkpoint)

3. **CONFIRM section completeness** using checklist below

**Do not design, implement, or review until TodoWrite is created and verified.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, you MUST verify EVERY item meets quality standards BEFORE proceeding.**

**Complete this checklist and output the results:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO (examples: "LCP < 2.5s", "4.5:1 contrast", "bundle 245KB → 260KB", "tab order 1-5")
    - Names specific tools/technologies? YES/NO (examples: "NVDA", "VoiceOver", "WebAIM checker", "Lighthouse", "Chart.js", "<button>")
    - States measurable outcome? YES/NO (examples: "NVDA announces 'Submit button'", "Lighthouse Accessibility = 100", "P95 < 500ms on 3G")
[ ] Item 2: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO
    - Names specific tools/technologies? YES/NO
    - States measurable outcome? YES/NO
[ ] Item 3: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO
    - Names specific tools/technologies? YES/NO
    - States measurable outcome? YES/NO

RESULT: All 9 checks must be YES. If any NO, revise items and re-verify.
```

**DO NOT PROCEED WITH IMPLEMENTATION until all 9 checks pass.**

---

**Minimum total: 18 specific items** covering all 3 categories.

---

## Section Completion Confirmation

**After creating TodoWrite, output this checklist to confirm all sections present:**

```
SECTION COMPLETION:
[ ] Accessibility (WCAG 2.1 AA): 8+ items
[ ] Performance (Core Web Vitals): 6+ items
[ ] Evidence Collection: 4+ items

TOTAL: ___ items (must be 18+)
```

**If any section is unchecked or total < 18, STOP and add missing items now.**

**Why this matters:** 17% create wrong TodoWrite structure (implementation tasks instead of A11y/Performance/Evidence). This checklist prevents that.

---

## TodoWrite Quality Standards

After creating TodoWrite, verify EVERY item meets these criteria:

- [ ] Names specific tool/technique/element (e.g., "NVDA screen reader", "<button>", "Lighthouse", "4.5:1 contrast")
- [ ] Includes measurable criteria (e.g., "LCP < 2.5s", "FID < 100ms", "CLS < 0.1", "tab order 1-5")
- [ ] States how to verify (e.g., "test with NVDA", "run Lighthouse audit", "use WebAIM contrast checker")

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

### What Makes an Item Specific?

Must include ALL three:
1. **Concrete numbers/thresholds**: "LCP < 2.5s", "FID < 100ms", "CLS < 0.1", "4.5:1 contrast", "bundle 245KB → 260KB", "tab order 1-5"
2. **Specific tools/technologies**: "NVDA", "VoiceOver", "WebAIM contrast checker", "Lighthouse", "Chart.js", "`<button>`", "DevTools"
3. **Measurable outcome**: "NVDA announces 'Submit button'", "Lighthouse Accessibility = 100", "P95 < 500ms on 3G", "passes 4.5:1"

### Test Examples

❌ **FAILS TEST**: "Check accessibility"
- Engineer asks: Which criteria? How verified? With what tool? What's passing?

✅ **PASSES TEST**: "Verify color contrast using WebAIM contrast checker: Body text `#333` on `#FFF` = 12.6:1 ✓ (need 4.5:1). Button text `#FFF` on `#007bff` = 8.6:1 ✓ (need 4.5:1). Link text `#0066cc` on `#FFF` = 7.2:1 ✓."
- Engineer knows: Tool (WebAIM), colors tested, ratios achieved, requirement (4.5:1)

❌ **FAILS TEST**: "Test keyboard navigation"
- Engineer asks: What order? What focus indicators? How verified? What's passing?

✅ **PASSES TEST**: "Tab order: 1. Start date input, 2. End date input, 3. Chart type dropdown, 4. Apply filter button, 5. Export button. Each has 2px solid `#0056b3` focus border (4.5:1 contrast with `#FFF` background). Test: Tab through, verify order and focus visible."
- Engineer knows: Complete tab order, focus indicator spec, contrast ratio, verification method

### Apply This Test

Before proceeding, select 3 random items from your TodoWrite and test them. If any fail, revise before proceeding.

---

### Examples of Quality Items

**❌ BAD (too generic):**
- "Check accessibility"
- "Test performance"
- "Make it accessible"
- "Optimize loading"
- "Test keyboard navigation"

**✅ GOOD (specific):**
- "Semantic HTML: Replace `<div onClick>` with `<button>` for submit action, verify with NVDA announces 'button'"
- "Color contrast: Verify all text meets 4.5:1 ratio using WebAIM contrast checker (body text #333 on #FFF = 12.6:1 ✓)"
- "Core Web Vitals: Measure LCP < 2.5s on 3G throttled connection using Lighthouse, target hero image load"
- "Keyboard nav: Tab through form (order: email input → password input → remember me checkbox → submit button), verify focus visible"
- "Bundle size: Current 245KB, new feature adds 15KB, justify increase (interactive data table requires ag-grid 12KB + custom logic 3KB)"

---

## ❌ Failed Examples (What NOT To Do)

**These items would FAIL verification. If your items look like these, revise them immediately.**

### Too Generic (No Specific Tools/Elements)

❌ "Check accessibility"
- **Why it fails**: Check what? How? With what tool?
- **Engineer asks**: WCAG criteria? Screen reader? Color contrast? Keyboard nav? All of them?

❌ "Test performance"
- **Why it fails**: Test what? How? What's passing?
- **Engineer asks**: LCP? FID? CLS? Lighthouse? DevTools? What targets?

❌ "Make it accessible"
- **Why it fails**: Make what accessible? How?
- **Engineer asks**: Semantic HTML? ARIA? Screen reader? Focus indicators? Which elements?

❌ "Optimize loading"
- **Why it fails**: Optimize what? By how much? How verified?
- **Engineer asks**: Images? JS bundles? Both? What's the target? Lazy loading?

### Missing Concrete Numbers

❌ "Keep LCP low"
- **Why it fails**: How low? Measured how? On what connection?
- **Engineer asks**: <2.5s? <3s? <4s? 3G? 4G? WiFi? Lighthouse? RUM?

❌ "Good color contrast"
- **Why it fails**: What ratio? Which colors? Verified how?
- **Engineer asks**: 4.5:1? 3:1? Which text? Body? Headers? Buttons? Checked with what?

❌ "Reasonable bundle size"
- **Why it fails**: What size? Increase by how much? Justified?
- **Engineer asks**: Current? New? Increase? Why? What's "reasonable"?

### Missing Verification Methods

❌ "Test keyboard navigation"
- **Why it fails**: Test how? What's the expected order? What's passing?
- **Engineer asks**: What order? Focus visible? How verify? Tested with what?

❌ "Screen reader compatible"
- **Why it fails**: Tested with which screen reader? What announced?
- **Engineer asks**: NVDA? VoiceOver? What should be announced? How verify?

❌ "Performance budget met"
- **Why it fails**: What budget? Measured how? What's passing?
- **Engineer asks**: Which metrics? What values? Lighthouse? DevTools? What scores?

### Accessibility-Critical Failures (LEGAL RISK)

❌ "Improve accessibility"
- **Why it fails**: Vague, no WCAG criteria specified.
- **Engineer asks**: Which WCAG criteria? 2.1 A? AA? AAA? Which specific items?

❌ "Add alt text"
- **Why it fails**: To which images? What text?
- **Engineer asks**: All images? Decorative vs meaningful? What's the description pattern?

❌ "Support keyboard users"
- **Why it fails**: How? Which elements? What's the tab order?
- **Engineer asks**: Tab order? Focus indicators? Skip links? All interactive elements?

### Performance-Critical Failures (BUSINESS IMPACT)

❌ "Make it fast"
- **Why it fails**: How fast? Which metric? Verified how?
- **Engineer asks**: LCP? FID? CLS? All? What targets? 3G? 4G?

❌ "Lazy load images"
- **Why it fails**: Which images? With what attribute/library?
- **Engineer asks**: All images? Above fold too? Native `loading="lazy"`? Intersection Observer?

**If 3+ of your TodoWrite items match these ❌ patterns, STOP. Your TodoWrite needs major revision before proceeding.**

**If ANY accessibility item is generic (❌ patterns), BLOCKED. Accessibility violations create legal liability.**

---

## Section Completeness Check

Before proceeding, confirm ALL mandatory sections present in your TodoWrite:

- [ ] **Accessibility**: 8+ items (semantic HTML, ARIA, keyboard nav, screen reader, contrast, focus indicators, headings, forms) ✓
- [ ] **Performance**: 6+ items (baseline measurement, Core Web Vitals, bundle size, lazy loading, throttled testing, Lighthouse score) ✓
- [ ] **Evidence Collection**: 4+ items (Lighthouse scores, Core Web Vitals measurements, keyboard nav proof, contrast verification) ✓

**If any section is missing or below minimum items, STOP and add them now.**

---

## Trigger Conditions

Activate this skill when:
- **STARTING** implementation of ANY user-facing UI component or page
- **BEFORE FIRST COMMIT** of frontend code
- **COMMITTING** ANY frontend code to version control
- **CREATING** pull requests with frontend changes
- **MARKING** frontend work as "ready for review"
- Reviewing frontend code or implementation plans
- Making decisions about UI libraries, frameworks, or approaches
- Someone says "we'll add accessibility/performance later" OR "I'll finish before code review"
- **Making ANY production change (including emergency fixes, hotfixes, or bug fixes)**
- **Production incident requiring code deployment**
- **Reverting or rolling back changes**
- **ANY time you think "I'll commit now and finish [X] later"**

---

## Mandatory Requirements

Create TodoWrite items for all categories below. Refer to Quality Standards and Completeness Check sections above.

### Accessibility (WCAG 2.1 AA)

**⚠️ CRITICAL: Inaccessible UI excludes 15% of users and risks legal liability.**

- [ ] **Semantic HTML**: Use `<button>`, `<a>`, `<input>`, `<select>` instead of `<div onClick>`. Verify with screen reader announces correct role.
- [ ] **ARIA labels**: Where semantic HTML insufficient, add `aria-label`, `aria-labelledby`, `aria-describedby`, `role`. Example: `<div role="dialog" aria-labelledby="dialog-title">`.
- [ ] **Keyboard navigation**: All interactive elements reachable via Tab/Shift+Tab. Document tab order (e.g., "1. Email input, 2. Password input, 3. Submit button").
- [ ] **Focus indicators**: Visible focus state on all interactive elements. Verify 2px solid border, 3:1 contrast ratio minimum.
- [ ] **Color contrast**: All text meets 4.5:1 (body text) or 3:1 (large text 24px+, UI components). Use WebAIM contrast checker.
- [ ] **Screen reader testing**: Test with NVDA (Windows) or VoiceOver (Mac). Verify all content announced, form inputs labeled, buttons named.
- [ ] **Heading hierarchy**: Logical structure (h1 → h2 → h3, no skips). One h1 per page. Verify with browser accessibility tree.
- [ ] **Form labels**: Every `<input>` has associated `<label>` or `aria-label`. Error messages linked with `aria-describedby`.

**WCAG 2.1 AA Checklist:**
```
- [ ] 1.1.1 Non-text content: Images have alt text (meaningful) or alt="" (decorative)
- [ ] 1.3.1 Info and relationships: Semantic HTML conveys structure (<button>, <nav>, <main>)
- [ ] 1.4.3 Contrast: Text 4.5:1, large text 3:1, UI components 3:1
- [ ] 2.1.1 Keyboard: All functionality via keyboard (no mouse-only)
- [ ] 2.4.1 Bypass blocks: Skip navigation link for keyboard users
- [ ] 2.4.3 Focus order: Logical tab order matching visual flow
- [ ] 2.4.7 Focus visible: 2px visible focus indicator, 3:1 contrast
- [ ] 3.2.2 On input: Input changes don't cause unexpected context changes
- [ ] 4.1.2 Name, role, value: All UI components have accessible name and role
```

### Performance (Core Web Vitals)

**⚠️ CRITICAL: Slow UX increases bounce rate. 1 second delay = 7% conversion loss.**

- [ ] **Baseline measurement**: Measure current Core Web Vitals before changes (LCP: ___, FID: ___, CLS: ___)
- [ ] **Core Web Vitals targets**:
  - **LCP (Largest Contentful Paint) < 2.5s**: Main content visible quickly
  - **FID (First Input Delay) < 100ms**: Page responsive to user input
  - **CLS (Cumulative Layout Shift) < 0.1**: No unexpected layout jumps
- [ ] **Bundle size impact**: Current bundle: ___ KB. New feature adds: ___ KB. Justify if >10KB increase.
- [ ] **Lazy loading**: Images use `loading="lazy"`. Non-critical JavaScript loaded on-demand (e.g., modal code loaded when button clicked).
- [ ] **Throttled testing**: Test on 3G network throttle (DevTools Network tab). Verify acceptable load time < 5s.
- [ ] **Lighthouse audit**: Run Lighthouse in DevTools. Target: Performance ≥ 90, Accessibility = 100.

**Performance Budget:**
```
- [ ] Lighthouse Performance score: ≥ 90 (current: ___, target: ≥ 90)
- [ ] Lighthouse Accessibility score: 100 (current: ___, target: 100)
- [ ] LCP: < 2.5s on 3G throttle (current: ___, target: < 2.5s)
- [ ] FID: < 100ms (current: ___, target: < 100ms)
- [ ] CLS: < 0.1 (current: ___, target: < 0.1)
- [ ] Bundle size: < [current + 10KB] (current: ___ KB, new feature: ___ KB)
```

### Evidence Collection

**Add these to TodoWrite before claiming task complete:**

- [ ] **Lighthouse accessibility screenshot**: Score must be 100. Include URL, date, device type.
- [ ] **Lighthouse performance screenshot**: Score must be ≥ 90. Include Core Web Vitals measurements.
- [ ] **Core Web Vitals with throttling**: Screenshot of DevTools Network tab showing 3G throttle + Performance tab showing LCP/FID/CLS.
- [ ] **Keyboard navigation proof**: List tab order and describe focus indicators (e.g., "1. Email input - 2px blue border, 2. Submit button - 2px blue border").
- [ ] **Screen reader test results**: What NVDA/VoiceOver announced for key interactions (e.g., "Announced: 'Submit button', 'Email input, edit text'").
- [ ] **Color contrast verification**: List all text color combos with WebAIM contrast checker results (e.g., "#333 on #FFF = 12.6:1 ✓").
- [ ] **Bundle size impact**: Screenshot of bundle analyzer showing before/after, justify any >10KB increase.

---

## Non-Negotiable Rules

### Accessibility First

**Block implementation that lacks accessibility plan.**

If no accessibility approach mentioned → STOP and add accessibility requirements to TodoWrite.

Semantic HTML is not optional, it is the foundation. ARIA attributes required when semantic HTML insufficient.

### Refuse "we'll add it later" for accessibility

```
❌ BLOCKED: I cannot implement UI without accessibility plan.

Risk: Retrofitting accessibility costs 3-5x more than building it in from start.
Inaccessible UI excludes 15% of users and creates legal liability (ADA compliance).

Required: Add to TodoWrite:
- Semantic HTML specification (which elements for which components)
- ARIA labels where needed (dialogs, custom controls)
- Keyboard navigation tab order
- Focus indicator specification (2px border, 3:1 contrast)
- Screen reader testing plan (NVDA or VoiceOver)

To override: Not recommended. If you insist, document accessibility debt with remediation timeline
and assign engineer to retrofit accessibility before production release.
```

### Keyboard navigation is mandatory

Every interactive element must be keyboard accessible. Tab order must match visual flow. Focus must be visible (2px border, 3:1 contrast minimum).

### Performance First

**Block implementation without performance budget.**

Define Core Web Vitals targets before implementation. Identify performance-critical paths (initial render, interactions). Choose lightweight solutions when impact is significant.

### Refuse performance assumptions

```
❌ BLOCKED: I cannot implement UI without performance budget.

Risk: Without performance budget, features accumulate unbounded JavaScript, causing slow page load.
1 second delay = 7% conversion loss. 3 second load time = 32% bounce rate.

Required: Add to TodoWrite:
- Baseline Core Web Vitals measurement (LCP, FID, CLS before changes)
- Target Core Web Vitals (LCP < 2.5s, FID < 100ms, CLS < 0.1)
- Bundle size impact (current + added, justify if >10KB)
- Lazy loading strategy (images, non-critical JS)
- Lighthouse audit plan (Performance ≥ 90, Accessibility = 100)

To override: Not recommended. If you insist, document performance debt and commit to optimization
sprint before next production release.
```

### Lazy loading and code splitting are default

Bundle size increase requires explicit justification. Heavy dependencies must be loaded on-demand. Images must use `loading="lazy"` by default.

---

## 🚩 Red Flags - STOP

**If you find yourself thinking or saying ANY of these, you are about to violate the skill:**

### Development Red Flags
- "We'll add accessibility later/in v2/future sprint" → No, implement now. Later = never (80% never added). Retrofit costs 3-5x more.
- "Design is approved, just implement it" → Design approval doesn't override accessibility/performance requirements
- "Sprint ends Friday, no time" → Shipping inaccessible UI creates legal risk + rework delays. Faster to build it right.
- "Just this once" → Every inaccessible feature sets precedent and accumulates legal risk
- "Internal tooling, accessibility less critical" → Wrong. Employees with disabilities have equal rights (ADA applies)
- "Being pragmatic not dogmatic" → These requirements ARE pragmatic (WCAG 2.1 AA is legal requirement)
- "Screen reader users are rare" → 2-3% of users = millions of people. Also: legal liability regardless of numbers.
- "Performance optimization later" → Retrofit costs 2-4 weeks. Building it in costs 2-4 hours.
- "Users have fast connections" → 30% of users on mobile/3G. Poor performance = 32% bounce rate.
- "We already tested manually" → Manual ≠ systematic. Lighthouse/NVDA testing catches issues manual testing misses.
- "Just use semantic HTML, don't need ARIA" → Sometimes true, but complex components (modals, tabs, accordions) NEED ARIA.
- "Performance is good enough" → "Good enough" = unmeasured = probably failing Core Web Vitals = poor SEO + high bounce rate.

### Emergency Red Flags (See Production Emergencies Section)
- "Production is down, no time to verify" → **Rollback or run 10-min minimum verification**
- "This is a 1-line fix, low risk" → **60% of "simple" emergency fixes introduce new bugs**
- "We'll verify during tomorrow's audit" → **No. Create 24-hour SLA ticket or verify now**
- "Emergency exception justified" → **No exceptions. Rollback or minimum verification**
- "The skill is for development, not emergencies" → **Skill applies to ALL production changes**
- "Process serves business, not vice versa" → **This process IS serving business** (preventing incident #2)
- "Deploy first, verify after" → **No. Verify first, deploy after. Or rollback**
- "The skill's protections are orthogonal to this fix" → **Regression prevention applies to ALL changes**
- "This is a documented exception" → **There are no exceptions. Only rollback or minimum verification**
- "Blindly following process is poor judgment" → **These requirements prevent 60% of emergency fix failures**

**When you notice a red flag, STOP. Re-read the specific skill requirement you're about to skip.**

**13% explicitly defer accessibility. 40% miss Core Web Vitals. 100% of emergency bypasses risk incident #2. Each red flag represents a known failure pattern.**

### WIP Code Red Flags (STOP IMMEDIATELY)
- "I'll finish accessibility before code review" → **No, finish before committing**
- "I'll finish accessibility before merge" → **No, finish before committing**
- "I'll finish accessibility before deploy" → **No, finish before committing**
- "Code review is the quality gate" → **No, YOU are the quality gate. Code review is backup.**
- "This is WIP, not production code" → **All commits must meet requirements. No WIP exception.**
- "I'll add TODO comments for what's missing" → **No, complete the work or don't commit**
- "I'll stash changes but commit the working parts" → **No, stash everything or commit everything complete**
- "Work-life balance means I can defer this" → **Work-life balance means don't start what you can't finish**
- "Personal commitment overrides skill" → **Personal commitment means stash changes, finish tomorrow**
- "It's just a commit, not a deploy" → **Commits become deploys. 80% of "later" never happens.**
- "I'm just saving my work" → **Stash your work (git stash). Don't commit incomplete work.**
- "The code works, just needs accessibility polish" → **Accessibility isn't polish. It's a legal requirement.**
- "I've been working 7 hours, I'm exhausted" → **Then stash it and finish tomorrow. Don't commit incomplete.**
- "Dinner plans at 6:30pm" → **Reschedule dinner OR stash code. Don't commit incomplete.**
- "Code review Monday will ensure quality" → **You ensure quality. Code review is a backup check.**

**When you notice ANY WIP code red flag:**
1. STOP immediately
2. Ask: "Am I about to commit code that I KNOW doesn't meet the skill's requirements?"
3. If YES → You have two choices: finish it now OR stash it
4. NEVER commit with "I'll finish X later"

---

## When Asked to Skip Requirements

Use these EXACT response templates:

### "We'll Add [Requirement] Later" OR "Before Code Review" OR "Before Merge" OR "Monday"

❌ **BLOCKED**: I cannot defer [accessibility/performance] to future iterations.

**Why "later" always fails:**
- "Later" never comes - next sprint has new priorities
- Retrofitting accessibility costs 3-5x more than building it in
- Technical debt accumulates and blocks future UI changes
- Legal liability accumulates with each inaccessible feature

**The data:**
- 80% of "we'll add later" items never get added
- Retrofitting accessibility costs 3-5x more than building it in
- Retrofitting performance after launch requires refactoring (2-4 week project)
- ADA lawsuits cost $20K-100K+ to settle
- Each inaccessible feature compounds legal risk (1 becomes 5 becomes 20)

**All of these are "later" - and 80% of "later" never happens:**
- "I'll add accessibility before code review" = later
- "I'll add accessibility before merge" = later
- "I'll add accessibility before deploy" = later
- "I'll add accessibility Monday morning" = later
- "I'll add accessibility next sprint" = later
- "I'll add TODO comments now, fix them later" = later

**The skill does NOT distinguish between these.**

"Later" is "later" regardless of when you promise it will happen.

**Specific consequence for this requirement:**
- Skipping accessibility → Legal liability (ADA lawsuits $20K-100K+) + exclusion of 15% of users + 3-5x retrofit cost
- Skipping performance → 32% bounce rate (3+ second load) + 7% conversion loss per second delay → revenue impact
- Skipping Core Web Vitals → Poor SEO ranking → reduced organic traffic → lost customers

**Required**: Implement now, or explicitly document:
1. Specific date for retrofit (not "later" - actual sprint/date)
2. Budget allocated (engineer-weeks + dollar cost + legal risk cost)
3. Risk acceptance signed by [decision maker's name + date] acknowledging legal liability
4. Interim mitigation plan (accessibility audit schedule? legal defense budget? acceptable exclusion of users with disabilities?)

**If you cannot provide these 4 items, requirement must be implemented now.**

**For accessibility:** This risk is NOT acceptable in many jurisdictions. WCAG 2.1 AA is a legal requirement. Shipping inaccessible UI creates liability that accumulates with each feature.

---

### Skipping Semantic HTML
```
❌ BLOCKED: I cannot implement UI with `<div onClick>` instead of `<button>`.

Risk: <div> elements are not keyboard accessible by default. Screen readers don't announce
them as interactive. Users with motor impairments cannot use the UI.

Required: Replace with semantic HTML:
- Buttons: <button> (announces "button", keyboard accessible, spacebar activates)
- Links: <a href> (announces "link", keyboard accessible, Enter activates)
- Inputs: <input>, <select>, <textarea> (announces type, keyboard accessible, labeled)

If custom styling needed, style the semantic element, don't replace with <div>.

To override: Not acceptable. This is WCAG 2.1 A compliance (basic requirement).
Semantic HTML is non-negotiable.
```

### Skipping Color Contrast
```
❌ BLOCKED: I cannot implement UI with insufficient color contrast.

Risk: Low contrast text is unreadable for users with low vision, color blindness, or viewing
in bright sunlight. Fails WCAG 2.1 AA (legal requirement in many jurisdictions).

Required: Verify all text meets contrast requirements:
- Body text (< 24px): 4.5:1 minimum (e.g., #333 on #FFF = 12.6:1 ✓)
- Large text (≥ 24px): 3:1 minimum
- UI components: 3:1 minimum (buttons, borders, icons)

Use WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/

To override: Not acceptable. This is WCAG 2.1 AA compliance (legal requirement).
Adjust colors to meet contrast requirements.
```

### Skipping Core Web Vitals Measurement
```
❌ BLOCKED: I cannot mark frontend work complete without Core Web Vitals verification.

Risk: Without measurement, we don't know if new feature caused performance regression.
Slow pages increase bounce rate (3s load = 32% bounce) and decrease conversions (1s delay = 7% loss).

Required: Add to TodoWrite:
- Run Lighthouse audit (Performance ≥ 90, Accessibility = 100)
- Measure Core Web Vitals on 3G throttle: LCP < 2.5s, FID < 100ms, CLS < 0.1
- Document bundle size impact (before: ___ KB, after: ___ KB)
- Screenshot evidence of measurements

Takes 5 minutes to measure. Not optional.

To override: Not recommended. If you insist, document performance risk and commit to
measurement before production release.
```

### Skipping Screen Reader Testing
```
❌ BLOCKED: I cannot mark UI complete without screen reader testing.

Risk: Screen readers are used by 2-3% of users (blind, low vision, motor impairments).
Without testing, we don't know if content is announced correctly or navigable.

Required:
- Windows: Download NVDA (free), test with NVDA + Chrome
- Mac: Use VoiceOver (built-in), test with VoiceOver + Safari
- Document what was announced for key interactions (form submission, button clicks, errors)

Takes 10 minutes. Catches issues semantic HTML/ARIA audits miss.

To override: Not recommended. If you insist, document accessibility gap and assign engineer
to screen reader testing before production release.
```

---

## Common Failure Prevention

### Anti-Pattern: Non-Semantic HTML
```
❌ BAD: <div onClick={handleSubmit}>Submit</div>
✅ GOOD: <button onClick={handleSubmit}>Submit</button>

Why: <button> is keyboard accessible (Tab, Space/Enter), screen reader announces "button",
has default focus style, supports disabled state.
```

### Anti-Pattern: Missing Alt Text
```
❌ BAD: <img src="product.jpg">
✅ GOOD (meaningful): <img src="product.jpg" alt="Blue ceramic coffee mug with white handle">
✅ GOOD (decorative): <img src="decoration.jpg" alt="">

Why: Screen readers need alt text to describe images. Empty alt="" for decorative images
tells screen reader to skip (better than "image" announced).
```

### Anti-Pattern: Form Without Labels
```
❌ BAD: <input type="email" placeholder="Email">
✅ GOOD: <label for="email">Email</label>
         <input type="email" id="email" placeholder="you@example.com">

Why: Placeholders disappear on input, are not announced by screen readers. Labels persist
and are announced, making form navigable for assistive tech users.
```

### Anti-Pattern: Color-Only Information
```
❌ BAD: Error text in red, success text in green (color-only distinction)
✅ GOOD: Error text in red + "❌ Error:" prefix + aria-live="polite"
         Success text in green + "✓ Success:" prefix + aria-live="polite"

Why: Color blind users can't distinguish red/green. Text prefix + icon + ARIA live region
ensures all users receive the information.
```

### Anti-Pattern: Invisible Focus Indicators
```
❌ BAD: button:focus { outline: none; }
✅ GOOD: button:focus { outline: 2px solid #005fcc; outline-offset: 2px; }

Why: Keyboard users need visible focus to know which element is active. 2px minimum,
3:1 contrast ratio with background.
```

### Anti-Pattern: Large Unoptimized Images
```
❌ BAD: <img src="hero-4000x3000.jpg" width="800">
✅ GOOD: <img src="hero-800x600.webp" loading="lazy" width="800" height="600"
         srcset="hero-400x300.webp 400w, hero-800x600.webp 800w"
         sizes="(max-width: 600px) 400px, 800px"
         alt="Modern office workspace with natural lighting">

Why: Right-sized images, modern formats (WebP), lazy loading, responsive sizes, reserved
space (width/height prevents CLS). Reduces LCP from 8s to 2s.
```

### Anti-Pattern: Blocking JavaScript
```
❌ BAD: <script src="heavy-analytics-500kb.js"></script> in <head>
✅ GOOD: <script src="heavy-analytics-500kb.js" defer></script>
         OR load on-demand: import('heavy-analytics').then(...)

Why: JavaScript in <head> blocks page render. Defer loads async, executes after DOM ready.
On-demand import loads only when needed (e.g., when user clicks button).
```

### Anti-Pattern: Layout Shifts
```
❌ BAD: <img src="hero.jpg"> (no dimensions, loads and shifts content down)
✅ GOOD: <img src="hero.jpg" width="800" height="600"> (reserves space, no shift)

Why: Images without dimensions cause CLS (Cumulative Layout Shift). Browser doesn't know
how much space to reserve, so content jumps when image loads. Specify width/height prevents this.
```

---

## Verification

Before marking frontend work complete:

### 1. Accessibility Audit
   - [ ] Run browser DevTools accessibility check (0 violations)
   - [ ] Navigate entire feature using only keyboard (Tab, Shift+Tab, Enter, Space)
   - [ ] Test with screen reader (NVDA or VoiceOver), verify all content announced
   - [ ] Verify color contrast with WebAIM contrast checker (all text 4.5:1+)
   - [ ] Check heading hierarchy (h1 → h2 → h3, no skips, inspect accessibility tree)

### 2. Performance Audit
   - [ ] Run Lighthouse performance audit (score ≥ 90)
   - [ ] Run Lighthouse accessibility audit (score = 100)
   - [ ] Measure Core Web Vitals on 3G throttle (LCP < 2.5s, FID < 100ms, CLS < 0.1)
   - [ ] Check bundle size impact (document if >10KB increase)
   - [ ] Profile runtime performance (no long tasks >50ms in DevTools Performance tab)

### 3. Real-World Testing
   - [ ] Test on mobile device with throttled network (3G)
   - [ ] Test with browser zoom at 200% (text remains readable, no horizontal scroll)
   - [ ] Test with high-contrast mode enabled (Windows High Contrast, browser extensions)
   - [ ] Test with JavaScript initially disabled (progressive enhancement - core content visible)

---

## Evidence Required

When claiming frontend work complete, provide in TodoWrite:

- [ ] **Lighthouse accessibility**: Screenshot showing score = 100
- [ ] **Lighthouse performance**: Screenshot showing score ≥ 90
- [ ] **Core Web Vitals**: Screenshot showing LCP, FID, CLS measurements with 3G throttle
- [ ] **Keyboard focus**: List tab order and describe focus indicators (e.g., "1. Email input - 2px blue solid, 2. Submit - 2px blue solid")
- [ ] **ARIA attributes**: List of ARIA used and why (e.g., `aria-label="Close dialog"` on `<button>×</button>` because × is not descriptive)
- [ ] **Color contrast**: List all text/background combos with ratios (e.g., "Body text: #333 on #FFF = 12.6:1 ✓, Button: #FFF on #007bff = 8.6:1 ✓")
- [ ] **Bundle size**: Before/after KB, justification if >10KB increase
- [ ] **Screen reader**: What was announced for key interactions (form submission, button clicks, navigation)

**Failure to provide evidence = work is not complete.**

---

## Final Self-Grading

**Before claiming frontend work complete, grade your own TodoWrite:**

```
SELF-GRADING CHECKLIST:
[ ] Minimum 18 items across 3 sections (Accessibility 8+, Performance 6+, Evidence 4+)
[ ] 80%+ of items have concrete numbers/thresholds (LCP < 2.5s, 4.5:1 contrast, tab order 1-5)
[ ] 80%+ of items name specific tools/technologies (NVDA, WebAIM, Lighthouse, <button>, Chart.js)
[ ] 100% of items have measurable outcomes ("NVDA announces 'Submit'", "Lighthouse A11y = 100", etc.)
[ ] Zero items use vague verbs without specifics ("check accessibility", "test performance" without tool/criteria)
[ ] Tested 3 random items with Specificity Test - all passed (can engineer implement without questions?)
[ ] Accessibility: WCAG 2.1 AA criteria explicitly specified (semantic HTML, ARIA, contrast, keyboard nav)
[ ] Performance: Core Web Vitals targets specified (LCP < 2.5s, FID < 100ms, CLS < 0.1)

GRADE YOURSELF:
- All 8 checkboxes passed: 9-10/10 (Excellent - ready to proceed)
- 6-7 checkboxes passed: 7-8/10 (Good - minor revisions needed)
- 4-5 checkboxes passed: 5-6/10 (Needs revision - improve specificity)
- 0-3 checkboxes passed: 1-4/10 (Failed - major revision required)
```

**If you graded yourself below 7/10, you MUST revise TodoWrite before proceeding with implementation.**

**If accessibility or performance targets are missing, BLOCKED. These are non-negotiable requirements.**

**Why this matters**: 60% create generic items. 40% miss Core Web Vitals targets. 13% defer accessibility. Self-grading prevents this.

---

## Workflow Integration

### 1. Before Implementation
   - Add accessibility and performance requirements to TodoWrite
   - Define specific WCAG criteria that apply (semantic HTML, ARIA, contrast, keyboard nav)
   - Set Core Web Vitals budget (LCP, FID, CLS targets)

### 2. During Implementation
   - Test keyboard navigation continuously (Tab through after each component)
   - Run accessibility audit after each component (DevTools Accessibility pane)
   - Monitor bundle size in real-time (webpack-bundle-analyzer, DevTools Network tab)

### 3. Before Completion
   - Run full verification checklist (accessibility + performance + real-world testing)
   - Gather evidence (screenshots, measurements, lists)
   - Document any accessibility/performance trade-offs made

---

## Escalation

If accessibility or performance requirements cannot be met:
1. Document the specific constraint preventing compliance
2. Propose alternative approaches that meet requirements
3. Get explicit user approval to proceed with known limitations
4. Create follow-up task to address limitation with timeline

**Never silently ship inaccessible or slow features.**

---

**Remember**: Accessibility and performance are not features - they are requirements. Users with disabilities have equal right to access UI. Users on slow connections have equal right to fast experience. Build inclusive, fast experiences for everyone from the start.
