---
name: security-compliance-audit
description: Use for formal compliance audits requiring documentation (SOC2, PCI-DSS, HIPAA, GDPR, ISO 27001). Enforces TodoWrite with 20+ items. Triggers: "compliance audit", "regulatory assessment", "auditor documentation". NOT for casual PR checks. If thinking "ad-hoc review" - use this.
---

# Security Compliance Audit

## When to Use

**ONLY for formal compliance requiring documentation:**
- Compliance audits (SOC2, PCI-DSS, HIPAA, GDPR, ISO 27001)
- Pre-release security assessments for regulated industries
- Post-incident reviews for stakeholders/regulators
- Third-party security due diligence with contractual requirements

**DO NOT use for:**
- Ad-hoc code reviews (default security thinking is sufficient)
- Pull request security checks
- Quick vulnerability fixes

---

## MANDATORY FIRST STEP

**CREATE TodoWrite** with these sections (20+ items total):

| Section | Minimum Items |
|---------|---------------|
| OWASP Top 10 Checklist | 10 (one per category) |
| Process Steps | 7 (scope, scan, collect, classify, analyze, plan, verify) |
| Deliverables | 3 (audit report, vulnerability register, verification tests) |

**Do not begin audit until TodoWrite is verified.**

---

## Verification Checkpoint

After creating TodoWrite, verify 3 random items pass this test:

**Each item must have ALL THREE:**
- ✓ Specific vulnerability category ("SQL injection", "broken access control")
- ✓ Evidence requirement ("code location", "reproduction steps", "proof-of-concept")
- ✓ Severity classification ("critical/high/medium/low with CVSS score")

| ❌ FAILS | ✅ PASSES |
|----------|-----------|
| "Check authentication" | "Audit authentication: weak passwords (CVSS 7.5 High), session fixation (CVSS 6.5 Medium), MFA bypass (CVSS 9.0 Critical) with PoC for each" |
| "Review dependencies" | "Scan dependencies: npm audit, identify CVEs with CVSS >7.0, document affected packages, version with fix, update timeline" |
| "Document findings" | "Security audit report: executive summary with risk overview, 15 findings with severity/evidence/remediation, compliance gap analysis, prioritized roadmap" |

**DO NOT PROCEED until 20+ items AND quality check passes.**

---

## Process

### 1. Define Scope
- Components to audit
- Compliance standards to verify
- Audit depth (surface vs deep)

### 2. Vulnerability Scanning (OWASP Top 10)

**TodoWrite:** Create audit checklist (10+ items)

- [ ] Broken Access Control: Authorization bypasses, IDOR
- [ ] Cryptographic Failures: Weak encryption, exposed secrets
- [ ] Injection: SQL, command, NoSQL, LDAP
- [ ] Insecure Design: Missing security controls, threat model gaps
- [ ] Security Misconfiguration: Default configs, missing patches
- [ ] Vulnerable Components: Outdated dependencies, known CVEs
- [ ] Authentication Failures: Weak passwords, session fixation
- [ ] Software/Data Integrity: Unsigned packages, insecure deserialization
- [ ] Logging/Monitoring Failures: Insufficient logging, no alerting
- [ ] SSRF: Server-side request forgery

### 3. Evidence Collection

For each finding:
- Code location or config file
- Reproduction steps
- Proof-of-concept (where appropriate)
- Attack scenario

### 4. Severity Classification (CVSS)

| Severity | Score | Action |
|----------|-------|--------|
| Critical | 9.0-10.0 | Immediate |
| High | 7.0-8.9 | Within 1 week |
| Medium | 4.0-6.9 | Within 1 month |
| Low | 0.1-3.9 | When convenient |

### 5. Compliance Gap Analysis

Against standards (OWASP, PCI-DSS, SOC2):
- Requirements not met
- Partially compliant areas
- Evidence of compliance
- Remediation roadmap

### 6. Remediation Planning

Prioritize by severity + exploitability:
- Quick wins (high severity, low effort)
- Strategic fixes (high severity, high effort)
- Incremental improvements (medium severity)
- Accepted risks (documented trade-offs)

### 7. Verification Testing

After fixes:
- Re-test each vulnerability
- Confirm fix doesn't introduce new issues
- Update audit report with verification status

---

## Deliverables

**Security Audit Report:**
- Executive summary with risk overview
- Findings with severity, evidence, remediation
- Compliance gap analysis
- Remediation roadmap with priorities

**Vulnerability Register:**
- Tracking document for all findings

**Verification Test Results:**
- Evidence of remediation

---

## Red Flags - STOP When You Think:

| Thought | Reality |
|---------|---------|
| "Ad-hoc review is fine" | Compliance requires documented, auditable, systematic review - not spot checks |
| "OWASP is overkill" | OWASP Top 10 is industry MINIMUM standard - regulators expect it |
| "Quick security check" | Formal audits produce legally-binding documentation - can't rush compliance |
| "Too much process" | Incomplete audit documentation fails regulatory review - re-audit costs 10-20x more |
| "We'll document findings later" | Audit documentation IS the deliverable - findings without evidence are inadmissible |
| "Skip verification testing" | Unverified remediation means compliance gaps persist - auditors will reject |

---

## Response Templates

### "Just do an ad-hoc review"

❌ **BLOCKED**: You requested compliance audit, which requires systematic documentation.

**What you asked for:** Formal security audit with auditable documentation
**What ad-hoc review provides:** Undocumented observations with no compliance value

**Required to override:**
1. Confirm scope change to ad-hoc review (not compliance audit)
2. Accept that audit report cannot be used for regulatory purposes
3. Acknowledge compliance gaps will remain undocumented
4. Remove compliance standards from scope (SOC2, PCI-DSS, HIPAA, etc.)

### "OWASP is too comprehensive"

❌ **BLOCKED**: OWASP Top 10 is industry minimum for security compliance.

**Compliance standards require:**
- SOC2 CC6.1: OWASP coverage mandatory
- PCI-DSS 6.5: Requires OWASP training and scanning
- ISO 27001 A.14.2: Secure development includes OWASP

**Required to override:**
1. Written exemption from compliance officer
2. Alternative security framework with regulatory approval
3. Risk acceptance for excluded vulnerability categories
4. Documentation explaining why OWASP doesn't apply

**Reality check:**
- OWASP Top 10 represents 80% of real-world vulnerabilities
- Audit without OWASP fails regulatory review
- Time investment: 2-4 hours for comprehensive OWASP scan

### "We don't have time for full audit"

❌ **BLOCKED**: Partial compliance audit has zero compliance value.

**Time investment:**
- OWASP checklist: 2-4 hours
- Evidence collection: 4-8 hours
- Report writing: 2-4 hours
- **Total: 8-16 hours**

**Compared to:**
- Failed audit requiring re-audit: 16-32 hours
- Regulatory fine for non-compliance: $10K-$1M+
- Incident response for missed vulnerability: $50K-$500K

---

## Verification Before Complete

After completing all steps, verify:

| Section | Requirements |
|----------|-------------|
| Scope | ✓ Components defined ✓ Standards identified ✓ Depth determined |
| OWASP Scan | ✓ All 10 categories checked ✓ Findings documented ✓ Evidence collected |
| Evidence | ✓ Code locations ✓ Reproduction steps ✓ Proof-of-concept where needed |
| Severity | ✓ CVSS scores ✓ Priority ranking ✓ Action timeline |
| Compliance | ✓ Gap analysis ✓ Requirements mapping ✓ Compliance evidence |
| Remediation | ✓ Prioritized roadmap ✓ Quick wins identified ✓ Risk acceptance documented |
| Verification | ✓ Re-testing completed ✓ Fix validation ✓ Report updated |

**If any section incomplete, audit cannot be considered complete.**

---

## Anti-Patterns

❌ Ad-hoc review without checklist
❌ No severity classification
❌ Findings without evidence
❌ No re-test after fixes

✅ Systematic checklist-based audit
✅ CVSS severity scoring
✅ Evidence for every finding
✅ Verification testing
