#!/bin/bash

set -e

echo "🐳 Setting up devcontainer environment..."

# Update package lists and install system packages (Linux only)
echo "📦 Installing system packages..."
sudo apt-get update -y
sudo apt-get install -y direnv\
         libglib2.0-0t64\
         libdbus-1-3\
         libatk1.0-0t64\
         libatk-bridge2.0-0t64\
         libcups2t64\
         libxkbcommon0\
         libatspi2.0-0t64\
         libxcomposite1\
         libxdamage1\
         libxfixes3\
         libxrandr2\
         libgbm1\
         libcairo2\
         libpango-1.0-0\
         libasound2t64

echo "🌍 Configuring direnv for container user..."
# Configure direnv for bash (backup shell)
echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc

# Configure direnv for zsh (default shell)
echo 'eval "$(direnv hook zsh)"' >> /home/vscode/.zshrc

# Auto-allow the .envrc file in the project root (container-specific path)
if [ -f "/workspaces/$(basename $(pwd))/.envrc" ]; then
    direnv allow "/workspaces/$(basename $(pwd))/.envrc"
    echo "📄 Auto-allowed .envrc file"
else
    echo "ℹ️  No .envrc file found, skipping auto-allow"
fi

echo "✅ Devcontainer-specific setup completed!"
echo "🔄 Running general Claude development setup..."

# Call the cross-platform setup script
bash .devcontainer/setup-claude-dev.sh
