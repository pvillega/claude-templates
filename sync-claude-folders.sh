#!/bin/bash

# Script to sync .claude folder from origin repository to destination repository
# Usage: ./sync-claude.sh /path/to/origin/repo /path/to/destination/repo

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
    echo "Syncs the .claude folder from origin repository to destination repository"
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

# Check if .claude folder exists in origin
if [ ! -d "$ORIGIN_REPO/.claude" ]; then
    print_color "$YELLOW" "Warning: .claude folder does not exist in origin repository: $ORIGIN_REPO/.claude"
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
print_color "$GREEN" "Syncing .claude folder:"
echo "  From: $ORIGIN_REPO/.claude/"
echo "  To:   $DEST_REPO/.claude/"
echo ""

# Create .claude directory in destination if it doesn't exist
if [ ! -d "$DEST_REPO/.claude" ]; then
    if [ -z "$DRY_RUN" ]; then
        mkdir -p "$DEST_REPO/.claude"
        print_color "$GREEN" "Created .claude directory in destination repository"
    else
        print_color "$YELLOW" "Would create .claude directory in destination repository"
    fi
fi

# Perform the sync
print_color "$GREEN" "Starting synchronization..."
echo "----------------------------------------"

# Run rsync and capture the exit code
if rsync "${RSYNC_OPTS[@]}" "$ORIGIN_REPO/.claude/" "$DEST_REPO/.claude/"; then
    echo "----------------------------------------"
    if [ -n "$DRY_RUN" ]; then
        print_color "$GREEN" "Dry run completed successfully!"
        echo "Run without -d/--dry-run flag to apply these changes."
    else
        print_color "$GREEN" "Synchronization completed successfully!"
    fi
else
    EXIT_CODE=$?
    echo "----------------------------------------"
    print_color "$RED" "Synchronization failed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
fi

# Optional: Show summary of what was synced
echo ""
print_color "$GREEN" "Summary:"
echo "  Origin: $ORIGIN_REPO/.claude/"
echo "  Destination: $DEST_REPO/.claude/"

# If not dry run, show the current state
if [ -z "$DRY_RUN" ]; then
    if command -v tree &> /dev/null; then
        echo ""
        print_color "$GREEN" "Current .claude folder structure in destination:"
        tree -L 2 "$DEST_REPO/.claude/" 2>/dev/null || ls -la "$DEST_REPO/.claude/"
    else
        echo ""
        print_color "$GREEN" "Current .claude folder contents in destination:"
        ls -la "$DEST_REPO/.claude/"
    fi
fi
