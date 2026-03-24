#!/bin/bash

# Configuration
USER="dcxadmin"
REALNAME="DCX Admin"
PASS="${DCXADMIN_PASS:?Error: Search 1P for DCXADMIN_PASS first}"
UID_WANTED="499"
HOME_DIR="/private/var/$USER"

# Identify the currently logged-in console user
# (More reliable than 'whoami' when running under sudo)
CURRENT_USER=$(stat -f '%Su' /dev/console)

# 1. Check if the username already exists
if id -u "$USER" >/dev/null 2>&1; then
    echo "User $USER already exists. Ensuring it is hidden..."
else
    # 2. Check if the UID is already taken by a different user
    UID_TAKEN=$(dscl . -search /Users UniqueID "$UID_WANTED" | awk '{print $1}')
    
    if [ ! -z "$UID_TAKEN" ]; then
        echo "Error: UID $UID_WANTED is already taken by user: $UID_TAKEN"
        echo "Please change UID_WANTED in the script to 498 or 497."
        exit 1
    fi

    echo "Creating hidden admin $USER..."
    # sysadminctl is best for M3 because it handles SecureToken correctly
    sysadminctl -addUser "$USER" -fullName "$REALNAME" -UID "$UID_WANTED" -password "$PASS" -home "$HOME_DIR" -admin
fi

# 3. Apply the "Invisibility Cloak"
dscl . create /Users/"$USER" IsHidden 1

# 4. Hide all users under UID 500 from the login window
defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES

echo
echo "Setup complete. To login, press Option+Return at the login screen."
echo
echo "--- SECURE TOKEN STATUS ---"

# 5. Check SecureToken status for the new user
TOKEN_STATUS=$(sysadminctl -secureTokenStatus "$USER" 2>&1)

if echo "$TOKEN_STATUS" | grep -q "ENABLED"; then
    echo "✅ Success: $USER already has a SecureToken."
else
    echo "⚠️  Attention: $USER does NOT have a SecureToken (Disabled)."
    echo "On modern Macs, you must manually 'vouch' for this new user using your current account ($CURRENT_USER)."
    echo
    echo "Run this command now to fix it:"
    echo "sudo sysadminctl -adminUser $CURRENT_USER -adminPassword - -secureTokenOn $USER -password -"
    echo
    echo "(It will ask for your $CURRENT_USER password first, then the $USER password.)"
fi
echo