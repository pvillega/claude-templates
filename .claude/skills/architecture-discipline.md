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

| Analysis Type | ❌ Retrofitting Problem | ✅ Proper Sequence Benefit |
|---------------|------------------------|---------------------------|
| **Alternatives** | Anchoring bias → rationalize existing choice | Unbiased comparison → best solution on merits |
| **Scale** | Wrong design won't work at ANY scale | Architecture shaped by scale from start |
| **Failure Modes** | Document failures vs prevent them | Resilience built in (circuit breakers, fallbacks) |
| **Ripple Effects** | Scope explosion discovered too late | Choose solution minimizing dependencies |

**Core issue**: You've already made key decisions; adding analysis afterward is rationalization, not evaluation.

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

### Worked Example: Redis Architecture

| Phase | ❌ WRONG (Retrofitting) | ✅ RIGHT (Proper Sequence) |
|-------|------------------------|---------------------------|
| **Hours 1-6** | Write 15-page Redis architecture<br>• Key structure, cluster config<br>• Capacity: 10K req/sec<br>• 2-week timeline | **Alternatives FIRST**<br>• Compare 5 options: Redis/RabbitMQ/Kafka/LRU/None<br>• Discovery: In-memory LRU may suffice<br>• Choose Redis only if it wins objectively |
| **Hours 7-10** | Retrofit missing sections<br>• Rationalize Redis (anchoring bias)<br>• Assume Redis scales (never questioned)<br>• Document failures as TODOs | **Scale shapes architecture**<br>• Discovery: Single cluster caps at 6K req/sec<br>• Design sharding strategy from day one<br>• Plan 3 shards across zones NOW |
| **Result** | Compliant-looking, flawed methodology | **Failure modes drive design**<br>• Circuit breaker + DB fallback built in<br>• Each section informs the next |

---

### Sunk Cost Analysis

| Option | Time | Result | Future Cost | Total Cost |
|--------|------|--------|-------------|------------|
| **A: Retrofit** | 2-3 hrs | Flawed architecture | 3-month rearchitecture (500 hrs) | 9 hrs + $100K-$500K |
| **B: Delete & Restart** | 6 hrs | Sound architecture | Zero | 6 hrs + $0 |

**Savings by deleting now**: 496 hours + $100K-$500K

**The 6 hours are already gone. The question is: which path leads to correct architecture?**

**Answer**: Restarting. Always. **DELETE the flawed work. Start over. No exceptions.**

---

## 🛑 MANDATORY VERIFICATION CHECKPOINT - DO NOT PROCEED

**After creating TodoWrite, verify quality using TWO checklists:**

### 1. Section Completeness (22+ items required)
```
[ ] Scale Analysis: 4+ items
[ ] Architectural Options: 3+ items
[ ] Ripple Effect Analysis: 5+ items
[ ] Failure Modes: 3+ items
[ ] Observability: 3+ items
[ ] Documentation: 2+ items
[ ] Migration/Compatibility: 2+ items
TOTAL: ___ items (must be 22+)
```

### 2. Item Quality (test 3 random items)
Each item must have ALL three:
- ✓ Concrete numbers/thresholds ("100K users", "$500/mo", "P95 < 500ms")
- ✓ Specific tools/technologies ("PostgreSQL", "Redis", "CloudWatch")
- ✓ Measurable outcome ("handles 1M req/sec", "costs $X at 10x")

**DO NOT PROCEED until Section Completeness passes AND all 3 tested items pass quality check.**

---

## TodoWrite Quality Standards

**Specificity Test**: "Could an engineer implement this tomorrow without asking clarifying questions?"

Each item must include ALL three:
1. **Concrete numbers**: "100K users", "$500/mo at 10x", "P95 < 500ms"
2. **Specific tools**: "PostgreSQL", "Redis Sentinel", "CloudWatch"
3. **Measurable outcome**: "handles 1M req/sec", "costs $X at 10x"

### Quality Examples

| ❌ FAILS | ✅ PASSES |
|----------|-----------|
| "Add monitoring" | "CloudWatch metrics: `websocket.connections.active` (gauge), alert if >5% error rate for 5min via PagerDuty" |
| "Evaluate caching" | "Compare Redis (1ms, $300/mo, 100K ops/sec) vs In-memory LRU (0.1ms, $0, 500K ops/sec) vs No cache (100ms from DB)" |
| "Analyze scale" | "Current: 100K DAU, 50 req/sec peak. 10x: 1M users, 500 req/sec. Bottleneck: PostgreSQL connection pool" |
| "Document trade-offs" | "ADR-015: Kafka over SQS (throughput 100K vs 10K msg/sec, ordering guarantees, cost $200 vs $500/mo at 10x)" |

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

Required items (4+):
- **Current scale**: Users (DAU/MAU), requests/sec (peak), data volume (GB/TB), read/write ratio
- **10x scale**: What are the numbers at 10x? When do we expect to reach it?
- **Bottlenecks**: What specifically breaks at 10x? (DB connections, API limits, memory, disk I/O)
- **Mitigation**: For each bottleneck, specific solution (sharding, caching, read replicas, async processing)

### Architectural Options

**⚠️ CRITICAL: Single-solution proposals indicate insufficient analysis.**

Required: MINIMUM 3 distinct options, each with:
- **Performance**: Latency (P50/P95/P99), throughput (req/sec), scale limit
- **Complexity**: LOC estimate, services involved, operational burden
- **Cost**: Infrastructure ($X/mo at current, $Y/mo at 10x), development (engineer-weeks), maintenance
- **Trade-offs**: Specific advantages (✅) and disadvantages (❌)

### Ripple Effect Analysis

**⚠️ CRITICAL: Changes propagate across layers. Analyze ALL layers systematically.**

Required items (5+):
- **Data layer**: Schema changes, migration scripts, indexes, query performance
- **Services**: Which services need updates? API contracts changed? New dependencies?
- **API**: Breaking changes? Version bump? Backward compatibility?
- **Clients**: Mobile app updates? Web UI changes? SDK version updates?
- **Operations**: Deployment changes? New monitoring? Infrastructure updates? Cost changes?

### Failure Modes

**⚠️ CRITICAL: Every architecture decision creates new failure modes.**

Required items (3+), each with:
- **Scenario**: [Component] fails because [reason]
- **Detection**: How we know (metrics drop, error rate spike, alert fires)
- **Impact**: What breaks (user features, data integrity, other services)
- **Mitigation**: Specific solution (circuit breaker, fallback, redundancy, graceful degradation)

Common modes: Service down/slow, data corruption, network partition

### Observability

Required items (3+):
- **Metrics**: Specific metrics (latency P95, error rate %, throughput req/sec, resource utilization %)
- **Alerts**: Specific conditions (error rate > 5%, latency P95 > 500ms, queue depth > 10000)
- **Dashboards**: Key visualizations (request flow, latency by endpoint, error breakdown)

### Documentation

Required items (2+):
- **ADR**: Chosen option, rejected alternatives, trade-off analysis, constraints
- **Diagram update**: New components, data flows, failure paths

### Migration/Compatibility

Required items (2+):
- **Backward compatibility**: Old clients work? Old data formats? API versioning strategy?
- **Migration path**: Phased rollout, feature flags, DB migration steps, rollback procedure

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

**The 7 sections are a REASONING SEQUENCE, not a checklist you can complete in any order.**

| Step | What It Does | Why Order Matters |
|------|--------------|-------------------|
| 1. **Scale Analysis** | Defines performance/capacity requirements | Rules out solutions that can't scale (e.g., 10K req/sec eliminates single-server) |
| 2. **Alternatives** | Objective comparison before commitment | Prevents anchoring bias (compare Redis/RabbitMQ/Kafka before deciding) |
| 3. **Solution Selection** | Choose based on scale + alternatives | Decision is defensible (considered options objectively) |
| 4. **Ripple Effects** | Understand integration complexity | Shapes deployment (discover 4 services need updates → plan coordination) |
| 5. **Failure Modes** | Build resilience into design | Circuit breakers/fallbacks built in, not bolted on later |
| 6. **Observability** | Instrument for production | Metrics based on failure modes (alert on circuit breaker trips) |
| 7. **Documentation + Migration** | Prepare for deployment | ADR documents why chosen (from alternatives analysis) |

**Why wrong order fails**:
- Alternatives AFTER choosing → Rationalization (justify existing choice, not evaluate objectively)
- Scale AFTER design → Wrong architecture (design assumptions baked in)
- Failure modes AFTER implementation → Resilience bolted on (circuit breakers become tech debt)
- Ripple effects AFTER commitment → Scope explosion discovered too late

**If you did steps out of order → DELETE and restart**. You cannot retrofit reasoning sequence.

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

**❌ BLOCKED: I cannot defer [scale analysis/alternatives/failure modes/ripple effects] to future iterations.**

### Why "Later" Always Fails
- 80% of "we'll add later" items never get added
- Retrofitting costs 5-10x more than building it in
- Re-architecting after launch costs months of engineering time

### Override Requirements
To skip ANY requirement, you MUST provide all 4:
1. Specific retrofit date (actual sprint/date, not "later")
2. Budget allocated (engineer-weeks + dollar cost)
3. Risk acceptance signed by [decision maker's name]
4. Interim mitigation plan (what you'll do before retrofit)

**If you cannot provide these 4 items, requirement must be implemented now.**

### Specific Consequences

| Skipped Requirement | Risk | Cost |
|---------------------|------|------|
| **Scale Analysis** | Re-architecture in 6-12 months when growth hits | 3-6 month project, 5-10x cost |
| **Alternatives** | Optimize for wrong dimension, costly migration later | 2-4 month project |
| **Failure Modes** | Production incidents, multi-hour debugging, data loss | $5-50K per incident |
| **Ripple Effects** | Broken clients, data inconsistencies, performance degradation | Deployment failures, operational incidents |

---

## Common Anti-Patterns

| Anti-Pattern | ❌ BAD | ✅ GOOD |
|--------------|--------|---------|
| **Shortsighted Design** | "This works for our current 10K users" | "Current: 10K users, 5 req/sec. 10x: 100K users, 50 req/sec. Bottleneck: PostgreSQL connection pool (max 100). Mitigation: PgBouncer + read replicas" |
| **Single-Path Thinking** | "Use Redis for caching" | "Option A (Redis): 1ms, $300/mo. Option B (In-memory LRU): 0.1ms, $0. Option C (No cache): 100ms, $0. Chosen: B for low latency + cost" |
| **Isolated Changes** | "Just updating the API to return user preferences" | "Data: New `user_preferences` table, migration, indexes<br>Service: `/api/v1/preferences` endpoint<br>API: New field in GET /users<br>Client: Mobile v2.1.0, web UI update<br>Ops: CloudWatch metric, P95 > 200ms alert" |
| **Undocumented Decisions** | "We use PostgreSQL because it's reliable" | "ADR-023: PostgreSQL over MySQL/MongoDB. ACID critical for financial data, team expertise, $500/mo at 10x. Trade-off: More complex than MongoDB, but reliability outweighs simplicity" |
| **Ignoring Operations** | "Deploy the new microservice" | "Monitoring: CloudWatch dashboard (latency, error rate, throughput)<br>Alerting: PagerDuty if error >1% or P95 >500ms<br>Deployment: Phased 10%→50%→100%, auto rollback on alert" |

---

## Verification

Before claiming architecture work complete, verify:

| Category | Requirements |
|----------|-------------|
| **Scale Check** | ✓ Current scale (users, req/sec, data)<br>✓ 10x scale projected<br>✓ Bottlenecks identified<br>✓ Mitigation strategies |
| **Trade-Off Evidence** | ✓ 3+ distinct options compared<br>✓ Performance, complexity, cost documented<br>✓ Rationale for chosen option<br>✓ Why alternatives rejected |
| **Impact Tracing** | ✓ ALL layers analyzed (data, services, APIs, clients, ops)<br>✓ Breaking changes identified<br>✓ Affected teams/components |
| **Failure Preparedness** | ✓ Specific failure modes (down, slow, corruption)<br>✓ Detection mechanisms (metrics, alerts)<br>✓ Mitigation strategies (circuit breakers, fallbacks)<br>✓ Rollback procedures |
| **Documentation** | ✓ Architecture diagram updated<br>✓ ADR/design doc with trade-offs<br>✓ Monitoring/observability requirements |

**If any item is missing, do not proceed to implementation.**

---

## Integration with Other Skills

- Use BEFORE `superpowers:brainstorming` to establish architectural constraints
- Use WITH `superpowers:writing-plans` to ensure plans include scale/failure analysis
- Use BEFORE `superpowers:test-driven-development` to define system boundaries for testing
- Invoke when `superpowers:requesting-code-review` identifies architectural concerns

---

**Remember**: Architecture decisions are expensive to reverse. A week of analysis now prevents months of re-architecture later. When in doubt, over-analyze rather than under-analyze.
