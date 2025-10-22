#!/bin/bash

# Script to sync .claude and .devcontainer folders, plus .envrc.example file from origin repository to destination repository
# Usage: ./sync-claude-folders.sh /path/to/origin/repo /path/to/destination/repo

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to print usage
usage() {
    echo "Usage: $0 <origin_repo_path> <destination_repo_path>"
    echo ""
    echo "Syncs .claude and .devcontainer folders, plus .envrc.example file from origin repository to destination repository"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --dry-run  Show what would be synced without making changes"
    echo ""
    echo "Example:"
    echo "  $0 ~/projects/repo1 ~/projects/repo2"
    echo "  $0 -d ~/projects/repo1 ~/projects/repo2  # Dry run"
    exit 1
}

# Parse arguments
DRY_RUN=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if we have exactly 2 arguments (origin and destination)
if [ ${#ARGS[@]} -ne 2 ]; then
    print_color "$RED" "Error: Exactly two repository paths required"
    usage
fi

ORIGIN_REPO="${ARGS[0]}"
DEST_REPO="${ARGS[1]}"

# Remove trailing slashes if present
ORIGIN_REPO="${ORIGIN_REPO%/}"
DEST_REPO="${DEST_REPO%/}"

# Check if origin repository exists
if [ ! -d "$ORIGIN_REPO" ]; then
    print_color "$RED" "Error: Origin repository does not exist: $ORIGIN_REPO"
    exit 1
fi

# Check if destination repository exists
if [ ! -d "$DEST_REPO" ]; then
    print_color "$RED" "Error: Destination repository does not exist: $DEST_REPO"
    exit 1
fi

# Check if at least one of the folders exists in origin
FOLDERS_TO_SYNC=()
if [ -d "$ORIGIN_REPO/.claude" ]; then
    FOLDERS_TO_SYNC+=(".claude")
fi
if [ -d "$ORIGIN_REPO/.devcontainer" ]; then
    FOLDERS_TO_SYNC+=(".devcontainer")
fi

# Check for individual files to sync
FILES_TO_SYNC=()
if [ -f "$ORIGIN_REPO/.envrc.example" ]; then
    FILES_TO_SYNC+=(".envrc.example")
fi

# Check for .mcp.json file (handled separately with merge logic)
MCP_JSON_EXISTS=false
if [ -f "$ORIGIN_REPO/.mcp.json" ]; then
    MCP_JSON_EXISTS=true
    # Check if jq is installed (required for JSON merging)
    if ! command -v jq &> /dev/null; then
        print_color "$RED" "Error: jq is required to merge .mcp.json files but is not installed"
        echo "Please install jq using your package manager:"
        echo "  - Ubuntu/Debian: sudo apt-get install jq"
        echo "  - macOS: brew install jq"
        echo "  - Or visit: https://jqlang.github.io/jq/download/"
        exit 1
    fi
fi

if [ ${#FOLDERS_TO_SYNC[@]} -eq 0 ] && [ ${#FILES_TO_SYNC[@]} -eq 0 ] && [ "$MCP_JSON_EXISTS" = false ]; then
    print_color "$YELLOW" "Warning: Neither .claude, .devcontainer folders nor .envrc.example, .mcp.json files exist in origin repository"
    print_color "$YELLOW" "Nothing to sync."
    exit 0
fi

# Prepare rsync options
RSYNC_OPTS=(
    -av                    # Archive mode (preserves permissions, timestamps, etc.) + verbose
    --delete               # Delete files in dest that don't exist in origin
    --update               # Skip files that are newer on the destination
    --times                # Preserve modification times
    --recursive            # Recurse into directories
    --human-readable       # Human-readable output
    --itemize-changes      # Show what changes are being made
    --exclude='.git'       # Exclude .git folders if any exist within .claude
    --exclude='.DS_Store'  # Exclude macOS metadata files
    --exclude='*.swp'      # Exclude vim swap files
    --exclude='*~'         # Exclude backup files
)

# Add dry-run flag if requested
if [ -n "$DRY_RUN" ]; then
    RSYNC_OPTS+=("$DRY_RUN")
    print_color "$YELLOW" "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Print sync information
SYNC_ITEMS=()
if [ ${#FOLDERS_TO_SYNC[@]} -gt 0 ]; then
    SYNC_ITEMS+=("folders: ${FOLDERS_TO_SYNC[*]}")
fi
if [ ${#FILES_TO_SYNC[@]} -gt 0 ]; then
    SYNC_ITEMS+=("files: ${FILES_TO_SYNC[*]}")
fi
if [ "$MCP_JSON_EXISTS" = true ]; then
    SYNC_ITEMS+=("special: .mcp.json (with merge)")
fi
print_color "$GREEN" "Syncing ${SYNC_ITEMS[*]}"
echo ""

# Sync each folder
SYNC_SUCCESS=true
for FOLDER in "${FOLDERS_TO_SYNC[@]}"; do
    echo "----------------------------------------"
    print_color "$GREEN" "Syncing $FOLDER:"
    echo "  From: $ORIGIN_REPO/$FOLDER/"
    echo "  To:   $DEST_REPO/$FOLDER/"
    echo ""

    # Create directory in destination if it doesn't exist
    if [ ! -d "$DEST_REPO/$FOLDER" ]; then
        if [ -z "$DRY_RUN" ]; then
            mkdir -p "$DEST_REPO/$FOLDER"
            print_color "$GREEN" "Created $FOLDER directory in destination repository"
        else
            print_color "$YELLOW" "Would create $FOLDER directory in destination repository"
        fi
    fi

    # Perform the sync for this folder
    if rsync "${RSYNC_OPTS[@]}" "$ORIGIN_REPO/$FOLDER/" "$DEST_REPO/$FOLDER/"; then
        print_color "$GREEN" "✅ $FOLDER synced successfully"
    else
        EXIT_CODE=$?
        print_color "$RED" "❌ $FOLDER sync failed with exit code: $EXIT_CODE"
        SYNC_SUCCESS=false
    fi
done

# Sync individual files
for FILE in "${FILES_TO_SYNC[@]}"; do
    echo "----------------------------------------"
    print_color "$GREEN" "Syncing $FILE:"
    echo "  From: $ORIGIN_REPO/$FILE"
    echo "  To:   $DEST_REPO/$FILE"
    echo ""

    # Perform the sync for this file
    if rsync "${RSYNC_OPTS[@]}" "$ORIGIN_REPO/$FILE" "$DEST_REPO/$FILE"; then
        print_color "$GREEN" "✅ $FILE synced successfully"
    else
        EXIT_CODE=$?
        print_color "$RED" "❌ $FILE sync failed with exit code: $EXIT_CODE"
        SYNC_SUCCESS=false
    fi
done

# Handle .mcp.json merge (if exists)
if [ "$MCP_JSON_EXISTS" = true ]; then
    echo "----------------------------------------"
    print_color "$GREEN" "Processing .mcp.json:"
    echo "  From: $ORIGIN_REPO/.mcp.json"
    echo "  To:   $DEST_REPO/.mcp.json"
    echo ""

    if [ -f "$DEST_REPO/.mcp.json" ]; then
        # Destination exists - perform deep merge
        print_color "$YELLOW" "Destination .mcp.json exists - performing deep merge (origin takes precedence)"

        if [ -z "$DRY_RUN" ]; then
            # Create temporary file for merged result
            TEMP_MERGED=$(mktemp)

            # Deep merge: destination * origin (origin takes precedence on conflicts)
            if jq -s '.[0] * .[1]' "$DEST_REPO/.mcp.json" "$ORIGIN_REPO/.mcp.json" > "$TEMP_MERGED"; then
                # Validate the merged JSON
                if jq empty "$TEMP_MERGED" 2>/dev/null; then
                    mv "$TEMP_MERGED" "$DEST_REPO/.mcp.json"
                    print_color "$GREEN" "✅ .mcp.json merged successfully"
                else
                    print_color "$RED" "❌ .mcp.json merge produced invalid JSON"
                    rm -f "$TEMP_MERGED"
                    SYNC_SUCCESS=false
                fi
            else
                print_color "$RED" "❌ .mcp.json merge failed"
                rm -f "$TEMP_MERGED"
                SYNC_SUCCESS=false
            fi
        else
            print_color "$YELLOW" "Would merge .mcp.json files (origin MCP servers added to destination)"
        fi
    else
        # Destination doesn't exist - simple copy
        print_color "$YELLOW" "Destination .mcp.json doesn't exist - copying from origin"

        if [ -z "$DRY_RUN" ]; then
            if cp "$ORIGIN_REPO/.mcp.json" "$DEST_REPO/.mcp.json"; then
                print_color "$GREEN" "✅ .mcp.json copied successfully"
            else
                print_color "$RED" "❌ .mcp.json copy failed"
                SYNC_SUCCESS=false
            fi
        else
            print_color "$YELLOW" "Would copy .mcp.json from origin to destination"
        fi
    fi
fi

echo "----------------------------------------"
if [ "$SYNC_SUCCESS" = true ]; then
    if [ -n "$DRY_RUN" ]; then
        print_color "$GREEN" "Dry run completed successfully!"
        echo "Run without -d/--dry-run flag to apply these changes."
    else
        print_color "$GREEN" "All synchronization completed successfully!"
    fi
else
    print_color "$RED" "Some synchronizations failed. Please check the output above."
    exit 1
fi

# Optional: Show summary of what was synced
echo ""
print_color "$GREEN" "Summary:"
echo "  Origin: $ORIGIN_REPO"
echo "  Destination: $DEST_REPO"
if [ ${#FOLDERS_TO_SYNC[@]} -gt 0 ]; then
    echo "  Synced folders: ${FOLDERS_TO_SYNC[*]}"
fi
if [ ${#FILES_TO_SYNC[@]} -gt 0 ]; then
    echo "  Synced files: ${FILES_TO_SYNC[*]}"
fi
if [ "$MCP_JSON_EXISTS" = true ]; then
    echo "  Merged/copied: .mcp.json"
fi

# If not dry run, show the current state of synced folders
if [ -z "$DRY_RUN" ]; then
    for FOLDER in "${FOLDERS_TO_SYNC[@]}"; do
        if [ -d "$DEST_REPO/$FOLDER" ]; then
            if command -v tree &> /dev/null; then
                echo ""
                print_color "$GREEN" "Current $FOLDER structure in destination:"
                tree -L 2 "$DEST_REPO/$FOLDER/" 2>/dev/null || ls -la "$DEST_REPO/$FOLDER/"
            else
                echo ""
                print_color "$GREEN" "Current $FOLDER contents in destination:"
                ls -la "$DEST_REPO/$FOLDER/"
            fi
        fi
    done
fi
