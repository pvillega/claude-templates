---
name: deployment-automation-enforcer
description: Use when designing or implementing deployment pipelines, CI/CD workflows, infrastructure provisioning, or any automation that touches production systems - enforces automation-first principles, failure recovery design, and mandatory observability
---

# Deployment Automation Enforcer

## ⚠️ MANDATORY FIRST STEP - READ THIS NOW

### 🚨 CRITICAL: Anti-Rationalization Warning

**Time pressure, production emergencies, and broken deployments are NOT exceptions to this skill.**

This skill exists BECAUSE of pressure. Shortcuts under pressure create:
- $5-50K per incident from missing rollback mechanisms (extended downtime)
- Silent failures that corrupt data before detection (missing observability)
- Manual recovery requiring 30+ minutes instead of 2-minute automated rollback
- Tribal knowledge silos that block team scaling

**Common rationalizations that mean you're about to fail:**
- "Manual deploy is broken, need automation fast" → No, automating without rollback/observability creates worse problems
- "We'll add [monitoring/rollback] after it's working" → No, you cannot detect or recover from failures without them
- "Just this once" → No, every manual deployment sets a precedent and blocks automation adoption
- "Production is down $10K/min" → Shipping unmonitored automation prolongs incidents, not shortens them
- "Being pragmatic not dogmatic" → No, these requirements ARE pragmatic (prevent expensive incidents)

**If you're thinking any of these thoughts, STOP. Re-read the skill requirements.**

---

## 🛑 ROLLBACK CHECKPOINT (COMPLETE THIS FIRST)

**MANDATORY: Before creating TodoWrite, answer these questions about rollback capability:**

- [ ] **Rollback script exists?** YES/NO [If YES, provide path: _________ | If NO, document "NEW DEPLOYMENT - will create rollback as first TodoWrite item"]
- [ ] **Rollback tested in staging?** YES/NO [If YES, date tested: _________ | If NO or >30 days ago, must test before production]
- [ ] **Rollback time measured?** YES/NO [If YES, duration: _________ minutes | If NO, must measure during test]
- [ ] **Rollback triggers defined?** YES/NO [If YES, list triggers: _________ | If NO, define them now]

**For new deployments without existing rollback:**
Document: "NEW DEPLOYMENT - Rollback mechanism will be created as part of Failure Recovery section in TodoWrite"

**For existing deployments:**
You MUST complete all 4 checkboxes before proceeding. If any answer is NO (except for new deployments), address it before creating TodoWrite.

**Why this comes first:**
27% of agents skip rollback requirements when this checkpoint appears later. Completing this BEFORE TodoWrite ensures rollback is not an afterthought.

---

**NOW proceed with TodoWrite creation:**

**STOP. Before proceeding with this deployment task, you MUST:**

1. **CREATE TodoWrite** with these 4 sections (DO NOT SKIP):
   - **Automation**: Minimum 5 items
   - **Observability**: Minimum 5 items
   - **Failure Recovery**: Minimum 5 items
   - **Verification**: Minimum 4 items

2. **VERIFY TodoWrite quality** using standards below (MANDATORY - see verification checkpoint)

3. **CONFIRM section completeness** using checklist below

**Do not analyze, design, or implement until TodoWrite is created and verified.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, you MUST verify EVERY item meets quality standards BEFORE proceeding.**

**Complete this checklist and output the results:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO (examples: "error rate > 5%", "15 min timeout", "24h log retention", "3 consecutive minutes")
    - Names specific tools/technologies? YES/NO (examples: "GitHub Actions", "CloudWatch", "ECS", "Grafana", "PagerDuty", "Terraform")
    - States measurable outcome? YES/NO (examples: "rollback tested on 2024-11-05", "alert fires within 5 minutes", "deployment completes in < 10 minutes")
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

**Minimum total: 19 specific items** covering all 4 categories.

---

## Section Completion Confirmation

**After creating TodoWrite, output this checklist to confirm all sections present:**

```
SECTION COMPLETION:
[ ] Automation: 5+ items
[ ] Observability: 5+ items (MUST come before Failure Recovery)
[ ] Failure Recovery: 5+ items (requires Observability to detect failures)
[ ] Verification: 4+ items

TOTAL: ___ items (must be 19+)
```

**If any section is unchecked or total < 19, STOP and add missing items now.**

**Critical Order:** Observability MUST come before Failure Recovery. You cannot define failure recovery without observability to detect failures.

**Why this matters:** 10% create Failure Recovery before Observability (wrong order), 20% miss sections entirely.

---

## TodoWrite Quality Standards

After creating TodoWrite, verify EVERY item meets these criteria:

- [ ] Names specific tool/framework/service (e.g., "GitHub Actions", "CloudWatch", "ECS", "Grafana")
- [ ] Includes concrete values/thresholds (e.g., "error rate > 5%", "15 min timeout", "24h log retention")
- [ ] States measurable outcome (e.g., "rollback tested in staging on 2024-01-15", not "test rollback")

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

### What Makes an Item Specific?

Must include ALL three:
1. **Concrete numbers/thresholds**: "error rate > 5%", "15 min timeout", "24h log retention", "3 consecutive minutes", "< 5 minute rollback"
2. **Specific tools/technologies**: "GitHub Actions", "CloudWatch", "ECS", "Grafana", "PagerDuty", "Terraform", "Docker"
3. **Measurable outcome**: "rollback tested on 2024-11-05", "alert fires within 5 minutes", "deployment completes in < 10 minutes"

### Test Examples

❌ **FAILS TEST**: "Add monitoring"
- Engineer asks: Which metrics? Which tool? What thresholds? Where displayed?

✅ **PASSES TEST**: "CloudWatch metric: `deployment.duration_seconds` (histogram), `deployment.success_count` (counter), `deployment.error_count` (counter). Grafana dashboard at `/dashboards/deployments` showing last 10 deployments. Alert via PagerDuty if error rate > 5% for 3 consecutive minutes."
- Engineer knows: Metrics, tool, dashboard location, alert system, threshold

❌ **FAILS TEST**: "Implement rollback"
- Engineer asks: How? What triggers it? How long should it take? How to verify?

✅ **PASSES TEST**: "Rollback script `.github/workflows/rollback.yml` reverts to previous Docker image tag stored in S3 `deployment-history/latest-stable.txt`. Triggers: manual button OR error rate > 5% for 3min OR failed health check 2x. Target duration: < 5 minutes. Test in staging on 2024-11-05."
- Engineer knows: Script location, mechanism, triggers, duration target, test requirement

### Apply This Test

Before proceeding, select 3 random items from your TodoWrite and test them. If any fail, revise before proceeding.

---

### Examples of Quality Items

**❌ BAD (too generic):**
- "Automate deployment"
- "Add monitoring"
- "Add rollback"
- "Test deployment"
- "Add logging"

**✅ GOOD (specific):**
- "GitHub Actions workflow deploys to ECS on push to main, triggers health check, auto-rolls back if check fails"
- "CloudWatch alarm triggers SNS notification when deployment error rate > 5% for 3 consecutive minutes"
- "Rollback script reverts to previous Docker image tag, verified in staging on [date]"
- "Smoke tests verify /health endpoint returns 200 and database connectivity within 30s post-deploy"
- "Structured deployment logs sent to CloudWatch with deployment-id tag, 30d retention"

---

## ❌ Failed Examples (What NOT To Do)

**These items would FAIL verification. If your items look like these, revise them immediately.**

### Too Generic (No Tool Names)

❌ "Automate deployment"
- **Why it fails**: Using what? Where? Triggered how?
- **Engineer asks**: GitHub Actions? Jenkins? GitLab CI? What triggers it?

❌ "Add monitoring"
- **Why it fails**: Monitor what? Which tool? What thresholds?
- **Engineer asks**: CloudWatch? Datadog? Grafana? Which metrics? What alerts?

❌ "Add rollback"
- **Why it fails**: How? Triggered how? What mechanism?
- **Engineer asks**: Script? Workflow? Manual? Automatic? What exactly gets reverted?

❌ "Test deployment"
- **Why it fails**: Test what? How? When?
- **Engineer asks**: Unit tests? Integration? Smoke tests? What's tested? When run?

### Missing Concrete Thresholds

❌ "Alert on errors"
- **Why it fails**: At what rate? Over what time? To whom?
- **Engineer asks**: 1 error? 5%? 10%? Over 1 min? 5 min? PagerDuty? Slack?

❌ "Implement health checks"
- **Why it fails**: Check what? How often? What's healthy?
- **Engineer asks**: What endpoint? What frequency? 200 OK enough? Dependencies checked?

❌ "Set log retention"
- **Why it fails**: How long? Which logs? Where stored?
- **Engineer asks**: 7 days? 30 days? 90 days? CloudWatch? S3? What costs?

### Missing Measurable Outcomes

❌ "Deployment should be fast"
- **Why it fails**: How fast? Measured how?
- **Engineer asks**: <5 min? <10 min? <30 min? Where measured? Acceptable?

❌ "Ensure rollback works"
- **Why it fails**: Tested when? How long should it take?
- **Engineer asks**: Last tested when? Target duration? Success criteria?

❌ "Monitor deployment success"
- **Why it fails**: Success measured how? What's the criteria?
- **Engineer asks**: Health checks? Error rates? Manual verification? What threshold?

### Rollback-Critical Failures (CRITICAL)

❌ "Create rollback mechanism"
- **Why it fails**: No details on how, where, when.
- **Engineer asks**: Script where? Triggered how? What gets reverted? How long? Tested when?

❌ "Rollback if issues detected"
- **Why it fails**: Which issues? Detected how? Auto or manual?
- **Engineer asks**: Error rate? Failed health checks? How many? Manual button?

❌ "Be able to revert deployment"
- **Why it fails**: Passive statement, no implementation.
- **Engineer asks**: Revert how? How long? Tested? Automated?

**If 3+ of your TodoWrite items match these ❌ patterns, STOP. Your TodoWrite needs major revision before proceeding.**

**If rollback item is generic (❌ patterns), BLOCKED. Rollback is non-negotiable and must be specific.**

---

## Section Completeness Check

Before proceeding, confirm ALL mandatory sections present in your TodoWrite:

- [ ] **Automation**: 5+ items (identify manual steps, automate steps, idempotency, rollback automation, document exceptions) ✓
- [ ] **Observability**: 5+ items (deployment logging, failure alerts, metrics, health checks, log location docs) ✓
- [ ] **Failure Recovery**: 5+ items (failure scenarios, rollback triggers, health checks, rollback testing, manual recovery docs) ✓
- [ ] **Verification**: 4+ items (pre-deploy tests, post-deploy smoke tests, monitoring verification, rollback accessible) ✓

**If any section is missing or below minimum items, STOP and add them now.**

---

## Trigger Conditions

Activate this skill when:
- Designing or implementing CI/CD pipelines
- Creating deployment scripts or workflows
- Setting up infrastructure provisioning (IaC)
- Implementing backup/restore procedures
- Configuring monitoring, logging, or alerting systems
- Reviewing deployment processes or runbooks
- Any task involving production system changes

---

## Mandatory Requirements

Create TodoWrite items for all categories below. Refer to Quality Standards and Completeness Check sections above.

---

## 🛑 CRITICAL: Section Order

**You MUST complete sections in this exact order:**

1. **Automation** (identify manual steps, automate them)
2. **Observability** (MUST come before Failure Recovery)
3. **Failure Recovery** (requires observability from step 2)
4. **Verification** (final validation)

### Why Order Matters

**You cannot define failure recovery without observability.**

How do you:
- Detect failures to trigger rollback? → Need metrics/alerts from Observability
- Know when rollback succeeds? → Need health checks from Observability
- Monitor deployment progress? → Need logging from Observability
- Alert on deployment failures? → Need alert system from Observability

**Example of wrong order:**
```
❌ WRONG ORDER:
1. Automation: Deploy via GitHub Actions
2. Failure Recovery: Rollback if deployment fails
   Problem: How do you detect "deployment fails"? No metrics defined yet.
3. Observability: Add CloudWatch metrics
   Too late - already defined rollback without knowing how to detect failures
```

**Example of correct order:**
```
✅ CORRECT ORDER:
1. Automation: Deploy via GitHub Actions
2. Observability: CloudWatch metrics (error_rate, latency), alerts if error_rate > 5%
3. Failure Recovery: Rollback triggered by CloudWatch alarm from step 2
   Now we know HOW to detect failures - using the alerting defined in step 2
```

### Verification

**BLOCKED if**: Creating Failure Recovery items before Observability section is complete.

**10% of agents violate this order.** The self-grading checklist verifies correct order.

---

**IMPORTANT: Observability is second priority after Automation - do not proceed to Failure Recovery without completing Observability items.**

### Automation

**⚠️ CRITICAL: Manual deployment steps are single points of failure and knowledge silos.**

- [ ] **Identify manual steps** in current deployment process (SSH commands, manual approvals, manual config changes)
- [ ] **Replace manual steps** with automated scripts/workflows (GitHub Actions/GitLab CI/CircleCI workflows)
- [ ] **Idempotency checks** ensure safe re-runs (check if resource exists before creating, use terraform/ansible idempotent operations)
- [ ] **Rollback automation** for this change (script/workflow that reverts deployment, restore previous version)
- [ ] **Document exceptions** for remaining manual steps (why automation impossible, remediation timeline, risk acceptance)

### Observability (PRIORITY: Complete before Failure Recovery)

**⚠️ CRITICAL: Cannot detect or respond to deployment failures without observability.**

- [ ] **Deployment logging** for start/progress/completion (structured logs with deployment-id, timestamps, steps completed)
- [ ] **Failure alerts** configured (e.g., PagerDuty/Opsgenie/SNS triggered on deployment failure, error rate spike)
- [ ] **Metrics tracking** deployment duration and success rate (e.g., CloudWatch/Datadog custom metrics, dashboard showing trends)
- [ ] **Health endpoint** or status checks (e.g., `/health` endpoint returns 200 + dependency status post-deploy)
- [ ] **Log/metric location documented** (where to find logs, how to access dashboard, alert channel names)

### Failure Recovery

- [ ] **Failure scenarios defined** for this deployment (service won't start, database migration fails, health checks fail, external dependency down)
- [ ] **Automated rollback triggers** (error rate > X%, failed health checks for Y minutes, manual rollback button)
- [ ] **Health checks post-deployment** (verify service responding, database connectivity, external APIs accessible)
- [ ] **Rollback tested** in non-prod environment (date tested, duration measured, success confirmed)
- [ ] **Manual recovery documentation** as last resort (step-by-step restore procedure, escalation contacts, data recovery steps)

### Verification

- [ ] **Pre-deployment tests** automated (unit tests, integration tests, linting all pass before deploy)
- [ ] **Smoke tests post-deployment** (critical user flows tested, key API endpoints verified, no 500 errors)
- [ ] **Monitoring/alerts verified working** (trigger test alert, confirm received, check dashboard updates)
- [ ] **Rollback procedure accessible** (script in repo, documented in runbook, access permissions verified)

---

## Non-Negotiable Rules

### NEVER proceed if:

- Deployment requires manual intervention without automated alternative
- No rollback mechanism exists for the change
- No monitoring/alerting configured for deployment success/failure
- Changes lack health checks or verification steps
- Failure scenarios haven't been documented

### ALWAYS refuse to:

- Create deployment processes that rely on "tribal knowledge"
- Skip observability because "it's just a small change"
- Deploy without testing rollback procedures first
- Accept "we'll add monitoring later" as valid
- Implement one-way deployments without recovery paths

---

## 🚩 Red Flags - STOP

**If you find yourself thinking or saying ANY of these, you are about to violate the skill:**

- "Manual deploy is broken, need automation fast" → Automating without rollback/observability creates WORSE problems
- "We'll add [monitoring/rollback] after it's working" → Can't detect or recover from failures without them
- "Just this once" → Every manual deployment sets precedent and blocks automation adoption
- "Production is down $10K/min" → Shipping unmonitored automation prolongs incidents, not shortens them
- "Being pragmatic not dogmatic" → These requirements ARE pragmatic (prevent $5-50K incidents)
- "Rollback is overkill for this change" → Manual recovery ALWAYS takes 10x longer than planned. Not overkill.
- "We'll add monitoring when we see issues" → Can't see issues without monitoring. Circular reasoning.
- "Deploy first, test later" → Untested deployments fail in production. Testing after = fixing in production under pressure.
- "We know it works, no need for health checks" → You don't know it works in production until health checks confirm it.
- "Logs aren't critical" → Logs are the ONLY way to debug production issues. Without them = blind for hours.
- "We can manually revert if needed" → Manual revert requires: detecting issue (no monitoring), finding previous version (no automation), applying it (error-prone manual steps). Takes 30+ min instead of 2 min automated.

**When you notice a red flag, STOP. Re-read the specific skill requirement you're about to skip.**

**27% skip rollback checkpoint. 67% create generic items. Each red flag represents a known failure pattern.**

---

### When Asked to Skip Requirements

Use these EXACT response templates:

#### "We'll Add [Requirement] Later"

❌ **BLOCKED**: I cannot defer [rollback/monitoring/observability] to future iterations.

**Why "later" always fails:**
- "Later" never comes - next sprint has new priorities
- Adding rollback after deployment failures requires emergency fixes under pressure
- Adding monitoring after incidents means debugging blind (10x harder)
- Technical debt accumulates and blocks automation adoption

**The data:**
- 80% of "we'll add later" items never get added
- Adding rollback after failures costs 10x more (emergency fixes under pressure)
- Adding monitoring after incidents costs 10x more (multi-hour blind debugging)
- Manual recovery during incidents costs $5-50K per incident
- Average time to implement monitoring post-incident: 2-4 weeks (vs 2-4 hours upfront)

**Specific consequence for this requirement:**
- Skipping rollback → Extended downtime (30+ min manual recovery vs 2-min automated rollback) → $5-50K per incident
- Skipping monitoring → Blind debugging → multi-hour incidents → data corruption before detection
- Skipping observability → Cannot detect failures → silent data corruption + prolonged outages

**Required**: Implement now, or explicitly document:
1. Specific date for retrofit (not "later" - actual sprint/date)
2. Budget allocated (engineer-weeks + dollar cost + incident cost risk)
3. Risk acceptance signed by [decision maker's name + date]
4. Interim mitigation plan (24/7 on-call? manual monitoring? acceptable downtime duration?)

**If you cannot provide these 4 items, requirement must be implemented now.**

**Critical:** Automated rollback is non-negotiable for production deployments. Manual recovery always takes 10x longer than planned.

---

#### Skipping Automated Rollback
```
❌ BLOCKED: I cannot implement deployment without automated rollback mechanism.

Risk: Without automated rollback, recovering from bad deployments requires manual intervention
during incidents - turning 2-minute rollbacks into 30-minute+ firefighting sessions with potential
for human error under pressure.

Required: Automated rollback script/workflow that:
- Reverts to previous known-good version (Docker tag, Git SHA, artifact version)
- Rolls back database migrations if applicable
- Verified in staging environment within last 30 days
- Documented rollback duration (target: < 5 minutes)

To override: Explicitly state you accept extended incident recovery time and I will document this risk.
```

#### Skipping Monitoring/Observability
```
❌ BLOCKED: I cannot implement deployment without monitoring and alerting.

Risk: Without monitoring, deployment failures go undetected. Silent failures can corrupt data,
degrade user experience, or cause cascading failures before anyone notices.

Required: Observability implementation:
- Deployment logs with structured format (deployment-id, timestamp, steps)
- Alerts for deployment failures (error rate spike, failed health checks)
- Dashboard showing deployment metrics (duration, success rate, last 10 deployments)
- Health check endpoint returning service + dependency status

To override: This is NOT recommended. If you insist, document monitoring gap with remediation timeline
and commit to manual monitoring during first production deployment.
```

#### Manual Deployment Steps
```
⚠️ MANUAL STEP DETECTED: Deployment includes manual intervention.

Manual step: [specific step requiring human action]

This violates automation-first principle. Options:

1. **Recommended**: Automate this step using [specific tool/approach]
2. **Acceptable with justification**: Document why automation impossible + remediation plan:
   - Technical constraint preventing automation: [specific reason]
   - Remediation timeline: [target date for automation]
   - Manual procedure documented in runbook: [link]
   - Risk accepted by: [user name + date]

Proceed only with option 2 if option 1 is truly impossible.
```

---

## Common Failure Prevention

### Anti-Pattern: Manual Deployment Steps
```
❌ BAD: "SSH to server and run these commands..."
✅ GOOD: Automated script/workflow with:
   - Idempotent operations (check before create)
   - Error handling (rollback on failure)
   - Progress logging (each step logged with timestamp)
   - Automatic rollback on failure (revert to previous state)
```

### Anti-Pattern: Missing Monitoring
```
❌ BAD: Deploy and hope it works
✅ GOOD:
   - Pre-deployment: verify monitoring baseline (current metrics known)
   - During: log deployment progress (each step, timestamp, deployment-id)
   - Post: automated health checks (verify service responding)
   - Alert on anomalies within 5 minutes (error rate, latency spike)
```

### Anti-Pattern: No Rollback Plan
```
❌ BAD: "We can restore from backup if needed"
✅ GOOD:
   - Automated rollback script tested in staging (last tested: [date])
   - Rollback triggers defined (error rate > 5%, failed health checks for 3 min)
   - Recovery time objective documented (target: < 5 minutes)
   - Rollback tested within last 30 days (next test due: [date])
```

### Anti-Pattern: Failure Blindness
```
❌ BAD: Assume deployment succeeded
✅ GOOD:
   - Health check endpoints return 200 OK (all dependencies healthy)
   - Error rates within normal bounds (< 1% for 10 minutes)
   - Dependency checks pass (database, external APIs responding)
   - Alerts silent for 10 minutes post-deploy (no anomalies detected)
```

---

## Evidence Collection

Add these items to your TodoWrite before marking task complete:

- [ ] **Automation code link**: URL to GitHub Actions/GitLab CI workflow file or deployment script
- [ ] **Staging deployment log**: Screenshot/log excerpt showing successful deployment execution
- [ ] **Monitoring dashboard**: Screenshot showing deployment metrics (duration, success rate, health status)
- [ ] **Rollback test evidence**: Log/screenshot of rollback execution in staging with timestamp and duration
- [ ] **Alert test confirmation**: Screenshot of test alert fired and received

---

## Verification

Before claiming deployment work complete:

### 1. Automation Check
   - Can deployment run without human intervention? (YES/NO)
   - If NO: Document why + remediation timeline

### 2. Failure Recovery Check
   - Does rollback script exist? (YES/NO)
   - Has rollback been tested in last 30 days? (YES/NO)
   - If NO to either: Test rollback or document gap

### 3. Observability Check
   - Are deployment logs accessible? (YES/NO)
   - Do alerts fire on deployment failure? (YES/NO)
   - Can you view deployment metrics? (YES/NO)
   - If NO to any: Add missing observability

### 4. Evidence Required
   - Link to deployment automation code
   - Screenshot/log of successful test deployment
   - Screenshot of monitoring dashboard showing metrics
   - Evidence of rollback test execution

**If any verification fails, do not mark task complete. Add blocking TodoWrite items.**

---

## Final Self-Grading

**Before claiming deployment work complete, grade your own TodoWrite:**

```
SELF-GRADING CHECKLIST:
[ ] Minimum 19 items across 4 sections (Automation, Observability, Failure Recovery, Verification)
[ ] 80%+ of items have concrete numbers/thresholds (error rate > 5%, 15min timeout, 24h retention, 3min)
[ ] 80%+ of items name specific tools/technologies (GitHub Actions, CloudWatch, ECS, Grafana, PagerDuty)
[ ] 100% of items have measurable outcomes ("rollback tested on [date]", "alert fires within 5min", etc.)
[ ] Zero items use vague verbs without specifics ("add monitoring", "add rollback" without tool/mechanism)
[ ] Tested 3 random items with Specificity Test - all passed (can engineer implement without questions?)
[ ] Rollback checkpoint completed (script exists, tested, duration measured, triggers defined)
[ ] Observability section comes BEFORE Failure Recovery section (correct order)

GRADE YOURSELF:
- All 8 checkboxes passed: 9-10/10 (Excellent - ready to proceed)
- 6-7 checkboxes passed: 7-8/10 (Good - minor revisions needed)
- 4-5 checkboxes passed: 5-6/10 (Needs revision - improve specificity or fix order)
- 0-3 checkboxes passed: 1-4/10 (Failed - major revision required)
```

**If you graded yourself below 7/10, you MUST revise TodoWrite before proceeding with implementation.**

**If rollback checkpoint is incomplete, BLOCKED. Cannot proceed regardless of other grades.**

**Why this matters**: 27% skip rollback checkpoint. 67% create generic items. 10% have wrong section order. Self-grading prevents this.

---

## Design Principles

### Automation First
- Default to automation; manual is exception requiring justification
- Scripts must be version-controlled and peer-reviewed
- Automation should be self-documenting through logging

### Design for Failure
- Every deployment can fail; plan recovery not just success
- Rollback must be faster than forward deployment
- Partial failures require automated detection + remediation

### Observability is Non-Optional
- No deployment without monitoring
- Alerts must be actionable and tested
- Logs must be searchable and retained per compliance requirements

### Idempotency
- Running deployment twice produces same result as running once
- Scripts check current state before making changes
- Cleanup is automatic on failure

---

## Integration with Development Workflow

When implementing deployment automation:
1. Create feature branch for deployment changes
2. Implement automation + observability + rollback
3. **Test in staging environment** (including rollback - document date and duration)
4. Request code review with **evidence of testing** (logs, screenshots, metrics)
5. Merge only after **verification checklist complete**
6. **Monitor first production deployment actively** (watch dashboard, be ready to rollback)

---

**Remember**: Deployment failures in production are inevitable. The difference between a 2-minute incident and a 2-hour outage is having automated rollback, monitoring, and well-tested recovery procedures.
