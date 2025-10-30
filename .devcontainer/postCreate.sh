#!/bin/bash

set -e

echo "🚀 Setting up development environment..."

# Update package lists
sudo apt-get update -y
sudo apt-get install -y \
    make \
    curl \
    wget \
    jq \
    tree \
    htop \
    direnv

echo "🌍 Configuring direnv..."
# Configure direnv for bash (backup shell)
echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc

# Configure direnv for zsh (default shell)
echo 'eval "$(direnv hook zsh)"' >> /home/vscode/.zshrc

# Auto-allow the .envrc file in the project root
if [ -f "/workspaces/$(basename $(pwd))/.envrc" ]; then
    direnv allow "/workspaces/$(basename $(pwd))/.envrc"
    echo "📄 Auto-allowed .envrc file"
else
    echo "ℹ️  No .envrc file found, skipping auto-allow"
fi

echo "📦 Installing uv via pipx, needed for some MCP..."
pipx install uv

echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

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
if [ -d "$HOME/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill" ]; then
    cd "$HOME/.claude/plugins/marketplaces/playwright-skill/skills/playwright-skill"
    npm run setup
    echo "  ✅ Playwright skill setup completed!"
else
    echo "  ⚠️  Playwright skill directory not found, skipping setup"
fi
cd /workspaces/$(basename $(pwd))

echo "🔧 Configuring Claude settings..."

if [ -f "/home/vscode/.claude.json" ]; then
    # Add autoCompactEnabled setting
    jq '. + {"autoCompactEnabled": false}' /home/vscode/.claude.json > /tmp/.claude.json.tmp && \
        mv /tmp/.claude.json.tmp /home/vscode/.claude.json
    echo "✅ Added autoCompactEnabled setting to .claude.json!"
else
    echo "⚠️  .claude.json not found, skipping configuration"
fi

echo "✅ Devcontainer setup completed successfully!"
