#!/bin/bash

set -e

echo "🦀 Installing Rust development tools..."

# Install Rust cargo tools
echo "📦 Installing cargo tools (cargo-watch, cargo-edit, cargo-audit, difftastic)..."
cargo install cargo-watch cargo-edit cargo-audit
cargo install --locked difftastic

# Add Rust components
echo "🔧 Adding Rust components (clippy and rustfmt)..."
rustup component add clippy rustfmt

echo "✅ Rust development tools installed successfully!"
