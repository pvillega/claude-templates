#!/usr/bin/env bash

# Claude Templates Setup Script
# Installs plugins via marketplace, merges sandbox settings, and copies template CLAUDE.md.
# Compatible with bash and zsh on macOS and Linux.

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Script directory (for finding source files)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared configuration (TOOLS, SKILLS, MARKETPLACES, PLUGINS)
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

# Load all tool scripts from tools/ directory
for _tool_script in "$SCRIPT_DIR"/tools/*.sh; do
    # shellcheck source=/dev/null
    source "$_tool_script"
done

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

# Arrays for tracking warnings and errors
WARNINGS=()
ERRORS=()

# Environment variable instructions (populated later)
ENV_VAR_INSTRUCTIONS=""

# Clean install mode (removes existing config before setup)
CLEAN_INSTALL=false
DRY_RUN=false

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Adds a warning message to the warnings array
add_warning() {
    WARNINGS+=("$1")
}

# Adds an error message to the errors array
add_error() {
    ERRORS+=("$1")
}

# Prints a summary of warnings, errors, and next steps at the end of the script
print_summary() {
    echo ""
    echo "============================================"
    echo "SETUP SUMMARY"
    echo "============================================"
    echo ""

    if [ ${#WARNINGS[@]} -eq 0 ] && [ ${#ERRORS[@]} -eq 0 ]; then
        echo "Setup completed successfully!"
        echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "WARNINGS:"
        for warning in "${WARNINGS[@]}"; do
            echo "- $warning"
        done
        echo ""
    fi

    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo "ERRORS:"
        for error in "${ERRORS[@]}"; do
            echo "! $error"
        done
        echo ""
    fi

    # Display environment variable instructions
    if [ -n "$ENV_VAR_INSTRUCTIONS" ]; then
        echo "$ENV_VAR_INSTRUCTIONS"
        echo ""
    fi

    echo "NEXT STEPS:"
    echo "1. Add the environment variables shown above to your shell config"
    echo "2. Run: source ~/.bashrc  (or ~/.zshrc)"
    echo "3. If Claude Code is running, type /reload-plugins to load newly installed plugins"
    echo "4. Verify setup: claude --version"
    echo ""
    echo "============================================"
    echo ""
    print_lsp_info
}

# Displays usage information
show_help() {
    echo "Claude Templates Setup Script"
    echo ""
    echo "Installs Claude plugins via marketplace, merges sandbox settings,"
    echo "and copies the template CLAUDE.md to ~/.claude/."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --clean, -c   Remove existing Claude configuration before setup"
    echo "                WARNING: Deletes agents/, skills/, hooks/, commands/,"
    echo "                CLAUDE.md, *.md files, settings.json, and empties mcpServers"
    echo "                (preserves settings.local.json and plugins/)"
    echo ""
    echo "  --dry-run     Show what would be deleted without deleting (use with --clean)"
    echo ""
    echo "  --help, -h    Show this help message"
}

# Reports a critical error and exits the script
# Args:
#   $1: Error message
critical_error() {
    add_error "$1"
    print_summary
    exit 1
}

# ==============================================================================
# SETUP FUNCTIONS
# ==============================================================================

# Configures Claude plugin marketplaces from MARKETPLACES array
# Attempts to update existing marketplaces, adds new ones if not found
configure_marketplaces() {
    echo "Configuring Claude plugin marketplaces..."

    for marketplace_config in "${MARKETPLACES[@]}"; do
        # Split into owner/repo and name
        local marketplace_path="${marketplace_config%%:*}"
        local marketplace_name="${marketplace_config##*:}"

        echo "Processing marketplace: $marketplace_name..."

        # Try to update first, add if that fails
        if claude plugin marketplace update "$marketplace_name" 2>/dev/null; then
            echo "Marketplace $marketplace_name updated"
        elif claude plugin marketplace add "$marketplace_path"; then
            echo "Marketplace $marketplace_path added"
        else
            add_warning "Failed to configure marketplace $marketplace_path"
        fi
    done
}

# Updates all configured marketplaces to ensure latest plugin lists are available
update_all_marketplaces() {
    echo "Updating all configured marketplaces..."

    local output
    if output=$(claude plugin marketplace update 2>&1); then
        echo "$output"
        echo "All marketplaces updated"
    else
        echo "$output"
        add_warning "Failed to update some marketplaces. Plugin installs may fail if marketplace indexes are stale."
    fi
}

# Installs Claude plugins from PLUGINS array
# Uninstalls existing plugins before reinstalling to ensure clean state
install_plugins() {
    echo "Installing Claude plugins..."
    local failed_plugins=()

    for plugin in "${PLUGINS[@]}"; do
        echo "Processing plugin: $plugin..."

        # Uninstall plugin if it exists (ignore errors)
        echo "Uninstalling $plugin (if exists)..."
        claude plugin uninstall "$plugin" 2>/dev/null || true

        # Install plugin, capturing output to show errors
        echo "Installing $plugin..."
        local output
        if output=$(claude plugin install "$plugin" 2>&1); then
            echo "$output"
        else
            echo "$output"
            failed_plugins+=("$plugin")
            add_warning "Failed to install plugin: $plugin"
        fi
    done

    if [ ${#failed_plugins[@]} -gt 0 ]; then
        echo ""
        echo "WARNING: ${#failed_plugins[@]} plugin(s) failed to install:"
        for p in "${failed_plugins[@]}"; do
            echo "  - $p"
        done
        echo ""
        echo "Try installing them manually with: claude plugin install <plugin>"
    fi
}

# Installs skills globally via skills.sh CLI
# Each skill can be aborted by the user; the loop continues with the next skill
install_skills() {
    echo "Installing skills via skills.sh..."

    if ! command -v npx &> /dev/null; then
        add_warning "npx not found, skipping skills installation"
        return 0
    fi

    for skill in "${SKILLS[@]}"; do
        echo ""
        echo "Installing skill: $skill (global)..."
        # shellcheck disable=SC2086
        if ! npx skills add $skill -g --all; then
            add_warning "Failed or skipped skill: $skill"
        else
            echo "Skill $skill installed successfully"
        fi
    done
}

# Copies templates/CLAUDE.md to ~/.claude/CLAUDE.md
copy_template_claude_md() {
    echo "Setting up template CLAUDE.md..."
    local template="$SCRIPT_DIR/templates/CLAUDE.md"
    local dest="$HOME/.claude/CLAUDE.md"

    if [ ! -f "$template" ]; then
        add_warning "templates/CLAUDE.md not found, skipping"
        return 0
    fi

    mkdir -p "$HOME/.claude"

    if [ -f "$dest" ]; then
        echo "  ~/.claude/CLAUDE.md already exists, skipping (use --clean to replace)"
    else
        cp "$template" "$dest"
        echo "  Copied templates/CLAUDE.md to ~/.claude/CLAUDE.md"
    fi
}

# Deep merge jq filter: recursively merges objects, concatenates+deduplicates arrays
# - Objects: recursively merged (keys from both sides kept)
# - Arrays: concatenated with stable deduplication (no reordering)
# - Scalars: overlay (second file) wins
DEEP_MERGE_JQ='
def uniq_stable:
  reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def deepmerge:
  .[0] as $a | .[1] as $b |
  if ($a | type) == "object" and ($b | type) == "object" then
    ([$a, $b] | map(keys) | add | unique) as $keys |
    ($keys | map(. as $k |
      if ($a | has($k)) and ($b | has($k)) then
        {($k): ([$a[$k], $b[$k]] | deepmerge)}
      elif ($b | has($k)) then
        {($k): $b[$k]}
      else
        {($k): $a[$k]}
      end
    ) | add) // {}
  elif ($a | type) == "array" and ($b | type) == "array" then
    ($a + $b) | uniq_stable
  else
    $b
  end;
[.[0], .[1]] | deepmerge
'

# Merges JSON configuration files into ~/.claude.json and ~/.claude/settings.json
# - Sets autoCompactEnabled in ~/.claude.json
# - Merges sandbox-settings.json into ~/.claude/settings.json (deep merge with array concatenation)
merge_json_configs() {
    echo "Updating JSON configurations..."

    # Update ~/.claude.json with autoCompactEnabled
    echo "Setting autoCompactEnabled in ~/.claude.json..."
    if [ ! -f "$HOME/.claude.json" ]; then
        echo '{}' > "$HOME/.claude.json"
    fi

    if jq '. + {"autoCompactEnabled": false}' "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"; then
        echo "autoCompactEnabled set to false"
    else
        add_error "Failed to update autoCompactEnabled in ~/.claude.json"
    fi

    # Merge sandbox-settings.json into ~/.claude/settings.json (recursive overwrite)
    echo "Merging sandbox settings configuration..."
    if [ ! -f "$SCRIPT_DIR/sandbox-settings.json" ]; then
        add_warning "sandbox-settings.json not found in script directory, skipping sandbox settings merge"
    else
        # Create ~/.claude directory if it doesn't exist
        mkdir -p "$HOME/.claude"

        # Create settings.json if it doesn't exist
        if [ ! -f "$HOME/.claude/settings.json" ]; then
            echo '{}' > "$HOME/.claude/settings.json"
            echo "  Created ~/.claude/settings.json"
        fi

        # Validate source JSON before merging
        if ! jq empty "$SCRIPT_DIR/sandbox-settings.json" 2>/dev/null; then
            add_error "sandbox-settings.json is not valid JSON, skipping sandbox settings merge"
        else
            # Deep merge: objects are recursively merged, arrays are concatenated and deduplicated
            if jq -s "$DEEP_MERGE_JQ" "$HOME/.claude/settings.json" "$SCRIPT_DIR/sandbox-settings.json" > "$HOME/.claude/settings.json.tmp" && mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"; then
                echo "Sandbox settings merged successfully (arrays concatenated, objects merged)"
            else
                add_error "Failed to merge sandbox-settings.json into ~/.claude/settings.json"
            fi
        fi
    fi
}

# Adds shell alias export for Claude Code's SessionStart hook
# Writes aliases to ~/.claude/shell-aliases.txt on every new shell
configure_shell_alias_export() {
    echo "Configuring shell alias export for Claude Code..."
    local export_line='alias > ~/.claude/shell-aliases.txt 2>/dev/null'
    local comment="# Export shell aliases for Claude Code (added by claude-templates install.sh)"

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            echo "  $rc_file does not exist, skipping"
            continue
        fi

        if grep -qF 'alias > ~/.claude/shell-aliases.txt' "$rc_file"; then
            echo "  Alias export already present in $rc_file, skipping"
        else
            echo "" >> "$rc_file"
            echo "$comment" >> "$rc_file"
            echo "$export_line" >> "$rc_file"
            echo "  Added alias export to $rc_file"
        fi
    done

    # Generate the file now so the current install works immediately
    mkdir -p "$HOME/.claude"
    alias > "$HOME/.claude/shell-aliases.txt" 2>/dev/null || true
    echo "  Generated ~/.claude/shell-aliases.txt"
}

# Adds the 'cl' alias to ~/.bashrc and ~/.zshrc if not already present
add_shell_alias() {
    echo "Configuring shell alias..."
    local alias_line="alias cl='SLASH_COMMAND_TOOL_CHAR_BUDGET=30000 claude --dangerously-skip-permissions'"
    local added=false

    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc_file" ]; then
            echo "  $rc_file does not exist, skipping"
            continue
        fi

        if grep -qF "alias cl=" "$rc_file"; then
            echo "  Alias 'cl' already present in $rc_file, skipping"
        else
            echo "" >> "$rc_file"
            echo "# Claude Code alias (added by claude-templates install.sh)" >> "$rc_file"
            echo "$alias_line" >> "$rc_file"
            echo "  Added 'cl' alias to $rc_file"
            added=true
        fi
    done

    if [ "$added" = true ]; then
        echo ""
        echo "  NOTE: Run 'source ~/.bashrc' (or ~/.zshrc) or open a new terminal for the alias to take effect."
    fi
}

# Prints LSP plugin and language server installation reference
print_lsp_info() {
    echo "============================================"
    echo "LSP INTEGRATION (optional)"
    echo "============================================"
    echo ""
    echo "Claude Code supports Language Server Protocol for code intelligence"
    echo "(go-to-definition, find-references, diagnostics, etc)."
    echo ""
    echo "Install the plugins and language servers for languages you use:"
    echo ""
    echo "  OFFICIAL PLUGINS (claude-plugins-official marketplace):"
    echo ""
    echo "  Language       Plugin Install                                                   Language Server Install"
    echo "  -----------    -----------------------------------------------------------------  -----------------------------------------------"
    echo "  TypeScript/JS  claude plugin install typescript-lsp@claude-plugins-official       npm install -g typescript-language-server typescript"
    echo "  Python         claude plugin install pyright-lsp@claude-plugins-official          npm install -g pyright  (or: pip install pyright)"
    echo "  Go             claude plugin install gopls-lsp@claude-plugins-official            go install golang.org/x/tools/gopls@latest"
    echo "  Rust           claude plugin install rust-analyzer-lsp@claude-plugins-official    rustup component add rust-analyzer"
    echo "  C/C++          claude plugin install clangd-lsp@claude-plugins-official           brew install llvm  (or: sudo apt install clangd)"
    echo "  Java           claude plugin install jdtls-lsp@claude-plugins-official            brew install jdtls  (requires JDK 21+)"
    echo "  C#             claude plugin install csharp-lsp@claude-plugins-official           dotnet tool install --global csharp-ls"
    echo "  Ruby           claude plugin install ruby-lsp@claude-plugins-official             gem install ruby-lsp  (requires Ruby 3.0+)"
    echo "  PHP            claude plugin install php-lsp@claude-plugins-official              npm install -g intelephense"
    echo "  Kotlin         claude plugin install kotlin-lsp@claude-plugins-official           brew install kotlin-language-server"
    echo "  Lua            claude plugin install lua-lsp@claude-plugins-official              brew install lua-language-server"
    echo "  Swift          claude plugin install swift-lsp@claude-plugins-official            (included with Xcode or: brew install swift)"
    echo ""
    echo "  COMMUNITY / THIRD-PARTY PLUGINS (no official plugin available):"
    echo ""
    echo "  Language       Plugin Source                                                      Language Server Install"
    echo "  -----------    -----------------------------------------------------------------  -----------------------------------------------"
    echo "  Scala          Piebald-AI/claude-code-lsps marketplace (Metals)                  cs install metals  (requires: brew install coursier/formulas/coursier && cs setup)"
    echo "  Haskell        m4dc4p/claude-hls (community plugin)                              ghcup install hls  (requires: curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh)"
    echo "  OCaml          Piebald-AI/claude-code-lsps or boostvolt/claude-code-lsps         opam install ocaml-lsp-server  (requires: brew install opam && opam init)"
    echo "  Unison         No plugin available yet                                           brew install unisonweb/unison/ucm  (LSP built into UCM: ucm lsp)"
    echo ""
    echo "  To use third-party marketplaces, add them first:"
    echo "    claude plugin marketplace add Piebald-AI/claude-code-lsps"
    echo "    claude plugin marketplace add boostvolt/claude-code-lsps"
    echo ""
    echo "After installing plugins, restart Claude Code for LSP servers to load."
    echo "Verify with: check ~/.claude/debug/latest for 'Total LSP servers loaded: N'"
    echo ""
}

# Prepares environment variable configuration instructions
# Populates ENV_VAR_INSTRUCTIONS global variable
prepare_env_instructions() {
    echo "Preparing environment variable configuration..."

    ENV_VAR_INSTRUCTIONS="ENVIRONMENT VARIABLES:
A mise.toml.example file is provided in the repository.
Copy it and fill in your API keys:

  cp mise.toml.example mise.toml
  # Edit mise.toml with your actual API keys
  mise trust

Alternatively, add these to your shell configuration (~/.bashrc or ~/.zshrc):

  export TAVILY_API_KEY=\"your-api-key-here\"

Note: You can also authenticate Tavily via 'tvly login --api-key \$(echo \$TAVILY_API_KEY)' instead of exporting the environment variable."

    echo "Environment variable instructions prepared"
}

# Removes existing Claude configuration files
# Prompts user for confirmation before proceeding
# Respects DRY_RUN mode to preview changes
clean_existing_config() {
    local claude_dir="$HOME/.claude"
    local claude_json="$HOME/.claude.json"

    echo ""
    echo "============================================"
    if [ "$DRY_RUN" = true ]; then
        echo "CLEAN INSTALL PREVIEW (--dry-run)"
    else
        echo "WARNING: CLEAN INSTALL MODE"
    fi
    echo "============================================"
    echo ""
    echo "The following will be DELETED:"

    # List directories
    for dir in agents skills hooks commands; do
        if [ -d "$claude_dir/$dir" ]; then
            local size
            size=$(du -sh "$claude_dir/$dir" 2>/dev/null | cut -f1)
            echo "  - ~/.claude/$dir/ ($size)"
        fi
    done

    # List CLAUDE.md
    if [ -f "$claude_dir/CLAUDE.md" ]; then
        echo "  - ~/.claude/CLAUDE.md"
    fi

    # List other *.md files at root (excluding CLAUDE.md which is listed above)
    if [ -d "$claude_dir" ]; then
        while IFS= read -r -d '' md_file; do
            local basename
            basename=$(basename "$md_file")
            echo "  - ~/.claude/$basename"
        done < <(find "$claude_dir" -maxdepth 1 -name "*.md" ! -name "CLAUDE.md" -type f -print0)
    fi

    # List settings.json
    if [ -f "$claude_dir/settings.json" ]; then
        echo "  - ~/.claude/settings.json"
    fi

    # List mcpServers
    if [ -f "$claude_json" ]; then
        local server_count
        server_count=$(jq '.mcpServers | length // 0' "$claude_json" 2>/dev/null || echo "0")
        echo "  - mcpServers in ~/.claude.json ($server_count servers)"
    fi

    echo ""
    echo "The following will be PRESERVED:"
    if [ -f "$claude_dir/settings.local.json" ]; then
        echo "  - ~/.claude/settings.local.json"
    fi
    if [ -d "$claude_dir/plugins" ]; then
        echo "  - ~/.claude/plugins/"
    fi
    echo ""

    if [ "$DRY_RUN" = true ]; then
        echo "This is a dry run. No files will be deleted."
        echo "Remove --dry-run to perform the actual cleanup."
        echo ""
        return 0
    fi

    echo "WARNING: You may lose custom configurations!"
    echo "WARNING: You may need to re-login to Claude after this."
    echo ""

    read -r -p "Are you sure you want to continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo ""
            echo "Proceeding with clean install..."
            ;;
        *)
            echo ""
            echo "Clean install cancelled."
            exit 0
            ;;
    esac

    echo ""

    # Remove directories
    for dir in agents skills hooks commands; do
        if [ -d "$claude_dir/$dir" ]; then
            if rm -rf "$claude_dir/$dir"; then
                echo "Removed: $claude_dir/$dir/"
            else
                add_error "Failed to remove $claude_dir/$dir/"
            fi
        fi
    done

    # Remove CLAUDE.md
    if [ -f "$claude_dir/CLAUDE.md" ]; then
        if rm -f "$claude_dir/CLAUDE.md"; then
            echo "Removed: $claude_dir/CLAUDE.md"
        else
            add_error "Failed to remove $claude_dir/CLAUDE.md"
        fi
    fi

    # Remove all *.md files at root of .claude (CLAUDE.md already removed above)
    if [ -d "$claude_dir" ]; then
        while IFS= read -r -d '' md_file; do
            if rm -f "$md_file"; then
                echo "Removed: $md_file"
            else
                add_error "Failed to remove $md_file"
            fi
        done < <(find "$claude_dir" -maxdepth 1 -name "*.md" ! -name "CLAUDE.md" -type f -print0)
    fi

    # Remove settings.json (NOT settings.local.json)
    if [ -f "$claude_dir/settings.json" ]; then
        if rm -f "$claude_dir/settings.json"; then
            echo "Removed: $claude_dir/settings.json"
        else
            add_error "Failed to remove $claude_dir/settings.json"
        fi
    fi

    # Empty mcpServers in ~/.claude.json
    if [ -f "$claude_json" ]; then
        if jq empty "$claude_json" 2>/dev/null; then
            if jq '.mcpServers = {}' "$claude_json" > "$claude_json.tmp" && \
               mv "$claude_json.tmp" "$claude_json"; then
                echo "Emptied mcpServers in: $claude_json"
            else
                add_error "Failed to empty mcpServers in $claude_json"
            fi
        else
            add_warning "$claude_json is not valid JSON, skipping mcpServers cleanup"
        fi
    fi

    echo ""
    echo "Clean install preparation completed."
    echo ""
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        --clean|-c)
            CLEAN_INSTALL=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Validate flag combinations
if [ "$DRY_RUN" = true ] && [ "$CLEAN_INSTALL" = false ]; then
    echo "Error: --dry-run requires --clean"
    exit 1
fi

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

echo "Starting Claude Templates setup..."
echo ""

# Clean existing config if requested
if [ "$CLEAN_INSTALL" = true ]; then
    clean_existing_config

    # Exit after dry run (don't proceed with setup)
    if [ "$DRY_RUN" = true ]; then
        exit 0
    fi
fi

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Darwin)
        OS_TYPE="macos"
        echo "Detected OS: macOS"
        ;;
    Linux)
        OS_TYPE="linux"
        echo "Detected OS: Linux"
        ;;
    *)
        critical_error "Unsupported operating system: $OS. This script supports macOS and Linux only."
        ;;
esac
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v curl &> /dev/null; then
    critical_error "curl is required but not installed. Please install curl first."
fi
echo "curl found: $(curl --version | head -1)"

if ! command -v npm &> /dev/null; then
    critical_error "npm is required but not installed. Please install Node.js and npm first."
fi
echo "npm found: $(npm --version)"
echo ""

# Copy template CLAUDE.md (before tools, as tool installers may modify it)
copy_template_claude_md
echo ""

# Install CLI tools from TOOLS array
for tool in "${TOOLS[@]}"; do
    "install_${tool}" "$OS_TYPE"
    echo ""
done

# Configure Claude plugin marketplaces
configure_marketplaces
echo ""

# Update all marketplaces before installing plugins
update_all_marketplaces
echo ""

# Install Claude plugins
install_plugins
echo ""

# Install skills via skills.sh
install_skills
echo ""

# Update JSON configurations
merge_json_configs
echo ""

# Configure shell alias export for Claude Code
configure_shell_alias_export
echo ""

# Add shell alias
add_shell_alias
echo ""

# Prepare environment variable instructions
prepare_env_instructions
echo ""

# Print final summary
print_summary
