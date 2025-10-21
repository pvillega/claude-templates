#!/bin/bash

set -e

echo "🐍 Installing Python development tools..."

# Install Python uv package manager via pipx
echo "📦 Installing uv via pipx..."
pipx install uv

echo "✅ Python development tools installed successfully!"
