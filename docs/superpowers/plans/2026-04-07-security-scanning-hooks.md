# Security Scanning Hooks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automated security scanning via Semgrep Claude Code plugin (PostToolUse SAST) and Gitleaks global git pre-commit hook (secret detection).

**Architecture:** Two independent components — `tools/semgrep.sh` installs the Semgrep CLI (prerequisite for the Semgrep plugin registered in `config.sh`), and `tools/gitleaks.sh` installs Gitleaks + sets up a global git pre-commit hook. No custom Claude Code hooks needed.

**Tech Stack:** Bash, Homebrew, Semgrep OSS CLI, Gitleaks, git hooks

---

### Task 1: Create `tools/semgrep.sh`

**Files:**
- Create: `tools/semgrep.sh`

- [ ] **Step 1: Create the tool script**

Create `tools/semgrep.sh` following the pattern from `tools/jq.sh`:

```bash
#!/usr/bin/env bash

# Semgrep OSS CLI - install, update, and uninstall
# SAST scanner used by the Semgrep Claude Code plugin for PostToolUse security scanning.
# Requires: critical_error, add_warning functions from parent script

install_semgrep() {
    echo "Checking for semgrep..."

    if command -v semgrep &> /dev/null; then
        echo "semgrep already installed: $(semgrep --version 2>&1 | head -1)"
        return 0
    fi

    echo "semgrep not found. Installing semgrep via Homebrew..."
    if ! brew install semgrep; then
        critical_error "Failed to install semgrep via Homebrew"
    fi

    if ! command -v semgrep &> /dev/null; then
        critical_error "semgrep installation appeared to succeed but semgrep command is still not available"
    fi

    echo "semgrep installed successfully: $(semgrep --version 2>&1 | head -1)"
}

update_semgrep() {
    echo "Updating semgrep..."

    if ! command -v semgrep &> /dev/null; then
        add_warning "semgrep is not installed, skipping update"
        return 0
    fi

    brew upgrade semgrep 2>/dev/null || echo "semgrep already up to date"
    echo "semgrep update complete"
}

uninstall_semgrep() {
    echo "Removing semgrep..."

    if ! command -v semgrep &> /dev/null; then
        echo "semgrep is not installed, nothing to remove"
        return 0
    fi

    brew uninstall semgrep 2>/dev/null || add_warning "Failed to uninstall semgrep via Homebrew"
    echo "semgrep removal complete"
}
```

- [ ] **Step 2: Verify the script is syntactically valid**

Run: `bash -n tools/semgrep.sh`
Expected: No output (no syntax errors)

- [ ] **Step 3: Commit**

```bash
git add tools/semgrep.sh
git commit -m "feat: add tools/semgrep.sh for Semgrep OSS CLI installation"
```

---

### Task 2: Create `tools/gitleaks.sh`

**Files:**
- Create: `tools/gitleaks.sh`

- [ ] **Step 1: Create the tool script**

Create `tools/gitleaks.sh`:

```bash
#!/usr/bin/env bash

# Gitleaks secret scanner - install, update, and uninstall
# Installs gitleaks CLI and sets up a global git pre-commit hook for secret detection.
# Requires: critical_error, add_warning functions from parent script

readonly GITLEAKS_HOOKS_DIR="$HOME/.git-hooks"
readonly GITLEAKS_HOOK_FILE="$GITLEAKS_HOOKS_DIR/pre-commit"

# Marker comments to identify the gitleaks section in the hook file
readonly GITLEAKS_MARKER_START="# --- gitleaks-start ---"
readonly GITLEAKS_MARKER_END="# --- gitleaks-end ---"

_gitleaks_hook_content() {
    cat <<'HOOK'
#!/usr/bin/env bash

# --- gitleaks-start ---
# Gitleaks pre-commit hook: scans staged changes for secrets
# Skip with: SKIP_GITLEAKS=1 git commit -m "..."
if [ "${SKIP_GITLEAKS}" != "1" ] && command -v gitleaks &> /dev/null; then
    gitleaks git --pre-commit --staged --redact -v
    if [ $? -ne 0 ]; then
        echo ""
        echo "gitleaks: secrets detected in staged changes. Commit blocked."
        echo "To skip: SKIP_GITLEAKS=1 git commit -m \"...\""
        exit 1
    fi
fi
# --- gitleaks-end ---

# Chain to repo-local pre-commit hook if it exists
_repo_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
if [ -x "$_repo_hook" ]; then
    exec "$_repo_hook"
fi
HOOK
}

install_gitleaks() {
    echo "Checking for gitleaks..."

    if command -v gitleaks &> /dev/null; then
        echo "gitleaks already installed: $(gitleaks version 2>&1)"
    else
        echo "gitleaks not found. Installing gitleaks via Homebrew..."
        if ! brew install gitleaks; then
            critical_error "Failed to install gitleaks via Homebrew"
        fi

        if ! command -v gitleaks &> /dev/null; then
            critical_error "gitleaks installation appeared to succeed but gitleaks command is still not available"
        fi

        echo "gitleaks installed successfully: $(gitleaks version 2>&1)"
    fi

    # Set up global git pre-commit hook
    _setup_gitleaks_hook
}

_setup_gitleaks_hook() {
    # Create hooks directory
    mkdir -p "$GITLEAKS_HOOKS_DIR"

    # Configure core.hooksPath if not already set
    local current_hooks_path
    current_hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")

    if [ -z "$current_hooks_path" ]; then
        echo "Setting global git hooks path to $GITLEAKS_HOOKS_DIR..."
        git config --global core.hooksPath "$GITLEAKS_HOOKS_DIR"
    elif [ "$current_hooks_path" != "$GITLEAKS_HOOKS_DIR" ]; then
        add_warning "core.hooksPath is already set to '$current_hooks_path' (not $GITLEAKS_HOOKS_DIR). Gitleaks hook will be installed there instead."
        # Use the existing hooks path
        GITLEAKS_HOOKS_DIR_ACTUAL="$current_hooks_path"
        mkdir -p "$GITLEAKS_HOOKS_DIR_ACTUAL"
    fi

    local target_dir="${GITLEAKS_HOOKS_DIR_ACTUAL:-$GITLEAKS_HOOKS_DIR}"
    local target_hook="$target_dir/pre-commit"

    # Check for existing pre-commit hook
    if [ -f "$target_hook" ]; then
        if grep -q "$GITLEAKS_MARKER_START" "$target_hook" 2>/dev/null; then
            echo "gitleaks hook already present in $target_hook"
            return 0
        fi
        add_warning "Pre-commit hook already exists at $target_hook. Gitleaks not added automatically. Add gitleaks manually — see README for instructions."
        return 0
    fi

    # Write the hook
    _gitleaks_hook_content > "$target_hook"
    chmod +x "$target_hook"
    echo "gitleaks pre-commit hook installed at $target_hook"
}

update_gitleaks() {
    echo "Updating gitleaks..."

    if ! command -v gitleaks &> /dev/null; then
        add_warning "gitleaks is not installed, skipping update"
        return 0
    fi

    brew upgrade gitleaks 2>/dev/null || echo "gitleaks already up to date"
    echo "gitleaks update complete"
}

uninstall_gitleaks() {
    echo "Removing gitleaks..."

    # Remove the binary
    if command -v gitleaks &> /dev/null; then
        brew uninstall gitleaks 2>/dev/null || add_warning "Failed to uninstall gitleaks via Homebrew"
    else
        echo "gitleaks is not installed, nothing to remove"
    fi

    # Clean up the pre-commit hook
    local hooks_path
    hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "$GITLEAKS_HOOKS_DIR")
    local target_hook="$hooks_path/pre-commit"

    if [ -f "$target_hook" ]; then
        if grep -q "$GITLEAKS_MARKER_START" "$target_hook" 2>/dev/null; then
            # Check if the hook contains ONLY gitleaks content
            local non_gitleaks_content
            non_gitleaks_content=$(sed "/$GITLEAKS_MARKER_START/,/$GITLEAKS_MARKER_END/d" "$target_hook" | grep -v '^#!/usr/bin/env bash' | grep -v '^#' | grep -v '^$' | grep -v '_repo_hook' | grep -v 'exec ')
            if [ -z "$non_gitleaks_content" ]; then
                rm "$target_hook"
                echo "gitleaks pre-commit hook removed"
            else
                add_warning "Pre-commit hook at $target_hook contains other content besides gitleaks. Remove the gitleaks section (between markers) manually."
            fi
        fi
    fi

    echo "gitleaks removal complete"
}
```

- [ ] **Step 2: Verify the script is syntactically valid**

Run: `bash -n tools/gitleaks.sh`
Expected: No output (no syntax errors)

- [ ] **Step 3: Commit**

```bash
git add tools/gitleaks.sh
git commit -m "feat: add tools/gitleaks.sh with global git pre-commit hook setup"
```

---

### Task 3: Update `config.sh`

**Files:**
- Modify: `config.sh`

- [ ] **Step 1: Add gitleaks to TOOLS array**

Add `"gitleaks"` after `"semgrep"` in the `TOOLS` array.

Before:
```bash
    "semgrep"
)
```

After:
```bash
    "semgrep"
    "gitleaks"
)
```

- [ ] **Step 2: Fix MARKETPLACES entry format**

The current entry `"semgrep/mcp-marketplace"` is missing the `:name` suffix required by `configure_marketplaces()` in `install.sh` (line 139 splits on `:`).

Before:
```bash
    "semgrep/mcp-marketplace"
```

After:
```bash
    "semgrep/mcp-marketplace:semgrep"
```

- [ ] **Step 3: Verify config.sh is syntactically valid**

Run: `bash -n config.sh`
Expected: No output (no syntax errors)

- [ ] **Step 4: Commit**

```bash
git add config.sh
git commit -m "feat: add gitleaks to TOOLS array and fix semgrep marketplace format"
```

---

### Task 4: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add Semgrep and Gitleaks to the CLI Tools table**

In the CLI Tools table (around line 104-119), add two new rows after the Nuclei + ZAP row:

```markdown
| [Semgrep](https://semgrep.dev) | OSS SAST scanner (used by Semgrep plugin for PostToolUse security scanning) | Homebrew |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | Secret detection via global git pre-commit hook | Homebrew |
```

- [ ] **Step 2: Add Semgrep plugin to the Plugins table**

In the Plugins table (around line 86-96), add a new row:

```markdown
| [Semgrep](https://semgrep.dev/docs/mcp) | 1 hook, 1 skill, MCP server | PostToolUse SAST + Supply Chain + Secrets scanning on every file edit (free OSS rules) | Automatic (post-Edit/Write) |
```

- [ ] **Step 3: Add a Security Scanning section after the CLI Tools section**

Add this section after the CLI Tools table (after line 120):

```markdown
### Security Scanning

Two layers of automated security scanning are installed:

**Semgrep Plugin** (Claude Code PostToolUse) — scans every file after Claude edits it using Semgrep Code (SAST), Supply Chain (dependency CVEs), and Secrets detection. Uses free community rules (~2,800 rules, no account required). For enhanced detection with 20,000+ rules, optionally run `/semgrep-plugin:setup-semgrep-plugin` to create a free Semgrep account.

**Gitleaks** (git pre-commit hook) — scans staged changes for secrets before every `git commit`. Defense-in-depth alongside Semgrep Secrets. Skip with `SKIP_GITLEAKS=1 git commit -m "..."`.

> **Note:** The global git hooks path (`core.hooksPath`) is set to `~/.git-hooks/`. This overrides per-repo `.git/hooks/` directories, but the hook script chains to repo-local hooks as a fallback. If you use the pre-commit framework in some repos, the chain-through ensures those hooks still run.
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Semgrep plugin and Gitleaks to README"
```

---

### Task 5: Verify full install flow

- [ ] **Step 1: Run syntax check on all modified files**

Run:
```bash
bash -n tools/semgrep.sh && bash -n tools/gitleaks.sh && bash -n config.sh && echo "All files valid"
```
Expected: `All files valid`

- [ ] **Step 2: Verify semgrep is already installed**

Run: `semgrep --version`
Expected: Version number (already installed from earlier in session)

- [ ] **Step 3: Verify gitleaks is already installed**

Run: `gitleaks version 2>&1`
Expected: Version number (already installed from earlier in session). If not installed, run `brew install gitleaks`.

- [ ] **Step 4: Test gitleaks hook manually**

Run:
```bash
# Check if the hook already exists
cat ~/.git-hooks/pre-commit 2>/dev/null || echo "No hook yet"
```

If a hook exists, check whether it has gitleaks markers. If not, verify the install script would correctly detect and warn.

- [ ] **Step 5: Test gitleaks on a clean commit**

Run from the project root:
```bash
gitleaks git --pre-commit --staged --redact -v
```
Expected: `no leaks found`

- [ ] **Step 6: Commit verification results**

No commit needed — this is a verification task.

---

### Task 6: Dispatch evaluator agent

- [ ] **Step 1: Dispatch the evaluator agent**

Dispatch the `ct:evaluator` agent against the project root to verify:
- `tools/semgrep.sh` follows the existing tool script pattern
- `tools/gitleaks.sh` follows the existing tool script pattern and hook setup is correct
- `config.sh` has valid entries for TOOLS, MARKETPLACES, and PLUGINS
- README documents both tools and the Semgrep plugin
- No security issues in the hook script itself
