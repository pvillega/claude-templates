#!/usr/bin/env bash
#
# sync-worktree.sh - Sync gitignored files to git worktrees
#
# Usage: sync-worktree.sh <worktree-path>
#
# Syncs development files like .claude/, .serena/, .env* from the main
# worktree to a target worktree. Reads patterns from .worktreeinclude
# (if exists) merged with built-in defaults.

set -euo pipefail

# ==============================================================================
# CONSTANTS
# ==============================================================================

readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

readonly CONFIG_FILE=".worktreeinclude"

# Default patterns (merged with .worktreeinclude if it exists)
readonly DEFAULT_PATTERNS=(
    ".claude/"
    ".serena/"
    ".env"
    ".env.*"
    ".envrc"
    ".tool-versions"
    ".nvmrc"
    ".node-version"
    ".python-version"
    ".ruby-version"
)

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

MAIN_WORKTREE=""
TARGET_WORKTREE=""
declare -a FILES_NEW=()
declare -a FILES_IDENTICAL=()
declare -a FILES_CONFLICT=()

# ==============================================================================
# FUNCTIONS
# ==============================================================================

parse_args() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: sync-worktree.sh <worktree-path>"
        echo ""
        echo "Syncs gitignored files from main worktree to target worktree."
        echo ""
        echo "Examples:"
        echo "  sync-worktree.sh ../feature-branch"
        echo "  sync-worktree.sh /path/to/worktree"
        exit 1
    fi

    TARGET_WORKTREE="$1"
}

validate_environment() {
    # Check target path exists
    if [[ ! -d "$TARGET_WORKTREE" ]]; then
        echo -e "${RED}Error: Path does not exist: $TARGET_WORKTREE${NC}"
        exit 1
    fi

    # Resolve to absolute path
    TARGET_WORKTREE=$(cd "$TARGET_WORKTREE" && pwd -P)

    # Check target is inside a git repository
    if ! git -C "$TARGET_WORKTREE" rev-parse --is-inside-work-tree &>/dev/null; then
        echo -e "${RED}Error: Not a git repository: $TARGET_WORKTREE${NC}"
        exit 1
    fi

    # Validate it's a git worktree
    local worktree_list
    worktree_list=$(git -C "$TARGET_WORKTREE" worktree list --porcelain)

    if ! echo "$worktree_list" | grep -q "^worktree $TARGET_WORKTREE$"; then
        echo -e "${RED}Error: Not a git worktree: $TARGET_WORKTREE${NC}"
        exit 1
    fi

    # Detect main worktree (first in list)
    MAIN_WORKTREE=$(git -C "$TARGET_WORKTREE" worktree list | head -1 | awk '{print $1}')

    if [[ ! -d "$MAIN_WORKTREE" ]]; then
        echo -e "${RED}Error: Could not detect main worktree${NC}"
        exit 1
    fi

    # Prevent self-sync
    if [[ "$MAIN_WORKTREE" == "$TARGET_WORKTREE" ]]; then
        echo -e "${RED}Error: Cannot sync worktree to itself${NC}"
        exit 1
    fi

    echo -e "${CYAN}Source:${NC} $MAIN_WORKTREE"
    echo -e "${CYAN}Target:${NC} $TARGET_WORKTREE"
    echo ""
}

load_patterns() {
    local patterns=()

    # Start with defaults
    patterns=("${DEFAULT_PATTERNS[@]}")

    # Merge with .worktreeinclude if it exists
    local config_path="$MAIN_WORKTREE/$CONFIG_FILE"
    if [[ -f "$config_path" ]]; then
        echo -e "${CYAN}Using patterns from:${NC} $CONFIG_FILE"
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            # Trim whitespace
            line=$(echo "$line" | xargs)
            # Add if not already in list
            local found=false
            for p in "${patterns[@]}"; do
                [[ "$p" == "$line" ]] && found=true && break
            done
            [[ "$found" == false ]] && patterns+=("$line")
        done < "$config_path"
    else
        echo -e "${CYAN}Using default patterns${NC} (no $CONFIG_FILE found)"
    fi

    printf '%s\n' "${patterns[@]}"
}

discover_files() {
    echo ""
    echo "Scanning for files to sync..."
    echo ""

    local patterns
    mapfile -t patterns < <(load_patterns)

    shopt -s nullglob dotglob

    for pattern in "${patterns[@]}"; do
        # Handle directory patterns (ending with /)
        if [[ "$pattern" == */ ]]; then
            local dir_name="${pattern%/}"
            if [[ -d "$MAIN_WORKTREE/$dir_name" ]]; then
                classify_item "$dir_name"
            fi
        else
            # Handle file patterns with potential globs
            for file in "$MAIN_WORKTREE"/$pattern; do
                if [[ -e "$file" ]]; then
                    local rel_path="${file#$MAIN_WORKTREE/}"
                    classify_item "$rel_path"
                fi
            done
        fi
    done

    shopt -u nullglob dotglob
}

classify_item() {
    local item="$1"
    local source="$MAIN_WORKTREE/$item"
    local target="$TARGET_WORKTREE/$item"

    # Target doesn't exist - new file
    if [[ ! -e "$target" ]]; then
        FILES_NEW+=("$item")
        return
    fi

    # Both are directories - check recursively
    if [[ -d "$source" ]] && [[ -d "$target" ]]; then
        # For directories, we'll copy the whole thing but note it exists
        FILES_CONFLICT+=("$item")
        return
    fi

    # Type mismatch (one is dir, one is file)
    if [[ -d "$source" && ! -d "$target" ]] || [[ ! -d "$source" && -d "$target" ]]; then
        FILES_CONFLICT+=("$item")
        return
    fi

    # Both are files - compare content
    if diff -q "$source" "$target" &>/dev/null; then
        FILES_IDENTICAL+=("$item")
    else
        FILES_CONFLICT+=("$item")
    fi
}

display_preview() {
    echo "============================================"
    echo "SYNC PREVIEW"
    echo "============================================"
    echo ""

    local total_count=$((${#FILES_NEW[@]} + ${#FILES_CONFLICT[@]}))

    if [[ $total_count -eq 0 ]]; then
        echo -e "${GREEN}Nothing to sync - all files are up to date!${NC}"
        exit 0
    fi

    if [[ ${#FILES_NEW[@]} -gt 0 ]]; then
        echo -e "${GREEN}NEW (will be copied):${NC}"
        for file in "${FILES_NEW[@]}"; do
            local size
            size=$(get_size "$MAIN_WORKTREE/$file")
            echo -e "  ${GREEN}+${NC} $file  ${CYAN}($size)${NC}"
        done
        echo ""
    fi

    if [[ ${#FILES_IDENTICAL[@]} -gt 0 ]]; then
        echo "IDENTICAL (will be skipped):"
        for file in "${FILES_IDENTICAL[@]}"; do
            echo "  = $file"
        done
        echo ""
    fi

    if [[ ${#FILES_CONFLICT[@]} -gt 0 ]]; then
        echo -e "${YELLOW}CONFLICTS (will prompt):${NC}"
        for file in "${FILES_CONFLICT[@]}"; do
            echo -e "  ${YELLOW}!${NC} $file"
        done
        echo ""
    fi

    echo "--------------------------------------------"
    echo "Summary: ${#FILES_NEW[@]} new, ${#FILES_IDENTICAL[@]} identical, ${#FILES_CONFLICT[@]} conflicts"
    echo ""
}

get_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        local count
        count=$(find "$path" -type f 2>/dev/null | wc -l | xargs)
        echo "directory, $count files"
    else
        local bytes
        bytes=$(wc -c < "$path" 2>/dev/null | xargs)
        if [[ $bytes -lt 1024 ]]; then
            echo "${bytes} bytes"
        else
            echo "$((bytes / 1024)) KB"
        fi
    fi
}

confirm_and_sync() {
    read -r -p "Proceed with sync? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            echo "Sync cancelled."
            exit 0
            ;;
    esac

    echo ""
    echo "Syncing files..."
    echo ""

    local copied=0
    local skipped=0

    # Copy new files
    for file in "${FILES_NEW[@]}"; do
        copy_item "$file"
        ((copied++)) || true
    done

    # Handle conflicts with prompts
    for file in "${FILES_CONFLICT[@]}"; do
        if resolve_conflict "$file"; then
            ((copied++)) || true
        else
            ((skipped++)) || true
        fi
    done

    echo ""
    echo "============================================"
    echo -e "${GREEN}Sync complete!${NC}"
    echo "  Copied: $copied"
    echo "  Skipped: $skipped"
    echo "============================================"
}

copy_item() {
    local item="$1"
    local source="$MAIN_WORKTREE/$item"
    local target="$TARGET_WORKTREE/$item"

    # Create parent directory if needed
    local target_dir
    target_dir=$(dirname "$target")
    mkdir -p "$target_dir"

    # Copy (use -a to preserve attributes, -T for directory handling)
    if [[ -d "$source" ]]; then
        cp -a "$source" "$target"
    else
        cp -a "$source" "$target"
    fi

    echo -e "  ${GREEN}✓${NC} Copied: $item"
}

resolve_conflict() {
    local item="$1"
    local source="$MAIN_WORKTREE/$item"
    local target="$TARGET_WORKTREE/$item"

    echo ""
    echo -e "${YELLOW}Conflict:${NC} $item"

    # Show diff for files (not directories)
    if [[ -f "$source" ]] && [[ -f "$target" ]]; then
        echo "  Source: $(wc -c < "$source" | xargs) bytes"
        echo "  Target: $(wc -c < "$target" | xargs) bytes"
    fi

    while true; do
        echo ""
        echo "  [o] Overwrite target with source"
        echo "  [s] Skip (keep target)"
        echo "  [d] Show diff"
        echo "  [q] Quit sync"
        read -r -p "  Choice: " choice

        case "$choice" in
            o|O)
                # Backup existing before overwrite
                local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
                if [[ -d "$target" ]]; then
                    mv "$target" "$backup"
                else
                    cp "$target" "$backup"
                fi
                copy_item "$item"
                echo -e "  ${CYAN}(backup: ${backup##*/})${NC}"
                return 0
                ;;
            s|S)
                echo -e "  ${YELLOW}Skipped${NC}"
                return 1
                ;;
            d|D)
                if [[ -f "$source" ]] && [[ -f "$target" ]]; then
                    echo ""
                    echo "--- Target (worktree)"
                    echo "+++ Source (main)"
                    diff -u "$target" "$source" | head -50 || true
                    local total_lines
                    total_lines=$(diff -u "$target" "$source" 2>/dev/null | wc -l)
                    if [[ $total_lines -gt 50 ]]; then
                        echo "... ($((total_lines - 50)) more lines)"
                    fi
                else
                    echo "  (Cannot diff directories - use overwrite or skip)"
                fi
                ;;
            q|Q)
                echo "Sync aborted."
                exit 1
                ;;
            *)
                echo "  Invalid choice"
                ;;
        esac
    done
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"
    validate_environment
    discover_files
    display_preview
    confirm_and_sync
}

main "$@"
