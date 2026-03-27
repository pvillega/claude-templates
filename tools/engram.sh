#!/usr/bin/env bash
# engram - Persistent memory for AI coding agents (https://github.com/Gentleman-Programming/engram)
# Requires: OS_TYPE variable set to "macos" or "linux"
# Requires: critical_error, add_warning functions from parent script

_install_engram_from_github() {
    local os_type="${1:-$OS_TYPE}"
    local os arch
    if [ "$os_type" = "macos" ]; then
        os="darwin"
    else
        os="linux"
    fi
    local machine
    machine=$(uname -m)
    if [ "$machine" = "x86_64" ]; then
        arch="amd64"
    elif [ "$machine" = "arm64" ] || [ "$machine" = "aarch64" ]; then
        arch="arm64"
    else
        critical_error "Unsupported architecture: $machine"
    fi
    local latest_version
    latest_version=$(curl -fsSL "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -z "$latest_version" ]; then
        critical_error "Failed to determine latest engram version from GitHub"
    fi
    local tarball="engram_${os}_${arch}.tar.gz"
    local download_url="https://github.com/Gentleman-Programming/engram/releases/download/${latest_version}/${tarball}"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    echo "Downloading engram ${latest_version} from GitHub..."
    if ! curl -fsSL "$download_url" -o "${tmp_dir}/${tarball}"; then
        rm -rf "$tmp_dir"
        critical_error "Failed to download engram from $download_url"
    fi
    if ! tar -xzf "${tmp_dir}/${tarball}" -C "$tmp_dir"; then
        rm -rf "$tmp_dir"
        critical_error "Failed to extract engram tarball"
    fi
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    if ! mv "${tmp_dir}/engram" "$install_dir/engram"; then
        rm -rf "$tmp_dir"
        critical_error "Failed to install engram binary to $install_dir"
    fi
    chmod +x "$install_dir/engram"
    rm -rf "$tmp_dir"
    echo "engram installed to $install_dir/engram"
}

install_engram() {
    echo "Checking for engram..."
    if command -v engram &> /dev/null; then
        echo "engram already installed: $(engram --version 2>/dev/null || echo 'version unknown')"
        return 0
    fi
    echo "engram not found. Installing engram..."
    local os_type="${1:-$OS_TYPE}"
    if command -v brew &> /dev/null; then
        echo "Installing engram via Homebrew..."
        if ! brew install gentleman-programming/tap/engram; then
            critical_error "Failed to install engram via Homebrew"
        fi
    else
        echo "Homebrew not found, installing engram from GitHub releases..."
        _install_engram_from_github "$os_type"
    fi
    if ! command -v engram &> /dev/null; then
        critical_error "engram installation appeared to succeed but engram command is still not available"
    fi
    echo "engram installed successfully: $(engram --version 2>/dev/null || echo 'version unknown')"
}

update_engram() {
    echo "Updating engram..."
    if ! command -v engram &> /dev/null; then
        add_warning "engram is not installed, skipping update"
        return 0
    fi
    if command -v brew &> /dev/null; then
        brew upgrade gentleman-programming/tap/engram 2>/dev/null || echo "engram already up to date"
    else
        echo "Updating engram from GitHub releases..."
        _install_engram_from_github 2>/dev/null || add_warning "Failed to update engram from GitHub releases"
    fi
    echo "engram update complete"
}

uninstall_engram() {
    echo "Removing engram..."
    if ! command -v engram &> /dev/null; then
        echo "engram is not installed, nothing to remove"
        return 0
    fi
    if command -v brew &> /dev/null; then
        brew uninstall gentleman-programming/tap/engram 2>/dev/null || add_warning "Failed to uninstall engram via Homebrew"
    else
        local engram_path
        engram_path=$(command -v engram 2>/dev/null)
        if [ -n "$engram_path" ]; then
            rm -f "$engram_path" 2>/dev/null || add_warning "Failed to remove engram binary at $engram_path"
            echo "  Removed $engram_path"
        else
            add_warning "Cannot find engram binary to remove."
        fi
    fi
    echo "engram removal complete"
}
