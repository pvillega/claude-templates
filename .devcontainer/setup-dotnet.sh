#!/bin/bash

set -e

echo "🔧 Installing .NET development tools..."

# Install .NET SDK 9 (latest stable)
echo "📦 Installing .NET 9 SDK..."
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 9.0

# Ensure dotnet is in PATH for this session
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

# Install global .NET tools for code quality
echo "📦 Installing code quality tools..."
dotnet tool install --global csharpier
dotnet tool install --global dotnet-outdated-tool

# Verification
echo "🔍 Verifying installation..."
echo "SDK Version:"
dotnet --version

echo ""
echo "Installed Global Tools:"
dotnet tool list --global

echo "✅ .NET development tools installed successfully!"
