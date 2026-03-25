#!/bin/bash

# De Appel - Mac Setup & Cleanup Script
# Client-specific setup tasks for De Appel computers
# Version: 1.1.0

set -e  # Exit on any error

SCRIPT_VERSION="1.1.0"

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

# (future tasks will be added here)

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
        sudo rm -rf "/Applications/iMovie.app"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "iMovie removed"
    else
        print_status "iMovie.app not found — already removed"
    fi

    # GarageBand
    if [[ -d "/Applications/GarageBand.app" ]]; then
        SIZE=$(du -sm "/Applications/GarageBand.app" 2>/dev/null | awk '{print $1}')
        print_status "Removing GarageBand.app (${SIZE:-?} MB)..."
        sudo rm -rf "/Applications/GarageBand.app"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "GarageBand removed"
    else
        print_status "GarageBand.app not found — already removed"
    fi

    # GarageBand support files
    if [[ -d "/Library/Application Support/GarageBand" ]]; then
        SIZE=$(du -sm "/Library/Application Support/GarageBand" 2>/dev/null | awk '{print $1}')
        print_status "Removing GarageBand support files (${SIZE:-?} MB)..."
        sudo rm -rf "/Library/Application Support/GarageBand"
        SPACE_FREED=$((SPACE_FREED + ${SIZE:-0}))
        print_success "GarageBand support files removed"
    else
        print_status "GarageBand support files not found — already removed"
    fi

    # Logic support files (installed as GarageBand dependency)
    if [[ -d "/Library/Application Support/Logic" ]]; then
        SIZE=$(du -sm "/Library/Application Support/Logic" 2>/dev/null | awk '{print $1}')
        print_status "Removing Logic support files (${SIZE:-?} MB)..."
        sudo rm -rf "/Library/Application Support/Logic"
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
echo