---
name: agent-creator
description: Use when creating agents. Routes to Simple (30-55 lines), Standard (100-300 lines), or Full (500+ lines) path based on complexity. Triggers: "create agent", "automate workflow". If thinking "just create basic agent" - that's valid for Simple path.
---

# Agent Creator - Meta-Skill

This skill teaches Claude Code how to create agents at the appropriate complexity level.

## When to Use This Skill

**Asks to create an agent:**
- "Create an agent for [objective]"
- "I need an agent that [description]"
- "Develop an agent to automate [workflow]"

**Asks to automate a workflow:**
- "Automate this process: [description]"
- "Every day I do [repetitive task], automate this"
- "Turn this workflow into an agent"

---

## STEP 1: COMPLEXITY ASSESSMENT (MANDATORY FIRST)

Before creating ANY agent, assess complexity to choose the right path.

### Classification Questions

| # | Question | Simple (0) | Standard (1) | Full (2) |
|---|----------|------------|--------------|----------|
| 1 | External API integration? | No | 1-2 simple APIs | 3+ or complex (auth, rate limits) |
| 2 | Persistent data/caching? | No | Optional | Required |
| 3 | Custom tools declarations? | No | Yes | Yes + multiple modes |
| 4 | For marketplace distribution? | No | No | Yes |
| 5 | Test suite required? | No | Optional | Yes (25+) |

### Scoring

```
Total points: 0-10
├─ 0-2 points → SIMPLE PATH
├─ 3-5 points → STANDARD PATH
└─ 6-10 points → FULL PATH
```

### Quick Heuristics

**Default to SIMPLE PATH when:**
- "Simple agent", "quick agent", "basic agent"
- Internal workflow automation
- No external APIs mentioned
- Agent description < 50 words

**Escalate to STANDARD PATH when:**
- Tools declarations needed
- Multiple workflow modes
- Boundaries are important
- Error handling matters

**Escalate to FULL PATH when:**
- "Production-ready", "marketplace", "publish"
- External APIs with auth/rate limits
- Test suite explicitly requested
- Data validation critical

### Path Comparison

| Aspect | Simple | Standard | Full |
|--------|--------|----------|------|
| **Output** | 30-55 lines | 100-300 lines | 500+ lines |
| **Time** | 15-30 min | 30-60 min | 60-120 min |
| **TodoWrite** | 5 items | 8 items | 12+ items |
| **marketplace.json** | No | No (unless requested) | Required |
| **Tests** | None | Optional | 25+ required |
| **Validators** | None | None | 4 required |

**After scoring, announce:**
> "Complexity score: X/10 → [SIMPLE/STANDARD/FULL] PATH selected"

---

## SIMPLE PATH (30-55 lines, 15-30 min)

**Target output:** Agents like repo-index.md (31 lines), deep-research.md (55 lines)

### TodoWrite: 5 items

1. Define purpose (single responsibility)
2. List core duties (3-5 bullets)
3. Define boundaries (DO NOT list)
4. Write operating procedure (3-5 steps)
5. Create agent file with frontmatter

### Phase 1: Define (5-10 min)

- **Purpose**: Single sentence describing what agent does
- **Core Duties**: 3-5 bullet points of responsibilities
- **Boundaries**: 3-5 "DO NOT" statements

### Phase 2: Implement (10-20 min)

Create single agent file:

```markdown
---
name: agent-name
description: Brief description of agent purpose
category: discovery|analysis|quality|automation
---

# Agent Name

[One paragraph explaining when to use this agent]

## Core Duties
- [Duty 1]
- [Duty 2]
- [Duty 3]

## Operating Procedure
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]

[Optional: Keep responses short and data-driven.]
```

### Quality Gate

- [ ] Frontmatter has name + description + category
- [ ] Purpose clear in opening paragraph
- [ ] Core duties are specific (not vague)
- [ ] Operating procedure is actionable
- [ ] Total lines: 30-55

### NOT Required

- marketplace.json
- tests/
- references/
- validators
- scripts/

---

## STANDARD PATH (100-300 lines, 30-60 min)

**Target output:** Agents with tools declarations, multiple modes, response templates

### TodoWrite: 8 items

1. Define purpose and scope
2. List responsibilities (5-8 items)
3. Define boundaries (DO NOT list)
4. Design workflow steps (5-7 steps)
5. Plan response templates
6. Decide on tools declarations
7. Create agent file
8. Verify activation works

### Phase 1: Discovery (5-10 min) - if API needed

- Research API requirements
- Document auth method
- Note rate limits

### Phase 2: Design (10-15 min)

- **Responsibilities**: 5-8 specific duties
- **Boundaries**: What agent should NOT do
- **Workflow**: Step-by-step procedure with skip conditions
- **Response format**: Templates for output

### Phase 3: Implement (15-25 min)

Create agent file with extended structure:

```markdown
---
name: agent-name
description: Detailed description with triggers
category: discovery|analysis|quality|automation
tools: [Read, Grep, Glob, Bash, Task, WebSearch]  # Optional
model: sonnet  # Optional
---

# Agent Name

[When to deploy this agent and why]

## Responsibilities
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

## Boundaries (DO NOT)
- [Boundary 1]
- [Boundary 2]

## Workflow

**Workflow Adherence:** All steps are mandatory.

1. **Step Name** — description
   - *Skip condition:* NEVER (or specific condition)

2. **Step Name** — description

3. **Report** — respond with:
   ```
   📊 Summary:
   🔗 Details:
   🚧 Next steps:
   ```

## Response Templates

### Scenario: [Common situation]
[Template response]
```

### Phase 4: Verify (5-10 min)

- Test agent activation with sample request
- Verify response quality
- Check workflow completeness

### Quality Gate

- [ ] Frontmatter complete (including tools if needed)
- [ ] Responsibilities are specific and actionable
- [ ] Boundaries prevent scope creep
- [ ] Workflow has skip conditions documented
- [ ] Response templates are useful
- [ ] Total lines: 100-300

### NOT Required

- marketplace.json (unless distributing)
- Full test suite (25+ tests)
- 4 validators
- Modular parsers

---

## FULL PATH (500+ lines, 60-120 min)

**When required:**
- Marketplace distribution
- External APIs with rate limiting/auth
- Production deployment
- Test suite explicitly requested

### TodoWrite: 12+ items

| Phase | Min Items | Example |
|-------|-----------|---------|
| Setup | 2+ | "Create marketplace.json", "Validate JSON" |
| Discovery | 2+ | "Research APIs", "Analyze coverage" |
| Design | 2+ | "Define analyses", "Design comprehensive report" |
| Architecture | 2+ | "Plan parsers", "Design validators" |
| Implementation | 2+ | "Implement validators", "Create scripts" |
| Testing | 2+ | "Create test suite", "Verify all pass" |

### STEP 0: marketplace.json (REQUIRED for Full Path)

**Create FIRST before any other files:**

```bash
mkdir -p agent-name/.claude-plugin
```

```json
{
  "name": "agent-name",
  "owner": {
    "name": "Agent Creator",
    "email": "noreply@example.com"
  },
  "metadata": {
    "description": "Brief agent description",
    "version": "1.0.0",
    "created": "YYYY-MM-DD"
  },
  "plugins": [
    {
      "name": "agent-plugin",
      "description": "MUST BE IDENTICAL to SKILL.md frontmatter",
      "source": "./",
      "strict": false,
      "skills": ["./"]
    }
  ]
}
```

**Validate immediately:**
```bash
python3 -c "import json; json.load(open('agent-name/.claude-plugin/marketplace.json')); print('✅ Valid')"
```

### Phase 1-4: Planning (See references/)

1. **Discovery**: Research APIs, compare options, decide with justification
2. **Design**: Define 4-6 analyses + mandatory comprehensive_report()
3. **Architecture**: Plan modular parsers (1 per data type), 4 validators
4. **Detection**: Determine ≥60 keywords, create description

**See references/** for detailed methodology:
- references/api-discovery-patterns.md
- references/python-templates.md
- references/validation-system.md

### Phase 5: Implementation

**Required structure:**

```
agent-name/
├── .claude-plugin/marketplace.json (FIRST!)
├── SKILL.md (5000+ words)
├── scripts/
│   ├── fetch_{api}.py
│   ├── parse_{type}.py (1 per data type)
│   ├── analyze_{domain}.py
│   └── utils/
│       ├── helpers.py (temporal context)
│       └── validators/ (4 validators)
├── tests/ (≥25 tests)
├── references/
├── README.md + INSTALLATION.md
└── VERSION + CHANGELOG.md
```

**Mandatory components:**
- `utils/helpers.py`: Temporal context functions
- `utils/validators/`: parameter, data, temporal, completeness validators
- Modular parsers: 1 per API data type
- `comprehensive_{domain}_report()`: All-in-one function

**CRITICAL**: Synchronize descriptions
- Copy description from SKILL.md frontmatter
- Paste in marketplace.json → plugins[0].description
- Must be IDENTICAL word-for-word

### Phase 6: Test Suite (≥25 tests)

- test_integration.py (≥5 tests)
- test_parse.py (1 per parser)
- test_analyze.py (1 per function)
- test_helpers.py (≥3 tests)
- test_validation.py (≥5 tests)

**ALL tests must PASS before delivery.**

### Final Validation

```bash
/plugin marketplace add ./agent-name
```

- [ ] Command executed without errors
- [ ] Skill appears in installed plugins
- [ ] Claude recognizes the skill

---

## Escalation Protocol

### During Simple → Standard

**Triggers:**
- User mentions tools declarations
- Multiple workflow modes needed
- Error handling becomes important

**Response:**
> "This agent needs more structure than Simple path provides.
> Upgrading to STANDARD PATH (100-300 lines, 30-60 min).
> Adding: tools declarations, boundaries section, response templates."

### During Standard → Full

**Triggers:**
- User mentions "marketplace" or "publish"
- External API with auth/rate limits needed
- Test suite explicitly requested

**Response:**
> "This agent requires production infrastructure.
> Upgrading to FULL PATH (500+ lines, 60-120 min).
> Adding: marketplace.json, test suite (25+), validators, modular parsers."

### Graceful Upgrade

When escalating:
1. Keep existing work
2. Add missing components for new path
3. Update TodoWrite with additional items
4. Continue from current phase

---

## Response Templates

### "Just create a basic agent"

✅ **Valid for SIMPLE PATH**

Simple agents (30-55 lines) are legitimate outputs. Running complexity assessment...

**Score: 0-2 → SIMPLE PATH**
- 2 phases, 15-30 minutes
- No marketplace.json, no tests
- Output like repo-index.md or deep-research.md

Proceeding with Simple path unless you need more complexity?

### "Skip marketplace.json"

**For Simple/Standard paths:** ✅ Not required. Proceeding without it.

**For Full path:** ❌ Required for marketplace distribution.
- Without it, skill cannot be installed via `/plugin marketplace add`
- Takes 2 minutes to create
- Creating now as Step 0...

### "We don't need tests"

**For Simple/Standard paths:** ✅ Tests are optional. Proceeding without them.

**For Full path:** ❌ Required for production quality.
- 25+ tests verify skill actually works
- Catches bugs before users do
- Creating test suite in Phase 6...

---

## Troubleshooting

### "Failed to install plugin"

**Cause:** marketplace.json missing or invalid (Full path only)

```bash
ls -la agent-name/.claude-plugin/marketplace.json
python3 -c "import json; json.load(open('agent-name/.claude-plugin/marketplace.json'))"
```

### "Skill not activating"

**Cause:** marketplace.json description ≠ SKILL.md description

```bash
grep "description:" agent-name/SKILL.md
grep "\"description\":" agent-name/.claude-plugin/marketplace.json
```

Must be IDENTICAL word-for-word.

---

## References

For Full path detailed guidance:
- **references/api-discovery-patterns.md** - API research methodology
- **references/python-templates.md** - Code templates
- **references/validation-system.md** - Validation system
- **examples/sample-agent-structure.md** - Complete example

---

## Keywords

**Create:** "create agent", "develop agent", "build agent", "create skill"

**Automate:** "automate workflow", "automate process", "turn into agent"

**Complexity signals:** "simple agent", "basic agent" → Simple | "production-ready", "marketplace" → Full
