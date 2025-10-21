#!/bin/bash

set -e

echo "🔧 Installing Go development tools..."

# Install GolangCI-Lint for Go code quality checking
echo "📦 Installing GolangCI-Lint..."
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

echo "✅ Go development tools installed successfully!"
