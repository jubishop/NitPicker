#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "bin/nitpicker" ]; then
    print_error "This script must be run from the NitPicker project root directory"
    exit 1
fi

# Make the script executable
chmod +x bin/nitpicker

# Determine install directory
if [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

print_info "Installing NitPicker to $INSTALL_DIR"

# Create symbolic link
ln -sf "$(pwd)/bin/nitpicker" "$INSTALL_DIR/nitpicker"

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_warning "$INSTALL_DIR is not in your PATH"
    print_info "Add the following line to your shell configuration file:"
    print_info "export PATH=\"$INSTALL_DIR:\$PATH\""
    
    # Try to add to common shell config files
    for shell_config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$shell_config" ]; then
            if ! grep -q "$INSTALL_DIR" "$shell_config"; then
                print_info "Adding $INSTALL_DIR to PATH in $shell_config"
                echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
                break
            fi
        fi
    done
fi

# Set up config directory
CONFIG_DIR="$HOME/.config/nitpicker"
PROMPT_FILE="$CONFIG_DIR/prompt"

print_info "Setting up configuration directory at $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# Copy default prompt if it doesn't exist
if [ ! -f "$PROMPT_FILE" ]; then
    if [ -f "config/prompt" ]; then
        cp "config/prompt" "$PROMPT_FILE"
        print_info "Default prompt file installed to $PROMPT_FILE"
    else
        print_error "Default prompt file not found at config/prompt"
        exit 1
    fi
else
    print_info "Prompt file already exists at $PROMPT_FILE"
fi

print_info "Installation complete!"
print_info ""
print_info "To get started:"
print_info "1. Set your OpenRouter API key: export OPENROUTER_API_KEY=\"your_api_key\""
print_info "2. Navigate to a git repository with staged changes"
print_info "3. Run: nitpicker"
print_info ""
print_info "For more information, see the README.md file"

# Test installation
if command -v nitpicker >/dev/null 2>&1; then
    print_info "✓ nitpicker is now available in your PATH"
else
    print_warning "nitpicker may not be immediately available in your PATH"
    print_info "You may need to restart your shell or run: source ~/.bashrc (or equivalent)"
fi