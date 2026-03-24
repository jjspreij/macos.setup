#!/bin/bash

# De Appel - Mac Setup & Cleanup Script
# Client-specific setup tasks for De Appel computers
# Version: 1.0.0

set -e  # Exit on any error

SCRIPT_VERSION="1.0.0"

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

# (future tasks will be added here)

print_divider

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: OmniDiskSweeper
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_OMNIDISKSWEEPER" == "y" ]]; then
    print_status "STEP 1: Installing OmniDiskSweeper"

    if [[ -d "/Applications/OmniDiskSweeper.app" ]]; then
        print_success "OmniDiskSweeper is already installed — skipping"
    else
        TEMP_DIR=$(mktemp -d)
        DMG_FILE="$TEMP_DIR/OmniDiskSweeper.dmg"
        DOWNLOAD_URL="https://www.omnigroup.com/download/latest/OmniDiskSweeper"

        print_status "Downloading OmniDiskSweeper..."
        if curl -L -o "$DMG_FILE" "$DOWNLOAD_URL"; then
            print_status "Mounting disk image..."
            MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse -quiet | grep "/Volumes" | awk -F'\t' '{print $NF}')

            if [[ -n "$MOUNT_POINT" ]]; then
                APP_PATH=$(find "$MOUNT_POINT" -maxdepth 1 -name "OmniDiskSweeper.app" -print -quit)

                if [[ -n "$APP_PATH" ]]; then
                    print_status "Copying OmniDiskSweeper to /Applications..."
                    cp -R "$APP_PATH" /Applications/
                    print_success "OmniDiskSweeper installed"
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
else
    print_status "OmniDiskSweeper installation skipped"
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
echo