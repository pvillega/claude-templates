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

echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "🔧 Configuring additional MCP servers..."

# Add MCP server configurations to .claude.json from default.mcp.json
if [ -f "/home/vscode/.claude.json" ]; then
    # Check if default.mcp.json exists in the workspace
    if [ -f "/workspaces/$(basename $(pwd))/default.mcp.json" ]; then
        # Use jq to merge MCP servers from default.mcp.json into .claude.json
        jq -s '.[0] * {mcpServers: (.[0].mcpServers * .[1].mcpServers)}' \
            /home/vscode/.claude.json \
            /workspaces/$(basename $(pwd))/default.mcp.json > /tmp/.claude.json.tmp && \
            mv /tmp/.claude.json.tmp /home/vscode/.claude.json

        echo "✅ MCP server configurations merged from default.mcp.json successfully!"
    else
        echo "⚠️  default.mcp.json not found in workspace, skipping MCP server merge"
    fi

    # Add autoCompactEnabled setting
    jq '. + {"autoCompactEnabled": false}' /home/vscode/.claude.json > /tmp/.claude.json.tmp && \
        mv /tmp/.claude.json.tmp /home/vscode/.claude.json
    echo "✅ Added autoCompactEnabled setting to .claude.json!"
else
    echo "⚠️  .claude.json not found, skipping MCP server configuration"
fi

echo "✅ Devcontainer setup completed successfully!"
