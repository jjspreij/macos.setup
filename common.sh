#!/bin/bash

# common.sh — Shared functions for macOS setup scripts
# Source this file at the top of each script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "$SCRIPT_DIR/common.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set DIVIDER_ICON before sourcing to customize (default: ═)
DIVIDER_ICON="${DIVIDER_ICON:-═}"

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
    echo -e "${BLUE}${DIVIDER_ICON}════════════════════════════════════════════════════════════════════════════════${DIVIDER_ICON}${NC}"
    echo
}

# Prompt for input with a default value
# Usage: prompt_with_default "Prompt text" "default_value" "VAR_NAME"
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

# Prompt yes/no with a default
# Usage: prompt_yn "Do something?" "y" "VAR_NAME"
prompt_yn() {
    local prompt="$1"
    local default="$2"  # y or n
    local var_name="$3"

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " input
        if [[ "$input" =~ ^[Nn]$ ]]; then
            eval "$var_name='n'"
        else
            eval "$var_name='y'"
        fi
    else
        read -p "$prompt [y/N]: " input
        if [[ "$input" =~ ^[Yy]$ ]]; then
            eval "$var_name='y'"
        else
            eval "$var_name='n'"
        fi
    fi
}
