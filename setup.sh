#!/usr/bin/env bash

# Claude Templates Setup Script
# Compatible with bash and zsh on macOS and Linux

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Script directory (for finding source files)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# NPM packages to install globally
readonly NPM_PACKAGES=(
    "@anthropic-ai/claude-code"
    "jscpd"
)

# Claude plugin marketplaces (format: "owner/repo:name")
readonly MARKETPLACES=(
    "obra/superpowers-marketplace:superpowers-marketplace"
    "lackeyjb/playwright-skill:playwright-skill"
)

# Claude plugins to install (format: "plugin@marketplace")
readonly PLUGINS=(
    "superpowers@superpowers-marketplace"
    "playwright-skill@playwright-skill"
)

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
        echo "✓ Setup completed successfully!"
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
            echo "⚠ $error"
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
    echo "3. Verify setup: claude --version"
    echo ""
    echo "============================================"
}

# Displays usage information
show_help() {
    echo "Claude Templates Setup Script"
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

# Installs jq JSON processor if not already present
# Detects OS and uses appropriate package manager
install_jq() {
    echo "Checking for jq..."

    if command -v jq &> /dev/null; then
        echo "✓ jq already installed: $(jq --version)"
        return 0
    fi

    echo "jq not found. Installing jq..."
    local os_type="$1"

    if [ "$os_type" = "macos" ]; then
        # macOS: use Homebrew
        if ! command -v brew &> /dev/null; then
            critical_error "Homebrew is required to install jq on macOS but is not installed. Please install Homebrew first: https://brew.sh"
        fi
        echo "Installing jq via Homebrew..."
        if ! brew install jq; then
            critical_error "Failed to install jq via Homebrew"
        fi
    else
        # Linux: try package managers
        if command -v apt-get &> /dev/null; then
            echo "Installing jq via apt-get..."
            if ! sudo apt-get update && sudo apt-get install -y jq; then
                critical_error "Failed to install jq via apt-get"
            fi
        elif command -v dnf &> /dev/null; then
            echo "Installing jq via dnf..."
            if ! sudo dnf install -y jq; then
                critical_error "Failed to install jq via dnf"
            fi
        elif command -v yum &> /dev/null; then
            echo "Installing jq via yum..."
            if ! sudo yum install -y jq; then
                critical_error "Failed to install jq via yum"
            fi
        else
            critical_error "Could not find a supported package manager (apt-get, dnf, or yum) to install jq. Please install jq manually."
        fi
    fi

    # Verify jq installation
    if ! command -v jq &> /dev/null; then
        critical_error "jq installation appeared to succeed but jq command is still not available"
    fi

    echo "✓ jq installed successfully"
}

# Installs npm global packages from NPM_PACKAGES array
install_npm_packages() {
    echo "Installing npm global packages..."

    for package in "${NPM_PACKAGES[@]}"; do
        echo "Installing $package..."
        if ! npm install -g "$package"; then
            critical_error "Failed to install $package"
        fi
        echo "✓ $package installed successfully"
    done
}

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
            echo "✓ Marketplace $marketplace_name updated"
        elif claude plugin marketplace add "$marketplace_path"; then
            echo "✓ Marketplace $marketplace_path added"
        else
            add_warning "Failed to configure marketplace $marketplace_path"
        fi
    done
}

# Installs Claude plugins from PLUGINS array
# Uninstalls existing plugins before reinstalling to ensure clean state
install_plugins() {
    echo "Installing Claude plugins..."

    for plugin in "${PLUGINS[@]}"; do
        echo "Processing plugin: $plugin..."

        # Uninstall plugin if it exists (ignore errors)
        echo "Uninstalling $plugin (if exists)..."
        claude plugin uninstall "$plugin" 2>/dev/null || true

        # Install plugin
        echo "Installing $plugin..."
        if ! claude plugin install "$plugin"; then
            add_warning "Failed to install plugin $plugin"
        else
            echo "✓ Plugin $plugin installed successfully"
        fi
    done
}

# Sets up the Playwright skill by running npm setup in its directory
setup_playwright_skill() {
    echo "Setting up Playwright skill..."
    local playwright_dir="$HOME/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill"

    if [ -d "$playwright_dir" ]; then
        echo "Running npm setup in Playwright skill directory..."
        if ! (cd "$playwright_dir" && npm run setup); then
            add_warning "Failed to run npm setup for Playwright skill"
        else
            echo "✓ Playwright skill setup completed"
        fi
    else
        add_warning "Playwright skill directory not found at $playwright_dir, skipping npm setup"
    fi
}

# Copies bin/cl.sh to ~/.local/bin/ and makes it executable
# Warns if ~/.local/bin is not in PATH
copy_bin_files() {
    echo "Copying bin/cl.sh to ~/.local/bin/..."

    if [ ! -f "$SCRIPT_DIR/bin/cl.sh" ]; then
        add_warning "bin/cl.sh not found in script directory, skipping"
        return 0
    fi

    # Create ~/.local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"

    if ! cp "$SCRIPT_DIR/bin/cl.sh" "$HOME/.local/bin/cl.sh"; then
        add_error "Failed to copy bin/cl.sh"
        return 1
    fi

    # Make executable
    chmod +x "$HOME/.local/bin/cl.sh"
    echo "✓ bin/cl.sh copied successfully"

    # Check if ~/.local/bin is in PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        add_warning "~/.local/bin is not in your PATH. Add it by adding this line to your shell config (~/.bashrc or ~/.zshrc): export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Copies .claude folder contents to ~/.claude/
# Skips identical files, reports conflicts for differing files
copy_claude_config() {
    echo "Copying .claude folder contents..."

    if [ ! -d "$SCRIPT_DIR/.claude" ]; then
        add_warning ".claude folder not found in script directory, skipping"
        return 0
    fi

    # Create ~/.claude if it doesn't exist
    mkdir -p "$HOME/.claude"

    # Find all files in .claude (excluding directories)
    while IFS= read -r -d '' source_file; do
        # Get relative path from .claude directory
        local rel_path="${source_file#$SCRIPT_DIR/.claude/}"
        local dest_file="$HOME/.claude/$rel_path"

        # Create destination directory if needed
        local dest_dir
        dest_dir="$(dirname "$dest_file")"
        mkdir -p "$dest_dir"

        # Check if destination file exists
        if [ -f "$dest_file" ]; then
            # File exists, compare
            if diff -q "$source_file" "$dest_file" &>/dev/null; then
                # Files are identical, skip
                echo "  Skipping $rel_path (identical)"
            else
                # Files differ, log error and continue
                add_error "Conflict: $rel_path differs between source and destination. Manual merge required."
            fi
        else
            # File doesn't exist, copy it
            if cp "$source_file" "$dest_file"; then
                echo "  ✓ Copied $rel_path"
            else
                add_error "Failed to copy $rel_path"
            fi
        fi
    done < <(find "$SCRIPT_DIR/.claude" -type f -print0)

    echo "✓ .claude folder processing completed"
}

# Merges JSON configuration files into ~/.claude.json and ~/.claude/settings.json
# - Sets autoCompactEnabled in ~/.claude.json
# - Merges .mcp.json into ~/.claude.json mcpServers (additive only)
# - Merges sandbox-settings.json into ~/.claude/settings.json (recursive overwrite)
merge_json_configs() {
    echo "Updating JSON configurations..."

    # Update ~/.claude.json with autoCompactEnabled
    echo "Setting autoCompactEnabled in ~/.claude.json..."
    if [ ! -f "$HOME/.claude.json" ]; then
        echo '{}' > "$HOME/.claude.json"
    fi

    if jq '. + {"autoCompactEnabled": false}' "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"; then
        echo "✓ autoCompactEnabled set to false"
    else
        add_error "Failed to update autoCompactEnabled in ~/.claude.json"
    fi

    # Merge .mcp.json into ~/.claude.json mcpServers (additive only)
    echo "Merging MCP server configurations..."
    if [ ! -f "$SCRIPT_DIR/.mcp.json" ]; then
        add_warning ".mcp.json not found in script directory, skipping MCP merge"
    else
        # Ensure mcpServers key exists in ~/.claude.json
        if ! jq '.mcpServers //= {}' "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"; then
            add_error "Failed to initialize mcpServers in ~/.claude.json"
        else
            # Get list of keys from source .mcp.json
            local mcp_keys
            mcp_keys=$(jq -r '.mcpServers | keys[]' "$SCRIPT_DIR/.mcp.json" 2>/dev/null)

            if [ -n "$mcp_keys" ]; then
                # Iterate through each key
                while IFS= read -r key; do
                    # Check if key already exists in ~/.claude.json mcpServers
                    if jq -e ".mcpServers | has(\"$key\")" "$HOME/.claude.json" > /dev/null 2>&1; then
                        echo "  Skipping $key (already exists in ~/.claude.json)"
                    else
                        # Add key to mcpServers
                        local server_config
                        server_config=$(jq --arg key "$key" '.mcpServers[$key]' "$SCRIPT_DIR/.mcp.json")
                        if jq --arg key "$key" --argjson config "$server_config" '.mcpServers[$key] = $config' "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"; then
                            echo "  ✓ Added $key to mcpServers"
                        else
                            add_error "Failed to add $key to mcpServers"
                        fi
                    fi
                done <<< "$mcp_keys"

                echo "✓ MCP server configuration merge completed"
            else
                add_warning ".mcp.json is empty or invalid, skipping merge"
            fi
        fi
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
            # Perform recursive merge with overwrite semantics
            # The * operator in jq performs a recursive merge where right-hand side overwrites left
            if jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" "$SCRIPT_DIR/sandbox-settings.json" > "$HOME/.claude/settings.json.tmp" && mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"; then
                echo "✓ Sandbox settings merged successfully (existing keys overwritten)"
            else
                add_error "Failed to merge sandbox-settings.json into ~/.claude/settings.json"
            fi
        fi
    fi
}

# Prepares environment variable configuration instructions
# Populates ENV_VAR_INSTRUCTIONS global variable
prepare_env_instructions() {
    echo "Preparing environment variable configuration..."

    ENV_VAR_INSTRUCTIONS="ENVIRONMENT VARIABLES:
Add the following environment variables to your shell configuration file (~/.bashrc or ~/.zshrc):

export PERPLEXITY_API_KEY=\"your-api-key-here\"
export TAVILY_API_KEY=\"your-api-key-here\"

After adding them, populate them with your actual API keys.
Then reload your shell configuration with: source ~/.bashrc (or source ~/.zshrc)"

    echo "✓ Environment variable instructions prepared"
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

# Check npm prerequisites
echo "Checking prerequisites..."
if ! command -v npm &> /dev/null; then
    critical_error "npm is required but not installed. Please install Node.js and npm first."
fi
echo "✓ npm found: $(npm --version)"
echo ""

# Install jq
install_jq "$OS_TYPE"
echo ""

# Install npm global packages
install_npm_packages
echo ""

# Configure Claude plugin marketplaces
configure_marketplaces
echo ""

# Install Claude plugins
install_plugins
echo ""

# Set up Playwright skill
setup_playwright_skill
echo ""

# Copy configuration files
copy_bin_files
copy_claude_config
echo ""

# Update JSON configurations
merge_json_configs
echo ""

# Prepare environment variable instructions
prepare_env_instructions
echo ""

# Print final summary
print_summary
