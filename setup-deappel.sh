#!/bin/bash

# De Appel - Mac Setup & Cleanup Script
# Client-specific setup tasks for De Appel computers
# Version: 1.3.0

set -e  # Exit on any error

SCRIPT_VERSION="1.3.0"

# Root check — needed for removing apps and clearing system caches
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root: sudo $0"
    exit 1
fi

echo "🍎 De Appel Mac Setup & Cleanup Script v$SCRIPT_VERSION"
echo "================================================"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_divider() {
    echo
    echo -e "${BLUE}🍎════════════════════════════════════════════════════════════════════════════════🍎${NC}"
    echo
}

# Function to prompt yes/no with default
prompt_yn() {
    local prompt="$1"
    local default="$2"  # y or n
    local var_name="$3"

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " input
        if [[ "$input" =~ ^[Nn]$ ]]; then
            eval "$var_name='n'"
        else
            eval "$var_name='y'"
        fi
    else
        read -p "$prompt [y/N]: " input
        if [[ "$input" =~ ^[Yy]$ ]]; then
            eval "$var_name='y'"
        else
            eval "$var_name='n'"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Collect preferences
# ─────────────────────────────────────────────────────────────────────────────

echo "Select which tasks to run:"
echo

prompt_yn "Install OmniDiskSweeper?" "y" "DO_OMNIDISKSWEEPER"
prompt_yn "Remove iMovie, GarageBand & support files?" "y" "DO_REMOVE_BLOAT"
prompt_yn "Clean up system caches, backups & unused files?" "y" "DO_CLEANUP"

print_divider

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: OmniDiskSweeper
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_OMNIDISKSWEEPER" == "y" ]]; then
    print_status "STEP 1: Installing OmniDiskSweeper"

    if [[ -d "/Applications/OmniDiskSweeper.app" ]]; then
        print_success "OmniDiskSweeper is already installed — skipping download"
    else
        TEMP_DIR=$(mktemp -d)
        DMG_FILE="$TEMP_DIR/OmniDiskSweeper.dmg"
        DOWNLOAD_URL="https://www.omnigroup.com/download/latest/OmniDiskSweeper"

        print_status "Downloading OmniDiskSweeper..."
        if curl -L -o "$DMG_FILE" "$DOWNLOAD_URL"; then

            print_status "Downloaded to: $DMG_FILE"
            print_status "Mounting disk image (accepting license agreement)..."
            MOUNT_OUTPUT=$(printf 'Y\n' | PAGER=cat hdiutil attach "$DMG_FILE" -nobrowse 2>&1)
            MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep "/Volumes" | awk -F'\t' '{print $NF}')

            if [[ -n "$MOUNT_POINT" ]]; then
                APP_PATH=$(find "$MOUNT_POINT" -maxdepth 1 -name "OmniDiskSweeper.app" -print -quit)

                if [[ -n "$APP_PATH" ]]; then
                    print_status "Copying OmniDiskSweeper to /Applications..."
                    cp -R "$APP_PATH" /Applications/
                    print_success "OmniDiskSweeper installed"
                    print_status "OmniDiskSweeper needs Full Disk Access to fully scan."
                    print_status "Terminal also needs Full Disk Access to launch it with sudo."
                    print_status "Opening Privacy & Security settings..."
                    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
                    echo
                    echo "  Add BOTH of these to Full Disk Access:"
                    echo "  → /Applications/OmniDiskSweeper.app"
                    echo "  → /Applications/Utilities/Terminal.app"
                    echo "  (You may need to unlock the padlock first)"
                    echo
                    read -p "Press Enter when done..."
                else
                    print_error "Could not find OmniDiskSweeper.app in disk image"
                    print_status "Contents of $MOUNT_POINT:"
                    ls -la "$MOUNT_POINT"
                fi

                hdiutil detach "$MOUNT_POINT" -quiet
            else
                print_error "Failed to mount disk image"
            fi
        else
            print_error "Failed to download OmniDiskSweeper"
        fi

        rm -rf "$TEMP_DIR"
    fi

    # Print launch command for full disk scanning
    echo
    echo "  To scan with full disk access, run:"
    echo "  sudo /Applications/OmniDiskSweeper.app/Contents/MacOS/OmniDiskSweeper &"
    echo
    
else
    print_status "OmniDiskSweeper installation skipped"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Remove iMovie, GarageBand & support files
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_REMOVE_BLOAT" == "y" ]]; then
    print_divider
    print_status "STEP 2: Removing iMovie, GarageBand & support files"

    SPACE_FREED=0

    # iMovie
    if [[ -d "/Applications/iMovie.app" ]]; then
        SIZE=$(du -sm "/Applications/iMovie.app" 2>/dev/null | awk '{print $1}')
        print_status "Removing iMovie.app (${SIZE:-?} MB)..."
        rm -rf "/Applications/iMovie.app"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "iMovie removed"
    else
        print_status "iMovie.app not found — already removed"
    fi

    # GarageBand
    if [[ -d "/Applications/GarageBand.app" ]]; then
        SIZE=$(du -sm "/Applications/GarageBand.app" 2>/dev/null | awk '{print $1}')
        print_status "Removing GarageBand.app (${SIZE:-?} MB)..."
        rm -rf "/Applications/GarageBand.app"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "GarageBand removed"
    else
        print_status "GarageBand.app not found — already removed"
    fi

    # GarageBand support files
    if [[ -d "/Library/Application Support/GarageBand" ]]; then
        SIZE=$(du -sm "/Library/Application Support/GarageBand" 2>/dev/null | awk '{print $1}')
        print_status "Removing GarageBand support files (${SIZE:-?} MB)..."
        rm -rf "/Library/Application Support/GarageBand"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "GarageBand support files removed"
    else
        print_status "GarageBand support files not found — already removed"
    fi

    # Logic support files (installed as GarageBand dependency)
    if [[ -d "/Library/Application Support/Logic" ]]; then
        SIZE=$(du -sm "/Library/Application Support/Logic" 2>/dev/null | awk '{print $1}')
        print_status "Removing Logic support files (${SIZE:-?} MB)..."
        rm -rf "/Library/Application Support/Logic"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "Logic support files removed"
    else
        print_status "Logic support files not found — already removed"
    fi

    if [[ "$SPACE_FREED" -gt 0 ]]; then
        if [[ "$SPACE_FREED" -ge 1024 ]]; then
            print_success "Freed approximately $((SPACE_FREED / 1024)) GB"
        else
            print_success "Freed approximately ${SPACE_FREED} MB"
        fi
    fi
else
    print_status "Bloatware removal skipped"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: System cleanup
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_CLEANUP" == "y" ]]; then
    print_divider
    print_status "STEP 3: System cleanup"

    CLEANUP_FREED=0

    # Helper: remove a path and tally space freed
    remove_and_tally() {
        local target="$1"
        local label="$2"

        if [[ -e "$target" ]]; then
            SIZE=$(du -sm "$target" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Removing $label (${SIZE} MB)..."
                rm -rf "$target"
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "$label removed"
            else
                print_status "$label exists but is empty — skipping"
            fi
        else
            print_status "$label not found — skipping"
        fi
    }

    # --- iOS/iPadOS device backups ---
    print_status "Checking for iOS/iPadOS device backups..."
    for BACKUP_DIR in /Users/*/Library/Application\ Support/MobileSync/Backup; do
        if [[ -d "$BACKUP_DIR" ]]; then
            USER_DIR=$(echo "$BACKUP_DIR" | cut -d'/' -f3)
            remove_and_tally "$BACKUP_DIR" "iOS backups for $USER_DIR"
        fi
    done

    # --- System caches ---
    remove_and_tally "/Library/Caches" "System caches (/Library/Caches)"
    # Recreate the directory so the system doesn't complain
    [[ ! -d "/Library/Caches" ]] && mkdir -p /Library/Caches

    # --- Per-user caches ---
    print_status "Checking per-user caches..."
    for USER_CACHE in /Users/*/Library/Caches; do
        if [[ -d "$USER_CACHE" ]]; then
            USER_DIR=$(echo "$USER_CACHE" | cut -d'/' -f3)
            SIZE=$(du -sm "$USER_CACHE" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Clearing caches for $USER_DIR (${SIZE} MB)..."
                rm -rf "$USER_CACHE"/*
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "Caches cleared for $USER_DIR"
            fi
        fi
    done

    # --- Old software update downloads ---
    remove_and_tally "/Library/Updates" "Old software update downloads"

    # --- Unused printer drivers ---
    if [[ -d "/Library/Printers" ]]; then
        SIZE=$(du -sm "/Library/Printers" 2>/dev/null | awk '{print $1}')
        if [[ "${SIZE:-0}" -gt 100 ]]; then
            print_status "Printer drivers found (${SIZE} MB)"
            echo "  This removes ALL printer drivers — printers will re-download"
            echo "  their drivers automatically when next used."
            prompt_yn "  Remove printer drivers?" "y" "DO_REMOVE_PRINTERS"
            if [[ "$DO_REMOVE_PRINTERS" == "y" ]]; then
                rm -rf /Library/Printers/*
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "Printer drivers removed"
            else
                print_status "Printer drivers kept"
            fi
        else
            print_status "Printer drivers only ${SIZE:-0} MB — not worth removing"
        fi
    fi

    # --- Mail downloads per user ---
    print_status "Checking Mail downloads..."
    for MAIL_DL in /Users/*/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads; do
        if [[ -d "$MAIL_DL" ]]; then
            USER_DIR=$(echo "$MAIL_DL" | cut -d'/' -f3)
            SIZE=$(du -sm "$MAIL_DL" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Clearing Mail downloads for $USER_DIR (${SIZE} MB)..."
                rm -rf "$MAIL_DL"/*
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "Mail downloads cleared for $USER_DIR"
            fi
        fi
    done

    # --- Time Machine local snapshots ---
    SNAPSHOT_COUNT=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple" || true)
    if [[ "$SNAPSHOT_COUNT" -gt 0 ]]; then
        print_status "Found $SNAPSHOT_COUNT local Time Machine snapshot(s)"
        prompt_yn "  Delete all local snapshots?" "y" "DO_DELETE_SNAPSHOTS"
        if [[ "$DO_DELETE_SNAPSHOTS" == "y" ]]; then
            print_status "Deleting local Time Machine snapshots..."
            tmutil listlocalsnapshots / 2>/dev/null | grep "com.apple" | while read -r SNAP; do
                SNAP_DATE=$(echo "$SNAP" | sed 's/com.apple.TimeMachine.//')
                tmutil deletelocalsnapshots "$SNAP_DATE" 2>/dev/null || true
            done
            print_success "Local Time Machine snapshots deleted"
        else
            print_status "Time Machine snapshots kept"
        fi
    else
        print_status "No local Time Machine snapshots found"
    fi

    # --- Cleanup total ---
    echo
    if [[ "$CLEANUP_FREED" -gt 0 ]]; then
        if [[ "$CLEANUP_FREED" -ge 1024 ]]; then
            print_success "Cleanup freed approximately $((CLEANUP_FREED / 1024)) GB"
        else
            print_success "Cleanup freed approximately ${CLEANUP_FREED} MB"
        fi
    else
        print_status "No significant space to clean up"
    fi
else
    print_status "System cleanup skipped"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────

print_divider
print_success "De Appel setup complete! 🎉"
echo
echo "Summary:"
[[ "$DO_OMNIDISKSWEEPER" == "y" ]] && echo "  ✓ OmniDiskSweeper"
[[ "$DO_OMNIDISKSWEEPER" == "n" ]] && echo "  – OmniDiskSweeper (skipped)"
[[ "$DO_REMOVE_BLOAT" == "y" ]] && echo "  ✓ Removed iMovie, GarageBand & support files"
[[ "$DO_REMOVE_BLOAT" == "n" ]] && echo "  – Bloatware removal (skipped)"
[[ "$DO_CLEANUP" == "y" ]] && echo "  ✓ System cleanup"
[[ "$DO_CLEANUP" == "n" ]] && echo "  – System cleanup (skipped)"
echo