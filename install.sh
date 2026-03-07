#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Mistral Vibe Hybrid Setup - Installer Script
# ============================================================================
#
# This script installs the Mistral Vibe Hybrid Setup project
# It handles downloading, setup, and configuration automatically
#
# Usage: curl -sSL https://raw.githubusercontent.com/your-repo/mistral-vibe-hybrid/main/install.sh | bash
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    error "This script should NOT be run as root. Please run as normal user."
fi

# Check minimum requirements
check_requirements() {
    info "Checking system requirements..."
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed. Please install curl first."
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        error "git is required but not installed. Please install git first."
    fi
    
    # Check for python3
    if ! command -v python3 &> /dev/null; then
        error "python3 is required but not installed. Please install python3 first."
    fi
    
    info "✓ All requirements satisfied"
}

# Verify script integrity (if signature checking is enabled)
verify_integrity() {
    if [ -n "${VERIFY_SIGNATURE:-}" ]; then
        info "Verifying script integrity..."
        # In a real implementation, this would check GPG signatures
        # For now, we'll just show a warning
        warn "Signature verification not yet implemented. Proceeding anyway."
    fi
}

# Download and install
install_project() {
    info "Downloading Mistral Vibe Hybrid Setup..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'vibe_install')
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Clone repository
    info "Cloning repository..."
    if ! git clone --depth 1 https://github.com/your-repo/mistral-vibe-hybrid.git "$TEMP_DIR/mistral-vibe-hybrid" 2>/dev/null; then
        error "Failed to clone repository. Check your internet connection."
    fi
    
    cd "$TEMP_DIR/mistral-vibe-hybrid"
    
    # Make all scripts executable
    info "Setting up permissions..."
    find . -name "*.sh" -exec chmod +x {} \;
    chmod +x vibe-extended
    
    # Run the main setup
    info "Running setup..."
    if ! ./setup_mistral_vibe.sh; then
        error "Setup failed. Check the error messages above."
    fi
    
    # Move to final location
    INSTALL_DIR="${INSTALL_DIR:-$HOME/mistral-vibe-hybrid}"
    
    if [ -d "$INSTALL_DIR" ]; then
        warn "Installation directory $INSTALL_DIR already exists"
        read -p "Overwrite existing installation? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            error "Installation cancelled by user"
        fi
        rm -rf "$INSTALL_DIR"
    fi
    
    info "Installing to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    cp -r . "$INSTALL_DIR/"
    
    echo ""
    info "=========================================="
    info "  Installation Complete! ✅"
    info "=========================================="
    echo ""
    echo "Mistral Vibe Hybrid Setup has been installed to:"
    echo "  $INSTALL_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. cd $INSTALL_DIR"
    echo "  2. ./start_llm_server.sh       # Start multi-backend LLM server"
    echo "  3. ./vibe-extended             # Launch extended Vibe"
    echo ""
    echo "Documentation:"
    echo "  - Read README.md for complete setup guide"
    echo "  - Use CONTRIBUTING.md to learn how to contribute"
    echo ""
}

# Show help
show_help() {
    echo "Mistral Vibe Hybrid Setup Installer"
    echo ""
    echo "Usage:"
    echo "  install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --dir DIR           Install to specific directory (default: ~/mistral-vibe-hybrid)"
    echo "  --verify            Verify script signature (not yet implemented)"
    echo "  --version, -v       Show version information"
    echo ""
    echo "Examples:"
    echo "  install.sh                          # Default installation"
    echo "  install.sh --dir ~/my-vibe         # Custom install directory"
    echo "  curl ... | bash                    # Direct installation"
    echo ""
}

# Show version
show_version() {
    echo "Mistral Vibe Hybrid Setup Installer v1.0.0"
    echo "Copyright (c) 2024 Mistral Vibe Hybrid Setup"
    echo "License: MIT"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --verify)
            VERIFY_SIGNATURE="true"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Main installation process
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  Mistral Vibe Hybrid Setup Installer"
    echo "==========================================${NC}"
    echo ""
    
    check_requirements
    verify_integrity
    install_project
}

# Run main function
main "$@"
