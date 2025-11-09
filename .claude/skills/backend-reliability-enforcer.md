---
name: backend-reliability-enforcer
description: Use when implementing backend systems, APIs, data persistence, or any server-side component - enforces reliability, fault tolerance, and data integrity as non-negotiable requirements
---

# Backend Reliability Enforcer

## ⚠️ MANDATORY FIRST STEP - READ THIS NOW

### 🚨 CRITICAL: Anti-Rationalization Warning

**Time pressure, tight deadlines, and customer urgency are NOT exceptions to this skill.**

This skill exists BECAUSE of pressure. Shortcuts under pressure create:
- Financial loss from duplicate charges or data corruption (payment bugs cost thousands)
- Compliance violations and legal liability (GDPR, PCI-DSS, SOX)
- Multi-hour production incidents from missing observability (cascade failures)
- Customer trust damage from security breaches or data loss

**Common rationalizations that mean you're about to fail:**
- "Let's get it working first, add [error handling/security] later" → No, reliability requirements are NOT optional
- "We'll add [idempotency/transactions/audit] in v2" → No, retrofitting costs 10x more + requires customer refunds
- "Just this once" → No, every shortcut creates technical debt and sets a dangerous precedent
- "Customer needs it in 3 days" → Shipping broken payment code causes more delay than building it right
- "Being pragmatic not dogmatic" → No, these requirements ARE pragmatic (learned from production incidents)
- "That edge case is unlikely" → Unlikely × scale = frequent. Unlikely failures corrupt data at scale.

**If you're thinking any of these thoughts, STOP. Re-read the skill requirements.**

---

**STOP. Before proceeding with this backend task, you MUST:**

1. **CREATE TodoWrite** with these 5 sections (DO NOT SKIP):
   - **Fault Tolerance**: Minimum 5 items
   - **Error Handling**: Minimum 5 items
   - **Data Integrity**: Minimum 5 items
   - **Security**: Minimum 5 items
   - **Observability**: Minimum 5 items

2. **VERIFY TodoWrite quality** using standards below (MANDATORY - see verification checkpoint)

3. **CONFIRM section completeness** using checklist below

**Do not analyze, plan, or implement until TodoWrite is created and verified.**

---

## 🛑 TODOWRITE OUTPUT REQUIREMENT - BLOCKING

**CRITICAL: You MUST output your TodoWrite creation BEFORE any implementation.**

**To prove you created TodoWrite, output this exact sequence:**

```
=== TODOWRITE CREATION ===

**Fault Tolerance** (5+ items):
[List your 5+ fault tolerance items here]

**Error Handling** (5+ items):
[List your 5+ error handling items here]

**Data Integrity** (5+ items):
[List your 5+ data integrity items here]

**Security** (5+ items):
[List your 5+ security items here]

**Observability** (5+ items):
[List your 5+ observability items here]

TOTAL: ___ items

=== TODOWRITE CREATED ===
```

**If you skip this output, you are violating the skill and must STOP immediately.**

**Why this is non-negotiable:**
- TodoWrite is the PRIMARY enforcement mechanism for reliability requirements
- Without visible TodoWrite, there's no proof you followed the discipline
- Skipping TodoWrite = skipping ALL the reliability safeguards

**After outputting TodoWrite, proceed to Verification Checkpoint below.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, you MUST verify EVERY item meets quality standards BEFORE proceeding.**

**Complete this checklist and output the results:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO (examples: "5 failures/10s", "15s timeout", "100 req/min", "24h TTL")
    - Names specific tools/technologies? YES/NO (examples: "Opossum", "pino", "Joi", "Knex", "Redis", "axios")
    - States measurable outcome? YES/NO (examples: "generates UUID v4 correlation ID", "validates email format", "alerts if error rate > 5%")
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

**Minimum total: 25 specific items** covering all 5 categories.

---

## Section Completion Confirmation

**After creating TodoWrite, output this checklist to confirm all sections present:**

```
SECTION COMPLETION:
[ ] Fault Tolerance: 5+ items
[ ] Error Handling: 5+ items
[ ] Data Integrity: 5+ items
[ ] Security: 5+ items
[ ] Observability: 5+ items

TOTAL: ___ items (must be 25+)
```

**If any section is unchecked or total < 25, STOP and add missing items now.**

**Why this matters:** 20% of agents miss entire sections (especially Data Integrity and Observability). For payment systems, missing Data Integrity = catastrophic (no idempotency, transactions, audit).

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

After creating TodoWrite, verify EVERY item meets these criteria:

- [ ] Names specific tool/library/framework (e.g., "Hystrix", "Opossum", "pino", "Joi")
- [ ] Includes concrete values/thresholds (e.g., "5 failures/10s", "15s timeout", "4.5:1 contrast")
- [ ] States measurable outcome (e.g., "generate UUID correlation ID", not "add logging")

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

### What Makes an Item Specific?

Must include ALL three:
1. **Concrete numbers/thresholds**: "5 failures/10s", "15s timeout", "100 req/min", "24h TTL", "error rate > 5%"
2. **Specific tools/technologies**: "Opossum", "pino", "Joi", "Zod", "Knex", "Sequelize", "Redis", "axios"
3. **Measurable outcome**: "generates UUID v4 correlation ID", "validates email format", "alerts if error rate > 5%", "stores 24h"

### Test Examples

❌ **FAILS TEST**: "Add error handling"
- Engineer asks: Which errors? How handled? With what tool? What logged?

✅ **PASSES TEST**: "Structured logging with pino: Include UUID v4 correlation ID from `X-Correlation-ID` header in all log entries. Log format: `{correlationId, level, timestamp, service, message, metadata}`"
- Engineer knows: Tool (pino), ID format (UUID v4), header name, log structure

❌ **FAILS TEST**: "Validate input"
- Engineer asks: Which fields? Which rules? Which library? What error response?

✅ **PASSES TEST**: "Joi schema validation: `amount` (number, positive, max 999999), `currency` (string, ISO 4217 codes), `customer_id` (UUID v4 format). Return 400 with `{error: 'validation_failed', fields: [...]}` on failure."
- Engineer knows: Tool (Joi), fields, rules, error response format

### Apply This Test

Before proceeding, select 3 random items from your TodoWrite and test them. If any fail, revise before proceeding.

---

### Examples of Quality Items

**❌ BAD (too generic):**
- "Add error handling"
- "Add logging"
- "Add timeout"
- "Validate input"
- "Add circuit breaker"

**✅ GOOD (specific):**
- "Implement structured logging with UUID correlation IDs using pino/winston"
- "Configure 15s timeout for Stripe API calls using axios timeout config"
- "Validate request body with Joi/Zod schema before processing"
- "Circuit breaker using Opossum with 5 failures/10s threshold, 30s reset"
- "Generate idempotency key from `Idempotency-Key` request header, store in Redis 24h TTL"

---

## ❌ Failed Examples (What NOT To Do)

**These items would FAIL verification. If your items look like these, revise them immediately.**

### Too Generic (No Tool Names)

❌ "Add error handling"
- **Why it fails**: Which errors? How handled? With what tool?
- **Engineer asks**: Try/catch? Error middleware? What logged? What returned?

❌ "Add logging"
- **Why it fails**: What logged? Which library? What format?
- **Engineer asks**: Console.log? Structured logging? Which tool? What fields?

❌ "Add timeout"
- **Why it fails**: On what? How long? With what mechanism?
- **Engineer asks**: API calls? Database? Which specific calls? Axios? Fetch? Native?

❌ "Validate input"
- **Why it fails**: Which fields? Which rules? Which library?
- **Engineer asks**: Joi? Zod? Yup? Custom? What validation rules?

### Missing Concrete Thresholds

❌ "Add circuit breaker"
- **Why it fails**: Failure threshold? Reset time? Which library?
- **Engineer asks**: How many failures? Over what time? When does it reset? Opossum? Hystrix?

❌ "Implement retry logic"
- **Why it fails**: How many retries? What backoff? For which operations?
- **Engineer asks**: 3 retries? Exponential backoff? Which errors trigger retry?

❌ "Add rate limiting"
- **Why it fails**: What limit? Per what timeframe? Per IP? Per user?
- **Engineer asks**: 100 req/min? 1000 req/hour? How tracked? Redis? In-memory?

### Missing Measurable Outcomes

❌ "Improve observability"
- **Why it fails**: What specifically gets observed? How measured?
- **Engineer asks**: Which metrics? What dashboards? What alerts?

❌ "Ensure data integrity"
- **Why it fails**: How ensured? What specific mechanism?
- **Engineer asks**: Transactions? Validation? Checksums? What exactly?

❌ "Make it secure"
- **Why it fails**: Which security measures? How verified?
- **Engineer asks**: Auth? Encryption? Input sanitization? Rate limiting? What exactly?

### Payment-Critical Failures (CATASTROPHIC)

❌ "Prevent duplicate charges"
- **Why it fails**: No implementation details. How prevented?
- **Engineer asks**: Idempotency keys? Which header? Stored where? What TTL?

❌ "Ensure atomicity"
- **Why it fails**: Using what mechanism? No tool specified.
- **Engineer asks**: Database transactions? Which ORM? Knex? Sequelize? Prisma?

❌ "Track payment history"
- **Why it fails**: Track what exactly? No audit trail fields specified.
- **Engineer asks**: Which fields? Who, what, when? Old/new values? Transaction IDs?

**If 3+ of your TodoWrite items match these ❌ patterns, STOP. Your TodoWrite needs major revision before proceeding.**

**If ANY payment-critical item is generic (❌ patterns), BLOCKED. Revise immediately.**

---

## Section Completeness Check

Before proceeding, confirm ALL mandatory sections present in your TodoWrite:

- [ ] **Fault Tolerance**: 5+ items (circuit breaker, retry, timeout, degradation, health checks) ✓
- [ ] **Error Handling**: 5+ items (correlation IDs, structured logs, error types, metrics, alerts) ✓
- [ ] **Data Integrity**: 5+ items (input validation, transactions, idempotency, retention, audit trail) ✓
- [ ] **Security**: 5+ items (auth, authorization, sanitization, encryption, rate limiting) ✓
- [ ] **Observability**: 5+ items (structured logs, metrics, tracing, dashboards, runbooks) ✓

**If any section is missing or below 5 items, STOP and add them now.**

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

## 🚩 Red Flags - STOP

**If you find yourself thinking or saying ANY of these, you are about to violate the skill:**

- "Let's get it working first, add [error handling/security/observability] later" → No, reliability requirements are NOT optional
- "We'll add [idempotency/transactions/audit] in v2/post-launch" → No, implement now. Later = never (80% never added)
- "Just this once" → Every shortcut creates technical debt and sets dangerous precedent
- "Customer needs it in 3 days" → Shipping broken payment code causes MORE delay than building it right
- "Being pragmatic not dogmatic" → These requirements ARE pragmatic (learned from production incidents)
- "That edge case is unlikely" → Unlikely × scale = frequent. Unlikely failures corrupt data at scale.
- "We already manually tested it" → Manual ≠ automated/systematic. Manual doesn't prevent production issues.
- "Code review will catch this" → Review is final gate, not substitute for requirements. Reviewers assume you built it right.
- "Internal tool, lower quality acceptable" → Wrong. Internal tools process real data. Data corruption = same impact.
- "We'll fix bugs in production" → Bugs in backend = data corruption = impossible to fix retroactively
- "Add logging after we see issues" → Can't debug production without logs. Adding after = blind debugging for hours.
- "Circuit breaker is overkill for this" → One slow external service takes down your entire system. Not overkill.
- "Validation slows down development" → Validation prevents data corruption. Cleaning corrupt data is 100x slower.

**When you notice a red flag, STOP. Re-read the specific skill requirement you're about to skip.**

**For payment operations, ANY red flag = CATASTROPHIC risk. No compromises.**

---

### When Asked to Skip Requirements

Use these EXACT response templates:

#### "We'll Add [Requirement] Later"

❌ **BLOCKED**: I cannot defer [error handling/idempotency/transactions/observability] to future iterations.

**Why "later" always fails:**
- "Later" never comes - next sprint has new priorities
- Retrofitting costs 10x more than building it in (especially for payment systems)
- Technical debt accumulates and blocks future changes
- Production bugs require emergency fixes + customer refunds + loss of trust

**The data:**
- 80% of "we'll add later" items never get added
- Retrofitting observability after incidents costs 10x more
- Adding idempotency after duplicate charges requires customer refunds + manual reconciliation (cost: $10K-100K+)
- Retrofitting transactions after data corruption requires manual cleanup (cost: days of engineering time)

**Specific consequence for this requirement:**
- Skipping idempotency (payments) → Duplicate charges → customer refunds + loss of trust + compliance violations
- Skipping transactions → Data corruption → manual cleanup + data loss + regulatory issues
- Skipping observability → Blind production incidents → multi-hour debugging + extended downtime
- Skipping circuit breakers → Cascade failures → system-wide outages

**Required**: Implement now, or explicitly document:
1. Specific date for retrofit (not "later" - actual sprint/date)
2. Budget allocated (engineer-weeks + dollar cost)
3. Risk acceptance signed by [decision maker's name + date]
4. Interim mitigation plan (manual monitoring? 24/7 on-call? customer refund process?)

**If you cannot provide these 4 items, requirement must be implemented now.**

**For payment operations:** This risk is NOT acceptable. Payment-critical requirements (idempotency, transactions, audit) must be implemented before launch. No exceptions.

---

#### Skipping Circuit Breaker
```
❌ BLOCKED: I cannot implement external service calls without circuit breaker protection.

Risk: Without circuit breaker, a slow/failing external service will exhaust our connection pool
and thread pool, causing cascade failure across all endpoints.

Required: Circuit breaker (Opossum/Hystrix) with failure threshold (e.g., 5 failures/10s),
open state timeout (30s), and fallback behavior (return cached data or error response).

To override: Explicitly state you accept cascade failure risk and I will document this in code comments.
```

#### Skipping Correlation IDs
```
❌ BLOCKED: I cannot implement this endpoint without correlation ID support.

Risk: Without correlation IDs, debugging production issues requires manual log correlation across
services - turning 5-minute investigations into multi-hour searches.

Required: Generate UUID v4 correlation ID at API gateway/ingress, pass via `X-Correlation-ID`
header, include in all structured logs, propagate to downstream services.

To override: Explicitly state you accept degraded observability and I will document this gap.
```

#### Skipping Idempotency (Payments)
```
❌ BLOCKED: I cannot implement payment operations without idempotency keys.

Risk: Without idempotency, network retries or duplicate requests will charge customers multiple
times, causing financial loss and compliance violations.

Required: Accept `Idempotency-Key` header (UUID), store in Redis/DB with 24h TTL, return cached
response if key seen before, atomic check-and-set operation.

To override: This risk is NOT acceptable for payment operations. If you insist, we must implement
manual refund process and customer support escalation path.
```

#### Skipping Transactions
```
❌ BLOCKED: I cannot implement multi-step data operations without database transactions.

Risk: Without transactions, partial failures leave data in inconsistent state (e.g., order created
but inventory not decremented), requiring manual data fixes.

Required: Wrap all related operations in database transaction (BEGIN/COMMIT/ROLLBACK), handle
rollback on any error, verify ACID guarantees.

To override: Explicitly state you accept data inconsistency risk and I will add manual cleanup script.
```

---

## Common Failure Prevention

### "We'll add error handling later"
❌ **BLOCK**: Error handling is not optional for backend code
✅ **REQUIRE**: Comprehensive error handling before merging

### "Just return 500 for all errors"
❌ **BLOCK**: Generic errors hide actionable information
✅ **REQUIRE**: Specific error types with appropriate HTTP status codes (400/401/403/404/422/500)

### "We don't need timeouts for that call"
❌ **BLOCK**: Unbounded waits cascade into system-wide failures
✅ **REQUIRE**: Explicit timeouts on all network I/O (axios config: `timeout: 15000`)

### "The database will handle consistency"
❌ **BLOCK**: Assuming consistency without verifying transaction boundaries
✅ **REQUIRE**: Explicit transaction scopes for multi-step operations (knex.transaction())

### "We'll add logging after it works"
❌ **BLOCK**: Observability must be built-in from the start
✅ **REQUIRE**: Structured logging and metrics instrumented during implementation

### "That edge case is unlikely"
❌ **BLOCK**: Unlikely failures in backend systems cause data corruption at scale
✅ **REQUIRE**: Handle all identified edge cases or document why they're impossible

---

## Evidence Collection

Add these items to your TodoWrite before marking task complete:

- [ ] **Build verification**: Run `./buildAll.sh`, screenshot showing all tests pass, zero lint errors
- [ ] **Error scenario testing**: Document test results for service down, timeout, invalid input cases
- [ ] **Security verification**: Screenshot/log showing auth check blocks unauthorized request
- [ ] **Observability proof**: Log excerpt showing correlation ID in structured logs, metric collection confirmed
- [ ] **Code review link**: PR/commit with changes implementing all TodoWrite items

---

## Verification

Before completing any backend task, verify:

1. **Build & Test**: Run `buildAll.sh` - all tests pass, no lint errors
2. **Error Scenarios**: Test failure modes (service down, timeout, invalid input)
3. **Security**: Verify authentication, authorization, input validation
4. **Observability**: Check logs contain correlation IDs, metrics are instrumented
5. **Documentation**: Update API docs, runbooks, deployment notes

### Verification Commands

```bash
# Run full test suite
./buildAll.sh

# Check for TODO/FIXME markers in backend code
rg -t ts -t js -t go -t py "TODO|FIXME" src/backend/

# Verify error handling coverage
rg -t ts -t js "throw new Error|throw Error" src/backend/ --count

# Verify correlation ID usage in logs
rg -t ts -t js "correlationId|correlation_id" src/backend/
```

**If verification fails**: Do not mark task complete. Add blocking TodoWrite items to address gaps.

---

## Final Self-Grading

**Before claiming backend work complete, grade your own TodoWrite:**

```
SELF-GRADING CHECKLIST:
[ ] Minimum 25 items across 5 sections (Fault Tolerance, Error Handling, Data Integrity, Security, Observability)
[ ] 80%+ of items have concrete numbers/thresholds (5 failures/10s, 15s timeout, 100 req/min, 24h TTL)
[ ] 80%+ of items name specific tools/technologies (Opossum, pino, Joi, Knex, Redis, axios)
[ ] 100% of items have measurable outcomes ("generates UUID correlation ID", "validates email format", etc.)
[ ] Zero items use vague verbs without specifics ("add error handling", "add logging" without tool/format)
[ ] Tested 3 random items with Specificity Test - all passed (can engineer implement without questions?)
[ ] For payments: ALL 3 critical requirements present (idempotency, transactions, audit trail with full details)

GRADE YOURSELF:
- All 7 checkboxes passed: 9-10/10 (Excellent - ready to proceed)
- 5-6 checkboxes passed: 7-8/10 (Good - minor revisions needed)
- 3-4 checkboxes passed: 5-6/10 (Needs revision - improve specificity)
- 0-2 checkboxes passed: 1-4/10 (Failed - major revision required)
```

**If you graded yourself below 7/10, you MUST revise TodoWrite before proceeding with implementation.**

**For payment operations**: If payment checkpoint item is unchecked, BLOCKED. Cannot proceed regardless of other grades.

**Why this matters**: 47% of agents create generic items. 50% miss payment-critical requirements. Self-grading prevents this.

---

## Reliability Checklist

For every backend component, ensure:

- ✅ All external calls have circuit breakers + timeouts with specific thresholds
- ✅ Database operations use transactions where needed
- ✅ All inputs validated with schema before processing
- ✅ Errors logged with correlation IDs + structured format
- ✅ Metrics/alerts configured for SLOs (latency, error rate, throughput)
- ✅ Security: authentication, authorization, input sanitization, rate limiting
- ✅ Graceful degradation defined for dependency failures
- ✅ Idempotency implemented for non-GET operations (especially payments)
- ✅ Audit trails for sensitive operations
- ✅ Documentation updated (API specs, runbooks)

---

**Remember**: Backend systems power critical business functions. One reliability bug can corrupt data at scale. When in doubt, prioritize correctness over speed.
