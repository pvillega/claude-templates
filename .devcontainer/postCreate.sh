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

echo "📦 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "🔧 Installing GolangCI-Lint..."
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

echo "🦀 Installing Rust development tools..."
cargo install cargo-watch cargo-edit cargo-audit

echo "🔧 Adding Rust components (clippy and rustfmt)..."
rustup component add clippy rustfmt 

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

echo "✅ Devcontainer setup completed successfully!"
