---
name: backend-reliability-enforcer
description: Use when implementing backend systems, APIs, data persistence, or any server-side component - enforces reliability, fault tolerance, and data integrity as non-negotiable requirements
---

# Backend Reliability Enforcer

## ⚠️ MANDATORY FIRST STEP

### Anti-Rationalization Warning

**Time pressure, tight deadlines, and customer urgency are NOT exceptions.**

Shortcuts create: financial loss (payment bugs cost thousands), compliance violations (GDPR, PCI-DSS), multi-hour incidents (cascade failures), customer trust damage.

| Rationalization | Why It Fails |
|----------------|--------------|
| "Add [error handling/security] later" | Reliability requirements are NOT optional |
| "Add [idempotency/transactions] in v2" | Retrofitting costs 10x more + requires refunds |
| "Just this once" | Every shortcut creates technical debt |
| "Customer needs it in 3 days" | Shipping broken code causes MORE delay |
| "Being pragmatic not dogmatic" | These ARE pragmatic (learned from incidents) |
| "That edge case is unlikely" | Unlikely × scale = frequent data corruption |

**If thinking these thoughts, STOP. Re-read requirements.**

---

### TodoWrite Creation Requirements

**Before proceeding, CREATE TodoWrite with 5 sections (25+ items total):**

1. **Fault Tolerance**: 5+ items
2. **Error Handling**: 5+ items
3. **Data Integrity**: 5+ items
4. **Security**: 5+ items
5. **Observability**: 5+ items

**Output this template:**

```
=== TODOWRITE CREATION ===

**Fault Tolerance** (5+ items):
[List items]

**Error Handling** (5+ items):
[List items]

**Data Integrity** (5+ items):
[List items]

**Security** (5+ items):
[List items]

**Observability** (5+ items):
[List items]

TOTAL: ___ items (must be 25+)

=== TODOWRITE CREATED ===
```

**Do not analyze, plan, or implement until TodoWrite is created and verified.**

---

## Verification Checkpoint

**Verify 3 random items meet ALL criteria:**

| Criteria | Example |
|----------|---------|
| Concrete numbers/thresholds | "5 failures/10s", "15s timeout", "100 req/min" |
| Specific tools/technologies | "Opossum", "pino", "Joi", "Knex", "Redis" |
| Measurable outcome | "generates UUID v4 correlation ID" |

**Test format:**
```
[ ] Item 1: [paste text]
    - Concrete numbers? YES/NO
    - Specific tools? YES/NO
    - Measurable outcome? YES/NO
[ ] Item 2: [repeat]
[ ] Item 3: [repeat]

RESULT: All 9 checks = YES
```

**BLOCKED if any NO. Revise and re-verify.**

---

## 🛑 PAYMENT OPERATIONS CHECKPOINT

**STOP: If implementing payment processing, subscription billing, refunds, or any financial transactions, complete this checkpoint FIRST.**

**Answer these questions:**

1. Does this involve charging customers money? **YES / NO**
2. Does this handle subscription state changes (active/canceled/past_due)? **YES / NO**
3. Does this process refunds or credits? **YES / NO**
4. Does this handle recurring billing? **YES / NO**

**If ANY answer is YES, you MUST include ALL of these in your Data Integrity section (NON-NEGOTIABLE):**

### Payment-Critical Requirements (MANDATORY - NO EXCEPTIONS)

**1. Idempotency Keys:**
- Accept `Idempotency-Key` request header (UUID v4 format)
- Atomic storage (Redis SET NX EX or PostgreSQL unique constraint)
- Return cached response if key exists (prevent duplicate charges)
- 24-hour minimum TTL

**2. Database Transactions:**
- Wrap ALL write operations in BEGIN/COMMIT/ROLLBACK
- Include: charge record + subscription update + audit entry (atomic)
- Handle rollback on any failure (no partial states)
- Specify tool: Knex/Sequelize/Prisma transaction blocks

**3. Audit Trail:**
- Who initiated (user_id, IP address)
- Payment method (last 4 digits only)
- Amount and currency
- Timestamp (ISO 8601 with timezone)
- Success/failure status
- Transaction ID (Stripe charge_id or similar)
- Old state → New state (for subscriptions)

### Verification Checklist (Complete Before Proceeding)

```
PAYMENT CHECKPOINT VERIFICATION:
[ ] Idempotency mechanism specified: [describe: header name, storage system, TTL]
[ ] Transaction boundaries defined: [list which operations wrapped in transaction]
[ ] Audit trail fields listed: [list all 7+ required fields]
[ ] Reconciliation process defined: [how to compare internal records vs payment provider]
[ ] Retry safety verified: [confirm retrying with same key returns cached result]
```

**BLOCKED: If any checkbox is empty, you cannot proceed with payment implementation.**

**Why this is non-negotiable:**
- Missing idempotency = duplicate charges = customer refunds + loss of trust
- Missing transactions = data corruption = manual cleanup + financial loss
- Missing audit trail = unreconcilable accounts = compliance violations + no debugging capability

---

## TodoWrite Quality Standards

**Specificity Test: "Could an engineer implement this tomorrow without asking questions?"**

### Required Elements (ALL three)

| Element | Examples |
|---------|----------|
| Concrete numbers/thresholds | "5 failures/10s", "15s timeout", "100 req/min", "24h TTL" |
| Specific tools/technologies | "Opossum", "pino", "Joi", "Knex", "Redis", "axios" |
| Measurable outcome | "generates UUID v4 correlation ID", "validates email format" |

### Quality Examples

| ❌ Generic (FAILS) | ✅ Specific (PASSES) |
|-------------------|---------------------|
| "Add error handling" | "Structured logging with pino: UUID v4 correlation ID from `X-Correlation-ID` header in format `{correlationId, level, timestamp, service, message}`" |
| "Validate input" | "Joi schema: `amount` (number, positive, max 999999), `currency` (ISO 4217), `customer_id` (UUID v4). Return 400 with `{error: 'validation_failed', fields: [...]}`" |
| "Add circuit breaker" | "Opossum circuit breaker: 5 failures/10s threshold, 30s reset, fallback to cached data" |
| "Add timeout" | "axios timeout: 15s for Stripe API calls, 5s for database queries" |
| "Prevent duplicate charges" | "`Idempotency-Key` header (UUID v4), Redis SET NX EX 24h, return cached response if exists" |

---

## Trigger Conditions

Activate this skill when:
- Implementing or modifying backend APIs, services, or endpoints
- Designing data persistence, caching, or state management
- Adding external service integrations or third-party API calls
- Working on authentication, authorization, or security components
- Implementing background jobs, message queues, or async processing
- Making changes to database schemas or data access layers

---

## Mandatory Requirements

Create TodoWrite items for all categories below. Refer to Quality Standards and Completeness Check sections above.

### Fault Tolerance

**⚠️ CRITICAL: External service calls without fault tolerance cause cascade failures.**

- [ ] **Circuit breaker** for ALL external service calls (e.g., Hystrix/Opossum with 5 failures/10s threshold, 30s reset)
- [ ] **Retry logic** with exponential backoff for transient failures (e.g., 3 retries with 100ms, 200ms, 400ms backoff)
- [ ] **Timeouts** configured for all I/O operations (e.g., 15s for API calls, 5s for database queries)
- [ ] **Graceful degradation** behavior when dependencies fail (e.g., return cached data, disable non-critical features)
- [ ] **Health checks** for service availability monitoring (e.g., `/health` endpoint returning dependency status)

### Error Handling

- [ ] **Comprehensive error handling** at all integration points (try/catch blocks, error middleware, promise rejection handlers)
- [ ] **Correlation IDs** for request tracing (e.g., generate UUID v4 on ingress, pass through all logs and downstream services)
- [ ] **Structured logging** with appropriate levels (INFO, WARN, ERROR) using pino/winston, include correlation ID
- [ ] **Error responses** with actionable information, appropriate HTTP status codes (400/401/403/404/422/500), never expose stack traces
- [ ] **Error metrics/alerts** for rate thresholds (e.g., Prometheus counter, alert if error rate > 5%)

### Data Integrity

- [ ] **Input validation** at API boundaries (Joi/Zod schema validation, type checking, sanitization)
- [ ] **Database transactions** where data consistency is critical (e.g., Knex/Sequelize transactions for multi-table updates)
- [ ] **Idempotency keys** for write operations that may be retried (e.g., read `Idempotency-Key` header, store in Redis 24h TTL)
- [ ] **Data retention policies** defined and enforced (e.g., auto-delete soft-deleted records after 90 days)
- [ ] **Audit trails** for sensitive data modifications (who, what, when, old value, new value logged to audit table)

### Security

- [ ] **Authentication** enforced on all endpoints (JWT/OAuth/API keys validated on every request)
- [ ] **Authorization** checks for resource access (RBAC, verify user permissions before operations)
- [ ] **Input sanitization** to prevent injection attacks (SQL parameterized queries, XSS prevention, command injection guards)
- [ ] **Encryption** for sensitive data at rest (AES-256) and in transit (TLS 1.3)
- [ ] **Rate limiting** configured to prevent abuse (e.g., 100 requests/minute per IP using express-rate-limit)
- [ ] **Security headers** properly configured (CORS, CSP, X-Frame-Options, helmet.js)

### Observability

- [ ] **Structured logging** at appropriate levels (INFO: requests/responses, WARN: degraded state, ERROR: failures)
- [ ] **Key metrics** instrumented (latency P50/P95/P99, throughput requests/sec, error rate %) using Prometheus/StatsD
- [ ] **Distributed tracing** enabled for request flows (OpenTelemetry, Jaeger, DataDog APM with trace/span IDs)
- [ ] **Dashboards/alerts** configured for critical metrics (Grafana dashboards, PagerDuty/Opsgenie alerts for SLO breaches)
- [ ] **Runbook documentation** for operational procedures (how to investigate errors, rollback procedures, escalation paths)

---

## ⚠️ PAYMENT OPERATIONS - CRITICAL REQUIREMENTS

If implementing payment processing, subscription billing, or financial transactions:

- [ ] **Idempotency keys MANDATORY** (via request header `Idempotency-Key`, stored in Redis/DB, prevent duplicate charges)
- [ ] **Database transactions MANDATORY** for all write operations (atomicity: charge + subscription record + audit entry)
- [ ] **Audit trail MANDATORY** (who initiated, payment method, amount, timestamp, success/failure, transaction ID)
- [ ] **Reconciliation** process defined (daily comparison of internal records vs payment provider reports)
- [ ] **Retry safety** verified (retrying failed payment attempt doesn't create duplicate charge)

**NO EXCEPTIONS - payment bugs cause financial loss and compliance violations.**

---

## Non-Negotiable Rules

### NEVER compromise on:

1. **Reliability over speed**: Refuse to skip fault tolerance mechanisms to "ship faster"
2. **Data integrity**: Block any change that risks data corruption or loss
3. **Security by default**: All endpoints must have authentication/authorization before going live
4. **Fail-safe behavior**: Systems must fail gracefully, never leave data in inconsistent state

---

## Red Flags & Anti-Patterns

**If thinking ANY of these, STOP and re-read requirements:**

| Red Flag | Why It Fails | Consequence |
|----------|--------------|-------------|
| "Add [reliability] later" | 80% never added, retrofitting costs 10x | Production incidents, data corruption |
| "Just this once" | Creates technical debt precedent | Cascading shortcuts |
| "Customer needs it in 3 days" | Broken code causes MORE delay | Emergency fixes, refunds |
| "That edge case is unlikely" | Unlikely × scale = frequent | Data corruption at scale |
| "Manual testing is enough" | Manual ≠ systematic | Production bugs slip through |
| "Code review will catch it" | Review ≠ substitute for requirements | Assumes you built it right |
| "Internal tool = lower quality" | Processes real data | Same corruption impact |
| "Add logging after issues" | Can't debug without logs | Hours of blind debugging |
| "Circuit breaker is overkill" | One slow service = cascade | System-wide outages |
| "Validation slows development" | Prevents corruption | Cleanup costs 100x more |

**For payment operations, ANY red flag = CATASTROPHIC. No compromises.**

---

## Response Templates for Pushback

### "We'll Add [Requirement] Later"

```
❌ BLOCKED: Cannot defer [requirement] to future iterations.

Why "later" fails:
- 80% never get added (next sprint has new priorities)
- Retrofitting costs 10x more
- Production bugs require emergency fixes + refunds

Consequences if skipped:
- Idempotency → Duplicate charges → $10K-100K refunds + compliance violations
- Transactions → Data corruption → days of manual cleanup
- Observability → Blind incidents → multi-hour debugging
- Circuit breakers → Cascade failures → system-wide outages

Required to defer:
1. Specific retrofit date (sprint/date, not "later")
2. Budget allocated (engineer-weeks + dollars)
3. Risk acceptance signed by [decision maker + date]
4. Interim mitigation plan (monitoring/on-call/refund process)

Cannot provide all 4? Implement now.
Payment operations: NOT acceptable to defer. No exceptions.
```

### Specific Requirement Blocks

| Requirement | Risk | Required Implementation |
|-------------|------|------------------------|
| Circuit breaker | Cascade failure across all endpoints | Opossum/Hystrix: 5 failures/10s, 30s reset, fallback behavior |
| Correlation IDs | 5-min debug → multi-hour search | UUID v4 at ingress, `X-Correlation-ID` header, all logs, downstream propagation |
| Idempotency (payments) | Duplicate charges, compliance violations | `Idempotency-Key` header (UUID), Redis/DB 24h TTL, atomic check-and-set |
| Transactions | Data inconsistency, manual fixes | BEGIN/COMMIT/ROLLBACK wrapping all related ops, rollback on error |

---

## Final Verification

**Before completion:**

| Category | Verification | Command |
|----------|--------------|---------|
| Build & Test | All tests pass, zero lint errors | `./buildAll.sh` |
| Error Scenarios | Test failure modes | Service down, timeout, invalid input |
| Security | Auth/validation works | Auth blocks unauthorized requests |
| Observability | Logs/metrics instrumented | `rg "correlationId\|correlation_id" src/backend/` |
| Documentation | Updated | API docs, runbooks, deployment notes |

**Self-Grading Checklist:**

```
[ ] 25+ items across 5 sections
[ ] 80%+ have concrete numbers (5 failures/10s, 15s timeout)
[ ] 80%+ name specific tools (Opossum, pino, Joi, Knex, Redis)
[ ] 100% have measurable outcomes ("generates UUID correlation ID")
[ ] Zero vague items ("add logging" without tool/format)
[ ] 3 random items passed Specificity Test (engineer can implement without questions)
[ ] Payments: ALL 3 critical requirements (idempotency, transactions, audit)

GRADING:
- All 7 passed: 9-10/10 (Excellent)
- 5-6 passed: 7-8/10 (Good - minor revisions)
- 3-4 passed: 5-6/10 (Needs revision)
- 0-2 passed: 1-4/10 (Failed - major revision)
```

**Below 7/10: MUST revise before proceeding.**
**Payment checkpoint unchecked: BLOCKED.**

---

**Remember**: Backend systems power critical business functions. One reliability bug can corrupt data at scale. When in doubt, prioritize correctness over speed.
