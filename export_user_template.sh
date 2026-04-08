#!/bin/bash

# Export user preferences as a reusable template archive
# Creates a .tar.gz that can be applied to new users on any Mac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$SCRIPT_DIR/common.sh" ]] && source "$SCRIPT_DIR/common.sh" || {
    print_status() { echo "[INFO] $1"; }
    print_success() { echo "[SUCCESS] $1"; }
    print_warning() { echo "[WARNING] $1"; }
    print_error() { echo "[ERROR] $1"; }
}

echo "📦 User Template Exporter"
echo "=========================="
echo

# List available users
echo "Available users:"
for USER_HOME in /Users/*/Library; do
    USER_DIR=$(echo "$USER_HOME" | cut -d'/' -f3)
    [[ "$USER_DIR" == "Shared" || "$USER_DIR" == ".localized" ]] && continue
    echo "  - $USER_DIR"
done
echo

read -p "Export settings from user: " SOURCE_USER

if [[ -z "$SOURCE_USER" ]]; then
    echo "Error: user required"
    exit 1
fi

SOURCE_HOME="/Users/$SOURCE_USER"
if [[ ! -d "$SOURCE_HOME/Library/Preferences" ]]; then
    print_error "User '$SOURCE_USER' not found or has no preferences"
    exit 1
fi

# Default output location
DEFAULT_OUTPUT="$SCRIPT_DIR/user_template.tar.gz"
read -p "Save template to [$DEFAULT_OUTPUT]: " OUTPUT_FILE
OUTPUT_FILE="${OUTPUT_FILE:-$DEFAULT_OUTPUT}"

# ─────────────────────────────────────────────────────────────────────────────
# Build file list
# ─────────────────────────────────────────────────────────────────────────────

TEMP_DIR=$(mktemp -d)
TEMPLATE_DIR="$TEMP_DIR/user_template"
mkdir -p "$TEMPLATE_DIR/Library/Preferences"

# Preference plists to capture
PREFS=(
    "com.apple.dock.plist"
    "com.apple.finder.plist"
    "com.apple.WindowManager.plist"
    "com.apple.NSGlobalDomain.plist"
)

print_status "Collecting preferences from '$SOURCE_USER'..."

for PREF in "${PREFS[@]}"; do
    SRC="$SOURCE_HOME/Library/Preferences/$PREF"
    if [[ -f "$SRC" ]]; then
        cp "$SRC" "$TEMPLATE_DIR/Library/Preferences/"
        print_success "  $PREF"
    else
        print_warning "  $PREF — not found, skipping"
    fi
done

# Dock application support (Ventura+ stores dock state here)
if [[ -d "$SOURCE_HOME/Library/Application Support/Dock" ]]; then
    mkdir -p "$TEMPLATE_DIR/Library/Application Support/Dock"
    cp -R "$SOURCE_HOME/Library/Application Support/Dock/"* "$TEMPLATE_DIR/Library/Application Support/Dock/" 2>/dev/null
    print_success "  Library/Application Support/Dock/"
fi

# SetupAssistant — generate fresh skip-all prefs rather than copying user-specific ones
print_status "Generating Setup Assistant skip preferences..."
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_BUILD=$(sw_vers -buildVersion)

defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeCloudSetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup2 -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeePrivacy -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeSiriSetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeAccessibility -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeAppearanceSetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeScreenTime -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeTrueTonePrivacy -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeTouchIDSetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeApplePaySetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" DidSeeAISetup -bool true
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" LastSeenCloudProductVersion -string "$MACOS_VERSION"
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" LastPreLoginTasksPerformedBuild -string "$MACOS_BUILD"
defaults write "$TEMPLATE_DIR/Library/Preferences/com.apple.SetupAssistant" LastPreLoginTasksPerformedVersion -string "$MACOS_VERSION"
print_success "  com.apple.SetupAssistant.plist (skip all wizards)"

# ─────────────────────────────────────────────────────────────────────────────
# Create archive
# ─────────────────────────────────────────────────────────────────────────────

print_status "Creating template archive..."
cd "$TEMP_DIR"
tar czf "$OUTPUT_FILE" -C "$TEMPLATE_DIR" .

# Show what's in it
echo
echo "Template contents:"
tar tzf "$OUTPUT_FILE" | sed 's/^/  /'
echo
FILESIZE=$(du -h "$OUTPUT_FILE" | awk '{print $1}')
print_success "Template saved to: $OUTPUT_FILE ($FILESIZE)"
echo
echo "Usage with setup_user.sh:"
echo "  sudo bash setup_user.sh -t $OUTPUT_FILE"
echo
echo "Or copy to another Mac and use there."
echo "Safe to commit to git — contains no passwords or personal data."

# Cleanup
rm -rf "$TEMP_DIR"
