---
name: design
description: "Design system architecture, APIs, and component interfaces with comprehensive specifications"
---

# /ct:design - System and Component Design

## Triggers
- Architecture planning and system design requests
- API specification and interface design needs
- Component design and technical specification requirements
- Database schema and data model design requests

## Usage
```
/ct:design [target] [--type architecture|api|component|database] [--format diagram|spec|code]
```

## Behavioral Flow
1. **Analyze**: Examine target requirements and existing system context
2. **Plan**: Define design approach and structure based on type and format
3. **Design**: Create comprehensive specifications with industry best practices
4. **Validate**: Ensure design meets requirements and maintainability standards
5. **Document**: Generate clear design documentation with diagrams and specifications

Key behaviors:
- Requirements-driven design approach with scalability considerations
- Industry best practices integration for maintainable solutions
- Multi-format output (diagrams, specifications, code) based on needs
- Validation against existing system architecture and constraints

## Integration with Architecture Discipline

When designing architecture (`--type architecture`), this command generates the initial design artifacts. For comprehensive architectural rigor, follow up with the `architecture-discipline` skill to ensure:

- Scale analysis (current + 10x scenarios)
- Alternative options evaluation (minimum 3 approaches)
- Ripple effect analysis across system components
- Failure modes consideration and mitigation strategies
- Observability planning and monitoring approach
- Migration strategy from current to proposed architecture

**Recommended Workflow:**
1. `/ct:design [target] --type architecture` - Generate initial design
2. Apply `architecture-discipline` skill - Validate and enhance with analytical rigor
3. Iterate based on discipline findings and alternative evaluation
4. Finalize design with comprehensive documentation

## Tool Coordination
- **Read**: Requirements analysis and existing system examination
- **Grep/Glob**: Pattern analysis and system structure investigation
- **Write**: Design documentation and specification generation
- **Bash**: External design tool integration when needed (e.g., diagram generators)

## Output Formats

### Diagram Format
Produces visual representations using:
- ASCII art for simple component relationships
- Mermaid diagrams for architecture and data flow visualization
- PlantUML for detailed class and sequence diagrams
- Entity-relationship diagrams for database schemas

### Specification Format
Generates detailed markdown specifications including:
- Component descriptions and responsibilities
- Interface contracts and API definitions
- Data models and type definitions
- Architectural decision records (ADRs)
- Integration patterns and guidelines

### Code Format
Creates implementation-ready artifacts:
- Interface definitions and type signatures
- API contract definitions (OpenAPI/GraphQL schemas)
- Database migration scripts and schema definitions
- Configuration templates and examples

## Key Patterns
- **Architecture Design**: Requirements → system structure → scalability planning → component relationships
- **API Design**: Interface specification → RESTful/GraphQL patterns → endpoint documentation → data models
- **Component Design**: Functional requirements → interface contracts → dependency mapping → implementation guidance
- **Database Design**: Data requirements → schema design → relationship modeling → normalization analysis

## Examples

### System Architecture Design
```
/ct:design user-management-system --type architecture --format diagram
# Creates comprehensive system architecture with component relationships
# Includes scalability considerations and industry best practices
# Follow up with architecture-discipline skill for rigorous validation
```

### API Specification Design
```
/ct:design payment-api --type api --format spec
# Generates detailed API specification with endpoints and data models
# Follows RESTful design principles and industry standards
# Includes authentication, error handling, and versioning strategies
```

### Component Interface Design
```
/ct:design notification-service --type component --format code
# Designs component interfaces with clear contracts and dependencies
# Provides implementation guidance and integration patterns
# Generates interface definitions ready for implementation
```

### Database Schema Design
```
/ct:design e-commerce-db --type database --format diagram
# Creates database schema with entity relationships and constraints
# Includes normalization analysis and performance considerations
# Provides migration strategy and indexing recommendations
```

## Complementary Tools

This command works synergistically with:
- **`/ct:research`** - Gather external information about design patterns and best practices
- **`/ct:reflect`** - Validate requirements before starting design process
- **`architecture-discipline` skill** - Apply rigorous architectural analysis to generated designs
- **`systematic-requirements-discovery` skill** - Elicit comprehensive requirements before design

## Boundaries

**Will:**
- Create comprehensive design specifications with industry best practices
- Generate multiple format outputs (diagrams, specs, code) based on requirements
- Validate designs against maintainability and scalability standards
- Bridge the gap between requirements and implementation

**Will Not:**
- Generate actual implementation code (designs are blueprints, not implementations)
- Modify existing system architecture without explicit design approval
- Create designs that violate established architectural constraints
- Replace the analytical rigor of architecture-discipline skill (use both together)
