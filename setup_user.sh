#!/bin/bash

# Create a new macOS user account
# Supports: template archive (-t), local template user, or macOS defaults
# Skips the new account setup wizards
# Must run as root (sudo)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$SCRIPT_DIR/common.sh" ]] && source "$SCRIPT_DIR/common.sh" || {
    print_status() { echo "[INFO] $1"; }
    print_success() { echo "[SUCCESS] $1"; }
    print_warning() { echo "[WARNING] $1"; }
    print_error() { echo "[ERROR] $1"; }
}

# ─────────────────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────────────────

TEMPLATE_ARCHIVE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--template)
            TEMPLATE_ARCHIVE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: sudo $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  -t, --template FILE  Apply settings from a template archive (.tar.gz)"
            echo "                       Created by export_user_template.sh"
            echo "  -h, --help           Show this help"
            echo
            echo "Without -t, you can copy settings from a local user interactively."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage"
            exit 1
            ;;
    esac
done

echo "👤 macOS User Account Creator"
echo "=============================="
echo

# Root check
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root: sudo $0"
    exit 1
fi

# Auto-detect template in script directory if not specified
if [[ -z "$TEMPLATE_ARCHIVE" && -f "$SCRIPT_DIR/user_template.tar.gz" ]]; then
    print_status "Found template: $SCRIPT_DIR/user_template.tar.gz"
    read -p "Use this template? [Y/n]: " USE_AUTO
    if [[ ! "$USE_AUTO" =~ ^[Nn]$ ]]; then
        TEMPLATE_ARCHIVE="$SCRIPT_DIR/user_template.tar.gz"
    fi
fi

# Validate template if specified
if [[ -n "$TEMPLATE_ARCHIVE" && ! -f "$TEMPLATE_ARCHIVE" ]]; then
    print_error "Template not found: $TEMPLATE_ARCHIVE"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Collect account details
# ─────────────────────────────────────────────────────────────────────────────

read -p "Full name (e.g. 'John Smith'): " FULLNAME
if [[ -z "$FULLNAME" ]]; then
    echo "Error: full name required"
    exit 1
fi

# Suggest a short name based on full name (lowercase first name)
SUGGESTED_SHORT=$(echo "$FULLNAME" | awk '{print tolower($1)}')
read -p "Account short name [$SUGGESTED_SHORT]: " SHORTNAME
SHORTNAME="${SHORTNAME:-$SUGGESTED_SHORT}"

# Validate short name
if [[ "$SHORTNAME" =~ [^a-z0-9._-] ]]; then
    print_error "Short name can only contain lowercase letters, numbers, dots, hyphens, underscores"
    exit 1
fi

# Check if user already exists
if id "$SHORTNAME" &>/dev/null; then
    print_error "User '$SHORTNAME' already exists"
    exit 1
fi

# Password
read -s -p "Password for $SHORTNAME: " PASSWORD
echo
if [[ -z "$PASSWORD" ]]; then
    echo "Error: password required"
    exit 1
fi
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo
if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    print_error "Passwords do not match"
    exit 1
fi

# Admin or standard
echo
read -p "Admin account? [y/N]: " IS_ADMIN
if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
    ADMIN_FLAG="-admin"
    ACCOUNT_TYPE="admin"
else
    ADMIN_FLAG=""
    ACCOUNT_TYPE="standard"
fi

# Template source: archive, local user, or none
TEMPLATE_USER=""
if [[ -z "$TEMPLATE_ARCHIVE" ]]; then
    echo
    echo "Copy Dock & Finder settings from an existing user?"
    echo "Available users:"
    for USER_HOME in /Users/*/Library; do
        USER_DIR=$(echo "$USER_HOME" | cut -d'/' -f3)
        [[ "$USER_DIR" == "Shared" || "$USER_DIR" == ".localized" ]] && continue
        echo "  - $USER_DIR"
    done
    echo
    read -p "Template user (leave blank to skip): " TEMPLATE_USER

    if [[ -n "$TEMPLATE_USER" && ! -d "/Users/$TEMPLATE_USER" ]]; then
        print_warning "User '$TEMPLATE_USER' not found — skipping template"
        TEMPLATE_USER=""
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary & confirm
# ─────────────────────────────────────────────────────────────────────────────

echo
echo "Summary:"
echo "  Full name:    $FULLNAME"
echo "  Short name:   $SHORTNAME"
echo "  Account type: $ACCOUNT_TYPE"
if [[ -n "$TEMPLATE_ARCHIVE" ]]; then
    echo "  Template:     $TEMPLATE_ARCHIVE"
elif [[ -n "$TEMPLATE_USER" ]]; then
    echo "  Template:     local user '$TEMPLATE_USER'"
else
    echo "  Template:     none (macOS defaults)"
fi
echo
read -p "Create this account? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Create the account
# ─────────────────────────────────────────────────────────────────────────────

print_status "Creating user '$SHORTNAME'..."
sysadminctl -addUser "$SHORTNAME" -fullName "$FULLNAME" -password "$PASSWORD" $ADMIN_FLAG

if ! id "$SHORTNAME" &>/dev/null; then
    print_error "Failed to create user"
    exit 1
fi
print_success "User '$SHORTNAME' created ($ACCOUNT_TYPE)"

# Get the new user's home directory
NEW_HOME=$(dscl . -read /Users/"$SHORTNAME" NFSHomeDirectory | awk '{print $2}')

# ─────────────────────────────────────────────────────────────────────────────
# Ensure home directory exists with proper structure
# ─────────────────────────────────────────────────────────────────────────────

if [[ ! -d "$NEW_HOME/Library/Preferences" ]]; then
    print_status "Initializing home directory..."
    su - "$SHORTNAME" -c "true" 2>/dev/null
    sleep 2
fi

mkdir -p "$NEW_HOME/Library/Preferences"

# ─────────────────────────────────────────────────────────────────────────────
# Apply template (archive or local user)
# ─────────────────────────────────────────────────────────────────────────────

SETUP_ASSISTANT_DONE=false

if [[ -n "$TEMPLATE_ARCHIVE" ]]; then
    # ── Template from archive ──
    print_status "Applying template from archive: $(basename "$TEMPLATE_ARCHIVE")"
    tar xzf "$TEMPLATE_ARCHIVE" -C "$NEW_HOME"

    # Check if SetupAssistant was included in the archive
    if [[ -f "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant.plist" ]]; then
        SETUP_ASSISTANT_DONE=true
        print_success "Template applied (includes Setup Assistant skip)"
    else
        print_success "Template applied"
    fi

elif [[ -n "$TEMPLATE_USER" ]]; then
    # ── Template from local user ──
    TEMPLATE_HOME="/Users/$TEMPLATE_USER"
    print_status "Copying settings from '$TEMPLATE_USER'..."

    PREFS_TO_COPY=(
        "com.apple.dock.plist"
        "com.apple.finder.plist"
        "com.apple.WindowManager.plist"
        "com.apple.NSGlobalDomain.plist"
    )

    for PREF in "${PREFS_TO_COPY[@]}"; do
        SRC="$TEMPLATE_HOME/Library/Preferences/$PREF"
        DST="$NEW_HOME/Library/Preferences/$PREF"
        if [[ -f "$SRC" ]]; then
            cp "$SRC" "$DST"
            print_success "  Copied $PREF"
        else
            print_warning "  $PREF not found — skipping"
        fi
    done

    # Dock application support (Ventura+)
    if [[ -d "$TEMPLATE_HOME/Library/Application Support/Dock" ]]; then
        mkdir -p "$NEW_HOME/Library/Application Support/Dock"
        cp -R "$TEMPLATE_HOME/Library/Application Support/Dock/"* "$NEW_HOME/Library/Application Support/Dock/" 2>/dev/null
        print_success "  Copied Dock application support data"
    fi

    print_success "Template settings applied from '$TEMPLATE_USER'"
else
    print_status "No template — account will use macOS defaults"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Skip Setup Assistant wizards (if not already done by template)
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$SETUP_ASSISTANT_DONE" == false ]]; then
    print_status "Configuring Setup Assistant to skip wizards..."

    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_BUILD=$(sw_vers -buildVersion)

    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeCloudSetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup2 -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeePrivacy -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeSiriSetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeAccessibility -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeAppearanceSetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeScreenTime -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeTrueTonePrivacy -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeTouchIDSetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeApplePaySetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" DidSeeAISetup -bool true
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" LastSeenCloudProductVersion -string "$MACOS_VERSION"
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" LastPreLoginTasksPerformedBuild -string "$MACOS_BUILD"
    defaults write "$NEW_HOME/Library/Preferences/com.apple.SetupAssistant" LastPreLoginTasksPerformedVersion -string "$MACOS_VERSION"

    print_success "Setup Assistant wizards will be skipped"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Fix ownership of entire home directory
# ─────────────────────────────────────────────────────────────────────────────

print_status "Fixing home directory ownership..."
chown -R "$SHORTNAME" "$NEW_HOME"
print_success "Ownership set"

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────

echo
print_success "Account '$SHORTNAME' is ready! 🎉"
echo
echo "  Full name:    $FULLNAME"
echo "  Short name:   $SHORTNAME"
echo "  Account type: $ACCOUNT_TYPE"
echo "  Home:         $NEW_HOME"
if [[ -n "$TEMPLATE_ARCHIVE" ]]; then
    echo "  Template:     $(basename "$TEMPLATE_ARCHIVE")"
elif [[ -n "$TEMPLATE_USER" ]]; then
    echo "  Template:     $TEMPLATE_USER (local)"
fi
echo "  Setup wizard: skipped"
echo
echo "The user can now log in at the login screen."
