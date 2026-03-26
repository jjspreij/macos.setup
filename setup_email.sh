#!/bin/bash

# Generate and install a .mobileconfig email profile
# Defaults: mail.webtic.net, IMAP 993 SSL, SMTP 587 SSL, @deappel.nl

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$SCRIPT_DIR/common.sh" ]] && source "$SCRIPT_DIR/common.sh"

# Defaults
DEFAULT_DOMAIN="deappel.nl"
IMAP_SERVER="mail.webtic.net"
SMTP_SERVER="mail.webtic.net"
IMAP_PORT=993
SMTP_PORT=587

echo "📧 Email Account Profile Generator"
echo "===================================="
echo
echo "Defaults: IMAP/SMTP = $IMAP_SERVER, SSL on, ports $IMAP_PORT/$SMTP_PORT"
echo "Email domain defaults to @$DEFAULT_DOMAIN"
echo

# Collect email address
read -p "Email address (e.g. 'john' for john@$DEFAULT_DOMAIN, or full address): " EMAIL_INPUT

if [[ -z "$EMAIL_INPUT" ]]; then
    echo "Error: email address required"
    exit 1
fi

# Append default domain if no @ present
if [[ "$EMAIL_INPUT" != *"@"* ]]; then
    EMAIL="${EMAIL_INPUT}@${DEFAULT_DOMAIN}"
else
    EMAIL="$EMAIL_INPUT"
fi

echo "  → Email: $EMAIL"

# Extract username (part before @) for IMAP/SMTP login
USERNAME="$EMAIL"

# Collect password
read -s -p "Password for $EMAIL: " PASSWORD
echo
if [[ -z "$PASSWORD" ]]; then
    echo "Error: password required"
    exit 1
fi

# Allow server overrides
echo
echo "Server settings (press Enter to keep defaults):"
read -p "IMAP server [$IMAP_SERVER]: " INPUT
[[ -n "$INPUT" ]] && IMAP_SERVER="$INPUT"

read -p "SMTP server [$SMTP_SERVER]: " INPUT
[[ -n "$INPUT" ]] && SMTP_SERVER="$INPUT"

read -p "IMAP port [$IMAP_PORT]: " INPUT
[[ -n "$INPUT" ]] && IMAP_PORT="$INPUT"

read -p "SMTP port [$SMTP_PORT]: " INPUT
[[ -n "$INPUT" ]] && SMTP_PORT="$INPUT"

# Generate UUIDs
PROFILE_UUID=$(uuidgen)
MAIL_PAYLOAD_UUID=$(uuidgen)

# Sanitize email for filename and identifier
EMAIL_SAFE=$(echo "$EMAIL" | tr '@.' '_')
PROFILE_FILE="/tmp/mail_${EMAIL_SAFE}.mobileconfig"

# Generate the .mobileconfig XML
cat > "$PROFILE_FILE" << PROFILE_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>EmailAccountDescription</key>
            <string>$EMAIL</string>
            <key>EmailAccountType</key>
            <string>EmailTypeIMAP</string>
            <key>EmailAddress</key>
            <string>$EMAIL</string>
            <key>IncomingMailServerAuthentication</key>
            <string>EmailAuthPassword</string>
            <key>IncomingMailServerHostName</key>
            <string>$IMAP_SERVER</string>
            <key>IncomingMailServerPortNumber</key>
            <integer>$IMAP_PORT</integer>
            <key>IncomingMailServerUseSSL</key>
            <true/>
            <key>IncomingMailServerUsername</key>
            <string>$USERNAME</string>
            <key>IncomingPassword</key>
            <string>$PASSWORD</string>
            <key>OutgoingMailServerAuthentication</key>
            <string>EmailAuthPassword</string>
            <key>OutgoingMailServerHostName</key>
            <string>$SMTP_SERVER</string>
            <key>OutgoingMailServerPortNumber</key>
            <integer>$SMTP_PORT</integer>
            <key>OutgoingMailServerUseSSL</key>
            <true/>
            <key>OutgoingMailServerUsername</key>
            <string>$USERNAME</string>
            <key>OutgoingPassword</key>
            <string>$PASSWORD</string>
            <key>PayloadDescription</key>
            <string>Email account for $EMAIL</string>
            <key>PayloadDisplayName</key>
            <string>$EMAIL</string>
            <key>PayloadIdentifier</key>
            <string>com.webtic.mail.$EMAIL_SAFE</string>
            <key>PayloadType</key>
            <string>com.apple.mail.managed</string>
            <key>PayloadUUID</key>
            <string>$MAIL_PAYLOAD_UUID</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>Email configuration for $EMAIL</string>
    <key>PayloadDisplayName</key>
    <string>Mail: $EMAIL</string>
    <key>PayloadIdentifier</key>
    <string>com.webtic.mailprofile.$EMAIL_SAFE</string>
    <key>PayloadOrganization</key>
    <string>Webtic</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>$PROFILE_UUID</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
PROFILE_EOF

echo
echo "Profile generated: $PROFILE_FILE"
echo
echo "Summary:"
echo "  Email:       $EMAIL"
echo "  IMAP:        $IMAP_SERVER:$IMAP_PORT (SSL)"
echo "  SMTP:        $SMTP_SERVER:$SMTP_PORT (SSL)"
echo "  Username:    $USERNAME"
echo

read -p "Open profile for installation? [Y/n]: " OPEN_PROFILE
if [[ ! "$OPEN_PROFILE" =~ ^[Nn]$ ]]; then
    open "$PROFILE_FILE"
    echo
    echo "Next steps:"
    echo "  1. Go to System Settings → General → Device Management"
    echo "     (or Privacy & Security → Profiles on older macOS)"
    echo "  2. Click the profile to install it"
    echo "  3. Mail.app will pick up the account automatically"
    echo
    echo "Note: the profile warning about 'unidentified' is normal — it's unsigned."
else
    DESKTOP_FILE="$HOME/Desktop/$(basename "$PROFILE_FILE")"
    cp "$PROFILE_FILE" "$DESKTOP_FILE"
    echo "Profile saved to: $DESKTOP_FILE"
    echo "Transfer to target Mac and double-click to install."
    echo "Delete the file after install (contains password in plain text)."
fi