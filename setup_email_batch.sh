#!/bin/bash

# Batch generate .mobileconfig email profiles from a text file
# Input: tab or space separated file with lines: email  password
# Defaults: mail.webtic.net, IMAP 993 SSL, SMTP 587 SSL, @deappel.nl

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$SCRIPT_DIR/common.sh" ]] && source "$SCRIPT_DIR/common.sh"

# Defaults
DEFAULT_DOMAIN="deappel.nl"
IMAP_SERVER="mail.webtic.net"
SMTP_SERVER="mail.webtic.net"
IMAP_PORT=993
SMTP_PORT=587

echo "📧 Batch Email Profile Generator"
echo "================================="
echo

# Check for input file
INPUT_FILE="${1:-}"
if [[ -z "$INPUT_FILE" ]]; then
    echo "Usage: $0 <accounts.txt>"
    echo
    echo "File format (tab or space separated):"
    echo "  john          password123"
    echo "  mary          password456"
    echo "  bob@other.com password789"
    echo
    echo "Names without @ get @$DEFAULT_DOMAIN appended."
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: file not found: $INPUT_FILE"
    exit 1
fi

# Create output directory on Desktop
OUTPUT_DIR="$HOME/Desktop/mail_profiles"
mkdir -p "$OUTPUT_DIR"

COUNT=0
ERRORS=0

while IFS=$'\t ' read -r EMAIL_INPUT PASSWORD REST; do
    # Skip empty lines and comments
    [[ -z "$EMAIL_INPUT" || "$EMAIL_INPUT" == \#* ]] && continue

    if [[ -z "$PASSWORD" ]]; then
        echo "⚠️  Skipping '$EMAIL_INPUT' — no password"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Append default domain if no @ present
    if [[ "$EMAIL_INPUT" != *"@"* ]]; then
        EMAIL="${EMAIL_INPUT}@${DEFAULT_DOMAIN}"
    else
        EMAIL="$EMAIL_INPUT"
    fi

    USERNAME="$EMAIL"
    EMAIL_SAFE=$(echo "$EMAIL" | tr '@.' '_')

    PROFILE_UUID=$(uuidgen)
    MAIL_PAYLOAD_UUID=$(uuidgen)

    PROFILE_FILE="$OUTPUT_DIR/mail_${EMAIL_SAFE}.mobileconfig"

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

    echo "  ✓ $EMAIL → $(basename "$PROFILE_FILE")"
    COUNT=$((COUNT + 1))

done < <(cat "$INPUT_FILE"; echo)

echo
echo "Generated $COUNT profile(s) in: $OUTPUT_DIR"
[[ "$ERRORS" -gt 0 ]] && echo "Skipped $ERRORS line(s) with errors"
echo
echo "⚠️  These files contain passwords in plain text."
echo "Delete the profiles and input file after installing on target Macs."
