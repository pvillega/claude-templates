# .NET Setup Script Design

## Overview

Create a modular setup script for .NET development tools that follows the established pattern of language-specific setup scripts (setup-go.sh, setup-rust.sh) in the .devcontainer directory.

## Requirements

- Install .NET 9 SDK (latest stable)
- Install code quality tools only (no EF, no testing tools)
- Include verification steps to confirm successful installation
- Follow existing script patterns (emoji output, error handling, clear progress)

## Technical Approach

### File Location
`.devcontainer/setup-dotnet.sh` - Executable bash script

### Installation Method

**SDK Installation:**
- Use Microsoft's official installation script from https://dot.net/v1/dotnet-install.sh
- Install .NET 9 using `--channel 9.0` flag
- Use default system location for SDK (automatic PATH configuration)

**Global Tools Installation:**
Use `dotnet tool install --global` for:
1. **csharpier** - Opinionated code formatter
2. **dotnet-outdated-tool** - Check for outdated NuGet packages

Note: `dotnet-format` is built into .NET SDK 6+ so no separate installation needed.

### Script Structure

```bash
#!/bin/bash
set -e  # Exit on any error

# 1. Install .NET SDK
#    - Download official installer
#    - Run with --channel 9.0

# 2. Install global tools
#    - dotnet tool install --global csharpier
#    - dotnet tool install --global dotnet-outdated-tool

# 3. Verification
#    - Check dotnet --version
#    - Verify tools in dotnet tool list --global
#    - Print success message with versions
```

### Error Handling
- `set -e` ensures script exits on first failure
- Each step has clear echo messages with emojis (🔧, 📦, ✅)
- Verification step catches installation issues before use

### Output Style
Consistent with other setup scripts:
- 🔧 for general setup messages
- 📦 for package installation
- ✅ for success confirmation

## Verification Steps

1. Run `dotnet --version` to confirm SDK installation
2. Run `dotnet tool list --global` to verify global tools
3. Print final success message with installed component versions

## Integration

- Script will be listed in README.md alongside setup-rust.sh and setup-go.sh
- Can be run standalone after devcontainer creation
- No dependencies on other setup scripts
