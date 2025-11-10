---
name: progressive-learning
description: Use when teaching or explaining programming concepts (execution) - applies progressive learning methodology with prerequisite mapping, practical examples, and understanding verification through structured exercises
---

# Progressive Learning Skill

## When to Use This Skill

Activate this skill when the user:

- Asks for explanation of programming concepts, algorithms, or code patterns
- Requests tutorials or learning materials for technical topics
- Needs step-by-step breakdowns of complex implementations
- Wants to understand how/why code works, not just what it does
- Requests learning paths or skill development guidance
- Asks to create educational content or documentation
- Needs progressive exercises that build on each other

## Triggers

**Educational Requests**:

- "Explain [concept]"
- "How does [algorithm/pattern] work?"
- "Teach me [technology]"
- "Create a tutorial for [topic]"
- "I don't understand [code/concept]"

**Learning Path Design**:

- "What should I learn to [goal]?"
- "How do I progress from [level] to [level]?"
- "What are the prerequisites for [skill]?"

**Exercise Creation**:

- "Create practice exercises for [topic]"
- "Give me problems to practice [skill]"
- "Build my understanding of [concept]"

## Quick Reference: 7-Phase Process

For rapid application, follow this condensed workflow:

### 1. Assess

Determine current knowledge level

- Ask about existing experience with related topics
- Identify knowledge gaps and misconceptions
- Establish baseline understanding

### 2. Decompose

Break complex topic into components

- Identify core concepts and supporting topics
- Separate essential from nice-to-know information
- Create a logical breakdown of the subject

### 3. Map Dependencies

Identify prerequisites and sequence

- Determine which concepts must come first
- Find prerequisite relationships between topics
- Document concept dependency chains

### 4. Design Progression

Create step-by-step path with difficulty scaling

- Order components from foundational to advanced
- Plan gradual increase in complexity
- Ensure each step builds on previous understanding

### 5. Provide Examples

Concrete examples at each level

- Use simple, relatable examples early
- Progress to realistic, domain-specific examples
- Include both positive and edge-case examples

### 6. Verify Comprehension

Checkpoints before advancing

- Create questions that test understanding
- Provide opportunities for hands-on practice
- Assess readiness before moving forward

### 7. Reinforce

Exercises that consolidate understanding

- Design practice problems that apply concepts
- Create review materials for key topics
- Build confidence through repetition and variation

**Quick Quality Checks**:

- Can learner complete each checkpoint?
- Is prerequisite knowledge identified correctly?
- Does difficulty scale appropriately?
- Are examples concrete and practical?
- Does each phase build logically on previous ones?
- Are learning outcomes clear at each step?

## How It Works

### Phase 1: Knowledge Assessment
- Identify current level, related knowledge, gaps
- Ask: "Experience with [prerequisite]?" "What's unclear about [topic]?"

### Phase 2: Concept Breakdown
- Core concept (1 sentence) + Prerequisites + 3-5 learning steps
- Map dependencies between concepts

### Phase 3: Progressive Examples
- Example 1 (Minimal): Simplest working code, one concept only
- Example 2 (Basic): Add ONE complexity, explain what changed
- Example 3 (Practical): Real-world with error handling, explain trade-offs

### Phase 4: Exercise Design
- **Guided**: Modify provided code (5-10 min)
- **Structured**: Implement from requirements (15-20 min)
- **Open-Ended**: Apply to new domain (30-45 min)

**Each exercise includes:** Title, difficulty, time, task, requirements, success criteria, hints.

### Phase 5: Understanding Verification
- Ask learner to explain concept in their own words
- Pose "what if" scenarios to test understanding
- Verify ability to apply concept to new scenario

### Phase 6: Learning Path Documentation
- Create skill tree (prerequisites → advanced topics)
- Define milestones with time estimates
- Provide resources and mastery criteria

## Explanation Best Practices

**Multiple angles:** Analogy → Visual → Concrete → Abstract
**Progressive disclosure:** Start simple → Add complexity → Explain why → Show professional handling
**Bridge to known:** "You know [X]. This is similar but [difference]."

**Avoid:** Dump complexity upfront | Skip "why" | Assume prerequisites | Use undefined jargon

## Educational Content Quality Standards

### Code Examples Must Have

- [ ] Correct syntax (actually runs)
- [ ] Inline comments explaining WHY (not what)
- [ ] Progressive complexity (simple → advanced)
- [ ] Error handling (show best practices)
- [ ] Realistic naming (not foo/bar unless teaching naming)

### Explanations Must Have

- [ ] Core concept in one sentence
- [ ] Why it matters (real-world motivation)
- [ ] How it works (mechanism explanation)
- [ ] When to use it (applicability context)
- [ ] Common mistakes to avoid
- [ ] Relationship to other concepts

### Exercises Must Have

- [ ] Clear learning objectives
- [ ] Specific success criteria
- [ ] Difficulty appropriate to concepts covered
- [ ] Hints for common sticking points
- [ ] Progressive challenge (easy → hard variations)

## Boundaries

### This Skill WILL

- Explain programming concepts with appropriate depth
- Create step-by-step tutorials with progressive examples
- Design exercises that build understanding systematically
- Map prerequisites and create learning paths
- Adapt explanations to learner's current level
- Verify understanding through questions and challenges
- Provide multiple explanation approaches (analogy, visual, concrete)
- Show code evolution (simple → complex, wrong → right)

### This Skill WILL NOT

- Complete homework or assignments without educational context
- Provide answers without explanation or learning opportunity
- Skip foundational concepts needed for true understanding
- Use advanced concepts before simpler ones are mastered
- Assume knowledge without verification
- Give "just make it work" solutions without teaching principles

### When NOT to Use

- User needs direct implementation help (not learning mode)
- Question is about debugging specific code (use systematic-debugging instead)
- User explicitly requests "just the answer, no explanation"
- Task is production code review (use requesting-code-review instead)

## Integration with Other Skills

- Use BEFORE implementation to teach concepts being applied
- Use AFTER code review to explain why changes are needed
- Use WITH brainstorming to teach design thinking process
- Invoke when user shows confusion or misconceptions about concepts

## Example Workflows

**"Explain recursion":** Assess prerequisites → Break down (base case, recursive case, call stack) → Progressive examples (countdown → factorial → tree traversal) → Exercises → Verify understanding

**"Create React learning path":** Assess JS knowledge → Map dependencies (JS → React basics → Hooks → Advanced) → Define milestones (static component → form → data-fetch → dashboard)

**"I don't understand async/await":** Assess Promises knowledge → Identify confusion → Build from callbacks → Promises → async/await → Show equivalence → Practice conversion

---

**Remember**: The goal is understanding, not memorization. Prioritize "why" over "what", and ensure learners can apply concepts to new scenarios, not just reproduce examples.
