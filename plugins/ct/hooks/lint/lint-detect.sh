#!/usr/bin/env bash
# SessionStart hook: detect project languages and prompt lint-guard setup.
#
# Fast, deterministic language detection via marker files and file extensions.
# Outputs a structured message if linting is not yet configured for this project.
# Does NOT install anything — detection and reporting only.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
  exit 0
fi

# Exit if already configured
if [ -f "${CWD}/.claude/linters.json" ]; then
  exit 0
fi

# Exit if user declined setup
if [ -f "${CWD}/.claude/.no-lint-setup" ]; then
  exit 0
fi

# --- Language detection ---
# Each language: name, marker files (high confidence), linter config files
DETECTED_LANGS=()
CONFIGURED_LINTERS=()
MISSING_LINTERS=()

# TypeScript/JavaScript
if [ -f "${CWD}/package.json" ] || [ -f "${CWD}/tsconfig.json" ]; then
  DETECTED_LANGS+=("TypeScript/JavaScript")
  if compgen -G "${CWD}/.eslintrc*" > /dev/null 2>&1 || \
     compgen -G "${CWD}/eslint.config.*" > /dev/null 2>&1; then
    CONFIGURED_LINTERS+=("ESLint (TypeScript/JavaScript)")
  else
    MISSING_LINTERS+=("TypeScript/JavaScript")
  fi
fi

# Python
if [ -f "${CWD}/pyproject.toml" ] || [ -f "${CWD}/setup.py" ] || \
   [ -f "${CWD}/requirements.txt" ] || [ -f "${CWD}/setup.cfg" ]; then
  DETECTED_LANGS+=("Python")
  if [ -f "${CWD}/ruff.toml" ] || \
     ([ -f "${CWD}/pyproject.toml" ] && grep -q '\[tool\.ruff\]' "${CWD}/pyproject.toml" 2>/dev/null) || \
     [ -f "${CWD}/.flake8" ] || \
     ([ -f "${CWD}/setup.cfg" ] && grep -q '^\[flake8\]' "${CWD}/setup.cfg" 2>/dev/null); then
    CONFIGURED_LINTERS+=("ruff/flake8 (Python)")
  else
    MISSING_LINTERS+=("Python")
  fi
fi

# Rust
if [ -f "${CWD}/Cargo.toml" ]; then
  DETECTED_LANGS+=("Rust")
  if [ -f "${CWD}/clippy.toml" ] || [ -f "${CWD}/.clippy.toml" ]; then
    CONFIGURED_LINTERS+=("clippy (Rust)")
  else
    MISSING_LINTERS+=("Rust")
  fi
fi

# Go
if [ -f "${CWD}/go.mod" ]; then
  DETECTED_LANGS+=("Go")
  if [ -f "${CWD}/.golangci.yml" ] || [ -f "${CWD}/.golangci.yaml" ] || \
     [ -f "${CWD}/.golangci.toml" ] || [ -f "${CWD}/.golangci.json" ]; then
    CONFIGURED_LINTERS+=("golangci-lint (Go)")
  else
    MISSING_LINTERS+=("Go")
  fi
fi

# C/C++
if compgen -G "${CWD}/CMakeLists.txt" > /dev/null 2>&1 || \
   compgen -G "${CWD}/Makefile" > /dev/null 2>&1 || \
   compgen -G "${CWD}/*.c" > /dev/null 2>&1 || \
   compgen -G "${CWD}/*.cpp" > /dev/null 2>&1 || \
   compgen -G "${CWD}/*.h" > /dev/null 2>&1; then
  DETECTED_LANGS+=("C/C++")
  if [ -f "${CWD}/.clang-tidy" ]; then
    CONFIGURED_LINTERS+=("clang-tidy (C/C++)")
  else
    MISSING_LINTERS+=("C/C++")
  fi
fi

# Java
if [ -f "${CWD}/pom.xml" ] || [ -f "${CWD}/build.gradle" ] || \
   [ -f "${CWD}/build.gradle.kts" ]; then
  DETECTED_LANGS+=("Java")
  if [ -f "${CWD}/pmd.xml" ] || find "${CWD}" -name "pmd.xml" -maxdepth 3 2>/dev/null | grep -q . || \
     [ -f "${CWD}/checkstyle.xml" ] || find "${CWD}" -name "checkstyle.xml" -maxdepth 3 2>/dev/null | grep -q .; then
    CONFIGURED_LINTERS+=("PMD/Checkstyle (Java)")
  else
    MISSING_LINTERS+=("Java")
  fi
fi

# C#
if compgen -G "${CWD}/*.csproj" > /dev/null 2>&1 || \
   compgen -G "${CWD}/*.sln" > /dev/null 2>&1; then
  DETECTED_LANGS+=("C#")
  if [ -f "${CWD}/.editorconfig" ]; then
    CONFIGURED_LINTERS+=("dotnet-format/Roslyn (C#)")
  else
    MISSING_LINTERS+=("C#")
  fi
fi

# Ruby
if [ -f "${CWD}/Gemfile" ]; then
  DETECTED_LANGS+=("Ruby")
  if [ -f "${CWD}/.rubocop.yml" ]; then
    CONFIGURED_LINTERS+=("RuboCop (Ruby)")
  else
    MISSING_LINTERS+=("Ruby")
  fi
fi

# PHP
if [ -f "${CWD}/composer.json" ]; then
  DETECTED_LANGS+=("PHP")
  if [ -f "${CWD}/phpcs.xml" ] || [ -f "${CWD}/phpcs.xml.dist" ] || \
     [ -f "${CWD}/phpstan.neon" ] || [ -f "${CWD}/phpstan.neon.dist" ]; then
    CONFIGURED_LINTERS+=("PHP_CodeSniffer/PHPStan (PHP)")
  else
    MISSING_LINTERS+=("PHP")
  fi
fi

# Kotlin
if [ -f "${CWD}/detekt.yml" ] || [ -f "${CWD}/detekt-config.yml" ] || \
   find "${CWD}/src" -name "*.kt" -maxdepth 5 2>/dev/null | grep -q .; then
  DETECTED_LANGS+=("Kotlin")
  if [ -f "${CWD}/detekt.yml" ] || [ -f "${CWD}/detekt-config.yml" ]; then
    CONFIGURED_LINTERS+=("detekt (Kotlin)")
  else
    MISSING_LINTERS+=("Kotlin")
  fi
fi

# Swift
if compgen -G "${CWD}/*.swift" > /dev/null 2>&1 || \
   [ -f "${CWD}/Package.swift" ]; then
  DETECTED_LANGS+=("Swift")
  if [ -f "${CWD}/.swiftlint.yml" ]; then
    CONFIGURED_LINTERS+=("SwiftLint (Swift)")
  else
    MISSING_LINTERS+=("Swift")
  fi
fi

# Scala
if [ -f "${CWD}/build.sbt" ]; then
  DETECTED_LANGS+=("Scala")
  if [ -f "${CWD}/.scalafix.conf" ]; then
    CONFIGURED_LINTERS+=("Scalafix (Scala)")
  else
    MISSING_LINTERS+=("Scala")
  fi
fi

# Haskell
if compgen -G "${CWD}/*.cabal" > /dev/null 2>&1 || \
   [ -f "${CWD}/stack.yaml" ]; then
  DETECTED_LANGS+=("Haskell")
  if [ -f "${CWD}/.hlint.yaml" ]; then
    CONFIGURED_LINTERS+=("HLint (Haskell)")
  else
    MISSING_LINTERS+=("Haskell")
  fi
fi

# OCaml
if [ -f "${CWD}/dune-project" ]; then
  DETECTED_LANGS+=("OCaml")
  if [ -f "${CWD}/.ocamlformat" ]; then
    CONFIGURED_LINTERS+=("ocamlformat (OCaml)")
  else
    MISSING_LINTERS+=("OCaml")
  fi
fi

# Lean
if [ -f "${CWD}/lakefile.lean" ] || [ -f "${CWD}/lean-toolchain" ]; then
  DETECTED_LANGS+=("Lean")
  # No linter available — always unsupported
fi

# Lua (extension-based fallback)
if compgen -G "${CWD}/*.lua" > /dev/null 2>&1 || \
   compgen -G "${CWD}/src/*.lua" > /dev/null 2>&1; then
  DETECTED_LANGS+=("Lua")
  if [ -f "${CWD}/.luacheckrc" ]; then
    CONFIGURED_LINTERS+=("luacheck (Lua)")
  else
    MISSING_LINTERS+=("Lua")
  fi
fi

# Unison (extension-based fallback)
if compgen -G "${CWD}/*.u" > /dev/null 2>&1; then
  DETECTED_LANGS+=("Unison")
  # No linter available — always unsupported
fi

# --- Output ---

# Exit silently if no languages detected
if [ ${#DETECTED_LANGS[@]} -eq 0 ]; then
  exit 0
fi

# Build output message
LANG_LIST=$(printf '%s, ' "${DETECTED_LANGS[@]}" | sed 's/, $//')

MSG="Lint Guard: Detected languages in this project: ${LANG_LIST}."

if [ ${#CONFIGURED_LINTERS[@]} -gt 0 ]; then
  CONFIGURED_LIST=$(printf '%s, ' "${CONFIGURED_LINTERS[@]}" | sed 's/, $//')
  MSG+=$'\nExisting linter configs: '"${CONFIGURED_LIST}."
fi

if [ ${#MISSING_LINTERS[@]} -gt 0 ]; then
  MISSING_LIST=$(printf '%s, ' "${MISSING_LINTERS[@]}" | sed 's/, $//')
  MSG+=$'\nMissing linter configs: '"${MISSING_LIST}."
fi

MSG+=$'\nRun /lint-guard to set up strict complexity linting for this project.'

# Output as structured hook response
jq -n --arg ctx "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
