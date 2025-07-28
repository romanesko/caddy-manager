#!/bin/bash

# Caddy Manager Installer Script
# Version: 1.0.11

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="romanesko/caddy-manager"
LATEST_VERSION="v1.0.11"
INSTALL_DIR="caddy-manager"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to detect OS and architecture
detect_system() {
    print_status "Detecting system..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    else
        print_error "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    print_status "Detected: $OS-$ARCH"
}

# Function to download and extract
download_and_extract() {
    local version=$1
    local os=$2
    local arch=$3
    
    local filename="caddy-manager-${os}-${arch}.tar.gz"
    local url="https://github.com/${REPO}/releases/download/${version}/${filename}"
    
    print_step "Downloading ${filename}..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download file
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$filename" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$url"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Check if download was successful
    if [[ ! -f "$filename" ]]; then
        print_error "Failed to download $filename"
        exit 1
    fi
    
    print_step "Extracting files..."
    
    # Extract to current directory
    tar -xzf "$filename"
    
    # Move files to target directory
    if [[ -d "$INSTALL_DIR" ]]; then
        # Update existing installation
        print_step "Updating existing installation..."
        
        # Backup existing .env if it exists
        if [[ -f "$INSTALL_DIR/.env" ]]; then
            cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
            print_status "Backed up existing .env file"
        fi
        
        # Copy new files, preserving .env
        cp -r caddy-manager-${os}-${arch}/* "$INSTALL_DIR/"
        
        # Restore .env if it was backed up
        if [[ -f "$INSTALL_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)" ]]; then
            cp "$INSTALL_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)" "$INSTALL_DIR/.env"
            print_status "Restored existing .env file"
        fi
        
    else
        # New installation
        print_step "Creating new installation..."
        mv caddy-manager-${os}-${arch} "$INSTALL_DIR"
        
        # Copy env.example to .env
        if [[ -f "$INSTALL_DIR/env.example" ]]; then
            cp "$INSTALL_DIR/env.example" "$INSTALL_DIR/.env"
            print_status "Created .env file from template"
        fi
    fi
    
    # Make binary executable
    chmod +x "$INSTALL_DIR/caddy-manager"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Function to show post-installation instructions
show_instructions() {
    echo
    print_status "Installation completed successfully!"
    echo
    echo "Next steps:"
    echo "1. cd $INSTALL_DIR"
    echo "2. Edit .env file with your settings:"
    echo "   - CADDYFILE_PATH (default: /etc/caddy/Caddyfile)"
    echo "   - AUTH_USERNAME and AUTH_PASSWORD"
    echo "   - Other settings as needed"
    echo "3. Run: make start"
    echo
    echo "The application will be available at: http://localhost:8000"
    echo
    print_warning "Note: You may need to run 'sudo make setup-sudo' for production use"
    echo
}

# Main installation logic
main() {
    echo "Caddy Manager Installer"
    echo "======================="
    echo
    
    # Detect system
    detect_system
    
    # Check if installation directory exists
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Directory '$INSTALL_DIR' already exists."
        echo -n "Do you want to update to the latest version? (y/N): "
        read -r response < /dev/tty
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_status "Updating existing installation..."
            download_and_extract "$LATEST_VERSION" "$OS" "$ARCH"
            print_status "Update completed!"
        else
            print_status "Installation cancelled."
            exit 0
        fi
    else
        print_status "Installing Caddy Manager..."
        download_and_extract "$LATEST_VERSION" "$OS" "$ARCH"
    fi
    
    # Show instructions
    show_instructions
}

# Run main function
main "$@" 