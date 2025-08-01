#!/bin/bash

# macOS System Customization Script
# Configures Finder, Dock, and system preferences
# Version: 1.4.1

set -e  # Exit on any error

SCRIPT_VERSION="1.4.1"
CONFIG_FILE="$HOME/.macos-setup.cfg"

echo "🎨 macOS System Customization Script v$SCRIPT_VERSION"
echo "===================================="
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
    echo -e "${BLUE}🎨════════════════════════════════════════════════════════════════════════════════🎨${NC}"
    echo
}

# Function to save config
save_config() {
    # Create config if it doesn't exist, or update system section if it does
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update existing config - remove old system settings and add new ones
        grep -v "^SET_\|^SHOW_\|^DISABLE_\|^ALWAYS_\|^DOCK_" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
        cat >> "${CONFIG_FILE}.tmp" << EOF
# System Customization Settings - Updated $(date)
SET_DOCK_AUTOHIDE="$SET_DOCK_AUTOHIDE"
SET_TRACKPAD_CLICK="$SET_TRACKPAD_CLICK"
DISABLE_STAGE_MANAGER="$DISABLE_STAGE_MANAGER"
SHOW_HIDDEN_FILES="$SHOW_HIDDEN_FILES"
SHOW_FILE_EXTENSIONS="$SHOW_FILE_EXTENSIONS"
SHOW_PATH_BAR="$SHOW_PATH_BAR"
SHOW_STATUS_BAR="$SHOW_STATUS_BAR"
ALWAYS_SHOW_SCROLLBARS="$ALWAYS_SHOW_SCROLLBARS"
DOCK_REMOVE_ITEMS="$DOCK_REMOVE_ITEMS"
DOCK_ADD_ITEMS="$DOCK_ADD_ITEMS"
EOF
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    else
        cat > "$CONFIG_FILE" << EOF
# macOS Setup Configuration
# Generated on $(date)
SET_DOCK_AUTOHIDE="$SET_DOCK_AUTOHIDE"
SET_TRACKPAD_CLICK="$SET_TRACKPAD_CLICK"
DISABLE_STAGE_MANAGER="$DISABLE_STAGE_MANAGER"
SHOW_HIDDEN_FILES="$SHOW_HIDDEN_FILES"
SHOW_FILE_EXTENSIONS="$SHOW_FILE_EXTENSIONS"
SHOW_PATH_BAR="$SHOW_PATH_BAR"
SHOW_STATUS_BAR="$SHOW_STATUS_BAR"
ALWAYS_SHOW_SCROLLBARS="$ALWAYS_SHOW_SCROLLBARS"
DOCK_REMOVE_ITEMS="$DOCK_REMOVE_ITEMS"
DOCK_ADD_ITEMS="$DOCK_ADD_ITEMS"
EOF
    fi
    print_success "System customization configuration saved to $CONFIG_FILE"
}

# Function to load config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_status "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " input
        if [[ -z "$input" ]]; then
            eval "$var_name='$default'"
        else
            eval "$var_name='$input'"
        fi
    else
        read -p "$prompt: " input
        eval "$var_name='$input'"
    fi
}

# Check for command line arguments
USE_CONFIG=false
SKIP_PROMPTS=false
SAVE_CONFIG_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--use-config)
            USE_CONFIG=true
            shift
            ;;
        -s|--skip-prompts)
            SKIP_PROMPTS=true
            shift
            ;;
        -o|--save-config)
            SAVE_CONFIG_ONLY=true
            shift
            ;;
        -f|--config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "macOS System Customization Script v$SCRIPT_VERSION"
            echo
            echo "Options:"
            echo "  -c, --use-config       Load settings from config file (still prompts for missing values)"
            echo "  -s, --skip-prompts     Use config file without any prompts (fails if no config)"
            echo "  -o, --save-config      Only save configuration, don't run customization"
            echo "  -f, --config-file FILE Use specific config file (default: ~/.macos-setup-config)"
            echo "  -h, --help             Show this help message"
            echo
            echo "Config file location: $CONFIG_FILE"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Load existing config if requested or if skipping prompts
if [[ "$USE_CONFIG" == true ]] || [[ "$SKIP_PROMPTS" == true ]]; then
    if load_config; then
        echo "Loaded system customization configuration:"
        echo "  Dock auto-hide: ${SET_DOCK_AUTOHIDE:-"n"}, Trackpad click: ${SET_TRACKPAD_CLICK:-"n"}"
        echo "  Disable Stage Manager wallpaper click: ${DISABLE_STAGE_MANAGER:-"n"}"
        echo "  Show hidden files: ${SHOW_HIDDEN_FILES:-"n"}, Show extensions: ${SHOW_FILE_EXTENSIONS:-"n"}"
        echo "  Show path bar: ${SHOW_PATH_BAR:-"n"}, Show status bar: ${SHOW_STATUS_BAR:-"n"}"
        echo "  Always show scrollbars: ${ALWAYS_SHOW_SCROLLBARS:-"n"}"
        echo "  Dock - Remove: ${DOCK_REMOVE_ITEMS:-"(none)"}"
        echo "  Dock - Add: ${DOCK_ADD_ITEMS:-"(none)"}"
        echo
    else
        if [[ "$SKIP_PROMPTS" == true ]]; then
            print_error "No config file found at $CONFIG_FILE and --skip-prompts specified"
            exit 1
        else
            print_warning "No config file found, will create one"
        fi
    fi
fi

# Collect user preferences (skip if using config without prompts)
if [[ "$SKIP_PROMPTS" != true ]]; then
    if [[ "$USE_CONFIG" == true ]]; then
        echo "Review and update system customization settings (press Enter to keep current value):"
    else
        echo "Let's configure your system customization preferences:"
    fi
    echo

    # System preferences
    echo "System preferences (y/n):"
    prompt_with_default "Set Dock to auto-hide? [y/N]" "$SET_DOCK_AUTOHIDE" "SET_DOCK_AUTOHIDE"
    prompt_with_default "Enable trackpad tap-to-click? [y/N]" "$SET_TRACKPAD_CLICK" "SET_TRACKPAD_CLICK"
    prompt_with_default "Disable Stage Manager 'click wallpaper to reveal desktop'? [y/N]" "$DISABLE_STAGE_MANAGER" "DISABLE_STAGE_MANAGER"
    
    echo
    echo "Finder preferences (y/n):"
    prompt_with_default "Show hidden files in Finder? [y/N]" "$SHOW_HIDDEN_FILES" "SHOW_HIDDEN_FILES"
    prompt_with_default "Show file extensions in Finder? [y/N]" "$SHOW_FILE_EXTENSIONS" "SHOW_FILE_EXTENSIONS"
    prompt_with_default "Show path bar in Finder? [y/N]" "$SHOW_PATH_BAR" "SHOW_PATH_BAR"
    prompt_with_default "Show status bar in Finder? [y/N]" "$SHOW_STATUS_BAR" "SHOW_STATUS_BAR"
    prompt_with_default "Always show scrollbars? [y/N]" "$ALWAYS_SHOW_SCROLLBARS" "ALWAYS_SHOW_SCROLLBARS"

    # Dock customization
    echo
    echo "Dock customization:"
    echo "Enter app names separated by commas (e.g., 'Safari,Mail,Photos')"
    prompt_with_default "Remove from Dock" "$DOCK_REMOVE_ITEMS" "DOCK_REMOVE_ITEMS"
    prompt_with_default "Add to Dock" "$DOCK_ADD_ITEMS" "DOCK_ADD_ITEMS"

    # Save configuration
    echo
    read -p "Save this configuration for future use? [Y/n]: " SAVE_CONFIG_CHOICE
    if [[ ! "$SAVE_CONFIG_CHOICE" =~ ^[Nn]$ ]]; then
        save_config
    fi
fi

# Exit if only saving config
if [[ "$SAVE_CONFIG_ONLY" == true ]]; then
    save_config
    echo "Configuration saved. Run without --save-config to execute customization."
    exit 0
fi

print_divider
print_status "STEP 1: Configuring System Preferences"

# Apply system preferences
RESTART_DOCK=false
RESTART_FINDER=false

if [[ "$SET_DOCK_AUTOHIDE" =~ ^[Yy]$ ]]; then
    print_status "Setting Dock to auto-hide..."
    defaults write com.apple.dock autohide -bool true
    RESTART_DOCK=true
    print_success "Dock auto-hide enabled"
fi

if [[ "$SET_TRACKPAD_CLICK" =~ ^[Yy]$ ]]; then
    print_status "Enabling trackpad tap-to-click..."
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    print_success "Trackpad tap-to-click enabled"
fi

if [[ "$DISABLE_STAGE_MANAGER" =~ ^[Yy]$ ]]; then
    print_status "Disabling Stage Manager 'click wallpaper to reveal desktop'..."
    defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
    print_success "Stage Manager wallpaper click disabled"
fi

if [[ "$ALWAYS_SHOW_SCROLLBARS" =~ ^[Yy]$ ]]; then
    print_status "Setting scrollbars to always show..."
    defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
    print_success "Scrollbars will always be visible"
fi

print_divider
print_status "STEP 2: Configuring Finder Preferences"

if [[ "$SHOW_HIDDEN_FILES" =~ ^[Yy]$ ]]; then
    print_status "Showing hidden files in Finder..."
    defaults write com.apple.finder AppleShowAllFiles -bool true
    RESTART_FINDER=true
    print_success "Hidden files will be shown in Finder"
fi

if [[ "$SHOW_FILE_EXTENSIONS" =~ ^[Yy]$ ]]; then
    print_status "Showing file extensions in Finder..."
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    RESTART_FINDER=true
    print_success "File extensions will be shown in Finder"
fi

if [[ "$SHOW_PATH_BAR" =~ ^[Yy]$ ]]; then
    print_status "Showing path bar in Finder..."
    defaults write com.apple.finder ShowPathbar -bool true
    RESTART_FINDER=true
    print_success "Path bar will be shown in Finder"
fi

if [[ "$SHOW_STATUS_BAR" =~ ^[Yy]$ ]] && echo "  ✓ Status bar shown in Finder"
[[ "$ALWAYS_SHOW_SCROLLBARS" =~ ^[Yy]$ ]] && echo "  ✓ Scrollbars always visible"
[[ -n "$DOCK_REMOVE_ITEMS" ]] && echo "  ✓ Removed from Dock: $DOCK_REMOVE_ITEMS"
[[ -n "$DOCK_ADD_ITEMS" ]] && echo "  ✓ Added to Dock: $DOCK_ADD_ITEMS"
echo
[[ -f "$CONFIG_FILE" ]] && echo "Configuration saved to: $CONFIG_FILE"
echo "You may need to log out and back in for some changes to take full effect."; then
    print_status "Showing status bar in Finder..."
    defaults write com.apple.finder ShowStatusBar -bool true
    RESTART_FINDER=true
    print_success "Status bar will be shown in Finder"
fi

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

# Dock customization
if [[ -n "$DOCK_REMOVE_ITEMS" ]]; then
    print_status "Removing items from Dock..."
    IFS=',' read -ra REMOVE_APPS <<< "$DOCK_REMOVE_ITEMS"
    for app in "${REMOVE_APPS[@]}"; do
        app=$(echo "$app" | xargs)  # Trim whitespace
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
        app=$(echo "$app" | xargs)  # Trim whitespace
        if [[ -n "$app" ]]; then
            print_status "Adding $app to Dock..."
            # Try common locations for the app
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

# Restart services to apply changes
if [[ "$RESTART_DOCK" == true ]]; then
    print_status "Restarting Dock..."
    killall Dock
    print_success "Dock restarted"
fi

if [[ "$RESTART_FINDER" == true ]]; then
    print_status "Restarting Finder..."
    killall Finder
    print_success "Finder restarted"
fi

print_divider
print_success "System customization complete! 🎉"
echo
echo "Summary of customizations applied:"
[[ "$SET_DOCK_AUTOHIDE" =~ ^[Yy]$ ]] && echo "  ✓ Dock set to auto-hide"
[[ "$SET_TRACKPAD_CLICK" =~ ^[Yy]$ ]] && echo "  ✓ Trackpad tap-to-click enabled"
[[ "$DISABLE_STAGE_MANAGER" =~ ^[Yy]$ ]] && echo "  ✓ Stage Manager wallpaper click disabled"
[[ "$SHOW_HIDDEN_FILES" =~ ^[Yy]$ ]] && echo "  ✓ Hidden files shown in Finder"
[[ "$SHOW_FILE_EXTENSIONS" =~ ^[Yy]$ ]] && echo "  ✓ File extensions shown in Finder"
[[ "$SHOW_PATH_BAR" =~ ^[Yy]$ ]] && echo "  ✓ Path bar shown in Finder"
[[ "$SHOW_STATUS_BAR" =~ ^[Yy]$ ]]