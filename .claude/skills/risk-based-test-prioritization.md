---
skill: risk-based-test-prioritization
description: Systematically prioritize testing efforts using risk assessment and impact analysis
category: quality
---

# Risk-Based Test Prioritization

## When to Use
- Planning test strategy for new features
- Limited testing time/resources
- Deciding what to test first
- Evaluating test coverage adequacy
- Release planning with quality gates

## Process

### 1. Identify Risk Factors
- **Technical complexity** - Novel algorithms, complex logic
- **Business criticality** - Revenue impact, user-facing, compliance
- **Change frequency** - Areas under active development
- **Historical defects** - Previously buggy components
- **Integration points** - External dependencies, APIs

### 2. Assess Probability × Impact
Create risk matrix:
- **Probability**: How likely is failure? (1-5)
- **Impact**: What's the consequence? (1-5)
- **Risk Score**: Probability × Impact

### 3. Prioritize Test Coverage
- High Risk (Score 15-25): Comprehensive testing required
- Medium Risk (Score 6-14): Standard testing sufficient
- Low Risk (Score 1-5): Smoke testing acceptable

### 4. Identify Critical Paths
- User journeys with highest business impact
- Core functionality required for basic operation
- Compliance-required features

### 5. Evaluate Coverage Gaps
- Map existing tests to risk areas
- Identify high-risk areas with low coverage
- Prioritize new test creation

### 6. Validate Strategy
- Are all high-risk areas covered?
- Is coverage proportional to risk?
- Can you justify low-coverage areas?

## Risk Matrix Example
```
        Impact →
      1  2  3  4  5
    1 1  2  3  4  5
P 2 2  4  6  8  10
r 3 3  6  9  12 15
o 4 4  8  12 16 20
b 5 5  10 15 20 25
```

## Output
- Risk assessment matrix
- Prioritized test plan
- Coverage justification
- Resource allocation recommendations
