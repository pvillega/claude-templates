---
name: wcag-audit
description: >
  WCAG accessibility auditing with two layers: static analysis (ESLint a11y plugins) and runtime analysis (axe-core CLI). Use when asked to audit accessibility, check WCAG compliance, find a11y issues, review for accessibility, check if a page is accessible, or after frontend-design completes a UI implementation. Triggers on: accessibility, a11y, WCAG, screen reader, alt text, aria, contrast ratio, keyboard navigation, "is this accessible", "check accessibility", "audit for accessibility".
---

# WCAG Accessibility Audit

Two-layer accessibility auditing: static analysis on source code (fast, no browser) and runtime analysis against a live URL (deeper, needs running app).

**Automated tools catch ~57% of real-world accessibility issues** (Deque study, 13,000+ pages). This skill covers that 57% and explicitly flags the remaining 43% that requires manual review.

## Phase 1: Framework Detection & Scope

Determine the project's frontend framework and which files to audit.

1. Check project files for framework indicators:
   - `package.json` with react/next/gatsby dependencies + JSX/TSX files → **React** (use `eslint-plugin-jsx-a11y`)
   - `.vue` files or `package.json` with vue dependency → **Vue** (use `eslint-plugin-vuejs-accessibility`)
   - Plain `.html` files with no framework → **HTML** (use axe-core CLI directly)
   - Fallback for unknown frameworks → **Runtime-only** (skip static, go to Phase 3)

2. Determine scope:
   - If user specified files → use those
   - Otherwise → changed files from `git diff` (staged + unstaged)
   - If no changes → ask user what to audit

3. Report framework detected and scope: "Detected React project. Auditing 5 changed files."

## Phase 2: Static Analysis (Layer 1)

Run ESLint with the appropriate accessibility plugin against source files. This catches issues without needing a running app.

**For React projects:**
```bash
npx eslint --no-eslintrc --plugin jsx-a11y --rule '{"jsx-a11y/alt-text": "error", "jsx-a11y/anchor-has-content": "error", "jsx-a11y/anchor-is-valid": "error", "jsx-a11y/aria-activedescendant-has-tabindex": "error", "jsx-a11y/aria-props": "error", "jsx-a11y/aria-proptypes": "error", "jsx-a11y/aria-role": "error", "jsx-a11y/aria-unsupported-elements": "error", "jsx-a11y/click-events-have-key-events": "error", "jsx-a11y/heading-has-content": "error", "jsx-a11y/html-has-lang": "error", "jsx-a11y/img-redundant-alt": "error", "jsx-a11y/interactive-supports-focus": "error", "jsx-a11y/label-has-associated-control": "error", "jsx-a11y/mouse-events-have-key-events": "error", "jsx-a11y/no-access-key": "error", "jsx-a11y/no-autofocus": "error", "jsx-a11y/no-distracting-elements": "error", "jsx-a11y/no-interactive-element-to-noninteractive-role": "error", "jsx-a11y/no-noninteractive-element-interactions": "error", "jsx-a11y/no-noninteractive-element-to-interactive-role": "error", "jsx-a11y/no-noninteractive-tabindex": "error", "jsx-a11y/no-redundant-roles": "error", "jsx-a11y/no-static-element-interactions": "error", "jsx-a11y/role-has-required-aria-props": "error", "jsx-a11y/role-supports-aria-props": "error", "jsx-a11y/scope": "error", "jsx-a11y/tabindex-no-positive": "error"}' --format json <files>
```

**For Vue projects:**
```bash
npx eslint --plugin vuejs-accessibility --rule '{"vuejs-accessibility/alt-text": "error", "vuejs-accessibility/anchor-has-content": "error", "vuejs-accessibility/aria-props": "error", "vuejs-accessibility/aria-role": "error", "vuejs-accessibility/aria-unsupported-elements": "error", "vuejs-accessibility/click-events-have-key-events": "error", "vuejs-accessibility/form-control-has-label": "error", "vuejs-accessibility/heading-has-content": "error", "vuejs-accessibility/interactive-supports-focus": "error", "vuejs-accessibility/label-has-for": "error", "vuejs-accessibility/mouse-events-have-key-events": "error", "vuejs-accessibility/no-access-key": "error", "vuejs-accessibility/no-autofocus": "error", "vuejs-accessibility/no-distracting-elements": "error", "vuejs-accessibility/no-redundant-roles": "error", "vuejs-accessibility/no-static-element-interactions": "error", "vuejs-accessibility/role-has-required-aria-props": "error", "vuejs-accessibility/tabindex-no-positive": "error"}' --format json <files>
```

If eslint-plugin is not installed in the project, install it as a dev dependency first:
```bash
npm install -D eslint-plugin-jsx-a11y  # React
npm install -D eslint-plugin-vuejs-accessibility  # Vue
```

Parse the JSON output. For each violation, present:
```
[SEVERITY] Rule description — file:line
  Rule: rule-id (WCAG criterion reference)
  Fix: Specific code change to fix the issue
```

**STOP** — Present static analysis findings grouped by severity. Ask: "Found N accessibility issues in source code. Want to also run runtime analysis against a live URL for deeper coverage?"

## Phase 3: Runtime Analysis (Layer 2)

Run axe-core CLI against a running application for deeper WCAG coverage.

1. Determine the target URL:
   - If user provided a URL → use it
   - Check if a dev server is running: `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000` (try common ports: 3000, 8080, 5173, 4200, 8000)
   - If no server found → skip this phase, report: "No running server detected. Start your dev server and re-run for runtime analysis."

2. Run axe-core:
```bash
axe <URL> --tags wcag22aa --save /tmp/axe-results.json --stdout
```

For multiple pages, use pa11y-ci or run axe against each URL:
```bash
axe <URL1> <URL2> <URL3> --tags wcag22aa --save /tmp/axe-results.json --stdout
```

3. Parse the JSON output. Each violation contains:
   - `id`: rule identifier (e.g., `image-alt`)
   - `impact`: `critical`, `serious`, `moderate`, or `minor`
   - `description`: human-readable explanation
   - `nodes[].html`: the HTML element that violated the rule
   - `nodes[].target`: CSS selector for the element
   - `helpUrl`: link to Deque documentation for the rule

4. For each violation, try to map back to source code:
   - Extract CSS selectors and class names from `nodes[].target`
   - Grep the source code for those selectors to find the originating component
   - Present with source file reference when possible

Present findings:
```
[CRITICAL] Images must have alternate text — src/components/Hero.tsx:15
  Rule: image-alt (WCAG 1.1.1 Non-text Content)
  Element: <img src="/hero.jpg" class="hero-image">
  Fix: Add alt attribute: <img src="/hero.jpg" alt="Description of hero image" class="hero-image">

[SERIOUS] Color contrast insufficient — src/components/Button.tsx:8
  Rule: color-contrast (WCAG 1.4.3 Contrast Minimum)
  Element: <button class="btn-light">Submit</button>
  Contrast ratio: 2.5:1 (needs 4.5:1 for normal text)
  Fix: Darken text color or lighten background to achieve 4.5:1 ratio
```

## Phase 4: Manual Review Checklist

After presenting automated findings, always present this checklist of things automation cannot verify:

```
MANUAL REVIEW NEEDED (automated tools cannot check these):

Keyboard Navigation:
- [ ] All interactive elements reachable via Tab key
- [ ] Focus order follows visual/logical order
- [ ] No keyboard traps (can always Tab away from elements)
- [ ] Custom widgets operable with Enter/Space/Arrow keys

Screen Reader:
- [ ] Alt text is meaningful (not just present) — describes purpose, not decoration
- [ ] Live regions announce dynamic content changes
- [ ] Form error messages are announced when they appear
- [ ] Page landmarks (nav, main, aside) are used correctly

Visual:
- [ ] Content understandable without color alone (links, errors, status)
- [ ] Text resizable to 200% without loss of content
- [ ] No content triggered only on hover (or also available on focus)

Cognitive:
- [ ] Error messages explain what went wrong and how to fix it
- [ ] Form inputs have visible labels (not just placeholders)
- [ ] Consistent navigation across pages
```

## Limitations

- Automated tools catch ~57% of real-world accessibility issues (16 of 50 WCAG 2.1 AA criteria)
- Those 16 criteria account for the majority of real-world violations by volume
- Cannot verify if alt text is meaningful (only that it exists)
- Cannot test keyboard navigation flow or screen reader experience
- Static analysis coverage depends on framework plugin maturity (React best, Vue good, others limited)
