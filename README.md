# macOS Setup Scripts

Two complementary scripts for streamlined macOS setup and customization.

## Scripts Overview

### `install-software.sh`
Installs Homebrew and applications with macOS update checking.

### `customize-system.sh`
Configures Finder, Dock, and system preferences.

## Quick Start

```bash
# First-time setup
./install-software.sh
./customize-system.sh

# Unattended setup (uses saved config)
./install-software.sh -s
./customize-system.sh -s
```

## Command Line Options

Both scripts support the same arguments:

| Short | Long | Description |
|-------|------|-------------|
| `-c` | `--use-config` | Load config file (still prompts for missing values) |
| `-s` | `--skip-prompts` | Use config file without prompts (fails if no config) |
| `-o` | `--save-config` | Only save configuration, don't run |
| `-f` | `--config-file` | Use specific config file |
| `-h` | `--help` | Show help message |

## Software Installed

### Homebrew Applications
- **Chrome** - Web browser
- **Firefox** - Web browser  
- **Sublime Text** - Premium text editor
- **IINA** - Media player
- **VLC** - Media player
- **1Password** - Password manager
- **Google Drive** - Cloud storage
- **Malwarebytes** - Anti-malware
- **Stats** - System monitor

### Special Applications
- **Acronis Cyber Protect Connect Quick Assist** - Remote support (manual download)

### Manual Setup Reminders
- **Microsoft Office** - Requires office.com login
- **Printer Setup** - Opens System Preferences

## System Customizations

### Finder Settings
- Show file extensions
- Show path bar
- Show status bar

### System Preferences
- Dock auto-hide
- Trackpad tap-to-click
- Disable Stage Manager wallpaper click
- Always show scrollbars

### Dock Management
- Remove unwanted apps (comma-separated: `Launchpad,Reminders`)
- Add apps (comma-separated: `Google Chrome,Sublime Text`)
- Auto-installs `dockutil` if needed

## Configuration File

Both scripts use `~/.macos-setup.cfg` for settings:

```bash
# Software Installation Settings
COMPUTER_NAME="My MacBook Pro"
INSTALL_CHROME="y"
INSTALL_FIREFOX="y"
INSTALL_SUBLIME_TEXT="y"
# ... other software settings

# System Customization Settings  
SET_DOCK_AUTOHIDE="y"
SHOW_FILE_EXTENSIONS="y"
DOCK_REMOVE_ITEMS="Safari,Mail,Photos,Launchpad"
DOCK_ADD_ITEMS="Google Chrome,Sublime Text"
# ... other system settings
```

A template configuration file (`macos-setup.cfg.template`) is provided with recommended defaults.

## Usage Examples

```bash
# Interactive setup with config save
./install-software.sh
./customize-system.sh

# Use existing config with review
./install-software.sh -c
./customize-system.sh -c

# Completely unattended
./install-software.sh -s && ./customize-system.sh -s

# Save config for later use
./install-software.sh -o
./customize-system.sh -o

# Use custom config file
./install-software.sh -f ~/my-setup.cfg -s

# Use provided template
cp macos-setup.cfg.template ~/.macos-setup.cfg
./install-software.sh -s && ./customize-system.sh -s
```

## Features

### Software Installation Script
- **macOS Updates** - Detects and offers to install system updates
- **Homebrew Management** - Installs Homebrew and fixes permissions
- **App Installation** - Installs selected apps via Homebrew
- **Manual Downloads** - Handles Acronis download/installation
- **Computer Naming** - Sets system hostname

### System Customization Script
- **Finder Tweaks** - Enhances Finder interface
- **System Settings** - Configures trackpad, Dock, scrollbars
- **Dock Management** - Add/remove Dock items automatically
- **Smart Dependencies** - Auto-installs dockutil when needed

## Requirements

- **macOS** (tested on recent versions)
- **Internet connection** for downloads
- **Admin privileges** for some operations (computer naming, updates)

## Notes

- Scripts default all software and settings to "Yes" (press Enter to install/enable)
- Press "n" to skip any software installation or system setting
- Config file is shared between both scripts
- Homebrew permissions are automatically fixed for multi-user setups
- Stage Manager setting only disables wallpaper click, not Stage Manager itself
- Template config file provided with recommended defaults