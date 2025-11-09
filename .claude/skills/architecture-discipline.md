---
name: architecture-discipline
description: Use when designing or modifying system architecture - enforces scale-first thinking, trade-off documentation, and holistic impact analysis before implementation
---

# Architecture Discipline

## ⚠️ MANDATORY FIRST STEP - READ THIS NOW

### 🚨 CRITICAL: Anti-Rationalization Warning

**Time pressure, tight deadlines, and stakeholder urgency are NOT exceptions to this skill.**

This skill exists BECAUSE of pressure. Shortcuts under pressure create:
- 5-10x rework costs when scaling issues emerge (re-architecting after launch)
- Months of engineering time fixing architectural mistakes
- Cascading failures from undocumented dependencies
- Technical debt that blocks future development

**Common rationalizations that mean you're about to fail:**
- "Analysis paralysis" → No, this IS the analysis that prevents expensive mistakes
- "We'll add [scale analysis/alternatives/failure modes] later" → No, retrofitting costs 5-10x more
- "Just this once" → No, every violation sets a precedent for cutting corners
- "[CTO/Director] already suggested X" → X is a candidate to evaluate, not the chosen solution
- "Being pragmatic not dogmatic" → No, these requirements ARE pragmatic (proven by decades of incidents)
- "Board meeting urgency justifies moving quickly" → No, hasty architecture decisions delay the project more

**If you're thinking any of these thoughts, STOP. Re-read the skill requirements.**

---

**STOP. Before proceeding with this architecture task, you MUST:**

1. **CREATE TodoWrite** with these 7 sections (DO NOT SKIP):
   - **Scale Analysis**: Minimum 4 items
   - **Architectural Options**: Minimum 3 items
   - **Ripple Effect Analysis**: Minimum 5 items
   - **Failure Modes**: Minimum 3 items
   - **Observability**: Minimum 3 items
   - **Documentation**: Minimum 2 items
   - **Migration/Compatibility**: Minimum 2 items

2. **VERIFY TodoWrite quality** using standards below (MANDATORY - see verification checkpoint)

3. **CONFIRM section completeness** using checklist below

**Do not design, propose solutions, or implement until TodoWrite is created and verified.**

---

## 🚨 CRITICAL: Anti-Retrofitting Rule

**If you wrote ANY architecture document without starting with all 7 sections from the beginning:**

### ❌ NEVER DO THIS:
- "I'll add the missing sections to my existing work"
- "The technical content is good, I just need to add alternatives/scale/failure analysis"
- "I can retrofit compliance by adding the sections now"
- "Keep existing work as 'reference' while writing missing sections"
- "I'll salvage my work by filling in the gaps"

### ✅ ALWAYS DO THIS:
- **DELETE the entire document**
- **Start over from scratch with all 7 sections**
- **No exceptions, no "salvaging", no retrofitting**

---

### Why Retrofitting Doesn't Work

#### 1. Alternatives Analysis Must Precede Solution Selection

**Scenario**: You wrote 15 pages about Redis without comparing alternatives

❌ **Retrofitting**: Add "alternatives analysis" section comparing Redis vs RabbitMQ vs Kafka
- **Problem**: You've already anchored on Redis
- **Result**: Your analysis will rationalize Redis, not evaluate objectively
- **Reality**: This is theatre, not analysis
- **Cognitive bias**: Confirmation bias makes you find reasons to justify existing work

✅ **Starting over**: Compare Redis vs RabbitMQ vs Kafka vs SQS FIRST (before choosing)
- **Benefit**: Unbiased evaluation might reveal RabbitMQ is actually better
- **Reality**: You might not choose Redis at all after proper comparison
- **Result**: Solution chosen on merits, not anchoring

#### 2. Scale Analysis Changes Current Design

**Scenario**: You designed for current scale, then realize you need 10x analysis

❌ **Retrofitting**: Add "10x scale" section to existing design
- **Problem**: Evaluating 10x might reveal current design won't work at ANY scale
- **Result**: Superficial "it will scale" claims without fundamental redesign
- **Reality**: You're validating, not analyzing
- **Outcome**: Architecture that fails at 2x scale, not just 10x

✅ **Starting over**: Design WITH 10x scale constraints from beginning
- **Benefit**: Architecture shaped by scale requirements from start
- **Reality**: Might choose completely different technology
- **Result**: Redis sharding strategy built in from day one, not bolted on later

#### 3. Failure Modes Expose Design Flaws

**Scenario**: You designed the happy path, then add failure modes analysis

❌ **Retrofitting**: Add "failure modes" section listing what could break
- **Problem**: Systematic failure analysis often reveals fundamental design flaws
- **Result**: You document failures instead of preventing them
- **Reality**: Can't tack on resilience as afterthought
- **Outcome**: No circuit breakers, no fallback strategies, no graceful degradation

✅ **Starting over**: Design WITH failure modes from beginning
- **Benefit**: Architecture includes circuit breakers, fallbacks, and degradation strategies
- **Reality**: Failure-aware design from foundation
- **Result**: System that stays up when Redis crashes, not crashes with Redis

#### 4. Ripple Effects Change Scope

**Scenario**: You designed an isolated component, then analyze ripple effects

❌ **Retrofitting**: Add section documenting which services are affected
- **Problem**: Ripple effect analysis might reveal your solution requires 4-team coordination
- **Result**: "Simple" solution becomes multi-month cross-team project
- **Reality**: Scope explosion discovered too late
- **Outcome**: Timeline blown, stakeholders surprised, teams blocked

✅ **Starting over**: Analyze ripple effects BEFORE designing solution
- **Benefit**: Choose solution that minimizes cross-team dependencies
- **Reality**: Might pick simpler option that's isolated to one service
- **Result**: Actually delivers on promised timeline

---

### The Self-Check Question

**Before claiming "I'll add the missing sections":**

Ask yourself: **"Am I trying to preserve work done with wrong methodology?"**

If YES → You need to **DELETE EVERYTHING and restart**

**Why this thought is a red flag:**
- You're treating architecture as checklist ("check all boxes")
- Not as reasoning discipline ("think in right order")
- Sequence matters: alternatives BEFORE selection, scale BEFORE design, failures BEFORE implementation
- No amount of retrofitting fixes reversed sequence
- You've already made the key decisions; adding analysis afterward is rationalization

---

### Worked Example: The Redis Architecture Case

**❌ WRONG Approach (Retrofitting)**:

Hours 1-6: Write 15-page Redis architecture
- Design cache key structure: `user:{id}:recs:{category}`
- Plan cluster configuration: 3 masters, 3 replicas
- Estimate capacity: handles 10K requests/sec
- Write implementation roadmap: 2-week timeline

Hour 7: Realize missing sections

Hours 8-10: Retrofit missing sections
- **Alternatives analysis**: Compare Redis vs RabbitMQ vs Kafka
  - Result: Find reasons Redis is better (anchoring bias at work)
  - Reality: Unconsciously biased toward justifying existing work
- **10x scale analysis**: Calculate Redis capacity at 100K req/sec
  - Result: Assume Redis scales with sharding (not questioning if it's right choice)
  - Reality: Never considered if different technology would be simpler at scale
- **Failure modes**: List what happens if Redis crashes
  - Result: Document problems ("add circuit breaker to backlog")
  - Reality: No actual resilience built into architecture

**Outcome**: Compliant-looking document with fundamentally flawed methodology

---

**✅ RIGHT Approach (Proper Sequence)**:

Hours 1-2: **Alternatives analysis FIRST** (before committing to Redis)
- Compare 5 options: Redis vs RabbitMQ vs Kafka vs In-memory LRU vs No cache
- Evaluate on: latency (P95), throughput, operational complexity, cost at current + 10x scale
- **Discovery**: In-memory LRU might handle 90% of cases with zero ops burden
- **Discovery**: RabbitMQ might be better if message ordering matters
- **Decision**: Choose Redis ONLY IF it wins on key criteria after objective comparison

Hours 3-4: **10x scale analysis shapes architecture** (before detailed design)
- Current: 1000 req/sec, 10x: 10,000 req/sec
- **Discovery**: Single Redis cluster caps at 6K req/sec
- **Design decision**: Need sharding strategy from day one (not "we'll add it later")
- **Discovery**: Network becomes bottleneck at 8Gbps
- **Design decision**: Need to plan for 3 shards across availability zones NOW

Hours 5-6: **Failure modes drive design** (before implementation plan)
- What if Redis cluster fails? → Need circuit breaker + database fallback
- What if cache stampede? → Need probabilistic early expiration in design
- What if network partition? → Need multi-zone replication in architecture
- **Design decision**: Architecture now includes resilience from foundation, not TODO items

Hours 7-8: **Complete other sections with context**
- Ripple effects: Now know which services need circuit breakers (discovered in failure analysis)
- Observability: Metrics identified based on failure modes (cache miss rate, circuit breaker trips)
- Documentation: ADR documents why Redis over 4 alternatives (real comparison, not rationalization)
- Migration: Rollback plan includes fallback to DB (designed in failure mode analysis)

**Outcome**: Architecture designed with all considerations from the start. Each section informed the others. No retrofitting needed.

---

### The Cost Analysis

**Emotional thinking**: "I spent 6 hours on this work. Deleting it feels wasteful."

**Rational analysis**:

- **Option A - Retrofit sections**:
  - Time: 2-3 hours
  - Result: Flawed architecture with rationalized justifications
  - Future cost: 3-month rearchitecture when scale/failures hit
  - Total cost: 9 hours + 3 months

- **Option B - Delete and restart**:
  - Time: 6 hours
  - Result: Sound architecture with objective analysis
  - Future cost: Zero (architecture works as designed)
  - Total cost: 6 hours

**The 6 hours are already gone (sunk cost). The question is: which path leads to correct architecture?**

**Answer**: Restarting. Always.

---

### Sunk Cost Principle: DELETE THE WORK

**Common rationalization**: "I already spent 6 hours. I can't throw that away."

**Reality**: Those 6 hours are GONE regardless of what you do next.

**The question is NOT**: "Can I salvage 6 hours of work?"

**The question IS**: "Will retrofitting produce better outcome than restarting?"

**Answer**: NO

**Why retrofitting fails**:
- Alternatives analysis after solution selection = rationalization
- Scale analysis after detailed design = validation, not input
- Failure modes after architecture = documentation, not prevention
- You've already made key decisions; adding analysis is theatre

**The math**:
- 6 hours sunk (irrelevant - already spent)
- Option A: Restart properly (6 hours) → Sound architecture → $0 future cost
- Option B: Retrofit sections (2 hours) → Flawed architecture → 3-month rewrite (500 hours) → $100K-$500K cost
- **Savings by deleting now**: 496 hours + $100K-$500K

**Command**: **DELETE the flawed work. Start over. No exceptions.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, you MUST verify EVERY item meets quality standards BEFORE proceeding.**

**Complete this checklist and output the results:**

```
VERIFICATION CHECKLIST:
[ ] Selected 3 random items from TodoWrite
[ ] Item 1: [paste full item text here]
    - Has concrete numbers/thresholds? YES/NO (examples: "100K users", "10x scale", "4.5:1 contrast", "$500/mo")
    - Names specific tools/technologies? YES/NO (examples: "PostgreSQL", "Redis", "CloudWatch", "Firebase")
    - States measurable outcome? YES/NO (examples: "P95 latency < 500ms", "handles 1M req/sec", "costs $X at 10x")
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

**DO NOT PROCEED WITH ARCHITECTURE DESIGN until all 9 checks pass.**

---

**Minimum total: 22 specific items** covering all 7 categories.

---

## Section Completion Confirmation

**After creating TodoWrite, output this checklist to confirm all sections present:**

```
SECTION COMPLETION:
[ ] Scale Analysis: 4+ items
[ ] Architectural Options: 3+ items
[ ] Ripple Effect Analysis: 5+ items
[ ] Failure Modes: 3+ items
[ ] Observability: 3+ items
[ ] Documentation: 2+ items
[ ] Migration/Compatibility: 2+ items

TOTAL: ___ items (must be 22+)
```

**If any section is unchecked or total < 22, STOP and add missing items now.**

**Why this matters:** 30% of agents miss entire sections (especially later ones: Migration, Documentation, Observability). This checklist prevents that.

---

## TodoWrite Quality Standards

After creating TodoWrite, verify EVERY item meets these criteria:

- [ ] Includes concrete numbers (users, requests/sec, data volume, latency, cost)
- [ ] Names specific components/services/technologies being analyzed
- [ ] States measurable outcome or specific analysis to perform

## The Specificity Test

**For EACH TodoWrite item, ask: "Could an engineer implement this tomorrow without asking clarifying questions?"**

**If NO → Item fails specificity test.**

### What Makes an Item Specific?

Must include ALL three:
1. **Concrete numbers/thresholds**: "100K users", "10x scale = 1M users", "$500/mo at 10x", "P95 < 500ms", "4.5:1 contrast"
2. **Specific tools/technologies**: "PostgreSQL", "Redis Sentinel", "CloudWatch", "Firebase", "Socket.io"
3. **Measurable outcome**: "handles 1M req/sec", "costs $X at 10x", "latency P95 < 500ms", "scales to 10x"

### Test Examples

❌ **FAILS TEST**: "Add monitoring"
- Engineer asks: Which metrics? Which tool? What thresholds? What alerts?

✅ **PASSES TEST**: "CloudWatch metrics: `websocket.connections.active` (gauge), `notifications.sent.count` (counter), `delivery.latency` P50/P95/P99 (histogram). Alert if error rate >5% for 5min via PagerDuty."
- Engineer knows: Metric names, types, tool, alert threshold, alert system

❌ **FAILS TEST**: "Evaluate caching options"
- Engineer asks: Which options? What criteria? What performance targets?

✅ **PASSES TEST**: "Compare Redis (1ms latency, $300/mo, 100K ops/sec) vs In-memory LRU (0.1ms, $0, 500K ops/sec, cache per instance) vs No cache (100ms from DB). Choose based on latency requirement <10ms."
- Engineer knows: Options, performance numbers, costs, decision criteria

### Apply This Test

Before proceeding, select 3 random items from your TodoWrite and test them. If any fail, revise before proceeding.

---

### Examples of Quality Items

**❌ BAD (too generic):**
- "Analyze scale requirements"
- "Document trade-offs"
- "Consider alternatives"
- "Check impact"
- "Think about failures"

**✅ GOOD (specific):**
- "Current scale: 100K daily active users, 50 requests/sec peak. 10x scale: 1M users, 500 req/sec"
- "Option A (PostgreSQL): 10ms read latency, ACID guarantees, vertical scaling limit ~500 req/sec. Cost: $200/mo"
- "Ripple effect on API Gateway: need to increase rate limit from 1000 to 10000 req/min, update CORS config"
- "Failure mode: Database connection pool exhausted. Mitigation: Circuit breaker + connection limit + graceful degradation"
- "Document decision in ADR-015: Why Kafka over SQS for event streaming (throughput, ordering, cost comparison)"

---

## ❌ Failed Examples (What NOT To Do)

**These items would FAIL verification. If your items look like these, revise them immediately.**

### Too Generic (No Concrete Values)

❌ "Analyze scale requirements"
- **Why it fails**: Which scale? Current? Future? How do you measure it?
- **Engineer asks**: What numbers should I be looking at? Where do I start?

❌ "Document trade-offs"
- **Why it fails**: Which trade-offs? Between what options? How documented?
- **Engineer asks**: What am I comparing? What format? What criteria?

❌ "Consider alternatives"
- **Why it fails**: Which alternatives? How many? Based on what criteria?
- **Engineer asks**: Which technologies? What's the comparison framework?

### Missing Concrete Numbers

❌ "Scale to handle growth"
- **Why it fails**: How much growth? When? What breaks first?
- **Engineer asks**: 2x growth? 10x? What's the timeline? What component fails?

❌ "Keep latency low"
- **Why it fails**: How low? Measured where? On what connection?
- **Engineer asks**: <100ms? <500ms? <1s? P50? P95? P99?

❌ "Reduce cost"
- **Why it fails**: From what to what? At what scale? Which component?
- **Engineer asks**: Current cost? Target cost? Which service costs most?

### Missing Specific Tools

❌ "Add caching"
- **Why it fails**: Which caching solution? Where? What TTL? What keys?
- **Engineer asks**: Redis? Memcached? In-memory? CDN? What configuration?

❌ "Use message queue"
- **Why it fails**: Which queue system? What throughput? What guarantees?
- **Engineer asks**: RabbitMQ? Kafka? SQS? What message size? What retention?

### Missing Verification Method

❌ "Ensure system scales"
- **Why it fails**: How do you verify scaling works?
- **Engineer asks**: Load testing? What metrics? What's passing criteria?

❌ "Monitor performance"
- **Why it fails**: What metrics? What thresholds? Which tool?
- **Engineer asks**: Which dashboard? What alerts? When do we act?

**If 3+ of your TodoWrite items match these ❌ patterns, STOP. Your TodoWrite needs major revision before proceeding.**

---

## Section Completeness Check

Before proceeding, confirm ALL mandatory sections present in your TodoWrite:

- [ ] **Scale Analysis**: 4+ items (current scale, 10x scale, bottlenecks, mitigation) ✓
- [ ] **Architectural Options**: 3+ items (minimum 3 distinct options with trade-offs) ✓
- [ ] **Ripple Effect Analysis**: 5+ items (data layer, services, APIs, clients, operations - all layers) ✓
- [ ] **Failure Modes**: 3+ items (specific failures, detection, mitigation for each) ✓
- [ ] **Observability**: 3+ items (monitoring requirements, alerts, metrics) ✓
- [ ] **Documentation**: 2+ items (ADR/design doc, diagram updates) ✓
- [ ] **Migration/Compatibility**: 2+ items (backward compat or migration path, rollback plan) ✓

**If any section is missing or below minimum items, STOP and add them now.**

---

## Trigger Conditions

Activate this skill when:
- Designing new features or services
- Modifying existing architectural components
- Evaluating technology choices or frameworks
- Refactoring system boundaries or data flows
- User requests "architecture review" or "system design"
- Changes affect multiple services or layers
- Performance, scalability, or reliability requirements are discussed

---

## This Is Not A Checklist - It's A Reasoning Discipline

**Understanding the difference is critical. Agents who treat this as a checklist violate it.**

### Checklist Thinking (WRONG ❌)

**Mindset**: "I need 7 sections checked off"

**Behavior**:
- "I have 5 sections, missing 2. I'll add them."
- "My work has all the boxes checked."
- "I can retrofit missing sections to existing work."
- Focus: **Compliance** (do I have all sections?)

**Problem**:
- Treats sections as items to add
- Order doesn't matter in their mind
- Sections can be retrofitted after the fact
- **Result**: Compliant-looking document with flawed reasoning

**Example violation**:
> "I already wrote 15 pages about Redis. I'm missing alternatives analysis. Let me add that section now."
>
> ❌ This is checklist thinking. You're trying to check a box, not fix broken reasoning.

---

### Discipline Thinking (CORRECT ✅)

**Mindset**: "I need to think in the right sequence"

**Behavior**:
- "I need to analyze alternatives BEFORE choosing a solution."
- "I need to design FOR scale, not validate afterward."
- "I need resilience built in from foundation, not TODO items."
- Focus: **Correct reasoning sequence** (am I thinking in the right order?)

**Benefit**:
- Sequence shapes decisions
- Each step informs the next
- Can't skip or reorder steps
- **Result**: Sound architecture from correct reasoning process

**Example compliance**:
> "I need to choose between Redis and Kafka. First, let me analyze scale requirements (section 1), then compare both options systematically (section 2), then I'll choose based on that analysis (section 3)."
>
> ✅ This is discipline thinking. The sequence guides the decision-making.

---

### The Key Difference

| Aspect | Checklist Thinking ❌ | Discipline Thinking ✅ |
|--------|---------------------|----------------------|
| **Goal** | Have all 7 sections | Follow correct reasoning sequence |
| **Order** | Doesn't matter | Critical - must be in sequence |
| **Retrofitting** | "I can add sections later" | "Must start over if out of order" |
| **Metric** | "Do I have 7 sections?" | "Did I think in right order?" |
| **Purpose** | Compliance | Correct decision-making |
| **Outcome** | Compliant-looking docs | Sound architecture |

### Self-Check

**If you're thinking**:
- "I need to check all the boxes" → ❌ **Checklist thinking**
- "I can add missing sections to my work" → ❌ **Checklist thinking**
- "I have all 7 sections, so I'm compliant" → ❌ **Checklist thinking**

**You should be thinking**:
- "Did I analyze alternatives BEFORE choosing?" → ✅ **Discipline thinking**
- "Did scale requirements shape my options?" → ✅ **Discipline thinking**
- "Are failure modes built into my design?" → ✅ **Discipline thinking**

### Why This Matters

**40% of agents fail by treating this as a checklist:**

**Common pattern** (from real testing):
1. Agent writes architectural design (6 hours)
2. Agent realizes missing sections
3. Agent thinks: "I'll add the missing sections" ← **Checklist thinking**
4. Agent retrofits sections to existing work
5. **Result**: Flawed architecture with fake analysis

**Correct pattern** (discipline thinking):
1. Agent starts with section 1 (Scale Analysis)
2. Outcomes from section 1 inform section 2 (Alternatives)
3. Outcomes from section 2 inform section 3 (Solution Selection)
4. Each section builds on previous sections
5. **Result**: Sound architecture from proper reasoning sequence

---

### The Bottom Line

**This skill is about HOW YOU THINK, not WHAT SECTIONS YOU INCLUDE.**

The 7 sections are **outputs of correct thinking**, not **items to add after the fact**.

**If you're thinking about "checking boxes" → You've already failed.**

The checklist format is scaffolding for a reasoning discipline. Use it to guide your thinking process, not to validate compliance.

---

## Handling Authority Bias

**30% of agents defer to stakeholder suggestions, skipping independent analysis. This section prevents that.**

### When Stakeholder/Director/CTO Suggests Specific Solution

❌ **WRONG**: "Director wants Firebase, so we'll use Firebase"
✅ **CORRECT**: "Director suggests Firebase. I will evaluate Firebase as Option A, and compare against Options B and C with equal rigor."

### Process

1. **Add stakeholder suggestion as one of the 3+ options**
   - Option A: [Stakeholder's suggestion]
   - Option B: [Alternative approach 1]
   - Option C: [Alternative approach 2]

2. **Evaluate stakeholder suggestion with SAME rigor as other options**
   - Performance: Latency, throughput, scale limit (with numbers)
   - Complexity: LOC estimate, operational burden
   - Cost: Infrastructure + development + maintenance ($X/month)
   - Trade-offs: Advantages and disadvantages

3. **Document why chosen (or why rejected despite suggestion)**
   - If stakeholder suggestion is best: Document WHY (specific trade-off analysis)
   - If alternative is better: Document WHY stakeholder suggestion was rejected (specific gaps)

### Key Principle

**"Director wants X" means X is a serious candidate requiring evaluation, NOT that X is automatically the answer.**

Stakeholders suggest solutions based on partial context. Your job is to validate (or invalidate) with complete analysis.

### If Stakeholder Pushes Back on Evaluation

Use this template:

"I'm documenting why your suggestion is the best choice by comparing it to alternatives. This strengthens the decision and makes it defensible to:
- Future engineers who maintain this system
- Auditors reviewing architectural decisions
- Post-mortems if issues arise

Comparing 3 options takes 30 minutes. Re-architecting a bad choice takes 3 months."

### Red Flags

If you're thinking:
- "Director already researched this" → Still need independent validation
- "CTO has more experience" → Experience doesn't replace systematic analysis
- "Board wants quick decision" → Quick bad decision costs more than slow good decision

**Stop and complete the 3-option comparison.**

---

## Mandatory Requirements

Create TodoWrite items for all categories below. Refer to Quality Standards and Completeness Check sections above.

### Scale Analysis

**⚠️ CRITICAL: Designing for current scale guarantees re-architecture within 6-12 months.**

- [ ] **Current scale defined**: Users (DAU/MAU), requests/second (peak), data volume (GB/TB), read/write ratio
- [ ] **10x scale projected**: What are the numbers at 10x? When do we expect to reach it?
- [ ] **Bottlenecks identified**: What specifically breaks at 10x scale? (database connections, API rate limits, memory, disk I/O)
- [ ] **Mitigation strategies**: For each bottleneck, specific solution (sharding, caching, read replicas, async processing)

**Template for scale analysis:**
```
Current scale:
- Users: [number] DAU
- Traffic: [number] requests/sec peak
- Data: [number] GB total, [number] GB/day growth
- Read/write ratio: [X:Y]

10x scale:
- Users: [10x number] DAU
- Traffic: [10x number] requests/sec peak
- Data: [10x number] GB total, [10x number] GB/day growth

Bottleneck at 10x: [specific component] breaks because [specific resource exhaustion]
Mitigation: [specific solution with estimated capacity gain]
```

### Architectural Options

**⚠️ CRITICAL: Single-solution proposals indicate insufficient analysis.**

Document MINIMUM 3 distinct options:

- [ ] **Option A**: [Technology/approach name], [key characteristics], [trade-offs]
- [ ] **Option B**: [Technology/approach name], [key characteristics], [trade-offs]
- [ ] **Option C**: [Technology/approach name], [key characteristics], [trade-offs]

**Template for each option:**
```
Option [A/B/C]: [Technology/Approach Name]

Performance:
- Latency: [P50/P95/P99 numbers]
- Throughput: [requests/sec or operations/sec]
- Scale limit: [where it breaks]

Complexity:
- Lines of code: [estimated LOC or "simple"/"moderate"/"complex"]
- Services: [number of services involved]
- Operational burden: [deployment, monitoring, debugging difficulty]

Cost:
- Infrastructure: $[amount]/month at current scale, $[amount]/month at 10x
- Development: [estimated engineer-weeks]
- Maintenance: [ongoing effort level]

Trade-offs:
- ✅ Advantage: [specific benefit]
- ❌ Disadvantage: [specific downside]
```

### Ripple Effect Analysis

**⚠️ CRITICAL: Changes propagate across layers. Analyze ALL layers systematically.**

- [ ] **Data layer impact**: Database schema changes, migration scripts, indexes, query performance impact
- [ ] **Services impact**: Which services need updates? API contracts changed? New service dependencies?
- [ ] **API impact**: Breaking changes? Version bump needed? Backward compatibility approach?
- [ ] **Client impact**: Mobile app updates required? Web UI changes? SDK version updates?
- [ ] **Operations impact**: Deployment changes? New monitoring? Infrastructure updates? Cost changes?

### Failure Modes

**⚠️ CRITICAL: Every architecture decision creates new failure modes.**

For each potential failure mode:

- [ ] **Failure scenario**: [Specific component] fails because [specific reason]
- [ ] **Detection**: How we know it failed (metrics drop, error rate spike, alert fires)
- [ ] **Impact**: What breaks? (user-facing features, data integrity, other services)
- [ ] **Mitigation**: Specific solution (circuit breaker, fallback, redundancy, graceful degradation)

**Common failure modes to analyze:**
- Service down (crashed, deployed bad version, infrastructure failure)
- Service slow (resource exhaustion, external dependency slow, database slow)
- Data corruption (partial write, race condition, migration bug)
- Network partition (can't reach database, can't reach external API, split brain)

### Observability

- [ ] **Metrics to instrument**: Specific metrics (latency P95, error rate %, throughput req/sec, resource utilization %)
- [ ] **Alerts to configure**: Specific conditions (error rate > 5%, latency P95 > 500ms, queue depth > 10000)
- [ ] **Dashboards to create**: Key visualizations (request flow diagram, latency by endpoint, error breakdown)

### Documentation

- [ ] **Architecture Decision Record**: Document chosen option, rejected alternatives, trade-off analysis, constraints
- [ ] **Architecture diagram update**: Add new components, update data flows, show failure paths

### Migration/Compatibility

- [ ] **Backward compatibility**: Can old clients still work? Old data formats supported? API versioning strategy?
- [ ] **Migration path**: Phased rollout plan, feature flags, database migration steps, rollback procedure
- [ ] **Rollback plan**: If new architecture fails, how to revert? Data migration reversal? Time to rollback?

---

## Non-Negotiable Rules

### Scale-First Mindset

**NEVER design for current scale only.**

Before proposing any solution, answer:
- **"What breaks at 10x scale?"**
- **"What is the bottleneck?"**
- **"What is the mitigation strategy?"**

If you can't answer these, you haven't done sufficient analysis.

### Sequence Matters: Why Order Is Non-Negotiable

**The 7 sections are not a checklist you can complete in any order. They are a REASONING SEQUENCE that must be followed.**

**Correct sequence**:

1. **Scale Analysis FIRST** → Shapes what technologies are viable
   - Defines performance/capacity requirements
   - Rules out solutions that can't scale
   - Example: Knowing you need 10K req/sec eliminates single-server solutions

2. **Alternatives Analysis SECOND** → Objective comparison before commitment
   - Must be done BEFORE choosing a solution
   - Prevents anchoring bias
   - Example: Compare Redis/RabbitMQ/Kafka before deciding, not after

3. **Solution Selection THIRD** → Based on scale + alternatives
   - Now you can choose with full information
   - Decision is defensible (you considered options)
   - Example: Choose Redis because it best meets scale + cost requirements

4. **Ripple Effects FOURTH** → Understand integration complexity
   - Now know which teams/services are affected
   - Shapes deployment strategy
   - Example: Discover 4 services need updates → choose simpler option or plan coordination

5. **Failure Modes FIFTH** → Build resilience into design
   - Design includes circuit breakers, fallbacks from start
   - Not bolted on later
   - Example: Redis architecture includes DB fallback and circuit breaker from day one

6. **Observability SIXTH** → Instrument for production
   - Metrics based on failure modes identified
   - Alerts for scenarios discovered in failure analysis
   - Example: Alert on circuit breaker trips (from failure mode analysis)

7. **Documentation + Migration SEVENTH** → Prepare for deployment
   - ADR documents why chosen (from alternatives analysis)
   - Rollback plan based on failure modes
   - Example: ADR explains why Redis over Kafka with specific trade-offs

**Why sequence matters**:

- Do alternatives analysis AFTER choosing solution → Rationalization theatre (you'll justify your choice, not evaluate objectively)
- Do scale analysis AFTER design → Wrong architecture that can't scale (design assumptions baked in)
- Do failure modes AFTER implementation → Resilience bolted on, not built in (circuit breakers become "tech debt items")
- Do ripple effects AFTER commitment → Scope explosion discovered too late (surprise 4-team coordination needed)

**If you did steps out of order → DELETE and restart**

You cannot retrofit reasoning sequence. The order shapes the outcome. Each step's output informs the next step's input.

**Example of why order matters**:

❌ **Wrong**: Choose Redis (step 3) → Analyze alternatives (step 2)
- Result: "Alternatives analysis" rationalizes Redis
- Bias: Confirmation bias drives you to find reasons Redis is better
- Outcome: Flawed decision justified by fake analysis

✅ **Right**: Analyze alternatives (step 2) → Choose Redis (step 3)
- Result: Objective comparison might reveal Kafka is actually better
- No bias: You haven't committed to anything yet
- Outcome: Best solution chosen on merits

### Trade-Off Documentation

**NEVER present a single solution without alternatives.**

Requirement: Minimum 3 distinct options with documented trade-offs across:
- Performance (latency, throughput, resource usage)
- Complexity (development effort, operational burden, debugging difficulty)
- Cost (infrastructure, development, maintenance)
- Reliability (failure modes, recovery time, data safety)

Record WHY chosen option is best FOR THIS SPECIFIC CONTEXT. Future engineers must understand the constraints that drove the decision.

### Holistic Impact Analysis

**NEVER modify one component in isolation.**

Mandatory ripple effect tracing through ALL layers:
1. **Data layer**: Schema changes, query performance, migrations
2. **Services**: API contracts, dependencies, backwards compatibility
3. **APIs**: Breaking changes, versioning, client updates
4. **Clients**: Mobile apps, web UI, third-party integrations
5. **Operations**: Deployment, monitoring, infrastructure, cost

Ask for each layer:
- **"What breaks if I make this change?"**
- **"What gets slower?"**
- **"What becomes harder to change later?"**

### Failure Mode Prevention

**REFUSE to design without discussing failure scenarios.**

For EVERY architectural decision, explicitly answer:
- **"What happens when [this component] is down?"**
- **"How do we detect degradation?"**
- **"What's the rollback plan?"**
- **"What's the blast radius if this fails?"**

If answers are "I don't know" or "it won't fail", analysis is incomplete.

---

## 🚩 Red Flags - STOP

**If you find yourself thinking or saying ANY of these, you are about to violate the skill:**

- "This is just a simple [feature/service]" → Simple things need structure too. Simple becomes complex at scale.
- "Analysis paralysis" → No, this IS the analysis that prevents expensive mistakes
- "We'll add [scale analysis/alternatives/failure modes] later/in v2/post-launch" → No, implement now. Later = never (80% never added)
- "Being pragmatic not dogmatic" → These requirements ARE pragmatic (proven by decades of incidents)
- "Just this once" → Every violation sets a precedent for cutting corners
- "[CTO/Director/Board] already decided" → Still needs independent evaluation. Authority ≠ correctness.
- "Board meeting urgency justifies moving quickly" → Hasty architecture delays projects MORE than thorough analysis
- "We already know the solution" → If you haven't compared 3 alternatives with trade-offs, you don't know
- "That edge case is unlikely" → Unlikely × scale = frequent. Design for 10x now or re-architect in 6 months.
- "Keep it simple" → Simple for current scale = complex re-architecture at 10x scale
- "We can optimize later" → Optimization ≠ re-architecture. Wrong architecture can't be optimized.
- **"I can add the missing sections to my existing work"** → NO. Delete and restart. Retrofitting = fake compliance.
- **"I'll retrofit the analysis to my current design"** → NO. Analysis must precede design, not follow it.
- **"Keep existing work as reference while doing proper analysis"** → NO. You'll anchor on it unconsciously.
- **"The technical work is good, just missing documentation"** → NO. Wrong methodology = flawed foundation.
- **"I can salvage X hours of work by adding sections"** → NO. Sunk cost fallacy. Delete it.
- **"I'm following the spirit by having all sections eventually"** → NO. Sequence matters. Letter IS spirit.

**When you notice a red flag, STOP. Re-read the specific skill requirement you're about to skip.**

**Each red flag represents a pattern from the 40-60% of agents who bypassed skill requirements under pressure.**

---

## When Asked to Skip Requirements

Use these EXACT response templates:

### "We'll Add [Requirement] Later"

❌ **BLOCKED**: I cannot defer [scale analysis/alternative evaluation/failure modes] to future iterations.

**Why "later" always fails:**
- "Later" never comes - next sprint has new priorities
- Retrofitting costs 5-10x more than building it in
- Technical debt accumulates and blocks future changes
- Re-architecting after launch costs months of engineering time

**The data:**
- 80% of "we'll add later" items never get added
- Re-architecting costs 5-10x more than getting it right initially
- Hasty architecture decisions delay projects more than thorough analysis
- Each skipped requirement creates cascading issues (1 becomes 5 becomes 20)

**Specific consequence for this requirement:**
- Skipping scale analysis → Re-architecture in 6-12 months when growth hits (3-6 month project)
- Skipping alternatives → Optimize for wrong dimension, costly migration later (2-4 month project)
- Skipping failure modes → Production incidents, multi-hour debugging, data loss (cost: $5-50K per incident)

**Required**: Implement now, or explicitly document:
1. Specific date for retrofit (not "later" - actual sprint/date)
2. Budget allocated (engineer-weeks + dollar cost)
3. Risk acceptance signed by [decision maker's name]
4. Interim mitigation plan (what you'll do when issues arise before retrofit)

**If you cannot provide these 4 items, requirement must be implemented now.**

---

### Skipping Scale Analysis
```
❌ BLOCKED: I cannot propose architecture without 10x scale analysis.

Risk: Designing for current scale means re-architecting in 6-12 months when growth hits.
Re-architecture costs 5-10x more than getting it right initially, plus migration risk.

Required:
- Current scale: [users, requests/sec, data volume]
- 10x scale: [projected numbers]
- Bottleneck at 10x: [specific component]
- Mitigation: [specific solution]

To override: Explicitly state this design is intentionally short-term (< 6 months lifespan)
and budget for re-architecture is approved.
```

### Skipping Alternative Options
```
❌ BLOCKED: I cannot recommend a solution without comparing alternatives.

Risk: Without trade-off analysis, we optimize for the wrong dimension (e.g., lowest cost
when performance matters, or simplicity when scale matters).

Required: Document minimum 3 distinct options with:
- Performance characteristics (latency, throughput)
- Complexity (development + operational burden)
- Cost (infrastructure + development + maintenance)
- Clear rationale for chosen option tied to business constraints

To override: Explicitly state why only one option is viable (technical constraint,
compliance requirement, existing vendor lock-in).
```

### Skipping Ripple Effect Analysis
```
❌ BLOCKED: I cannot proceed without analyzing impact across all system layers.

Risk: Unanalyzed downstream impacts cause:
- Broken client applications (mobile app crashes)
- Data inconsistencies (write failures, orphaned records)
- Performance degradation (slow queries, connection exhaustion)
- Operational incidents (deployment failures, monitoring gaps)

Required: Explicit analysis of impact on:
- Data layer (schema, queries, migrations)
- Services (dependencies, APIs, contracts)
- Clients (mobile, web, third-party)
- Operations (deployment, monitoring, cost)

To override: Not recommended. If you insist, document which layers were NOT analyzed
and commit to reactive fixes when issues arise.
```

### Skipping Failure Mode Analysis
```
❌ BLOCKED: I cannot finalize architecture without documented failure modes.

Risk: Undocumented failure modes become production incidents. Average cost of
production incident: $5-50K (downtime, lost revenue, engineering time, reputation).

Required: For each critical component, document:
- Failure scenario (what breaks, why)
- Detection mechanism (metric, alert, health check)
- Impact analysis (what stops working, blast radius)
- Mitigation strategy (circuit breaker, fallback, redundancy)

To override: Explicitly accept incident risk and commit to 24/7 on-call rotation
for manual incident response.
```

---

## Common Failure Prevention

### Anti-Pattern: Shortsighted Design
```
❌ BAD: "This works for our current 10K users"
✅ GOOD: "Current: 10K users, 5 req/sec. 10x: 100K users, 50 req/sec.
         Bottleneck: PostgreSQL connection pool (max 100 connections).
         Mitigation: PgBouncer connection pooling + read replicas for queries"
```

### Anti-Pattern: Single-Path Thinking
```
❌ BAD: "Use Redis for caching"
✅ GOOD:
   Option A (Redis): 1ms latency, complex setup, $300/mo, 100K ops/sec
   Option B (In-memory LRU): 0.1ms latency, simple, $0, 500K ops/sec, cache per instance
   Option C (No cache): 100ms latency, simplest, $0, acceptable for current scale
   Chosen: B because low latency matters for UX, cost conscious, acceptable ops burden
```

###Anti-Pattern: Isolated Changes
```
❌ BAD: "Just updating the API to return user preferences"
✅ GOOD:
   - Data: New `user_preferences` table, migration script, indexes on user_id
   - Service: New `/api/v1/preferences` endpoint, updated user service
   - API: New field in GET /users response, documented in API spec
   - Client: Mobile app v2.1.0 needed to read preferences, web UI update
   - Ops: New CloudWatch metric for preferences read latency, alert if P95 > 200ms
```

### Anti-Pattern: Undocumented Decisions
```
❌ BAD: Verbal explanation: "We use PostgreSQL because it's reliable"
✅ GOOD: ADR-023: Database Choice for User Data
   - Evaluated: PostgreSQL, MySQL, MongoDB
   - PostgreSQL chosen: ACID guarantees critical for financial data, team expertise,
     proven at 10x scale (Instagram case study), acceptable $500/mo at 10x
   - Trade-off: More complex than MongoDB, but reliability outweighs simplicity
   - Date: 2024-01-15, Approved: [Tech Lead]
```

### Anti-Pattern: Ignoring Operations
```
❌ BAD: "Deploy the new microservice"
✅ GOOD:
   - Monitoring: CloudWatch dashboard with latency, error rate, throughput
   - Alerting: PagerDuty alert if error rate > 1% or latency P95 > 500ms
   - Runbook: Investigation steps, rollback procedure, escalation path
   - Deployment: Phased rollout (10% → 50% → 100%), automatic rollback on alert
```

---

## Verification

Before claiming architecture work is complete:

### 1. Scale Check
   - [ ] Documented current scale (users, requests/sec, data volume)
   - [ ] Projected 10x scale
   - [ ] Identified bottlenecks at 10x
   - [ ] Defined mitigation strategies

### 2. Trade-Off Evidence
   - [ ] Compared minimum 3 distinct options
   - [ ] Documented trade-offs (performance, complexity, cost)
   - [ ] Clear rationale for chosen option
   - [ ] Documented why alternatives rejected

### 3. Impact Tracing
   - [ ] Analyzed ALL layers (data, services, APIs, clients, operations)
   - [ ] Identified breaking changes or migration needs
   - [ ] Documented affected teams/components

### 4. Failure Preparedness
   - [ ] Listed specific failure modes (service down, slow, data corruption)
   - [ ] Defined detection mechanisms (metrics, alerts)
   - [ ] Documented mitigation strategies (circuit breakers, fallbacks)
   - [ ] Defined rollback procedures

### 5. Documentation
   - [ ] Created or updated architecture diagram
   - [ ] Written ADR or design doc with trade-offs
   - [ ] Specified monitoring/observability requirements

**If any verification item is missing, do not proceed to implementation. Add blocking TodoWrite items.**

---

## Final Self-Grading

**Before claiming architecture work complete, grade your own TodoWrite:**

```
SELF-GRADING CHECKLIST:
[ ] Minimum 22 items across 7 sections
[ ] 80%+ of items have concrete numbers/thresholds (users, req/sec, costs, latency, scale)
[ ] 80%+ of items name specific tools/technologies (PostgreSQL, Redis, CloudWatch, etc.)
[ ] 100% of items have measurable outcomes ("handles 1M req/sec", "costs $X at 10x", etc.)
[ ] Zero items use vague verbs without specifics ("analyze", "consider", "check" without details)
[ ] Tested 3 random items with Specificity Test - all passed (can engineer implement without questions?)
[ ] All 7 sections present (Scale, Options, Ripple, Failure, Observability, Docs, Migration)

GRADE YOURSELF:
- All 7 checkboxes passed: 9-10/10 (Excellent - ready to proceed)
- 5-6 checkboxes passed: 7-8/10 (Good - minor revisions needed)
- 3-4 checkboxes passed: 5-6/10 (Needs revision - improve specificity)
- 0-2 checkboxes passed: 1-4/10 (Failed - major revision required)
```

**If you graded yourself below 7/10, you MUST revise TodoWrite before proceeding with architecture design.**

**Why this matters**: 40% of agents create generic items that pass item count but fail implementation guidance. Self-grading prevents this.

---

## Integration with Other Skills

- Use BEFORE `superpowers:brainstorming` to establish architectural constraints
- Use WITH `superpowers:writing-plans` to ensure plans include scale/failure analysis
- Use BEFORE `superpowers:test-driven-development` to define system boundaries for testing
- Invoke when `superpowers:requesting-code-review` identifies architectural concerns

---

**Remember**: Architecture decisions are expensive to reverse. A week of analysis now prevents months of re-architecture later. When in doubt, over-analyze rather than under-analyze.
