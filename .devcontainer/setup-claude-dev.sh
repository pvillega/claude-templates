#!/bin/bash

set -e

echo "🚀 Setting up Claude development environment..."

# Detect OS
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="macOS";;
    *)          echo "❌ Unsupported OS: $OS_TYPE"; exit 1;;
esac

echo "🖥️  Detected OS: $OS"

# Check for Homebrew on macOS
if [ "$OS" = "macOS" ]; then
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install from https://brew.sh"
        exit 1
    fi
    echo "✅ Homebrew found"
fi

# Install system packages
echo "📦 Installing system packages..."
if [ "$OS" = "Linux" ]; then
    sudo apt-get update -y
    sudo apt-get install -y \
        make \
        curl \
        wget \
        jq \
        tree \
        htop \
        direnv
elif [ "$OS" = "macOS" ]; then
    # Install packages via Homebrew
    # make, curl, wget are typically pre-installed on macOS
    brew install jq tree htop direnv 2>/dev/null || true
fi

# Configure shell environment (direnv + PATH)
echo "🌍 Configuring shell environment..."
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

# Configure .bashrc
if [ -f "$BASHRC" ]; then
    # Add direnv hook if not already present
    if ! grep -q 'direnv hook bash' "$BASHRC"; then
        echo 'eval "$(direnv hook bash)"' >> "$BASHRC"
        echo "  ✅ Added direnv hook to .bashrc"
    else
        echo "  ℹ️  direnv hook already in .bashrc"
    fi

    # Add ~/.local/bin to PATH on Linux if not already present
    if [ "$OS" = "Linux" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$BASHRC"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
            echo "  ✅ Added ~/.local/bin to PATH in .bashrc"
        else
            echo "  ℹ️  ~/.local/bin already in PATH in .bashrc"
        fi
    fi
fi

# Configure .zshrc
if [ -f "$ZSHRC" ]; then
    # Add direnv hook if not already present
    if ! grep -q 'direnv hook zsh' "$ZSHRC"; then
        echo 'eval "$(direnv hook zsh)"' >> "$ZSHRC"
        echo "  ✅ Added direnv hook to .zshrc"
    else
        echo "  ℹ️  direnv hook already in .zshrc"
    fi

    # Add ~/.local/bin to PATH on Linux if not already present
    if [ "$OS" = "Linux" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
            echo "  ✅ Added ~/.local/bin to PATH in .zshrc"
        else
            echo "  ℹ️  ~/.local/bin already in PATH in .zshrc"
        fi
    fi
fi

# Auto-allow .envrc file in current directory if it exists
if [ -f "$(pwd)/.envrc" ]; then
    direnv allow "$(pwd)/.envrc"
    echo "📄 Auto-allowed .envrc file"
else
    echo "ℹ️  No .envrc file found in current directory, skipping auto-allow"
fi

# Install uv
echo "📦 Installing uv..."
if command -v uv &> /dev/null; then
    echo "  ℹ️  uv already installed"
else
    if [ "$OS" = "Linux" ]; then
        # Use standalone installer for Linux (no native apt package available)
        curl -LsSf https://astral.sh/uv/install.sh | sh
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        echo "  ✅ uv installed via standalone installer"
    elif [ "$OS" = "macOS" ]; then
        # Use Homebrew for macOS
        brew install uv
        echo "  ✅ uv installed via Homebrew"
    fi
fi

echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "📋 Installing jscpd (copy-paste detector)..."
npm install -g jscpd

echo "🔌 Installing Claude Code plugins..."

echo "  📦 Adding superpowers marketplace..."
claude plugin marketplace add obra/superpowers-marketplace || echo "  ℹ️  Marketplace already added"

echo "  ⚡ Installing superpowers plugin..."
claude plugin install superpowers@superpowers-marketplace || echo "  ℹ️  Plugin already installed"

# Verify installation
if claude plugin marketplace list 2>/dev/null | grep -q "superpowers-marketplace"; then
    echo "  ✅ Superpowers plugin installed successfully!"
else
    echo "  ⚠️  Plugin installation may have failed"
fi

echo "  🎭 Installing playwright skill..."
claude plugin marketplace add lackeyjb/playwright-skill || echo "  ℹ️  Marketplace already added"
claude plugin install playwright-skill@playwright-skill || echo "  ℹ️  Plugin already installed"

# Run setup for playwright skill
PLAYWRIGHT_SKILL_DIR="$HOME/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill"
if [ -d "$PLAYWRIGHT_SKILL_DIR" ]; then
    cd "$PLAYWRIGHT_SKILL_DIR"
    npm run setup
    echo "  ✅ Playwright skill setup completed!"
    cd - > /dev/null
else
    echo "  ⚠️  Playwright skill directory not found, skipping setup"
fi

echo "🔧 Configuring Claude settings..."

CLAUDE_CONFIG="$HOME/.claude.json"
if [ -f "$CLAUDE_CONFIG" ]; then
    # Add autoCompactEnabled setting
    jq '. + {"autoCompactEnabled": false}' "$CLAUDE_CONFIG" > /tmp/.claude.json.tmp && \
        mv /tmp/.claude.json.tmp "$CLAUDE_CONFIG"
    echo "  ✅ Added autoCompactEnabled setting to .claude.json!"
else
    echo "  ⚠️  .claude.json not found, skipping configuration"
fi

echo "✅ Claude development setup completed successfully on $OS!"
