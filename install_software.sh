#!/bin/bash

# macOS Software Installation Script
# Installs Homebrew and selected applications
# Version: 1.7.0

set -e  # Exit on any error

SCRIPT_VERSION="1.7.0"
CONFIG_FILE="$HOME/.macos-setup.cfg"

echo "📦 macOS Software Installation Script v$SCRIPT_VERSION"
echo "====================================="
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
    echo -e "${BLUE}🔷════════════════════════════════════════════════════════════════════════════════🔷${NC}"
    echo
}

# Function to save config
save_config() {
    # Create config if it doesn't exist, or update software section if it does
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update existing config - remove old software settings and add new ones
        grep -v "^COMPUTER_NAME\|^INSTALL_" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" 2>/dev/null || true
        cat >> "${CONFIG_FILE}.tmp" << EOF
# Software Installation Settings - Updated $(date)
COMPUTER_NAME="$COMPUTER_NAME"
INSTALL_CHROME="$INSTALL_CHROME"
INSTALL_FIREFOX="$INSTALL_FIREFOX"
INSTALL_SUBLIME_TEXT="$INSTALL_SUBLIME_TEXT"
INSTALL_IINA="$INSTALL_IINA"
INSTALL_VLC="$INSTALL_VLC"
INSTALL_1PASSWORD="$INSTALL_1PASSWORD"
INSTALL_ACRONIS="$INSTALL_ACRONIS"
INSTALL_GOOGLE_DRIVE="$INSTALL_GOOGLE_DRIVE"
INSTALL_MALWAREBYTES="$INSTALL_MALWAREBYTES"
INSTALL_STATS="$INSTALL_STATS"
EOF
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    else
        cat > "$CONFIG_FILE" << EOF
# macOS Setup Configuration
# Generated on $(date)
COMPUTER_NAME="$COMPUTER_NAME"
INSTALL_CHROME="$INSTALL_CHROME"
INSTALL_FIREFOX="$INSTALL_FIREFOX"
INSTALL_SUBLIME_TEXT="$INSTALL_SUBLIME_TEXT"
INSTALL_IINA="$INSTALL_IINA"
INSTALL_VLC="$INSTALL_VLC"
INSTALL_1PASSWORD="$INSTALL_1PASSWORD"
INSTALL_ACRONIS="$INSTALL_ACRONIS"
INSTALL_GOOGLE_DRIVE="$INSTALL_GOOGLE_DRIVE"
INSTALL_MALWAREBYTES="$INSTALL_MALWAREBYTES"
INSTALL_STATS="$INSTALL_STATS"
EOF
    fi
    print_success "Software configuration saved to $CONFIG_FILE"
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
            echo "macOS Software Installation Script v$SCRIPT_VERSION"
            echo
            echo "Options:"
            echo "  -c, --use-config       Load settings from config file (still prompts for missing values)"
            echo "  -s, --skip-prompts     Use config file without any prompts (fails if no config)"
            echo "  -o, --save-config      Only save configuration, don't run installation"
            echo "  -f, --config-file FILE Use specific config file (default: ~/.macos-setup.cfg)"
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
        echo "Loaded software configuration:"
        echo "  Computer name: ${COMPUTER_NAME:-"(not set)"}"
        echo "  Chrome: ${INSTALL_CHROME:-"y"}, Firefox: ${INSTALL_FIREFOX:-"y"}, Sublime Text: ${INSTALL_SUBLIME_TEXT:-"y"}"
        echo "  IINA: ${INSTALL_IINA:-"y"}, VLC: ${INSTALL_VLC:-"y"}, 1Password: ${INSTALL_1PASSWORD:-"y"}"
        echo "  Acronis Quick Assist: ${INSTALL_ACRONIS:-"y"}, Google Drive: ${INSTALL_GOOGLE_DRIVE:-"y"}"
        echo "  Malwarebytes: ${INSTALL_MALWAREBYTES:-"y"}, Stats: ${INSTALL_STATS:-"y"}"
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
        echo "Review and update software selection (press Enter to keep current value):"
    else
        echo "Let's configure your software installation preferences:"
    fi
    echo

    # Computer name
    prompt_with_default "Enter the computer name (leave blank to skip)" "$COMPUTER_NAME" "COMPUTER_NAME"

    # Software selection
    echo
    echo "Select software to install (Y/n) - defaults to Yes:"
    prompt_with_default "Chrome? [Y/n]" "${INSTALL_CHROME:-"y"}" "INSTALL_CHROME"
    prompt_with_default "Firefox? [Y/n]" "${INSTALL_FIREFOX:-"y"}" "INSTALL_FIREFOX"
    prompt_with_default "Sublime Text? [Y/n]" "${INSTALL_SUBLIME_TEXT:-"y"}" "INSTALL_SUBLIME_TEXT"
    prompt_with_default "IINA? [Y/n]" "${INSTALL_IINA:-"y"}" "INSTALL_IINA"
    prompt_with_default "VLC? [Y/n]" "${INSTALL_VLC:-"y"}" "INSTALL_VLC"
    prompt_with_default "1Password? [Y/n]" "${INSTALL_1PASSWORD:-"y"}" "INSTALL_1PASSWORD"
    prompt_with_default "Google Drive? [Y/n]" "${INSTALL_GOOGLE_DRIVE:-"y"}" "INSTALL_GOOGLE_DRIVE"
    prompt_with_default "Malwarebytes? [Y/n]" "${INSTALL_MALWAREBYTES:-"y"}" "INSTALL_MALWAREBYTES"
    prompt_with_default "Stats (system monitor)? [Y/n]" "${INSTALL_STATS:-"y"}" "INSTALL_STATS"
    prompt_with_default "Acronis Cyber Protect Connect Quick Assist? [Y/n]" "${INSTALL_ACRONIS:-"y"}" "INSTALL_ACRONIS"

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
    echo "Configuration saved. Run without --save-config to execute installation."
    exit 0
fi

print_divider
print_status "STEP 1: Checking for macOS Updates"

# Check for macOS software updates
print_status "Checking for macOS software updates..."
UPDATE_OUTPUT=$(softwareupdate -l 2>/dev/null || true)
UPDATE_COUNT=$(echo "$UPDATE_OUTPUT" | grep -i "recommended.*yes" | wc -l | tr -d ' ')

if [[ "$UPDATE_COUNT" -gt 0 ]]; then
    print_warning "Found $UPDATE_COUNT recommended macOS update(s)"
    echo
    echo "$UPDATE_OUTPUT" | grep -i "recommended.*yes" -A 1 -B 1
    echo
    read -p "Install macOS updates now? This may require a restart [y/N]: " INSTALL_UPDATES
    if [[ "$INSTALL_UPDATES" =~ ^[Yy]$ ]]; then
        print_status "Installing macOS updates..."
        sudo softwareupdate -i -a
        print_success "macOS updates installed"
        print_warning "You may need to restart your Mac after the script completes"
    else
        print_status "Skipping macOS updates"
    fi
else
    print_success "macOS is up to date"
fi

print_divider
print_status "STEP 2: Setting up Homebrew"

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed"
else
    print_status "Homebrew already installed, updating..."
    
    # Check if current user has write access to Homebrew directories
    if [[ ! -w "/opt/homebrew" ]] && [[ -d "/opt/homebrew" ]]; then
        print_warning "Homebrew permission issue detected"
        print_status "Homebrew directories are not writable by current user: $(whoami)"
        echo
        read -p "Fix Homebrew permissions for current user? [Y/n]: " FIX_PERMISSIONS
        
        if [[ ! "$FIX_PERMISSIONS" =~ ^[Nn]$ ]]; then
            print_status "Fixing Homebrew permissions..."
            print_status "This will change ownership of Homebrew directories to: $(whoami)"
            
            # Fix ownership of Homebrew directories
            sudo chown -R $(whoami) /opt/homebrew
            
            # Ensure write permissions
            chmod u+w /opt/homebrew /opt/homebrew/etc/bash_completion.d /opt/homebrew/share/doc /opt/homebrew/share/man /opt/homebrew/share/man/man1 /opt/homebrew/share/zsh /opt/homebrew/share/zsh/site-functions /opt/homebrew/var/homebrew/locks 2>/dev/null || true
            
            print_success "Homebrew permissions fixed"
        else
            print_warning "Skipping permission fix - you may encounter errors during installation"
        fi
    fi
    
    brew update
fi

print_divider
print_status "STEP 3: Installing Applications via Homebrew"

# Install selected software
SOFTWARE_TO_INSTALL=()

# Check logic to handle both y/Y and empty (default Y)
if [[ -z "$INSTALL_CHROME" || "$INSTALL_CHROME" =~ ^[Yy]$ ]]; then
    INSTALL_CHROME="y"
    SOFTWARE_TO_INSTALL+=("google-chrome")
fi
if [[ -z "$INSTALL_FIREFOX" || "$INSTALL_FIREFOX" =~ ^[Yy]$ ]]; then
    INSTALL_FIREFOX="y"
    SOFTWARE_TO_INSTALL+=("firefox")
fi
if [[ -z "$INSTALL_SUBLIME_TEXT" || "$INSTALL_SUBLIME_TEXT" =~ ^[Yy]$ ]]; then
    INSTALL_SUBLIME_TEXT="y"
    SOFTWARE_TO_INSTALL+=("sublime-text")
fi
if [[ -z "$INSTALL_IINA" || "$INSTALL_IINA" =~ ^[Yy]$ ]]; then
    INSTALL_IINA="y"
    SOFTWARE_TO_INSTALL+=("iina")
fi
if [[ -z "$INSTALL_VLC" || "$INSTALL_VLC" =~ ^[Yy]$ ]]; then
    INSTALL_VLC="y"
    SOFTWARE_TO_INSTALL+=("vlc")
fi
if [[ -z "$INSTALL_1PASSWORD" || "$INSTALL_1PASSWORD" =~ ^[Yy]$ ]]; then
    INSTALL_1PASSWORD="y"
    SOFTWARE_TO_INSTALL+=("1password")
fi
if [[ -z "$INSTALL_GOOGLE_DRIVE" || "$INSTALL_GOOGLE_DRIVE" =~ ^[Yy]$ ]]; then
    INSTALL_GOOGLE_DRIVE="y"
    SOFTWARE_TO_INSTALL+=("google-drive")
fi
if [[ -z "$INSTALL_MALWAREBYTES" || "$INSTALL_MALWAREBYTES" =~ ^[Yy]$ ]]; then
    INSTALL_MALWAREBYTES="y"
    SOFTWARE_TO_INSTALL+=("malwarebytes")
fi
if [[ -z "$INSTALL_STATS" || "$INSTALL_STATS" =~ ^[Yy]$ ]]; then
    INSTALL_STATS="y"
    SOFTWARE_TO_INSTALL+=("stats")
fi

if [ ${#SOFTWARE_TO_INSTALL[@]} -gt 0 ]; then
    print_status "Installing selected applications..."
    for app in "${SOFTWARE_TO_INSTALL[@]}"; do
        print_status "Installing $app..."
        if brew install --cask "$app"; then
            print_success "$app installed"
        else
            print_error "Failed to install $app"
        fi
    done
else
    print_warning "No Homebrew applications selected for installation"
fi

print_divider
print_status "STEP 4: Installing Special Applications"

# Handle Acronis separately since it's not in Homebrew
if [[ -z "$INSTALL_ACRONIS" || "$INSTALL_ACRONIS" =~ ^[Yy]$ ]]; then
    print_status "Downloading and installing Acronis Cyber Protect Connect Quick Assist..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the installer (filename will be determined by server)
    print_status "Downloading Acronis installer..."
    if curl -L -J -O "https://go.acronis.com/AcronisCyberProtectConnect_QAforMac"; then
        # Find the downloaded file (won't have .zip extension)
        DOWNLOADED_FILE=$(ls -t | head -1)
        
        if [[ -n "$DOWNLOADED_FILE" && -f "$DOWNLOADED_FILE" ]]; then
            # Rename to .zip for extraction
            ZIP_FILE="${DOWNLOADED_FILE}.zip"
            print_status "Renaming $DOWNLOADED_FILE to $ZIP_FILE"
            mv "$DOWNLOADED_FILE" "$ZIP_FILE"
            
            # Extract the zip
            print_status "Extracting $ZIP_FILE..."
            if unzip -q "$ZIP_FILE"; then
                # Look for the Acronis app (it has spaces in the name)
                if [[ -d "Acronis Cyber Protect Connect Quick Assist.app" ]]; then
                    print_status "Installing Acronis app to Applications..."
                    
                    # Remove existing installation if present
                    if [[ -d "/Applications/Acronis Cyber Protect Connect Quick Assist.app" ]]; then
                        print_status "Removing existing installation..."
                        rm -rf "/Applications/Acronis Cyber Protect Connect Quick Assist.app"
                    fi
                    
                    # Move the app to Applications
                    mv "Acronis Cyber Protect Connect Quick Assist.app" /Applications/
                    print_success "Acronis app installed to Applications"
                else
                    print_warning "Could not find 'Acronis Cyber Protect Connect Quick Assist.app'"
                    print_status "Contents found:"
                    ls -la
                fi
            else
                print_error "Failed to extract $ZIP_FILE"
            fi
        else
            print_error "No file found after download"
        fi
    else
        print_error "Failed to download Acronis installer"
    fi
    
    # Return to original directory
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
else
    print_status "Acronis installation skipped"
fi

print_divider
print_status "STEP 5: Setting Computer Name"

# Set computer name
if [[ -n "$COMPUTER_NAME" ]]; then
    print_status "Setting computer name to '$COMPUTER_NAME'..."
    sudo scutil --set ComputerName "$COMPUTER_NAME"
    sudo scutil --set HostName "$COMPUTER_NAME"
    sudo scutil --set LocalHostName "${COMPUTER_NAME// /-}"  # Replace spaces with hyphens
    print_success "Computer name set"
else
    print_status "Computer name change skipped"
fi

print_divider
print_success "Software installation complete! 🎉"

# Office installation reminder
print_divider
print_status "📄 Microsoft Office Setup"
echo "Microsoft Office requires manual installation through your Microsoft account:"
echo "1. Go to https://office.com"
echo "2. Sign in with your Microsoft/work account"
echo "3. Install Office apps (Word, Excel, PowerPoint, etc.)"
echo
echo "Note: Office installation cannot be automated due to licensing requirements."

# Printer setup reminder
print_divider
print_status "🖨️ Printer Setup Reminder"
echo "Don't forget to set up your printer!"
echo "You can do this in System Preferences > Printers & Scanners"
echo "Or use: System Settings > Printers & Scanners (macOS Ventura+)"
echo
read -p "Open Printer settings now? [y/N]: " OPEN_PRINTER_SETTINGS
if [[ "$OPEN_PRINTER_SETTINGS" =~ ^[Yy]$ ]]; then
    print_status "Opening Printer settings..."
    open "x-apple.systempreferences:com.apple.preference.printfax"
fi

print_divider
echo
echo "Summary of installed software:"
[[ -n "$COMPUTER_NAME" ]] && echo "  ✓ Computer name set to: $COMPUTER_NAME"
[[ ${#SOFTWARE_TO_INSTALL[@]} -gt 0 ]] && echo "  ✓ Installed via Homebrew: $(IFS=', '; echo "${SOFTWARE_TO_INSTALL[*]}")"
[[ -z "$INSTALL_ACRONIS" || "$INSTALL_ACRONIS" =~ ^[Yy]$ ]] && echo "  ✓ Installed Acronis Cyber Protect Connect Quick Assist"
echo
[[ -f "$CONFIG_FILE" ]] && echo "Configuration saved to: $CONFIG_FILE"
echo "Run 'customize-system.sh' next to configure Finder, Dock, and system preferences!"