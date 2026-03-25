#!/bin/bash

# macOS Reclaim Space Script
# Removes bloatware and cleans up caches to free disk space
# Version: 2.0.0

SCRIPT_VERSION="2.0.0"
DIVIDER_ICON="🧹"

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Root check — needed for removing apps and clearing system caches
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root: sudo $0"
    exit 1
fi

echo "🧹 macOS Reclaim Space Script v$SCRIPT_VERSION"
echo "======================================="
echo

# ─────────────────────────────────────────────────────────────────────────────
# Collect preferences
# ─────────────────────────────────────────────────────────────────────────────

echo "Select which tasks to run:"
echo

prompt_yn "Remove iMovie, GarageBand & support files?" "y" "DO_REMOVE_BLOAT"
prompt_yn "Clean up system caches, backups & unused files?" "y" "DO_CLEANUP"

print_divider

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Remove iMovie, GarageBand & support files
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_REMOVE_BLOAT" == "y" ]]; then
    print_status "STEP 1: Removing iMovie, GarageBand & support files"

    SPACE_FREED=0

    # Helper: remove an app or directory and tally space freed
    remove_and_tally() {
        local target="$1"
        local label="$2"

        if [[ -e "$target" ]]; then
            SIZE=$(du -sm "$target" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Removing $label (${SIZE} MB)..."
                rm -rf "$target" 2>/dev/null || print_warning "$label: some files protected by SIP — partially cleared"
                SPACE_FREED=$((SPACE_FREED + SIZE))
                print_success "$label removed"
            else
                print_status "$label exists but is empty — skipping"
            fi
        else
            print_status "$label not found — already removed"
        fi
    }

    remove_and_tally "/Applications/iMovie.app" "iMovie.app"
    remove_and_tally "/Applications/GarageBand.app" "GarageBand.app"
    remove_and_tally "/Library/Application Support/GarageBand" "GarageBand support files"
    remove_and_tally "/Library/Application Support/Logic" "Logic support files"

    if [[ "$SPACE_FREED" -gt 0 ]]; then
        if [[ "$SPACE_FREED" -ge 1024 ]]; then
            print_success "Bloatware removal freed approximately $((SPACE_FREED / 1024)) GB"
        else
            print_success "Bloatware removal freed approximately ${SPACE_FREED} MB"
        fi
    fi
else
    print_status "Bloatware removal skipped"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: System cleanup
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$DO_CLEANUP" == "y" ]]; then
    print_divider
    print_status "STEP 2: System cleanup"

    CLEANUP_FREED=0

    # --- iOS/iPadOS device backups ---
    print_status "Checking for iOS/iPadOS device backups..."
    for BACKUP_DIR in /Users/*/Library/Application\ Support/MobileSync/Backup; do
        if [[ -d "$BACKUP_DIR" ]]; then
            USER_DIR=$(echo "$BACKUP_DIR" | cut -d'/' -f3)
            SIZE=$(du -sm "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Removing iOS backups for $USER_DIR (${SIZE} MB)..."
                rm -rf "$BACKUP_DIR" 2>/dev/null || print_warning "iOS backups for $USER_DIR: some files could not be removed"
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "iOS backups removed for $USER_DIR"
            fi
        fi
    done

    # --- System caches ---
    if [[ -d "/Library/Caches" ]]; then
        SIZE=$(du -sm "/Library/Caches" 2>/dev/null | awk '{print $1}')
        if [[ "${SIZE:-0}" -gt 0 ]]; then
            print_status "Clearing system caches (${SIZE} MB)..."
            rm -rf /Library/Caches/* 2>/dev/null || print_warning "Some system caches protected by SIP — partially cleared"
            CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
            print_success "System caches cleared"
        else
            print_status "System caches empty — skipping"
        fi
    fi

    # --- Per-user caches ---
    print_status "Checking per-user caches..."
    for USER_CACHE in /Users/*/Library/Caches; do
        if [[ -d "$USER_CACHE" ]]; then
            USER_DIR=$(echo "$USER_CACHE" | cut -d'/' -f3)
            SIZE=$(du -sm "$USER_CACHE" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE:-0}" -gt 0 ]]; then
                print_status "Clearing caches for $USER_DIR (${SIZE} MB)..."
                rm -rf "$USER_CACHE"/* 2>/dev/null || print_warning "Some caches for $USER_DIR could not be removed"
                CLEANUP_FREED=$((CLEANUP_FREED + SIZE))
                print_success "Caches cleared for $USER_DIR"
            fi
        fi
    done

    # --- Unused printer drivers ---
    if [[ -d "/Library/Printers" ]]; then
        SIZE=$(du -sm "/Library/Printers" 2>/dev/null | awk '{print $1}')
        if [[ "${SIZE:-0}" -gt 100 ]]; then
            print_status "Printer drivers found (${SIZE} MB)"
            echo "  This removes ALL printer drivers — printers will re-download"
            echo "  their drivers automatically when next used."
            prompt_yn "  Remove printer drivers?" "y" "DO_REMOVE_PRINTERS"
            if [[ "$DO_REMOVE_PRINTERS" == "y" ]]; then
                rm -rf /Library/Printers/* 2>/dev/null || print_warning "Some printer drivers could not be removed"
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
                rm -rf "$MAIL_DL"/* 2>/dev/null || print_warning "Some Mail downloads for $USER_DIR could not be removed"
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
print_success "Reclaim space complete! 🎉"
echo
echo "Summary:"
[[ "$DO_REMOVE_BLOAT" == "y" ]] && echo "  ✓ Removed iMovie, GarageBand & support files"
[[ "$DO_REMOVE_BLOAT" == "n" ]] && echo "  – Bloatware removal (skipped)"
[[ "$DO_CLEANUP" == "y" ]] && echo "  ✓ System cleanup"
[[ "$DO_CLEANUP" == "n" ]] && echo "  – System cleanup (skipped)"
echo
