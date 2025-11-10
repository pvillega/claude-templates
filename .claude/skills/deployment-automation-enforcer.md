---
name: deployment-automation-enforcer
description: Use when designing or implementing deployment pipelines, CI/CD workflows, infrastructure provisioning, or any automation that touches production systems - enforces automation-first principles, failure recovery design, and mandatory observability
---

# Deployment Automation Enforcer

## Why This Matters (Read Once, Reference Throughout)

**Time pressure and production emergencies are NOT exceptions to this skill.** Shortcuts under pressure create:
- $5-50K per incident from missing rollback mechanisms (extended downtime)
- Silent failures that corrupt data before detection (missing observability)
- Manual recovery requiring 30+ minutes instead of 2-minute automated rollback
- Tribal knowledge silos that block team scaling

**These requirements ARE pragmatic** - they prevent expensive incidents, not create bureaucracy.

---

## 🛑 ROLLBACK CHECKPOINT (COMPLETE THIS FIRST)

**MANDATORY: Before creating TodoWrite, answer these questions:**

- [ ] **Rollback script exists?** YES/NO [If YES, provide path: _________ | If NO, document "NEW DEPLOYMENT - will create rollback as first TodoWrite item"]
- [ ] **Rollback tested in staging?** YES/NO [If YES, date tested: _________ | If NO or >30 days ago, must test before production]
- [ ] **Rollback time measured?** YES/NO [If YES, duration: _________ minutes | If NO, must measure during test]
- [ ] **Rollback triggers defined?** YES/NO [If YES, list triggers: _________ | If NO, define them now]

**Why this comes first:** 27% of agents skip rollback requirements when this checkpoint appears later.

---

## TodoWrite Creation & Verification

**STOP. Before proceeding, you MUST:**

1. **CREATE TodoWrite** with these 4 sections (minimum 19 items total):
   - **Automation**: 5+ items
   - **Observability**: 5+ items (MUST come before Failure Recovery)
   - **Failure Recovery**: 5+ items (requires Observability to detect failures)
   - **Verification**: 4+ items

2. **VERIFY TodoWrite quality** - each item must include ALL three:
   - **Concrete numbers/thresholds**: "error rate > 5%", "15 min timeout", "24h log retention", "3 consecutive minutes"
   - **Specific tools/technologies**: "GitHub Actions", "CloudWatch", "ECS", "Grafana", "PagerDuty", "Terraform"
   - **Measurable outcome**: "rollback tested on 2024-11-05", "alert fires within 5 minutes", "deployment completes in < 10 minutes"

3. **COMPLETE verification checklist** (below) before proceeding with implementation

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT

**After creating TodoWrite, verify 3 random items meet quality standards:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO
    - Names specific tools/technologies? YES/NO
    - States measurable outcome? YES/NO
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

**Confirm section completeness:**

```
SECTION COMPLETION:
[ ] Automation: 5+ items
[ ] Observability: 5+ items (MUST come before Failure Recovery)
[ ] Failure Recovery: 5+ items (requires Observability to detect failures)
[ ] Verification: 4+ items

TOTAL: ___ items (must be 19+)
```

**DO NOT PROCEED WITH IMPLEMENTATION until all checks pass.**

---

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

| Quality Check | ❌ FAILS TEST | ✅ PASSES TEST |
|---------------|---------------|----------------|
| **Example 1** | "Add monitoring"<br>*Engineer asks: Which metrics? Which tool? What thresholds? Where displayed?* | "CloudWatch metric: `deployment.duration_seconds` (histogram), `deployment.success_count` (counter), `deployment.error_count` (counter). Grafana dashboard at `/dashboards/deployments` showing last 10 deployments. Alert via PagerDuty if error rate > 5% for 3 consecutive minutes."<br>*Engineer knows: Metrics, tool, dashboard location, alert system, threshold* |
| **Example 2** | "Implement rollback"<br>*Engineer asks: How? What triggers it? How long should it take? How to verify?* | "Rollback script `.github/workflows/rollback.yml` reverts to previous Docker image tag stored in S3 `deployment-history/latest-stable.txt`. Triggers: manual button OR error rate > 5% for 3min OR failed health check 2x. Target duration: < 5 minutes. Test in staging on 2024-11-05."<br>*Engineer knows: Script location, mechanism, triggers, duration target, test requirement* |

**Apply this test:** Select 3 random items from your TodoWrite. If any fail, revise before proceeding.

---

## 🚩 Red Flags & Anti-Patterns

**If you find yourself thinking ANY of these, STOP and re-read the skill requirements:**

| Red Flag Rationalization | Why It's Wrong | Known Failure Rate |
|--------------------------|----------------|-------------------|
| "Manual deploy is broken, need automation fast" | Automating without rollback/observability creates WORSE problems | 27% skip rollback |
| "We'll add [monitoring/rollback] after it's working" | Can't detect or recover from failures without them (circular reasoning) | 80% never add "later" |
| "Just this once" | Every manual deployment sets precedent and blocks automation adoption | N/A |
| "Production is down $10K/min" | Shipping unmonitored automation prolongs incidents, not shortens them | N/A |
| "Rollback is overkill for this change" | Manual recovery ALWAYS takes 10x longer than planned | Average 30+ min manual vs 2 min automated |
| "We'll add monitoring when we see issues" | Can't see issues without monitoring (circular reasoning) | Silent failures cause data corruption |
| "Logs aren't critical" | Logs are the ONLY way to debug production issues | Multi-hour blind debugging |
| "We can manually revert if needed" | Manual revert: detect issue (no monitoring) + find previous version (no automation) + apply (error-prone) = 30+ min vs 2 min automated | N/A |

**When you notice a red flag:** Re-read the specific skill requirement you're about to skip.

---

## 🛑 CRITICAL: Section Order

**You MUST complete sections in this exact order:**

1. **Automation** (identify manual steps, automate them)
2. **Observability** (MUST come before Failure Recovery)
3. **Failure Recovery** (requires observability from step 2)
4. **Verification** (final validation)

**Why:** You cannot define failure recovery without observability to detect failures.

**Example comparison:**

| ❌ WRONG ORDER | ✅ CORRECT ORDER |
|----------------|------------------|
| 1. Automation: Deploy via GitHub Actions<br>2. Failure Recovery: Rollback if deployment fails<br>**Problem: How do you detect "deployment fails"? No metrics defined yet.**<br>3. Observability: Add CloudWatch metrics<br>**Too late - already defined rollback without knowing how to detect failures** | 1. Automation: Deploy via GitHub Actions<br>2. Observability: CloudWatch metrics (error_rate, latency), alerts if error_rate > 5%<br>3. Failure Recovery: Rollback triggered by CloudWatch alarm from step 2<br>**Now we know HOW to detect failures - using the alerting defined in step 2** |

**BLOCKED if:** Creating Failure Recovery items before Observability section is complete (10% of agents violate this order).

---

## Mandatory Requirements

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

| NEVER proceed if | ALWAYS refuse to |
|------------------|------------------|
| Deployment requires manual intervention without automated alternative | Create deployment processes that rely on "tribal knowledge" |
| No rollback mechanism exists for the change | Skip observability because "it's just a small change" |
| No monitoring/alerting configured for deployment success/failure | Deploy without testing rollback procedures first |
| Changes lack health checks or verification steps | Accept "we'll add monitoring later" as valid |
| Failure scenarios haven't been documented | Implement one-way deployments without recovery paths |

---

## Response Templates for Skipped Requirements

### "We'll Add [Requirement] Later"

❌ **BLOCKED**: I cannot defer [rollback/monitoring/observability] to future iterations.

**Why "later" always fails:**
- 80% of "we'll add later" items never get added
- Adding rollback after failures costs 10x more (emergency fixes under pressure)
- Adding monitoring after incidents costs 10x more (multi-hour blind debugging)
- Manual recovery during incidents costs $5-50K per incident

**Required:** Implement now, or explicitly document:
1. Specific date for retrofit (not "later" - actual sprint/date)
2. Budget allocated (engineer-weeks + dollar cost + incident cost risk)
3. Risk acceptance signed by [decision maker's name + date]
4. Interim mitigation plan (24/7 on-call? manual monitoring? acceptable downtime duration?)

**If you cannot provide these 4 items, requirement must be implemented now.**

### Skipping Automated Rollback

❌ **BLOCKED**: I cannot implement deployment without automated rollback mechanism.

**Risk:** Without automated rollback, recovering from bad deployments requires manual intervention during incidents - turning 2-minute rollbacks into 30-minute+ firefighting sessions with potential for human error under pressure.

**Required:** Automated rollback script/workflow that:
- Reverts to previous known-good version (Docker tag, Git SHA, artifact version)
- Rolls back database migrations if applicable
- Verified in staging environment within last 30 days
- Documented rollback duration (target: < 5 minutes)

**To override:** Explicitly state you accept extended incident recovery time and I will document this risk.

### Skipping Monitoring/Observability

❌ **BLOCKED**: I cannot implement deployment without monitoring and alerting.

**Risk:** Without monitoring, deployment failures go undetected. Silent failures can corrupt data, degrade user experience, or cause cascading failures before anyone notices.

**Required:** Observability implementation:
- Deployment logs with structured format (deployment-id, timestamp, steps)
- Alerts for deployment failures (error rate spike, failed health checks)
- Dashboard showing deployment metrics (duration, success rate, last 10 deployments)
- Health check endpoint returning service + dependency status

**To override:** This is NOT recommended. If you insist, document monitoring gap with remediation timeline and commit to manual monitoring during first production deployment.

### Manual Deployment Steps

⚠️ **MANUAL STEP DETECTED**: Deployment includes manual intervention.

**Manual step:** [specific step requiring human action]

**Options:**
1. **Recommended**: Automate this step using [specific tool/approach]
2. **Acceptable with justification**: Document why automation impossible + remediation plan:
   - Technical constraint preventing automation: [specific reason]
   - Remediation timeline: [target date for automation]
   - Manual procedure documented in runbook: [link]
   - Risk accepted by: [user name + date]

**Proceed only with option 2 if option 1 is truly impossible.**

---

## Common Anti-Patterns

| Anti-Pattern | ❌ BAD | ✅ GOOD |
|--------------|--------|---------|
| **Manual Deployment Steps** | "SSH to server and run these commands..." | Automated script/workflow with: idempotent operations, error handling, progress logging, automatic rollback on failure |
| **Missing Monitoring** | Deploy and hope it works | Pre-deployment: verify monitoring baseline<br>During: log deployment progress<br>Post: automated health checks<br>Alert on anomalies within 5 minutes |
| **No Rollback Plan** | "We can restore from backup if needed" | Automated rollback script tested in staging (last tested: [date]), rollback triggers defined (error rate > 5%, failed health checks for 3 min), recovery time objective documented (target: < 5 minutes), rollback tested within last 30 days |
| **Failure Blindness** | Assume deployment succeeded | Health check endpoints return 200 OK, error rates within normal bounds (< 1% for 10 minutes), dependency checks pass, alerts silent for 10 minutes post-deploy |

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

**Why this matters:** 27% skip rollback checkpoint. 67% create generic items. 10% have wrong section order. Self-grading prevents this.

---

## Evidence Collection

Add these items to your TodoWrite before marking task complete:

- [ ] **Automation code link**: URL to GitHub Actions/GitLab CI workflow file or deployment script
- [ ] **Staging deployment log**: Screenshot/log excerpt showing successful deployment execution
- [ ] **Monitoring dashboard**: Screenshot showing deployment metrics (duration, success rate, health status)
- [ ] **Rollback test evidence**: Log/screenshot of rollback execution in staging with timestamp and duration
- [ ] **Alert test confirmation**: Screenshot of test alert fired and received

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
