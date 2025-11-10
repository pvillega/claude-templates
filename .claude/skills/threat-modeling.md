---
skill: threat-modeling
description: Systematically identify and assess security threats using structured threat analysis framework
category: security
---

# Threat Modeling

## When to Use
- Designing new features with security implications
- Architecture reviews for security
- Before implementing authentication/authorization
- When handling sensitive data
- External API design

## Process

### 1. Define Assets and Entry Points
- What needs protection? (data, functionality, resources)
- Where can attackers interact? (APIs, UI, integrations)
- What are trust boundaries?

### 2. Create Data Flow Diagram
- Map how data moves through system
- Identify trust boundaries
- Note external dependencies

### 3. Enumerate Threats (STRIDE)
- **Spoofing**: Can attacker impersonate legitimate user/component?
- **Tampering**: Can attacker modify data/code?
- **Repudiation**: Can attacker deny actions?
- **Information Disclosure**: Can attacker access sensitive data?
- **Denial of Service**: Can attacker disrupt availability?
- **Elevation of Privilege**: Can attacker gain unauthorized access?

### 4. Risk Scoring
For each threat:
- **Likelihood** (1-5): How easy to exploit?
- **Impact** (1-5): What's the damage?
- **Risk Score**: Likelihood × Impact

### 5. Identify Controls
For each threat, determine:
- Existing controls (what protects currently?)
- Control gaps (what's missing?)
- Recommended controls (what to implement?)
- Priority (based on risk score)

### 6. Document Threat Model
Create threat model document:
- Architecture diagram with trust boundaries
- Threat enumeration with risk scores
- Control recommendations prioritized
- Acceptance criteria for residual risk

## Deliverables
- Data flow diagram with trust boundaries
- Threat register (STRIDE analysis)
- Risk-prioritized control recommendations
- Threat model document for future reference

## Anti-Patterns
❌ Ad-hoc "what could go wrong" brainstorming
❌ No risk prioritization (everything is critical)
❌ Skipping threat modeling until after implementation
❌ No documentation for future reference
