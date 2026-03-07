#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Mistral Vibe Hybrid Setup - Script Signing System
# ============================================================================
#
# This script signs scripts using GPG for security and verification
# It also creates checksum files for integrity verification
#
# Usage: ./sign_scripts.sh [script1.sh script2.sh ...]
#        ./sign_scripts.sh --all      # Sign all scripts
#        ./sign_scripts.sh --verify   # Verify all signatures
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

# Configuration
SIGNATURE_DIR="signatures"
CHECKSUM_FILE="checksums.sha256"

# Create signature directory
mkdir -p "$SIGNATURE_DIR"

# Check if GPG is available
check_gpg() {
    if ! command -v gpg &> /dev/null; then
        error "GPG is required for signing but not installed."
        echo "Install GPG with:"
        echo "  sudo apt-get install gnupg    # Debian/Ubuntu"
        echo "  sudo yum install gnupg      # RHEL/CentOS"
        echo "  brew install gnupg          # macOS"
    fi
}

# Sign a script
sign_script() {
    local script="$1"
    local sig_file="$SIGNATURE_DIR/$(basename "$script").sig"
    
    if [ ! -f "$script" ]; then
        error "Script not found: $script"
    fi
    
    info "Signing $script..."
    
    # Check if script is already signed
    if [ -f "$sig_file" ]; then
        warn "Signature already exists for $script, overwriting..."
    fi
    
    # Sign the script (detached signature)
    if gpg --detach-sign --armor --output "$sig_file" "$script"; then
        info "✓ Signed $script -> $sig_file"
    else
        error "Failed to sign $script"
    fi
}

# Verify a script signature
verify_script() {
    local script="$1"
    local sig_file="$SIGNATURE_DIR/$(basename "$script").sig"
    
    if [ ! -f "$script" ]; then
        error "Script not found: $script"
    fi
    
    if [ ! -f "$sig_file" ]; then
        error "No signature found for $script"
    fi
    
    info "Verifying $script..."
    
    # Verify the signature
    if gpg --verify "$sig_file" "$script"; then
        info "✓ Signature valid for $script"
    else
        error "Invalid signature for $script"
    fi
}

# Create checksums
create_checksums() {
    info "Creating checksums..."
    
    echo "# Mistral Vibe Hybrid Setup - Script Checksums" > "$CHECKSUM_FILE"
    echo "# Generated: $(date)" >> "$CHECKSUM_FILE"
    echo "" >> "$CHECKSUM_FILE"
    
    # Add checksums for all scripts
    for script in "$@"; do
        if [ -f "$script" ]; then
            sha256sum "$script" >> "$CHECKSUM_FILE"
            
            # Also check if signature exists
            local sig_file="$SIGNATURE_DIR/$(basename "$script").sig"
            if [ -f "$sig_file" ]; then
                sha256sum "$sig_file" >> "$CHECKSUM_FILE"
            fi
        fi
    done
    
    info "✓ Checksums created: $CHECKSUM_FILE"
}

# Verify checksums
verify_checksums() {
    if [ ! -f "$CHECKSUM_FILE" ]; then
        error "Checksum file not found: $CHECKSUM_FILE"
    fi
    
    info "Verifying checksums..."
    
    if sha256sum --check "$CHECKSUM_FILE"; then
        info "✓ All checksums valid"
    else
        error "Checksum verification failed"
    fi
}

# Get all scripts
get_all_scripts() {
    find . -name "*.sh" -type f | grep -v node_modules | grep -v ".git"
}

# Show help
show_help() {
    echo "Mistral Vibe Hybrid Setup - Script Signing System"
    echo ""
    echo "Usage:"
    echo "  sign_scripts.sh [OPTIONS] [SCRIPTS...]"
    echo ""
    echo "Options:"
    echo "  --all              Sign all scripts in the project"
    echo "  --verify           Verify all script signatures"
    echo "  --checksums        Create checksums for scripts"
    echo "  --verify-checksums Verify checksums"
    echo "  --help, -h         Show this help message"
    echo "  --version, -v      Show version information"
    echo ""
    echo "Examples:"
    echo "  ./sign_scripts.sh install.sh package.sh        # Sign specific scripts"
    echo "  ./sign_scripts.sh --all                      # Sign all scripts"
    echo "  ./sign_scripts.sh --verify                   # Verify all signatures"
    echo "  ./sign_scripts.sh --checksums                # Create checksums"
    echo "  ./sign_scripts.sh --verify-checksums          # Verify checksums"
    echo ""
    echo "Note: GPG must be installed and configured for signing."
    echo ""
}

# Show version
show_version() {
    echo "Mistral Vibe Hybrid Setup Script Signing System v1.0.0"
    echo "Copyright (c) 2024 Mistral Vibe Hybrid Setup"
    echo "License: MIT"
}

# Main function
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  Script Signing System"
    echo "==========================================${NC}"
    echo ""
    
    # Check for GPG
    check_gpg
    
    # Parse arguments
    local action="sign"
    local all_scripts=false
    local verify=false
    local create_checksums=false
    local verify_checksums=false
    local scripts=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                all_scripts=true
                shift
                ;;
            --verify)
                verify=true
                shift
                ;;
            --checksums)
                create_checksums=true
                shift
                ;;
            --verify-checksums)
                verify_checksums=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --*)
                error "Unknown option: $1"
                ;;
            *)
                scripts+=("$1")
                shift
                ;;
        esac
    done
    
    # Handle --all
    if [ "$all_scripts" = true ]; then
        scripts=($(get_all_scripts))
        if [ ${#scripts[@]} -eq 0 ]; then
            error "No scripts found to sign"
        fi
        info "Found ${#scripts[@]} scripts to sign"
    fi
    
    # Handle --verify
    if [ "$verify" = true ]; then
        scripts=($(get_all_scripts))
        if [ ${#scripts[@]} -eq 0 ]; then
            error "No scripts found to verify"
        fi
        info "Verifying ${#scripts[@]} scripts..."
        
        for script in "${scripts[@]}"; do
            verify_script "$script"
        done
        
        exit 0
    fi
    
    # Handle --checksums
    if [ "$create_checksums" = true ]; then
        scripts=($(get_all_scripts))
        if [ ${#scripts[@]} -eq 0 ]; then
            error "No scripts found for checksums"
        fi
        create_checksums "${scripts[@]}"
        exit 0
    fi
    
    # Handle --verify-checksums
    if [ "$verify_checksums" = true ]; then
        verify_checksums
        exit 0
    fi
    
    # Default action: sign scripts
    if [ ${#scripts[@]} -eq 0 ]; then
        error "No scripts specified and --all not used"
    fi
    
    for script in "${scripts[@]}"; do
        sign_script "$script"
    done
    
    # Create checksums after signing
    create_checksums "${scripts[@]}"
    
    echo ""
    info "=========================================="
    info "  Script Signing Complete! ✅"
    info "=========================================="
    echo ""
    echo "Signed scripts:"
    for script in "${scripts[@]}"; do
        local sig_file="$SIGNATURE_DIR/$(basename "$script").sig"
        echo "  • $script -> $sig_file"
    done
    echo ""
    echo "Verification files:"
    echo "  • $CHECKSUM_FILE (SHA256 checksums)"
    echo "  • $SIGNATURE_DIR/ (GPG signatures)"
    echo ""
    echo "To verify scripts:"
    echo "  ./sign_scripts.sh --verify"
    echo ""
    echo "To verify checksums:"
    echo "  ./sign_scripts.sh --verify-checksums"
    echo ""
}

# Run main function
main "$@"
