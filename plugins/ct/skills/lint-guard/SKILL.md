---
name: lint-guard
description: >
  Set up strict complexity linting for any project. Detects languages, recommends linters,
  configures strict rules, and installs a Stop hook to enforce them automatically.
  Use when prompted by the SessionStart detection message, or manually to configure/reconfigure linting.
user-invocable: true
tools: Read, Edit, Write, Bash, Glob, AskUserQuestion
---

# Lint Guard

Set up and enforce strict linter complexity rules for the current project. Language-agnostic — supports 17 languages.

## Overview

This skill:
1. Detects which languages are used in the project
2. Checks which linters are already configured
3. Recommends the best linter + strict complexity rules for each language
4. Installs linters and writes configs on user approval
5. Generates `.claude/linters.json`
6. Installs a `Stop` hook that runs linters on every code change

## When Invoked During Coding (Not Setup)

If `.claude/linters.json` already exists and the user invokes this skill, switch to **lint-check mode**:
1. Read `.claude/linters.json`
2. Get changed files via `git diff --name-only`
3. Run each linter's `command` on matching changed files
4. For violations with `safe_autofix: true` in the config, run the `autofix_command`
5. For complexity violations (not auto-fixable), report them and suggest refactoring
6. Do NOT auto-fix complexity violations — report only

## Setup Flow

### Step 1: Detect Languages

Check the project for these marker files to detect languages:

| Language | Marker Files |
|---|---|
| TypeScript/JavaScript | `package.json`, `tsconfig.json` |
| Python | `pyproject.toml`, `setup.py`, `requirements.txt` |
| Rust | `Cargo.toml` |
| Go | `go.mod` |
| C/C++ | `CMakeLists.txt`, `Makefile`, `*.c`, `*.cpp`, `*.h` |
| Java | `pom.xml`, `build.gradle`, `build.gradle.kts` |
| C# | `*.csproj`, `*.sln` |
| Ruby | `Gemfile` |
| PHP | `composer.json` |
| Kotlin | `detekt.yml`, `*.kt` in `src/` |
| Swift | `Package.swift`, `*.swift` |
| Scala | `build.sbt` |
| Haskell | `*.cabal`, `stack.yaml` |
| OCaml | `dune-project` |
| Lean | `lakefile.lean`, `lean-toolchain` |
| Lua | `*.lua` |
| Unison | `*.u` |

If the SessionStart hook already provided detection results in the conversation, use those instead of re-detecting.

### Step 2: Check Existing Linter Configs

For each detected language, check if a linter config already exists:

| Language | Linter Config Files |
|---|---|
| TypeScript/JavaScript | `.eslintrc*`, `eslint.config.*` |
| Python | `ruff.toml`, `pyproject.toml [tool.ruff]`, `.flake8` |
| Rust | `clippy.toml`, `.clippy.toml` |
| Go | `.golangci.yml`, `.golangci.yaml` |
| C/C++ | `.clang-tidy` |
| Java | `pmd.xml`, `checkstyle.xml` |
| C# | `.editorconfig` |
| Ruby | `.rubocop.yml` |
| PHP | `phpcs.xml`, `phpstan.neon` |
| Kotlin | `detekt.yml`, `detekt-config.yml` |
| Swift | `.swiftlint.yml` |
| Scala | `.scalafix.conf` |
| Haskell | `.hlint.yaml` |
| OCaml | `.ocamlformat` |

### Step 3: Present Recommendations

Present the findings to the user in a clear summary:

**For each language with an existing linter:**
> "[Language]: Found [linter]. Checking for strict complexity rules..."
> Then inspect the config and list which strict rules are missing.

**For each language without a linter:**
> "[Language]: No linter configured. Recommended: [linter]."
> Show the install command and what strict rules would be enabled.

**For unsupported languages (Lean, Unison):**
> "[Language]: No complexity linter available. Skipping."

**For formatting-only languages (OCaml, Lua):**
> "[Language]: Only formatting tools available ([tool]). Limited complexity enforcement."

Then ask: **"Want me to install and configure these linters with strict complexity rules? (y/n)"**

If the user declines:

```bash
mkdir -p .claude
touch .claude/.no-lint-setup
```

Report: "Lint Guard setup skipped. The `.claude/.no-lint-setup` marker will prevent future prompts. Delete it to re-enable."

Stop here — do not proceed to Step 4.

**Scope gate (before Step 4):** List the languages detected in Step 1 literally in your response. Install and configure ONLY for those languages. Do NOT pre-emptively configure languages absent from the project, even if this SKILL.md documents them.

### Step 4: Install and Configure Linters

For each language the user approved, install the linter and write strict configs.

Use the reference table below for exact install commands, config content, and strict rules.

#### TypeScript/JavaScript — ESLint + SonarJS + Unicorn + Perfectionist

**Install:**
```bash
npm install -D eslint eslint-plugin-sonarjs eslint-plugin-unicorn eslint-plugin-perfectionist @eslint/js
```

**Strict rules** (add to existing ESLint config or create `eslint.config.mjs`):
```javascript
// Strict complexity rules — added by lint-guard
{
  rules: {
    'complexity': ['error', { max: 10 }],
    'max-depth': ['error', { max: 3 }],
    'max-lines-per-function': ['error', { max: 60, skipBlankLines: true, skipComments: true }],
    'max-params': ['error', { max: 4 }],
    'max-statements': ['error', { max: 15 }],
    'max-nested-callbacks': ['error', { max: 3 }],
    'sonarjs/cognitive-complexity': ['error', 10],
  }
}
```

**linters.json entry:**
```json
{
  "name": "eslint",
  "language": "typescript/javascript",
  "command": "npx eslint --max-warnings 0",
  "autofix_command": "npx eslint --fix",
  "safe_autofix": true,
  "glob": "*.{js,ts,jsx,tsx,mjs,cjs}",
  "strict_rules_applied": true
}
```

#### Python — ruff

**Install:**
```bash
pip install ruff
```
Or if using brew: `brew install ruff`

**Strict rules** (add to `ruff.toml` or `pyproject.toml [tool.ruff]`):
```toml
[lint]
select = [
  "E",     # pycodestyle errors
  "W",     # pycodestyle warnings
  "F",     # pyflakes
  "C901",  # McCabe complexity
  "PLR",   # pylint refactor rules
]

[lint.mccabe]
max-complexity = 10

[lint.pylint]
max-args = 5
max-branches = 12
max-returns = 6
max-statements = 50
```

**linters.json entry:**
```json
{
  "name": "ruff",
  "language": "python",
  "command": "ruff check",
  "autofix_command": "ruff check --fix",
  "safe_autofix": true,
  "glob": "*.py",
  "strict_rules_applied": true
}
```

#### Go — golangci-lint

**Install:**
```bash
brew install golangci-lint
```

**Strict rules** (create `.golangci.yml`):
```yaml
linters:
  enable:
    - cyclop
    - funlen
    - gocognit
    - gocyclo
    - nestif

linters-settings:
  cyclop:
    max-complexity: 10
  funlen:
    lines: 60
    statements: 40
  gocognit:
    min-complexity: 10
  gocyclo:
    min-complexity: 10
  nestif:
    min-complexity: 4
```

**linters.json entry:**
```json
{
  "name": "golangci-lint",
  "language": "go",
  "command": "golangci-lint run",
  "autofix_command": "golangci-lint run --fix",
  "safe_autofix": true,
  "glob": "*.go",
  "strict_rules_applied": true
}
```

#### Rust — clippy

**Install:** Included with rustup (no extra install needed).

**Strict rules** (create `clippy.toml` if it doesn't exist):
```toml
cognitive-complexity-threshold = 10
too-many-arguments-threshold = 5
too-many-lines-threshold = 60
```

Also add to the project's `Cargo.toml` or `.cargo/config.toml`:
```toml
[lints.clippy]
pedantic = { level = "warn", priority = -1 }
cognitive_complexity = "deny"
too_many_arguments = "warn"
too_many_lines = "warn"
```

**linters.json entry:**
```json
{
  "name": "clippy",
  "language": "rust",
  "command": "cargo clippy -- -D warnings",
  "autofix_command": "cargo clippy --fix --allow-dirty",
  "safe_autofix": true,
  "glob": "*.rs",
  "strict_rules_applied": true
}
```

#### C/C++ — clang-tidy

**Install:**
```bash
brew install llvm
```

**Strict rules** (create `.clang-tidy`):
```yaml
Checks: >
  -*,
  readability-function-cognitive-complexity,
  readability-function-size,
  readability-simplify-boolean-expr

CheckOptions:
  readability-function-cognitive-complexity.Threshold: 10
  readability-function-size.LineThreshold: 60
  readability-function-size.StatementThreshold: 40
  readability-function-size.ParameterThreshold: 5
```

**linters.json entry:**
```json
{
  "name": "clang-tidy",
  "language": "c/c++",
  "command": "clang-tidy",
  "autofix_command": "clang-tidy --fix",
  "safe_autofix": false,
  "glob": "*.{c,cpp,cc,h,hpp}",
  "strict_rules_applied": true
}
```

#### Java — PMD

**Install:**
```bash
brew install pmd
```

**Strict rules** (create `pmd-ruleset.xml`):
```xml
<?xml version="1.0"?>
<ruleset name="Lint Guard Strict"
  xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 https://pmd.sourceforge.io/ruleset_2_0_0.xsd">

  <rule ref="category/java/design.xml/CyclomaticComplexity">
    <properties><property name="methodReportLevel" value="10"/></properties>
  </rule>
  <rule ref="category/java/design.xml/NPathComplexity">
    <properties><property name="reportLevel" value="200"/></properties>
  </rule>
  <rule ref="category/java/design.xml/ExcessiveMethodLength">
    <properties><property name="minimum" value="60"/></properties>
  </rule>
  <rule ref="category/java/design.xml/ExcessiveParameterList">
    <properties><property name="minimum" value="5"/></properties>
  </rule>
  <rule ref="category/java/design.xml/CognitiveComplexity">
    <properties><property name="reportLevel" value="10"/></properties>
  </rule>
</ruleset>
```

**linters.json entry:**
```json
{
  "name": "pmd",
  "language": "java",
  "command": "pmd check -d src -R pmd-ruleset.xml -f text",
  "autofix_command": "",
  "safe_autofix": false,
  "glob": "*.java",
  "strict_rules_applied": true
}
```

#### C# — dotnet format + Roslyn analyzers

**Install:** Included with .NET SDK.

**Strict rules** (add to `.editorconfig`):
```ini
[*.cs]
# Complexity analyzers
dotnet_diagnostic.CA1502.severity = warning  # Avoid excessive complexity
dotnet_diagnostic.CA1505.severity = warning  # Avoid unmaintainable code
dotnet_diagnostic.CA1506.severity = warning  # Avoid excessive coupling
```

**linters.json entry:**
```json
{
  "name": "dotnet-format",
  "language": "c#",
  "command": "dotnet format --verify-no-changes --diagnostics CA1502 CA1505 CA1506",
  "autofix_command": "dotnet format",
  "safe_autofix": true,
  "glob": "*.cs",
  "strict_rules_applied": true
}
```

#### Ruby — RuboCop

**Install:**
```bash
gem install rubocop
```

**Strict rules** (add to `.rubocop.yml`):
```yaml
Metrics/CyclomaticComplexity:
  Enabled: true
  Max: 10

Metrics/PerceivedComplexity:
  Enabled: true
  Max: 10

Metrics/MethodLength:
  Enabled: true
  Max: 20

Metrics/AbcSize:
  Enabled: true
  Max: 30

Metrics/ParameterLists:
  Enabled: true
  Max: 4

Metrics/BlockNesting:
  Enabled: true
  Max: 3
```

**linters.json entry:**
```json
{
  "name": "rubocop",
  "language": "ruby",
  "command": "rubocop --format simple",
  "autofix_command": "rubocop --autocorrect",
  "safe_autofix": true,
  "glob": "*.rb",
  "strict_rules_applied": true
}
```

#### PHP — PHP_CodeSniffer + PHPStan

**Install:**
```bash
composer require --dev squizlabs/php_codesniffer phpstan/phpstan
```

**Strict rules** (create `phpcs.xml`):
```xml
<?xml version="1.0"?>
<ruleset name="Lint Guard Strict">
  <rule ref="Generic.Metrics.CyclomaticComplexity">
    <properties><property name="complexity" value="10"/></properties>
  </rule>
  <rule ref="Generic.Metrics.NestingLevel">
    <properties><property name="nestingLevel" value="3"/></properties>
  </rule>
  <rule ref="Generic.Files.LineLength">
    <properties><property name="lineLimit" value="120"/></properties>
  </rule>
</ruleset>
```

**linters.json entry:**
```json
{
  "name": "phpcs",
  "language": "php",
  "command": "vendor/bin/phpcs --standard=phpcs.xml",
  "autofix_command": "vendor/bin/phpcbf --standard=phpcs.xml",
  "safe_autofix": true,
  "glob": "*.php",
  "strict_rules_applied": true
}
```

#### Kotlin — detekt

**Install:**
```bash
brew install detekt
```

**Strict rules** (create `detekt-config.yml`):
```yaml
complexity:
  CyclomaticComplexMethod:
    active: true
    threshold: 10
  LongMethod:
    active: true
    threshold: 60
  LongParameterList:
    active: true
    functionThreshold: 5
  NestedBlockDepth:
    active: true
    threshold: 3
  CognitiveComplexMethod:
    active: true
    threshold: 10
```

**linters.json entry:**
```json
{
  "name": "detekt",
  "language": "kotlin",
  "command": "detekt --config detekt-config.yml --input src",
  "autofix_command": "",
  "safe_autofix": false,
  "glob": "*.kt",
  "strict_rules_applied": true
}
```

#### Swift — SwiftLint

**Install:**
```bash
brew install swiftlint
```

**Strict rules** (create `.swiftlint.yml`):
```yaml
opt_in_rules:
  - cyclomatic_complexity
  - function_body_length
  - function_parameter_count
  - nesting

cyclomatic_complexity:
  warning: 10
  error: 15

function_body_length:
  warning: 60
  error: 100

function_parameter_count:
  warning: 4
  error: 6

nesting:
  type_level: 2
  function_level: 3
```

**linters.json entry:**
```json
{
  "name": "swiftlint",
  "language": "swift",
  "command": "swiftlint lint --strict",
  "autofix_command": "swiftlint lint --fix",
  "safe_autofix": true,
  "glob": "*.swift",
  "strict_rules_applied": true
}
```

#### Scala — Scalafix

**Install:**
```bash
cs install scalafix
```

**Strict rules** (create `.scalafix.conf`):
```
rules = [
  RemoveUnused,
  DisableSyntax,
  LeakingImplicitClassVal,
  NoValInForComprehension
]

DisableSyntax.noVars = true
DisableSyntax.noReturns = true
```

Note: Limited complexity enforcement — Scala's linting ecosystem is weaker on metrics.

**linters.json entry:**
```json
{
  "name": "scalafix",
  "language": "scala",
  "command": "scalafix --check .",
  "autofix_command": "scalafix .",
  "safe_autofix": true,
  "glob": "*.scala",
  "strict_rules_applied": true
}
```

#### Haskell — HLint

**Install:**
```bash
brew install hlint
```

**Strict rules** (create `.hlint.yaml`):
```yaml
- warn: {name: "Use fewer imports"}
- warn: {name: "Redundant bracket"}
- warn: {name: "Eta reduce"}
- warn: {name: "Use newtype instead of data"}
- suggest: {name: "Reduce duplication"}
```

Note: HLint is suggestions-based, not metrics-based. No cyclomatic complexity caps available.

**linters.json entry:**
```json
{
  "name": "hlint",
  "language": "haskell",
  "command": "hlint .",
  "autofix_command": "hlint --refactor .",
  "safe_autofix": false,
  "glob": "*.hs",
  "strict_rules_applied": true
}
```

#### OCaml — ocamlformat (formatting only)

**Install:**
```bash
opam install ocamlformat
```

**Config** (create `.ocamlformat`):
```
version = 0.26.2
profile = default
```

Note: Formatting only — no complexity rules available for OCaml.

**linters.json entry:**
```json
{
  "name": "ocamlformat",
  "language": "ocaml",
  "command": "ocamlformat --check .",
  "autofix_command": "ocamlformat -i",
  "safe_autofix": true,
  "glob": "*.ml",
  "strict_rules_applied": false
}
```

#### Lua — luacheck (limited)

**Install:**
```bash
brew install luacheck
```

**Config** (create `.luacheckrc`):
```lua
max_line_length = 120
max_code_line_length = 120
unused_args = true
unused_secondaries = true
```

Note: No cyclomatic complexity rules. Catches unused vars and basic style issues only.

**linters.json entry:**
```json
{
  "name": "luacheck",
  "language": "lua",
  "command": "luacheck .",
  "autofix_command": "",
  "safe_autofix": false,
  "glob": "*.lua",
  "strict_rules_applied": false
}
```

#### Lean — No linter available

Report: "Lean: No complexity linter available. `lake build` catches type errors but no complexity metrics exist. Skipping."

Add to `unsupported` array in linters.json.

#### Unison — No linter available

Report: "Unison: No linter available. Skipping."

Add to `unsupported` array in linters.json.

### Step 5: Generate `.claude/linters.json`

After installing and configuring linters, generate the config file:

```bash
mkdir -p .claude
```

Write `.claude/linters.json` with entries for each configured linter, using the exact JSON entries shown above. Include:

```json
{
  "version": 1,
  "linters": [
    // ... one entry per configured linter from the tables above
  ],
  "unsupported": ["lean", "unison"],
  "settings": {
    "stop_hook_enabled": true,
    "max_output_lines": 500,
    "timeout_per_linter_seconds": 30
  }
}
```

### Step 6: Install Stop Hook

Only install the Stop hook if the user explicitly approved lint-guard in the earlier approval step (Step 3). If they declined or deferred, skip hook installation entirely.

Copy the `lint-on-stop.sh` template to the project and register it:

```bash
# Copy the Stop hook script
mkdir -p .claude/hooks
cp "${CLAUDE_PLUGIN_ROOT}/hooks/lint/lint-on-stop.sh" .claude/hooks/lint-on-stop.sh
chmod +x .claude/hooks/lint-on-stop.sh
```

Then add the Stop hook entry to `.claude/settings.json`. Read the existing file first (create if missing), and add:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/lint-on-stop.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

If `.claude/settings.json` already has a `hooks.Stop` array, append to it rather than overwriting.

### Step 7: Report Success

Print a summary:

```
Lint Guard setup complete!

Configured linters:
- [ESLint] TypeScript/JavaScript — strict complexity rules enabled
- [ruff] Python — strict complexity rules enabled
  
Unsupported (no linter available):
- Lean
- Unison

Files created/modified:
- .claude/linters.json (linter configuration)
- .claude/hooks/lint-on-stop.sh (Stop hook script)
- .claude/settings.json (Stop hook registration)
- [linter config files created/modified]

The Stop hook will now run linters on changed files after every response.
Set LINT_GUARD_SKIP=1 to disable for a session.
```

## Environment Variable

`LINT_GUARD_SKIP=1` — disables the Stop hook for the current session. Useful for:
- Exploratory work where lint noise is unwanted
- Debugging linter configuration
- Non-code focused sessions

The SessionStart detection hook is NOT affected — it still checks and offers setup.
