---
skill: security-audit
description: Formal compliance-focused security audits (SOC2, PCI-DSS, HIPAA, GDPR) using OWASP Top 10 and CVSS
category: security
---

# Security Audit

## When to Use
Use this skill ONLY when formal compliance or regulatory requirements demand systematic documentation:
- **Compliance audits** requiring evidence (SOC2, PCI-DSS, HIPAA, GDPR, ISO 27001)
- **Pre-release security assessments** for regulated industries (healthcare, finance, government)
- **Post-incident security reviews** requiring formal documentation for stakeholders/regulators
- **Third-party security due diligence** with contractual audit requirements

## When NOT to Use
DO NOT use this skill for:
- Ad-hoc code reviews (default security thinking is sufficient)
- Pull request security checks (standard review practices apply)
- General development work (Claude naturally considers security)
- Quick vulnerability fixes (direct remediation is faster)

## Process

**Note:** This systematic framework is designed for formal compliance scenarios where documentation and evidence are required. For standard development work, Claude's default security practices are sufficient.

### 1. Define Scope
- Components to audit
- Compliance standards to verify
- Audit depth (surface scan vs. deep analysis)

### 2. Vulnerability Scanning (OWASP Top 10 Checklist)
TodoWrite: Create audit checklist with minimum 10 items

- [ ] **Broken Access Control**: Authorization bypasses, IDOR, missing access controls
- [ ] **Cryptographic Failures**: Weak encryption, exposed secrets, plaintext sensitive data
- [ ] **Injection**: SQL injection, command injection, NoSQL injection, LDAP injection
- [ ] **Insecure Design**: Missing security controls, threat model gaps, business logic flaws
- [ ] **Security Misconfiguration**: Default configs, unnecessary features, missing patches
- [ ] **Vulnerable Components**: Outdated dependencies, known CVEs, unpatched libraries
- [ ] **Authentication Failures**: Weak passwords, session fixation, credential stuffing vulnerabilities
- [ ] **Software/Data Integrity**: Unsigned packages, unverified updates, insecure deserialization
- [ ] **Logging/Monitoring Failures**: Insufficient logging, no alerting, log tampering possible
- [ ] **SSRF**: Server-side request forgery allowing internal network access

### 3. Evidence Collection
For each finding:
- Code location or configuration file
- Reproduction steps
- Proof-of-concept (where appropriate)
- Attack scenario description

### 4. Severity Classification (CVSS)
- **Critical** (9.0-10.0): Immediate action required
- **High** (7.0-8.9): Address within 1 week
- **Medium** (4.0-6.9): Address within 1 month
- **Low** (0.1-3.9): Address when convenient

### 5. Compliance Gap Analysis
Against standards (OWASP, PCI-DSS, SOC2, etc.):
- Requirements not met
- Partially compliant areas
- Evidence of compliance
- Remediation roadmap

### 6. Remediation Planning
Prioritize by severity and exploitability:
- Quick wins (high severity, low effort)
- Strategic fixes (high severity, high effort)
- Incremental improvements (medium severity)
- Accepted risks (documented trade-offs)

### 7. Verification Testing
After fixes applied:
- Re-test each vulnerability
- Confirm fix doesn't introduce new issues
- Update audit report with verification status

## Deliverables
- Security Audit Report
  - Executive summary with risk overview
  - Findings with severity, evidence, remediation
  - Compliance gap analysis
  - Remediation roadmap with priorities
- Vulnerability Register (tracking document)
- Verification Test Results

## Anti-Patterns
❌ Ad-hoc security review without checklist
❌ No severity classification
❌ Findings without evidence
❌ No re-test after fixes
✅ Systematic checklist-based audit
