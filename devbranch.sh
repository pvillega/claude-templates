#!/bin/bash

# devbranch - Automated branch management for parallel feature development
# Usage: ./devbranch <branch-name> [options]

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to print usage
usage() {
    cat << EOF
Usage: $0 <branch-name> [options]
       $0 --list
       $0 --clean <branch-name>
       $0 --clean-merged

Automated branch management for parallel feature development.
Creates isolated git clones for each branch in sibling directories.

Commands:
  <branch-name>           Create/open branch in sibling directory
  --list                  List all branch directories with merge status
  --clean <branch-name>   Remove specific branch directory
  --clean-merged          Remove all merged branch directories

Options:
  -h, --help              Show this help message
  -d, --dry-run           Preview operations without making changes
  -n, --no-open           Skip opening VS Code after setup

Examples:
  $0 feature-auth                    # Create branch in sibling directory
  $0 feature-auth --dry-run          # Preview creation
  $0 --list                          # List all branch directories with merge status
  $0 --clean feature-auth            # Remove specific branch directory
  $0 --clean-merged                  # Remove all merged branches (with confirmation)
  $0 --clean-merged --dry-run        # Preview which branches would be removed

Directory structure:
  If current project is at: /path/to/project
  Branch directory created: /path/to/project-<branch-name>

Requirements:
  - git
  - code command (VS Code CLI, optional)

EOF
    exit 1
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local warnings=()

    print_color "$BLUE" "Checking dependencies..."

    # Check git
    if command_exists git; then
        print_color "$GREEN" "✓ git found"
    else
        missing_deps+=("git")
    fi

    # Check VS Code CLI (warning only)
    if command_exists code; then
        print_color "$GREEN" "✓ code command found"
    else
        warnings+=("code (VS Code CLI)")
    fi

    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        print_color "$RED" "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                git)
                    echo "  - git: Install from https://git-scm.com/"
                    ;;
            esac
        done
        return 1
    fi

    # Report warnings
    if [ ${#warnings[@]} -gt 0 ]; then
        echo ""
        print_color "$YELLOW" "Warnings:"
        for warning in "${warnings[@]}"; do
            case $warning in
                "code (VS Code CLI)")
                    echo "  - code command not found (VS Code opening will be manual)"
                    ;;
            esac
        done
    fi

    echo ""
    return 0
}

# Get git repository information
get_repo_info() {
    # Check if in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        print_color "$RED" "Error: Not in a git repository"
        echo "Please run this command from within a git repository"
        exit 1
    fi

    # Get repository root
    REPO_ROOT=$(git rev-parse --show-toplevel)

    # Get project name (directory name)
    PROJECT_NAME=$(basename "$REPO_ROOT")

    # Get parent directory
    PARENT_DIR=$(dirname "$REPO_ROOT")

    # Get remote URL
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

    if [ -z "$REMOTE_URL" ]; then
        print_color "$RED" "Error: No remote origin configured"
        echo "Please configure a remote origin first: git remote add origin <url>"
        exit 1
    fi
}

# Detect the default branch (main or master)
get_default_branch() {
    local repo_dir=$1

    # Try to get remote default branch
    local default_branch=$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [ -n "$default_branch" ]; then
        echo "$default_branch"
        return 0
    fi

    # Fallback: check if main exists
    if git -C "$repo_dir" show-ref --verify --quiet refs/heads/main; then
        echo "main"
        return 0
    fi

    # Fallback: check if master exists
    if git -C "$repo_dir" show-ref --verify --quiet refs/heads/master; then
        echo "master"
        return 0
    fi

    # Default to main if nothing found
    echo "main"
}

# Check if a branch is merged into the default branch
is_branch_merged() {
    local repo_dir=$1
    local branch_name=$2
    local default_branch=$3

    # Change to repo directory
    cd "$repo_dir" || return 1

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        cd - > /dev/null
        return 1
    fi

    # Check if default branch exists
    if ! git show-ref --verify --quiet "refs/heads/$default_branch"; then
        cd - > /dev/null
        return 1
    fi

    # Use merge-base to check if branch is ancestor of default branch
    if git merge-base --is-ancestor "$branch_name" "$default_branch" 2>/dev/null; then
        cd - > /dev/null
        return 0
    fi

    cd - > /dev/null
    return 1
}

# List branch directories
list_directories() {
    get_repo_info

    print_color "$BLUE" "Branch directories for '$PROJECT_NAME':"
    echo ""

    # Detect default branch from main repo
    local default_branch=$(get_default_branch "$REPO_ROOT")

    # Find all directories matching the pattern
    local found=0
    local merged_count=0
    for dir in "$PARENT_DIR"/"$PROJECT_NAME"-*; do
        if [ -d "$dir" ]; then
            found=$((found + 1))
            local branch_name=$(basename "$dir" | sed "s/^${PROJECT_NAME}-//")

            # Check if it's a git repo and get current branch
            local merge_status=""
            if [ -d "$dir/.git" ]; then
                local current_branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

                if [ -n "$current_branch" ]; then
                    # Check if branch is merged
                    if is_branch_merged "$dir" "$current_branch" "$default_branch"; then
                        merge_status="${GREEN}[MERGED ✓]${NC}"
                        merged_count=$((merged_count + 1))
                    else
                        merge_status="${BLUE}[ACTIVE]${NC}"
                    fi
                fi
            fi

            echo -e "  ${GREEN}${branch_name}${NC} ${merge_status}"
            echo "  └─ $dir"
            echo ""
        fi
    done

    if [ $found -eq 0 ]; then
        print_color "$YELLOW" "No branch directories found"
        echo "Create one with: $0 <branch-name>"
    else
        print_color "$GREEN" "Total: $found branch director(ies)"
        if [ $merged_count -gt 0 ]; then
            print_color "$YELLOW" "Merged: $merged_count branch(es) can be cleaned up"
            echo "Run: $0 --clean-merged"
        fi
    fi
}

# Clean up branch directory
clean_directory() {
    local branch_name=$1
    get_repo_info

    local target_dir="$PARENT_DIR/${PROJECT_NAME}-${branch_name}"

    if [ ! -d "$target_dir" ]; then
        print_color "$RED" "Error: Branch directory not found: $target_dir"
        exit 1
    fi

    print_color "$YELLOW" "Cleaning up branch directory:"
    echo "  Branch: $branch_name"
    echo "  Location: $target_dir"
    echo ""

    # Confirm deletion
    if [ -z "$DRY_RUN" ]; then
        echo ""
        print_color "$YELLOW" "⚠️  This will permanently delete: $target_dir"
        read -p "Continue? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Cleanup cancelled"
            exit 0
        fi
    fi

    # Remove directory
    print_color "$YELLOW" "Removing directory..."
    if [ -z "$DRY_RUN" ]; then
        rm -rf "$target_dir"
        print_color "$GREEN" "✓ Directory removed"
    else
        print_color "$YELLOW" "Would remove directory: $target_dir"
    fi

    echo ""
    print_color "$GREEN" "✅ Branch directory cleaned up successfully!"
}

# Clean up all merged branch directories
clean_merged_directories() {
    get_repo_info

    print_color "$BLUE" "Finding merged branch directories..."
    echo ""

    # Detect default branch from main repo
    local default_branch=$(get_default_branch "$REPO_ROOT")
    print_color "$BLUE" "Using default branch: $default_branch"
    echo ""

    # Find all merged directories
    local merged_dirs=()
    local merged_branches=()

    for dir in "$PARENT_DIR"/"$PROJECT_NAME"-*; do
        if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
            local branch_name=$(basename "$dir" | sed "s/^${PROJECT_NAME}-//")
            local current_branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

            if [ -n "$current_branch" ]; then
                if is_branch_merged "$dir" "$current_branch" "$default_branch"; then
                    merged_dirs+=("$dir")
                    merged_branches+=("$branch_name")
                fi
            fi
        fi
    done

    # Check if any merged branches found
    if [ ${#merged_dirs[@]} -eq 0 ]; then
        print_color "$GREEN" "No merged branch directories found"
        echo "All branch directories are still active"
        exit 0
    fi

    # Display merged branches
    print_color "$YELLOW" "Found ${#merged_dirs[@]} merged branch(es):"
    echo ""
    for i in "${!merged_branches[@]}"; do
        echo -e "  ${GREEN}${merged_branches[$i]}${NC} [MERGED ✓]"
        echo "  └─ ${merged_dirs[$i]}"
        echo ""
    done

    # Confirm deletion
    if [ -z "$DRY_RUN" ]; then
        echo ""
        print_color "$YELLOW" "⚠️  This will permanently delete ${#merged_dirs[@]} director(ies)"
        read -p "Continue? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Cleanup cancelled"
            exit 0
        fi
    fi

    # Remove directories
    print_color "$YELLOW" "Removing directories..."
    local removed_count=0
    for i in "${!merged_dirs[@]}"; do
        if [ -z "$DRY_RUN" ]; then
            rm -rf "${merged_dirs[$i]}"
            print_color "$GREEN" "✓ Removed: ${merged_branches[$i]}"
            removed_count=$((removed_count + 1))
        else
            print_color "$YELLOW" "Would remove: ${merged_dirs[$i]}"
        fi
    done

    echo ""
    if [ -z "$DRY_RUN" ]; then
        print_color "$GREEN" "✅ Successfully removed $removed_count merged branch director(ies)!"
    else
        print_color "$YELLOW" "DRY RUN: Would remove ${#merged_dirs[@]} director(ies)"
    fi
}

# Create branch directory
create_directory() {
    local branch_name=$1
    get_repo_info

    local target_dir="$PARENT_DIR/${PROJECT_NAME}-${branch_name}"

    print_color "$BLUE" "Creating branch directory..."
    echo "  Source: $REPO_ROOT"
    echo "  Target: $target_dir"
    echo "  Branch: $branch_name"
    echo ""

    # Check if target directory exists
    if [ -d "$target_dir" ]; then
        if [ -z "$DRY_RUN" ]; then
            print_color "$YELLOW" "⚠️  Directory already exists: $target_dir"
            echo "Options:"
            echo "  [O]verwrite - Delete and create fresh"
            echo "  [U]se existing - Skip clone, just open"
            echo "  [A]bort - Cancel operation"
            read -p "Choose [O/U/A]: " -n 1 -r
            echo ""
            case $REPLY in
                [Oo]*)
                    print_color "$YELLOW" "Removing existing directory..."
                    rm -rf "$target_dir"
                    ;;
                [Uu]*)
                    print_color "$YELLOW" "Using existing directory"
                    USE_EXISTING=true
                    ;;
                *)
                    print_color "$YELLOW" "Operation cancelled"
                    exit 0
                    ;;
            esac
        else
            print_color "$YELLOW" "Directory exists: $target_dir"
            print_color "$YELLOW" "Would prompt: Overwrite/Use/Abort"
        fi
    fi

    # Clone repository
    if [ "$USE_EXISTING" != "true" ]; then
        print_color "$BLUE" "Cloning repository..."
        if [ -z "$DRY_RUN" ]; then
            if git clone "$REMOTE_URL" "$target_dir"; then
                print_color "$GREEN" "✓ Clone completed"
            else
                print_color "$RED" "✗ Clone failed"
                exit 1
            fi
        else
            print_color "$YELLOW" "Would run: git clone $REMOTE_URL $target_dir"
        fi
        echo ""

        # Checkout/create branch
        print_color "$BLUE" "Setting up branch '$branch_name'..."
        if [ -z "$DRY_RUN" ]; then
            cd "$target_dir"

            # Fetch all branches
            git fetch --all &> /dev/null || true

            # Check if branch exists remotely
            if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
                print_color "$YELLOW" "Branch exists remotely, checking out..."
                git checkout "$branch_name"
            elif git show-ref --verify --quiet "refs/heads/$branch_name"; then
                print_color "$YELLOW" "Branch exists locally, checking out..."
                git checkout "$branch_name"
            else
                print_color "$YELLOW" "Creating new branch..."
                git checkout -b "$branch_name"
            fi
            print_color "$GREEN" "✓ Branch ready: $branch_name"
            cd "$REPO_ROOT"
        else
            print_color "$YELLOW" "Would checkout/create branch: $branch_name"
        fi
        echo ""
    fi

    # Open in VS Code
    if [ "$NO_OPEN" != "true" ]; then
        print_color "$BLUE" "Opening in VS Code..."
        if [ -z "$DRY_RUN" ]; then
            if command_exists code; then
                code -n "$target_dir"
                print_color "$GREEN" "✓ VS Code launched"
            else
                print_color "$YELLOW" "⚠️  'code' command not found"
                echo "  Please open VS Code manually: $target_dir"
            fi
        else
            print_color "$YELLOW" "Would run: code -n $target_dir"
        fi
        echo ""
    fi

    # Summary
    echo "----------------------------------------"
    print_color "$GREEN" "✅ Branch directory ready!"
    echo ""
    echo "Summary:"
    echo "  Project: $PROJECT_NAME"
    echo "  Branch: $branch_name"
    echo "  Location: $target_dir"
    echo ""
}

# Parse arguments
DRY_RUN=""
NO_OPEN=""
COMMAND=""
BRANCH_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        -n|--no-open)
            NO_OPEN="true"
            shift
            ;;
        --list)
            COMMAND="list"
            shift
            ;;
        --clean)
            COMMAND="clean"
            shift
            if [ $# -eq 0 ]; then
                print_color "$RED" "Error: --clean requires a branch name"
                usage
            fi
            BRANCH_NAME="$1"
            shift
            ;;
        --clean-merged)
            COMMAND="clean-merged"
            shift
            ;;
        *)
            if [ -z "$BRANCH_NAME" ]; then
                BRANCH_NAME="$1"
            else
                print_color "$RED" "Error: Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Execute command
case $COMMAND in
    list)
        list_directories
        ;;
    clean)
        if [ -n "$DRY_RUN" ]; then
            print_color "$YELLOW" "DRY RUN MODE - No changes will be made"
            echo ""
        fi
        clean_directory "$BRANCH_NAME"
        ;;
    clean-merged)
        if [ -n "$DRY_RUN" ]; then
            print_color "$YELLOW" "DRY RUN MODE - No changes will be made"
            echo ""
        fi
        clean_merged_directories
        ;;
    *)
        if [ -z "$BRANCH_NAME" ]; then
            print_color "$RED" "Error: Branch name required"
            usage
        fi

        if [ -n "$DRY_RUN" ]; then
            print_color "$YELLOW" "DRY RUN MODE - No changes will be made"
            echo ""
        fi

        if ! check_dependencies; then
            exit 1
        fi

        create_directory "$BRANCH_NAME"
        ;;
esac
