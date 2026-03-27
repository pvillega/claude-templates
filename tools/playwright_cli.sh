#!/usr/bin/env bash

# Playwright CLI - install, update, and uninstall via npm
# Requires: critical_error, add_warning functions from parent script

_npm_install_playwright_cli() {
    if npm install -g @playwright/cli@latest 2>/dev/null; then
        return 0
    fi
    echo "Retrying with sudo..."
    if sudo npm install -g @playwright/cli@latest; then
        return 0
    fi
    return 1
}

install_playwright_cli() {
    echo "Checking for Playwright CLI..."

    if npm list -g @playwright/cli &> /dev/null; then
        echo "Playwright CLI already installed"
        return 0
    fi

    echo "Playwright CLI not found. Installing..."
    if ! _npm_install_playwright_cli; then
        critical_error "Failed to install @playwright/cli"
    fi

    echo "Playwright CLI installed successfully"

    echo "Installing required browsers (Firefox, WebKit)..."
    playwright-cli install-browser firefox || add_warning "Failed to install Firefox browser"
    playwright-cli install-browser webkit || add_warning "Failed to install WebKit browser"
}

update_playwright_cli() {
    echo "Updating Playwright CLI..."

    if ! npm list -g @playwright/cli &> /dev/null; then
        add_warning "Playwright CLI is not installed, skipping update"
        return 0
    fi

    if _npm_install_playwright_cli; then
        echo "Playwright CLI updated successfully"
    else
        add_warning "Failed to update Playwright CLI"
    fi
}

uninstall_playwright_cli() {
    echo "Removing Playwright CLI..."

    echo "Removing installed browsers (Firefox, WebKit)..."
    playwright-cli uninstall-browser firefox 2>/dev/null || true
    playwright-cli uninstall-browser webkit 2>/dev/null || true

    if ! npm uninstall -g @playwright/cli 2>/dev/null; then
        sudo npm uninstall -g @playwright/cli 2>/dev/null || add_warning "Failed to uninstall @playwright/cli"
    fi

    echo "Playwright CLI removal complete"
}
