---
name: threat-modeling
description: >
  Use when implementing auth, file uploads, payments, webhooks, OAuth/SSO, APIs, CI/CD, or external integrations. Also use when the user asks about security, security review, security audit, hardening, or vulnerability assessment for a feature or system. Applies STRIDE framework with DFD trust boundaries and DREAD scoring. Triggers on authentication, file upload, payment, multi-tenant, external API, webhook, OAuth, SSO, CI/CD, API gateway, WebSocket, background jobs, "is this secure", "security concerns", "security review", "make this secure", "harden this", "check security". Use this for ANY feature that handles user data, accepts external input, or crosses trust boundaries - even if it seems simple. If thinking I know security - use this anyway.
---

# Threat Modeling (STRIDE)

## MANDATORY FIRST STEP

**TodoWrite:** Create 28+ items covering:
1. Data Flow Diagram with trust boundaries (4+ items)
2. Threat enumeration per STRIDE category (12+ items, 2+ per category)
3. Risk scoring with DREAD (3+ items)
4. Controls and mitigations (3+ items)
5. Verification checkpoint (2+ items)
6. Write SECURITY-ACTIONS.md with manual actions (2+ items)
7. Auto-implement automatable fixes (2+ items)

---

## Phase 1: Data Flow Diagram & Trust Boundaries

Before enumerating threats, map the system. Skip this and you will miss threats.

### Identify Trust Boundaries

A trust boundary exists wherever data crosses between zones of different trust levels:

| Boundary Type | Example | Why It Matters |
|---------------|---------|----------------|
| Network | Internet to DMZ, DMZ to internal | Untrusted input enters |
| Process | User browser to API server | Different privilege levels |
| Data store | App to database, app to cache | Persistence layer access |
| Service | Your service to third-party API | Different security postures |
| Account | Tenant A data vs Tenant B data | Isolation requirements |

### Build the DFD

For each component, document:
- **External entities**: Users, third-party services, browsers, mobile apps
- **Processes**: API servers, background workers, message consumers
- **Data stores**: Databases, caches, file storage, message queues
- **Data flows**: Label each arrow with what data moves and the protocol (HTTPS, gRPC, SQL)
- **Trust boundaries**: Draw lines between zones; every crossing is a threat surface

### Map Entry/Exit Points

| Entry Point | Data Accepted | Trust Level |
|-------------|---------------|-------------|
| Public API endpoint | User input (JSON) | Untrusted |
| Webhook receiver | Third-party payloads | Semi-trusted |
| Admin dashboard | Staff input | Trusted but verified |
| Message queue consumer | Internal events | Trusted |
| File upload endpoint | Binary data | Untrusted |

---

## Phase 2: STRIDE Threat Enumeration

Apply each category to **every trust boundary crossing** identified in Phase 1.

### S - Spoofing Identity

Can an attacker pretend to be someone or something they are not?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Can credentials be stolen via phishing or credential stuffing? | Brute force, credential reuse from breaches |
| 2 | Can session tokens be hijacked (XSS, network sniffing, fixation)? | Session fixation, cookie theft |
| 3 | Can API keys be extracted from client-side code or logs? | Key leakage in JS bundles, error logs |
| 4 | Can webhook senders be impersonated (missing signature verification)? | Forged webhook payloads |
| 5 | Can service-to-service calls be spoofed (no mutual TLS)? | Internal network attacker |
| 6 | Can OAuth tokens be forged or replayed across tenants? | Token confusion, issuer mismatch |
| 7 | Can DNS or IP be spoofed to redirect traffic? | DNS rebinding, SSRF |
| 8 | Can email/SMS verification be bypassed? | SIM swap, email takeover |

**OWASP**: A07:2021 (Identification and Authentication Failures), CWE-287, CWE-384

### T - Tampering with Data

Can an attacker modify data they should not be able to?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Can request bodies be modified in transit (no TLS, no integrity check)? | MITM, parameter manipulation |
| 2 | Can hidden form fields or client-side state be tampered with? | Mass assignment, hidden field manipulation |
| 3 | Can database records be modified via SQL injection? | SQLi in dynamic queries |
| 4 | Can file contents be replaced or modified after upload? | TOCTOU race, path traversal overwrite |
| 5 | Can JWT claims be modified (weak signing, algorithm confusion)? | `alg:none` attack, key confusion |
| 6 | Can message queue payloads be altered? | Compromised queue access |
| 7 | Can configuration or environment variables be modified? | Env injection, config file tampering |
| 8 | Can audit logs be altered or deleted to hide tracks? | Log injection, log file tampering |

**OWASP**: A03:2021 (Injection), A08:2021 (Software and Data Integrity Failures), CWE-89, CWE-352

### R - Repudiation

Can an attacker deny performing an action with no way to prove otherwise?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Are all authentication events logged (login, logout, failed attempts)? | No audit trail for account compromise |
| 2 | Are data modifications logged with who/what/when/before/after? | Cannot prove unauthorized changes |
| 3 | Are financial transactions logged with immutable records? | Disputed charges with no evidence |
| 4 | Can log entries be forged via log injection? | Injecting fake log lines via user input |
| 5 | Are logs stored in a tamper-evident system (append-only, signed)? | Attacker deletes evidence |
| 6 | Is there sufficient context in logs to reconstruct events? | Incomplete forensic trail |

**OWASP**: A09:2021 (Security Logging and Monitoring Failures), CWE-778

### I - Information Disclosure

Can an attacker access data they should not see?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Do error messages reveal stack traces, SQL queries, or internal paths? | Verbose errors in production |
| 2 | Are API responses over-fetching (returning fields the client does not need)? | GraphQL introspection, REST over-exposure |
| 3 | Can directory listing or source maps expose internal structure? | `.map` files, directory traversal |
| 4 | Is sensitive data logged (passwords, tokens, PII in plain text)? | Log aggregator compromise |
| 5 | Can timing attacks reveal valid usernames or secret values? | User enumeration via response time |
| 6 | Is data encrypted at rest (database, backups, file storage)? | Stolen disk/backup exposure |
| 7 | Can SSRF be used to access internal metadata endpoints? | Cloud metadata API (169.254.169.254) |
| 8 | Are secrets stored in code, env vars, or config files without a vault? | Git history exposure, env dump |

**OWASP**: A01:2021 (Broken Access Control), A02:2021 (Cryptographic Failures), CWE-200, CWE-209

### D - Denial of Service

Can an attacker disrupt availability for legitimate users?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Are there rate limits on all public endpoints? | Volumetric flooding |
| 2 | Can large payloads exhaust memory (unbounded JSON, huge file uploads)? | Zip bombs, billion laughs XML |
| 3 | Can expensive queries be triggered (unindexed search, N+1, regex DoS)? | ReDoS, slow query flooding |
| 4 | Can a single tenant monopolize shared resources? | Noisy neighbor in multi-tenant |
| 5 | Can background jobs be flooded to block the queue? | Queue saturation |
| 6 | Are there circuit breakers for downstream dependencies? | Cascade failure |
| 7 | Can account lockout be weaponized against legitimate users? | Locking out victim accounts |
| 8 | Is there graceful degradation when dependencies fail? | Hard dependency on non-critical service |

**OWASP**: CWE-400, CWE-770

### E - Elevation of Privilege

Can an attacker gain access beyond what they are authorized for?

| # | Question | Attack Pattern |
|---|----------|---------------|
| 1 | Are authorization checks enforced server-side on every request? | IDOR, missing function-level access control |
| 2 | Can users access other users' data by changing IDs in URLs/params? | Insecure Direct Object Reference |
| 3 | Can a regular user access admin endpoints? | Missing role checks |
| 4 | Can deserialization or template injection achieve code execution? | Pickle/YAML deserialization, SSTI |
| 5 | Can file uploads lead to code execution (unrestricted file types)? | Web shell upload |
| 6 | Can dependency vulnerabilities be exploited for RCE? | Known CVE in transitive dependency |
| 7 | Can container escape or shared infrastructure be exploited? | Kubernetes pod escape, shared tmp |
| 8 | Can OAuth scope escalation grant broader permissions than intended? | Scope creep, consent screen bypass |

**OWASP**: A01:2021 (Broken Access Control), A08:2021 (Software and Data Integrity Failures), CWE-269, CWE-863

---

## Phase 3: Risk Scoring (DREAD)

Score each identified threat using DREAD (each dimension 1-3):

| Dimension | 1 (Low) | 2 (Medium) | 3 (High) |
|-----------|---------|------------|----------|
| **D**amage | Minor inconvenience | Data loss, partial breach | Full system compromise, PII breach |
| **R**eproducibility | Requires specific conditions | Reproducible with some effort | Trivially reproducible |
| **E**xploitability | Requires deep expertise/insider access | Requires moderate skill | Script kiddie can do it |
| **A**ffected users | Single user | Subset of users | All users |
| **D**iscoverability | Requires source code access | Discoverable with testing | Publicly visible |

**Total = sum of 5 dimensions (range 5-15)**

| Score | Priority | Action |
|-------|----------|--------|
| 12-15 | Critical | Block release. Fix immediately. |
| 8-11 | High | Fix before release. Requires control. |
| 5-7 | Medium | Track. Fix in next sprint. Accept with documented rationale. |

### Calibration Tips

- If you score most threats the same, you are not differentiating enough. Re-examine Reproducibility and Exploitability.
- Compare your scores against known CVEs (e.g., Log4Shell would be 15/15, a minor info disclosure via error message might be 7/15).
- When in doubt, score higher. Downgrading after review is cheaper than missing a real threat.

---

## Feature Templates

### Authentication / Login

**Assets:** Credentials, session tokens, reset tokens, MFA secrets
**Entry points:** Login, signup, password reset, MFA enrollment
**Key trust boundaries:** Browser-to-API, API-to-identity-provider, API-to-database

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Credential stuffing / brute force | S | Reproducibility: high |
| Session fixation / hijacking | S, E | Exploitability: varies by cookie config |
| Password reset token leakage | I | Discoverability: check referrer headers |
| Account lockout weaponization | D | Affected users: targeted |
| MFA bypass via backup codes | S, E | Exploitability: social engineering |

### File Upload

**Assets:** Stored files, file metadata, server filesystem
**Entry points:** Upload endpoint, download/preview endpoint
**Key trust boundaries:** Browser-to-API, API-to-storage, storage-to-CDN

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Web shell upload / RCE | E | Damage: 3, Exploitability: 2-3 |
| Path traversal (write to arbitrary path) | T | Reproducibility: high if unsanitized |
| Zip bomb / decompression bomb | D | Affected users: all (server crash) |
| Access control bypass on downloads | I, E | Discoverability: IDOR on file IDs |
| Malware distribution via stored files | T | Affected users: downstream consumers |

### Payment / Billing Flow

**Assets:** Payment credentials, transaction records, subscription state, invoices
**Entry points:** Checkout, webhook from payment provider, billing portal
**Key trust boundaries:** Browser-to-API, API-to-payment-provider, webhook-ingress

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Price/quantity tampering in checkout request | T | Damage: 3 (financial loss) |
| Webhook signature bypass (replay/forge) | S | Reproducibility: high if no verification |
| Race condition on coupon/credit application | T, E | Exploitability: moderate |
| PCI data in logs or error messages | I | Discoverability: log search |
| Subscription state manipulation (skip billing) | T, E | Damage: ongoing revenue loss |

### Webhook Integration

**Assets:** Webhook secrets, payload data, processing state
**Entry points:** Webhook receiver endpoint
**Key trust boundaries:** External-service-to-API, API-to-internal-queue

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Missing signature verification | S | Exploitability: 3 (trivial to forge) |
| Replay attacks (no timestamp/nonce check) | S, T | Reproducibility: 3 |
| SSRF via URL fields in webhook payload | E, I | Damage: cloud metadata access |
| Queue flooding via rapid webhook delivery | D | Affected users: all |
| Idempotency failure (double-processing) | T | Damage: duplicate charges/actions |

### OAuth / SSO

**Assets:** OAuth tokens, client secrets, user profile data, session state
**Entry points:** Authorization redirect, callback endpoint, token exchange
**Key trust boundaries:** Browser-to-IdP, IdP-to-API, API-to-resource-server

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Open redirect via callback URL manipulation | S, I | Exploitability: 2-3 |
| CSRF on authorization flow (missing state param) | S | Reproducibility: 3 |
| Token leakage via referrer header or logs | I | Discoverability: 2 |
| Scope escalation / insufficient scope validation | E | Damage: broader access than consented |
| IdP impersonation (no issuer validation) | S | Damage: full account takeover |

### CI/CD Pipeline

**Assets:** Source code, secrets/credentials, build artifacts, deployment keys
**Entry points:** Git push, PR events, artifact registry, deployment triggers
**Key trust boundaries:** Developer-to-VCS, VCS-to-CI, CI-to-artifact-store, CI-to-production

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Secret exfiltration via build logs or env vars | I | Damage: 3 (all secrets compromised) |
| Malicious PR injecting code into build pipeline | T, E | Exploitability: depends on review policy |
| Dependency confusion / typosquatting | T | Discoverability: automated scanners exist |
| Build artifact tampering (unsigned artifacts) | T | Reproducibility: if registry is writable |
| Overprivileged CI service account | E | Damage: production access from CI |

### API Gateway / Public API

**Assets:** API keys, rate limit state, routing configuration, backend services
**Entry points:** All public API endpoints
**Key trust boundaries:** Internet-to-gateway, gateway-to-backend-services

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| API key leakage in client apps or URLs | I | Discoverability: 3 (public code search) |
| Broken Object Level Authorization (BOLA) | E | Affected users: any user's data |
| Mass assignment via unvalidated fields | T | Exploitability: depends on framework |
| Rate limit bypass via header/IP rotation | D | Reproducibility: moderate |
| GraphQL introspection / query depth abuse | I, D | Exploitability: 2-3 |

### WebSocket Connections

**Assets:** Real-time data streams, connection state, user presence
**Entry points:** WebSocket upgrade endpoint, message handlers
**Key trust boundaries:** Browser-to-WS-server, WS-server-to-backend

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Missing authentication on WS upgrade | S, E | Exploitability: 3 |
| Cross-site WebSocket hijacking (CSWSH) | S | Reproducibility: 3 if no origin check |
| Message injection / channel subscription abuse | T, E | Damage: data corruption or leakage |
| Connection flooding (exhausting server resources) | D | Affected users: all connected users |
| Missing per-message authorization checks | E | Damage: access to unauthorized channels |

### Multi-Tenant System

**Assets:** Tenant data, tenant configurations, shared infrastructure, API keys per tenant
**Entry points:** All endpoints with tenant context, admin/management APIs
**Key trust boundaries:** Tenant-A-to-tenant-B (logical), API-to-shared-database, tenant-admin-to-platform-admin

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Cross-tenant data leakage via shared queries | I | Affected users: 3 (other tenants' data) |
| Tenant ID manipulation in requests | S, E | Exploitability: 2-3 (predictable IDs) |
| Noisy neighbor resource exhaustion | D | Affected users: all tenants on shared infra |
| Shared cache key collision between tenants | I, T | Discoverability: race conditions |
| Privilege escalation from tenant admin to platform admin | E | Damage: 3 (full platform access) |

### Background Job Processing

**Assets:** Job payloads, processing state, worker credentials
**Entry points:** Job enqueue API, scheduled triggers, retry mechanisms
**Key trust boundaries:** API-to-queue, queue-to-worker, worker-to-external-services

| Priority Threats | STRIDE | DREAD Focus |
|-----------------|--------|-------------|
| Job payload tampering in queue | T | Exploitability: depends on queue auth |
| Privilege escalation via worker service account | E | Damage: workers often have broad access |
| Poison pill jobs crashing workers (retry storms) | D | Affected users: all queued jobs delayed |
| Sensitive data persisted in job payloads | I | Discoverability: queue inspection tools |
| Missing idempotency on retried jobs | T | Damage: duplicate side effects |

---

## Phase 4: Framework-Aware Mitigations

After identifying threats and scoring risk, select mitigations appropriate to your stack.

### Common Mitigations by Framework

| Threat | Django | Express/Node | Spring Boot | Rails |
|--------|--------|-------------|-------------|-------|
| CSRF | `{% csrf_token %}` (on by default) | `csurf` middleware | `CsrfFilter` (on by default) | `protect_from_forgery` (on by default) |
| SQLi | ORM parameterized queries | `knex` parameterized, `prisma` | JPA/Hibernate parameterized | ActiveRecord parameterized |
| XSS | Auto-escaped templates | `helmet` + `DOMPurify` | Thymeleaf auto-escape | ERB auto-escape, `sanitize` helper |
| Auth | `django.contrib.auth`, `django-allauth` | `passport.js`, `next-auth` | Spring Security | Devise, Warden |
| Rate limit | `django-ratelimit` | `express-rate-limit` | `bucket4j`, `resilience4j` | `rack-attack` |
| Input validation | Django Forms, DRF serializers | `joi`, `zod`, `express-validator` | Bean Validation (`@Valid`) | Strong Parameters, ActiveModel validations |
| Session | Signed cookies (default) | `express-session` + secure store | Spring Session | Encrypted cookies (default) |
| File upload | `FileField` + validators | `multer` + type check | `MultipartFile` + validators | Active Storage + validators |
| Secrets | `django-environ`, vault | `dotenv` + vault | Spring Vault, `@Value` | `credentials.yml.enc`, vault |

### Cross-Cutting Mitigations

| Control | Implementation |
|---------|---------------|
| TLS everywhere | Enforce HTTPS, HSTS header, TLS 1.2+ only |
| Security headers | CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy |
| Dependency scanning | `npm audit`, `pip-audit`, `bundle-audit`, Dependabot/Renovate |
| Secret management | Never in code/env. Use HashiCorp Vault, AWS Secrets Manager, or cloud KMS |
| Logging | Structured, no PII/secrets, centralized, tamper-evident |

---

## Verification Checkpoint

Before marking the threat model complete, verify ALL of the following with specific evidence:

| Check | Required Evidence |
|-------|-------------------|
| DFD exists with trust boundaries marked | List each boundary and what data crosses it |
| Every trust boundary has STRIDE analysis | Reference specific threat IDs per boundary |
| Each STRIDE category has 3+ threats identified | Count per category, not just total |
| All threats scored 8+ DREAD have mitigations | Name the specific control for each |
| Mitigations reference actual framework tools | Not "add validation" but "Zod schema on POST /api/orders" |
| No OWASP Top 10 category left unaddressed | Map your threats to A01-A10, flag gaps |
| Residual risk documented for accepted threats | "Accepting X because Y, revisit by Z date" |

**If any check fails, go back and fill the gap. A threat model with blind spots is worse than no model (false confidence).**

---

## Phase 5: Actionable Output

A threat model that lives only in conversation context is a threat model that gets lost. After completing the analysis, produce concrete deliverables.

### Write a Manual Actions File

Create a `SECURITY-ACTIONS.md` file in the project root (or alongside the feature code) containing all findings that require human decisions or manual steps. This file gets committed, making the actions visible in code review and git history.

Structure it like this:

```markdown
# Security Actions: [Feature Name]
Generated: [date]

## Critical (DREAD 12-15) — Block release
- [ ] [Threat ID]: [Description] — [Specific action needed]

## High (DREAD 8-11) — Fix before release
- [ ] [Threat ID]: [Description] — [Specific action needed]

## Accepted Risk (DREAD 5-7) — Documented decisions
- [Threat ID]: [Description] — Accepting because [reason], revisit by [date]

## Configuration/Infrastructure Changes (require manual action)
- [ ] [Action]: [Details, who needs to do it, where]
```

Include in this file anything that cannot be automated: infrastructure changes, third-party service configuration, policy decisions, manual security testing needed, secrets to provision, DNS/certificate changes.

### Auto-implement What You Can

After writing the actions file, look at the mitigations and identify which ones can be implemented directly in code right now. For each automatable fix:

1. **Plan the implementation** — use available planning skills to create a structured implementation plan for the security controls
2. **Implement using subagents** — dispatch independent fixes in parallel where possible (e.g., adding rate limiting, input validation schemas, security headers can all be done independently)
3. **Mark completed items** — check off items in `SECURITY-ACTIONS.md` as they are implemented, with a note about what was done

Examples of automatable fixes:
- Adding rate limiting middleware configuration
- Creating input validation schemas (Zod, Joi, Django Forms)
- Adding security headers (CSP, HSTS, X-Frame-Options)
- Setting up CSRF protection configuration
- Adding webhook signature verification boilerplate
- Creating authorization middleware/decorators

Examples of non-automatable actions (leave in the file):
- Provisioning API keys or secrets in a vault
- Configuring WAF rules or CDN settings
- Setting up monitoring/alerting thresholds
- Purchasing or configuring TLS certificates
- Organizational decisions (acceptable risk, compliance sign-off)

The goal: after this skill runs, the user has both a committed record of what needs doing AND as many controls as possible already in place.

---

## Response Templates

**"This is over-engineering for a simple feature"**
> Security bugs cost 30x more post-release than during design. STRIDE takes 30-60 minutes and prevents deployment blockers. Which trust boundaries in your DFD have zero threats? Start there.

**"We'll add security later"**
> Security is not a feature you bolt on. Architectural decisions (data flow, trust boundaries, auth model) are expensive to change. Identify the top 3 DREAD-scored threats now, implement those controls, and track the rest.

**"We already have a WAF/firewall"**
> Network controls address only one trust boundary. STRIDE covers application-level threats: business logic flaws, authorization bugs, data leakage in APIs. WAFs do not prevent IDOR or privilege escalation.

---

## Red Flags

| Thought | Reality |
|---------|---------|
| "Ad-hoc brainstorming is enough" | Misses 60% of threats vs. systematic STRIDE |
| "Everything is critical" | No prioritization = wrong fixes first. Use DREAD. |
| "We'll security review later" | 30x more expensive post-implementation |
| "Only external attackers matter" | Insider threats and supply chain are STRIDE categories too |
| "We use HTTPS so we're secure" | Transport security is one control among dozens |
