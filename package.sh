#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Mistral Vibe Hybrid Setup - Packaging Script
# ============================================================================
#
# This script creates distributable packages for the project
# Supports: tar.gz, zip, and signed packages
#
# Usage: ./package.sh [format]
# Formats: tar.gz (default), zip, sign
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
PROJECT_NAME="mistral-vibe-hybrid"
VERSION="1.0.0"
OUTPUT_DIR="dist"
PACKAGE_DATE=$(date +%Y%m%d)

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create package
create_package() {
    local format="$1"
    local output_file=""

    case "$format" in
        "tar.gz"|"tgz")
            output_file="$OUTPUT_DIR/${PROJECT_NAME}-${VERSION}-${PACKAGE_DATE}.tar.gz"
            info "Creating tar.gz package: $output_file" >&2
            
            # Create temporary directory structure
            local temp_dir=$(mktemp -d)
            local project_dir="$temp_dir/${PROJECT_NAME}-${VERSION}"
            
            # Copy files
            mkdir -p "$project_dir"
            cp -r . "$project_dir/"
            
            # Remove unnecessary files
            rm -rf "$project_dir/$OUTPUT_DIR"
            rm -rf "$project_dir/.git"
            rm -rf "$project_dir/__pycache__"
            
            # Create tarball
            tar -czf "$output_file" -C "$temp_dir" "${PROJECT_NAME}-${VERSION}"
            
            rm -rf "$temp_dir"
            info "✓ tar.gz package created: $output_file" >&2
            ;;

        "zip")
            output_file="$OUTPUT_DIR/${PROJECT_NAME}-${VERSION}-${PACKAGE_DATE}.zip"
            info "Creating zip package: $output_file" >&2
            
            # Create temporary directory structure
            local temp_dir=$(mktemp -d)
            local project_dir="$temp_dir/${PROJECT_NAME}-${VERSION}"
            
            # Copy files
            mkdir -p "$project_dir"
            cp -r . "$project_dir/"
            
            # Remove unnecessary files
            rm -rf "$project_dir/$OUTPUT_DIR"
            rm -rf "$project_dir/.git"
            rm -rf "$project_dir/__pycache__"
            
            # Create zip
            (cd "$temp_dir" && zip -r "$output_file" "${PROJECT_NAME}-${VERSION}")
            
            rm -rf "$temp_dir"
            info "✓ zip package created: $output_file" >&2
            ;;

        "sign")
            # First create a tar.gz package
            create_package "tar.gz"
            local tar_file="$OUTPUT_DIR/${PROJECT_NAME}-${VERSION}-${PACKAGE_DATE}.tar.gz"
            local sig_file="${tar_file}.sig"
            
            info "Signing package (simulated - implement with GPG)..." >&2
            
            # In a real implementation, you would use:
            # gpg --detach-sign --armor "$tar_file"
            
            # For now, create a placeholder signature file
            echo "SIMULATED-SIGNATURE-FOR-$tar_file" > "$sig_file"
            warn "⚠️  Signature is simulated. Implement real GPG signing." >&2
            info "✓ Signed package created: $sig_file" >&2
            ;;
        
        *)
            error "Unknown package format: $format. Use tar.gz, zip, or sign."
            ;;
    esac
    
    echo "$output_file"
}

# Create checksums
create_checksums() {
    info "Creating checksums..."
    
    local checksum_file="$OUTPUT_DIR/checksums.txt"
    echo "Checksums for Mistral Vibe Hybrid $VERSION" > "$checksum_file"
    echo "Generated: $(date)" >> "$checksum_file"
    echo "" >> "$checksum_file"
    
    # Add checksums for all files in dist/
    for file in "$OUTPUT_DIR"/*; do
        if [ -f "$file" ]; then
            # SHA256 checksum
            sha256sum "$file" >> "$checksum_file"
            
            # Also add file size
            echo "Size: $(du -h "$file" | cut -f1)" >> "$checksum_file"
            echo "" >> "$checksum_file"
        fi
    done
    
    info "✓ Checksums created: $checksum_file"
}

# Show help
show_help() {
    echo "Mistral Vibe Hybrid Setup - Packaging Script"
    echo ""
    echo "Usage:"
    echo "  package.sh [FORMAT] [OPTIONS]"
    echo ""
    echo "Formats:"
    echo "  tar.gz, tgz    Create tar.gz package (default)"
    echo "  zip           Create zip package"
    echo "  sign          Create signed tar.gz package"
    echo "  all           Create all package formats"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --version, -v  Show version information"
    echo "  --checksums    Create checksums for packages"
    echo ""
    echo "Examples:"
    echo "  ./package.sh tar.gz           # Create tar.gz package"
    echo "  ./package.sh zip              # Create zip package"
    echo "  ./package.sh sign             # Create signed package"
    echo "  ./package.sh all --checksums   # Create all packages with checksums"
    echo ""
}

# Show version
show_version() {
    echo "Mistral Vibe Hybrid Setup Packaging Script v1.0.0"
    echo "Copyright (c) 2024 Mistral Vibe Hybrid Setup"
    echo "License: MIT"
}

# Main function
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  Mistral Vibe Hybrid Setup Packaging"
    echo "==========================================${NC}"
    echo ""
    
    # Parse arguments
    local formats=()
    local create_checksums=false
    
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
            --checksums)
                create_checksums=true
                shift
                ;;
            tar.gz|tgz|zip|sign|all)
                formats+=("$1")
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Default to tar.gz if no format specified
    if [ ${#formats[@]} -eq 0 ]; then
        formats=("tar.gz")
    fi
    
    # Handle "all" format
    if [[ "${formats[0]}" == "all" ]]; then
        formats=("tar.gz" "zip" "sign")
    fi
    
    # Create packages
    local created_files=()
    for format in "${formats[@]}"; do
        local file=$(create_package "$format")
        created_files+=("$file")
    done
    
    # Create checksums if requested
    if [ "$create_checksums" = true ]; then
        create_checksums
    fi
    
    echo ""
    info "=========================================="
    info "  Packaging Complete! ✅"
    info "=========================================="
    echo ""
    echo "Created packages:"
    for file in "${created_files[@]}"; do
        size=$(du -h "$file" | cut -f1)
        echo "  • $file ($size)"
    done
    echo ""
    echo "Package contents:"
    echo "  • Complete project source code"
    echo "  • All scripts and templates"
    echo "  • Documentation (README, CONTRIBUTING, LICENSE)"
    echo "  • Configuration files"
    echo ""
    echo "Installation instructions:"
    echo "  1. Download package from dist/ directory"
    echo "  2. Extract: tar -xzf package.tar.gz"
    echo "  3. Run: cd mistral-vibe-hybrid && ./install.sh"
    echo ""
}

# Run main function
main "$@"
