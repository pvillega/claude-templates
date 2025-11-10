---
name: troubleshoot
description: "Diagnose and resolve issues in code, builds, deployments, and system behavior"
---

# /ct:troubleshoot - Issue Diagnosis and Resolution

## Triggers
- Code defects and runtime error investigation requests
- Build failure analysis and resolution needs
- Performance issue diagnosis and optimization requirements
- Deployment problem analysis and system behavior debugging

## Usage
```
/ct:troubleshoot [issue] [--type bug|build|performance|deployment] [--trace] [--fix]
```

## Behavioral Flow
1. **Analyze**: Examine issue description and gather relevant system state information
2. **Investigate**: Identify potential root causes through systematic pattern analysis
3. **Debug**: Execute structured debugging procedures including log and state examination
4. **Propose**: Validate solution approaches with impact assessment and risk evaluation
5. **Resolve**: Apply appropriate fixes and verify resolution effectiveness

Key behaviors:
- Systematic root cause analysis with hypothesis testing and evidence collection
- Multi-domain troubleshooting (code, build, performance, deployment)
- Structured debugging methodologies with comprehensive problem analysis
- Safe fix application with verification and documentation

## Skill Integration

This command leverages existing skills for systematic investigation:

### For Bug Investigation (`--type bug`)
Applies **`root-cause-analysis` skill**:
- Evidence-based investigation methodology
- Hypothesis generation and testing
- Systematic root cause identification
- Fix validation with verification

### For Performance Issues (`--type performance`)
Applies **`performance-optimization` skill**:
- Performance measurement and baseline establishment
- Bottleneck identification through profiling
- Optimization recommendations with trade-off analysis
- Validation through metrics comparison

### For Build and Deployment Issues
Applies systematic debugging approach:
- Log analysis and error pattern detection
- Configuration validation and dependency checking
- Environment verification and compatibility assessment
- Fix application with comprehensive testing

## Troubleshooting Type Workflows

### Bug Investigation (`--type bug`)
```
1. Analyze error context and stack traces
2. Apply root-cause-analysis skill methodology
3. Identify root cause through evidence chain
4. Propose fixes with impact assessment
5. Validate fix resolves issue without side effects
```

### Build Troubleshooting (`--type build`)
```
1. Analyze build logs and compilation errors
2. Check dependency versions and compatibility
3. Validate configuration files and build settings
4. Identify root cause (dependency, config, or code)
5. Apply fixes and verify successful build
```

### Performance Diagnosis (`--type performance`)
```
1. Establish performance baselines with profiling
2. Apply performance-optimization skill
3. Identify bottlenecks through measurement
4. Recommend optimizations with trade-offs
5. Validate improvements with metrics
```

### Deployment Issues (`--type deployment`)
```
1. Analyze environment and configuration
2. Verify deployment requirements and dependencies
3. Check service health and connectivity
4. Identify configuration or environment issues
5. Apply fixes and verify service functionality
```

## Tool Coordination
- **Read**: Log analysis and system state examination
- **Bash**: Diagnostic command execution and system investigation
- **Grep**: Error pattern detection and log analysis
- **Write**: Diagnostic reports and resolution documentation
- **Edit**: Apply fixes when `--fix` flag is used
- **AskUserQuestion**: Clarify ambiguous error scenarios or fix approaches

## Flags

### `--type [bug|build|performance|deployment]`
Specifies the troubleshooting domain:
- **bug**: Code defects and runtime errors
- **build**: Compilation and build failures
- **performance**: Performance degradation and bottlenecks
- **deployment**: Deployment failures and environment issues

### `--trace`
Enables comprehensive tracing:
- Full stack trace analysis
- Detailed execution path examination
- Verbose logging and state inspection
- Comprehensive evidence collection

### `--fix`
Automatically applies fixes:
- Safe fix application with validation
- Rollback capabilities for risky changes
- Comprehensive testing after fix
- Documentation of changes made

## Key Patterns

### Bug Investigation Pattern
```
Error analysis → Stack trace examination → Code inspection →
Root cause identification → Fix proposal → Validation
```

### Build Troubleshooting Pattern
```
Build log analysis → Dependency checking → Configuration validation →
Issue identification → Fix application → Build verification
```

### Performance Diagnosis Pattern
```
Metrics analysis → Bottleneck identification →
Optimization recommendations → Implementation guidance
```

### Deployment Issue Pattern
```
Environment analysis → Configuration verification →
Service validation → Issue resolution → Health check
```

## Examples

### Code Bug Investigation
```
/ct:troubleshoot "Null pointer exception in user service" --type bug --trace
# Applies root-cause-analysis skill for systematic investigation
# Examines stack traces and error context comprehensively
# Identifies root cause through evidence-based methodology
# Provides targeted fix recommendations with validation
```

### Build Failure Analysis
```
/ct:troubleshoot "TypeScript compilation errors" --type build --fix
# Analyzes build logs and TypeScript configuration
# Checks dependency compatibility and version conflicts
# Automatically applies safe fixes for common compilation issues
# Verifies successful build after fix application
```

### Performance Issue Diagnosis
```
/ct:troubleshoot "API response times degraded" --type performance
# Applies performance-optimization skill with measurement-first approach
# Analyzes performance metrics and identifies bottlenecks
# Provides optimization recommendations with trade-off analysis
# Includes monitoring guidance and profiling strategies
```

### Deployment Problem Resolution
```
/ct:troubleshoot "Service not starting in production" --type deployment --trace
# Comprehensive environment and configuration analysis
# Systematic verification of deployment requirements and dependencies
# Detailed logging and state inspection with --trace flag
# Identifies configuration or environment-specific issues
```

## Execution Workflow

When you invoke `/ct:troubleshoot`:

1. **Intake**: Parse issue description and type flag
2. **Route**: Determine appropriate investigation approach based on type
3. **Investigate**: Apply root-cause-analysis or domain-specific methodology
4. **Report**: Generate findings with evidence chain and confidence levels
5. **Propose**: Suggest fixes with risk assessment and implementation guidance
6. **Verify**: Confirm resolution if `--fix` flag used, document results

## Complementary Tools

Works synergistically with:
- **`/ct:research`** - Research external solutions and known issues
- **`/ct:reflect`** - Validate investigation completeness and task adherence
- **`root-cause-analysis` skill** - Systematic evidence-based debugging
- **`performance-optimization` skill** - Performance issue resolution
- **`/ct:test-*` commands** - Validation after fixes are applied

## Relationship with Other Commands

- **`/ct:research`** - External information gathering (documentation, known issues)
- **`/ct:troubleshoot`** - Internal problem solving (codebase investigation)
- **`/ct:improve`** - Systematic improvements (proactive)
- **`/ct:troubleshoot`** - Issue resolution (reactive)

This command fills the "problem diagnosis and resolution" gap in the command suite.

## Boundaries

**Will:**
- Execute systematic issue diagnosis using structured debugging methodologies
- Provide validated solution approaches with comprehensive problem analysis
- Apply safe fixes with verification and detailed resolution documentation
- Leverage root-cause-analysis and performance-optimization skills

**Will Not:**
- Apply risky fixes without proper analysis and user confirmation
- Modify production systems without explicit permission and safety validation
- Make architectural changes without understanding full system impact
- Skip evidence collection and hypothesis testing in rush to fix
