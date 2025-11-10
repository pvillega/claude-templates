---
name: improve
description: "Apply systematic improvements to code quality, performance, and maintainability"
---

# /ct:improve - Code Improvement

## Triggers
- Code quality enhancement and refactoring requests
- Performance optimization and bottleneck resolution needs
- Maintainability improvements and technical debt reduction
- Best practices application and coding standards enforcement

## Usage
```
/ct:improve [target] [--type quality|performance|maintainability|security] [--safe] [--interactive]
```

## Behavioral Flow
1. **Analyze**: Examine codebase for improvement opportunities and quality issues
2. **Plan**: Choose improvement approach and select relevant domain expertise
3. **Execute**: Apply systematic improvements with domain-specific best practices
4. **Validate**: Ensure improvements preserve functionality and meet quality standards
5. **Document**: Generate improvement summary and recommendations for future work

Key behaviors:
- Multi-domain expertise application (architecture, performance, quality, security) based on improvement type
- Framework-specific optimization patterns and best practices
- Systematic analysis for complex multi-component improvements
- Safe refactoring with comprehensive validation and rollback capabilities

## Improvement Type Mapping

This command acts as a unified entry point that routes to appropriate skills based on improvement type:

### Quality Improvements (`--type quality`)
Delegates to:
- **`duplicate-code-detector` skill** - Identifies code duplication with jscpd analysis
- **`technical-debt-assessment` skill** - Prioritizes technical debt reduction
- **`incremental-refactoring` skill** - Applies safe refactoring patterns

Workflow:
1. Run duplicate-code-detector for duplication analysis
2. Use technical-debt-assessment for prioritization
3. Apply incremental-refactoring for safe implementation

### Performance Improvements (`--type performance`)
Delegates to:
- **`performance-optimization` skill** - Systematic performance improvement with measurement
- **`measure-first-optimization` skill** - Measurement-driven optimization approach

Workflow:
1. Establish performance baselines with profiling
2. Identify bottlenecks through measurement
3. Apply targeted optimizations
4. Verify improvements with metrics

### Maintainability Improvements (`--type maintainability`)
Delegates to:
- **`technical-debt-assessment` skill** - Complexity analysis and debt quantification
- **`incremental-refactoring` skill** - Structure improvements and simplification
- **`architecture-discipline` skill** - Architectural consistency validation

Workflow:
1. Assess technical debt and complexity metrics
2. Plan incremental refactoring approach
3. Apply structure improvements
4. Validate against architectural principles

### Security Improvements (`--type security`)
Delegates to:
- **`security-audit` skill** - OWASP Top 10 vulnerability analysis
- Code review for security anti-patterns
- Secure coding practices application

Workflow:
1. Run security-audit skill for vulnerability scanning
2. Identify security anti-patterns
3. Apply security hardening patterns
4. Validate with comprehensive testing

## MCP Integration
- **Sequential MCP**: Auto-activated for complex multi-step improvement analysis and planning
- **Context7 MCP**: Framework-specific best practices and optimization patterns
- **Serena MCP**: Memory persistence for improvement recommendations and patterns

## Tool Coordination
- **Read/Grep/Glob**: Code analysis and improvement opportunity identification
- **Edit**: Safe code modification and systematic refactoring (multiple Edit calls for multi-file changes)
- **TodoWrite**: Progress tracking for complex multi-file improvement operations
- **Task**: Delegation for large-scale improvement workflows requiring systematic coordination

## Key Patterns
- **Quality Improvement**: Code analysis → technical debt identification → systematic refactoring
- **Performance Optimization**: Baseline measurement → bottleneck identification → targeted optimization → validation
- **Maintainability Enhancement**: Complexity analysis → incremental simplification → documentation improvement
- **Security Hardening**: Vulnerability scanning → security pattern application → comprehensive validation

## Examples

### Code Quality Enhancement
```
/ct:improve src/ --type quality --safe
# Invokes duplicate-code-detector for duplication analysis
# Uses technical-debt-assessment for prioritization
# Applies incremental-refactoring with safe mode enabled
# Improves code structure, reduces technical debt, enhances readability
```

### Performance Optimization
```
/ct:improve api-endpoints --type performance --interactive
# Applies performance-optimization skill with measurement-first approach
# Analyzes bottlenecks through profiling and metrics
# Interactive guidance for complex performance improvement decisions
# Validates improvements with before/after benchmarks
```

### Maintainability Improvements
```
/ct:improve legacy-modules --type maintainability
# Uses technical-debt-assessment for complexity analysis
# Applies incremental-refactoring for structure improvements
# Validates against architecture-discipline principles
# Reduces complexity and improves code organization
```

### Security Hardening
```
/ct:improve auth-service --type security
# Invokes security-audit skill for vulnerability identification
# Applies security patterns and OWASP best practices
# Comprehensive validation ensures security improvements are effective
# Documents security enhancements and remaining considerations
```

## Flags

### `--safe`
Enables safe refactoring mode:
- Creates backups before modifications
- Applies changes incrementally with validation
- Provides rollback capabilities
- Conservative approach to preserve functionality

### `--interactive`
Enables interactive guidance:
- Asks for confirmation before significant changes
- Provides options for complex improvement decisions
- Explains trade-offs and alternatives
- Allows user to guide improvement priorities

## How This Command Works

The `/ct:improve` command provides a user-friendly orchestration layer:

1. **Analyzes the target** to understand improvement opportunities
2. **Routes to appropriate skills** based on `--type` parameter
3. **Coordinates multi-skill workflows** when improvements span multiple domains
4. **Applies domain expertise** through skill invocation
5. **Validates results** to ensure quality and functionality preservation
6. **Documents improvements** and provides recommendations

This makes the repository's improvement capabilities more discoverable and easier to use than invoking individual skills directly.

## Complementary Tools

Works synergistically with:
- **`/ct:research`** - Research best practices and improvement patterns
- **`/ct:reflect`** - Validate task adherence during improvement process
- **Individual skills** - Can invoke skills directly for specialized needs
- **`/ct:design`** - Design improved architecture before refactoring

## Boundaries

**Will:**
- Apply systematic improvements with domain-specific expertise and validation
- Provide comprehensive analysis with multi-domain coordination and best practices
- Execute safe refactoring with rollback capabilities and quality preservation
- Route to appropriate skills based on improvement type

**Will Not:**
- Apply risky improvements without proper analysis and user confirmation
- Make architectural changes without understanding full system impact
- Override established coding standards or project-specific conventions
- Skip validation steps even when under time pressure
