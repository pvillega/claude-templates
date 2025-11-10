---
skill: tdd-python-production
description: Test-driven development workflow for production-grade Python with security and performance integration
category: engineering
---

# TDD Python Production

## When to Use
- Implementing new Python features/modules
- Production code requiring quality guarantees
- Security-sensitive Python components
- Performance-critical Python code

## 5-Phase Process

### Phase 1: Requirements Analysis
- TodoWrite: Create analysis checklist
- Identify scope and boundaries
- Enumerate edge cases and error conditions
- Flag security implications (input validation, sensitive data)
- Define acceptance criteria

### Phase 2: Design
- Apply SOLID principles
- Plan clean architecture with separation of concerns
- Design for testability (dependency injection, interfaces)
- Identify integration points

### Phase 3: TDD Cycle
**RED**
- Write test first (unit test for smallest unit)
- Test must fail initially
- Validates test actually tests something

**GREEN**
- Write minimal code to pass test
- Focus on making it work, not perfect
- Incremental implementation

**REFACTOR**
- Improve code with test safety net
- Apply patterns where appropriate
- Maintain test coverage

### Phase 4: Security Integration
- Input validation for all entry points
- OWASP Top 10 compliance checks
- Secrets management (never hardcode)
- SQL injection / XSS prevention
- Authentication / authorization validation

### Phase 5: Performance Validation
- Profile code to identify bottlenecks
- Targeted optimization based on measurements
- Benchmark before/after optimization
- Document performance characteristics

## Quality Gates
- 95%+ test coverage
- All security checks pass
- Performance meets requirements
- No OWASP violations
