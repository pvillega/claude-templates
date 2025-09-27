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

echo "🔧 Installing Python uv..."
pipx install uv

echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "🔧 Installing SuperClaude..."
pipx install SuperClaude
printf "1,2,3,4,5,6,7\n" | SuperClaude install --yes --auto-update --components agents commands core mcp mcp_docs modes

echo "🔧 Installing GolangCI-Lint..."
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

echo "🦀 Installing Rust development tools..."
cargo install cargo-watch cargo-edit cargo-audit
cargo install --locked difftastic

echo "🔧 Adding Rust components (clippy and rustfmt)..."
rustup component add clippy rustfmt

echo "🔧 Configuring additional MCP servers..."

# Add MCP server configurations to .claude.json
if [ -f "/home/vscode/.claude.json" ]; then
    # Create a temporary file with the new MCP servers to add
    cat > /tmp/mcp_servers_to_add.json << 'EOF'
{
    "perplexity-ask": {
        "type": "stdio",
        "command": "npx",
        "args": [
            "-y",
            "server-perplexity-ask"
        ],
        "env": {
            "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"
        }
    },
    "deepwiki": {
        "command": "npx",
        "args": [
            "-y",
            "mcp-deepwiki@latest"
        ]
    }
}
EOF

    # Use jq to merge the new servers into the existing configuration
    jq '.mcpServers += input' /home/vscode/.claude.json /tmp/mcp_servers_to_add.json > /tmp/.claude.json.tmp && \
        mv /tmp/.claude.json.tmp /home/vscode/.claude.json

    # Clean up temporary file
    rm -f /tmp/mcp_servers_to_add.json

    echo "✅ MCP server configurations added successfully!"
else
    echo "⚠️  .claude.json not found, skipping MCP server configuration"
fi

echo "✅ Devcontainer setup completed successfully!"
