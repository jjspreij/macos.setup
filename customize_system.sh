#!/bin/bash

# macOS System Customization Script
# Configures Finder, Dock, Desktop, and system preferences
# Version: 2.0.0

SCRIPT_VERSION="2.0.0"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/macos-setup.cfg"
DIVIDER_ICON="🎨"

# Source shared functions
source "$SCRIPT_DIR/common.sh"

echo "🎨 macOS System Customization Script v$SCRIPT_VERSION"
echo "===================================="
echo

# Load config for Dock items (only settings that need user input)
if [[ -f "$CONFIG_FILE" ]]; then
    print_status "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

# Dock customization prompts
echo "Dock customization:"
echo "Enter app names separated by commas, or leave blank to skip"
prompt_with_default "Remove from Dock" "${DOCK_REMOVE_ITEMS:-""}" "DOCK_REMOVE_ITEMS"
prompt_with_default "Add to Dock" "${DOCK_ADD_ITEMS:-""}" "DOCK_ADD_ITEMS"

# ─────────────────────────────────────────────────────────────────────────────

RESTART_DOCK=false
RESTART_FINDER=false

print_divider
print_status "STEP 1: Configuring System Preferences"

print_status "Setting Dock to auto-hide..."
defaults write com.apple.dock autohide -bool true
RESTART_DOCK=true
print_success "Dock auto-hide enabled"

print_status "Enabling trackpad tap-to-click..."
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
print_success "Trackpad tap-to-click enabled"

print_status "Disabling Stage Manager 'click wallpaper to reveal desktop'..."
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
print_success "Stage Manager wallpaper click disabled"

print_status "Setting scrollbars to always show..."
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
print_success "Scrollbars always visible"

print_divider
print_status "STEP 2: Configuring Finder & Desktop Preferences"

print_status "Showing file extensions in Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
RESTART_FINDER=true
print_success "File extensions shown"

print_status "Showing path bar in Finder..."
defaults write com.apple.finder ShowPathbar -bool true
RESTART_FINDER=true
print_success "Path bar shown"

print_status "Showing status bar in Finder..."
defaults write com.apple.finder ShowStatusBar -bool true
RESTART_FINDER=true
print_success "Status bar shown"

print_status "Showing hard drives, servers, and removable media on desktop..."
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
RESTART_FINDER=true
print_success "Hard drives, servers, and removable media shown on desktop"

print_status "Setting desktop icons to sort by kind..."
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy kind" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :DesktopViewSettings:IconViewSettings:arrangeBy string kind" ~/Library/Preferences/com.apple.finder.plist
RESTART_FINDER=true
print_success "Desktop icons sorted by kind"

print_status "Setting desktop icon labels to right side..."
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:labelOnSide true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :DesktopViewSettings:IconViewSettings:labelOnSide bool true" ~/Library/Preferences/com.apple.finder.plist
RESTART_FINDER=true
print_success "Desktop icon labels set to right side"

print_divider
print_status "STEP 3: Customizing Dock"

# Install dockutil if needed and dock customization is requested
if [[ -n "$DOCK_REMOVE_ITEMS" || -n "$DOCK_ADD_ITEMS" ]]; then
    if ! command -v dockutil &> /dev/null; then
        print_status "Installing dockutil for Dock management..."
        if command -v brew &> /dev/null; then
            brew install dockutil
            print_success "dockutil installed"
        else
            print_error "Homebrew not found - cannot install dockutil"
            print_warning "Dock customization will be skipped"
            DOCK_REMOVE_ITEMS=""
            DOCK_ADD_ITEMS=""
        fi
    fi
fi

if [[ -n "$DOCK_REMOVE_ITEMS" ]]; then
    print_status "Removing items from Dock..."
    IFS=',' read -ra REMOVE_APPS <<< "$DOCK_REMOVE_ITEMS"
    for app in "${REMOVE_APPS[@]}"; do
        app=$(echo "$app" | xargs)
        if [[ -n "$app" ]]; then
            print_status "Removing $app from Dock..."
            dockutil --remove "$app" --no-restart 2>/dev/null || print_warning "Could not remove $app (may not be in Dock)"
        fi
    done
    RESTART_DOCK=true
fi

if [[ -n "$DOCK_ADD_ITEMS" ]]; then
    print_status "Adding items to Dock..."
    IFS=',' read -ra ADD_APPS <<< "$DOCK_ADD_ITEMS"
    for app in "${ADD_APPS[@]}"; do
        app=$(echo "$app" | xargs)
        if [[ -n "$app" ]]; then
            print_status "Adding $app to Dock..."
            APP_PATH=""
            if [[ -d "/Applications/$app.app" ]]; then
                APP_PATH="/Applications/$app.app"
            elif [[ -d "/System/Applications/$app.app" ]]; then
                APP_PATH="/System/Applications/$app.app"
            elif [[ -d "/Applications/Utilities/$app.app" ]]; then
                APP_PATH="/Applications/Utilities/$app.app"
            fi

            if [[ -n "$APP_PATH" ]]; then
                dockutil --add "$APP_PATH" --no-restart 2>/dev/null && print_success "$app added to Dock" || print_warning "Failed to add $app to Dock"
            else
                print_warning "Could not find $app.app in common locations"
            fi
        fi
    done
    RESTART_DOCK=true
fi

print_divider
print_status "STEP 4: Applying Changes"

if [[ "$RESTART_DOCK" == true ]]; then
    print_status "Restarting Dock..."
    killall Dock
    print_success "Dock restarted"
fi

if [[ "$RESTART_FINDER" == true ]]; then
    print_status "Flushing preference cache..."
    killall cfprefsd 2>/dev/null || true
    print_status "Restarting Finder..."
    killall Finder
    print_success "Finder restarted"
fi

print_divider
print_success "System customization complete! 🎉"
echo
echo "Summary of customizations applied:"
echo "  ✓ Dock set to auto-hide"
echo "  ✓ Trackpad tap-to-click enabled"
echo "  ✓ Stage Manager wallpaper click disabled"
echo "  ✓ Scrollbars always visible"
echo "  ✓ File extensions shown in Finder"
echo "  ✓ Path bar shown in Finder"
echo "  ✓ Status bar shown in Finder"
echo "  ✓ Hard drives, servers, removable media shown on desktop"
echo "  ✓ Desktop icons sorted by kind"
echo "  ✓ Desktop icon labels on right side"
[[ -n "$DOCK_REMOVE_ITEMS" ]] && echo "  ✓ Removed from Dock: $DOCK_REMOVE_ITEMS"
[[ -n "$DOCK_ADD_ITEMS" ]] && echo "  ✓ Added to Dock: $DOCK_ADD_ITEMS"
echo
echo "You may need to log out and back in for some changes to take full effect."