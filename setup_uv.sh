#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# UV Setup Script for Mistral Vibe Hybrid
# ============================================================================
#
# This script sets up UV (Ultrafast Python Package Installer) for the project
# Usage: ./setup_uv.sh
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

# Check if UV is installed
check_uv_installed() {
    if command -v uv &> /dev/null; then
        info "UV is already installed: $(uv --version)"
        return 0
    else
        return 1
    fi
}

# Install UV
install_uv() {
    info "Installing UV..."
    
    # Try to install UV using the recommended method
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget &> /dev/null; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        error "Neither curl nor wget found. Cannot install UV."
    fi
    
    # Add UV to PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if command -v uv &> /dev/null; then
        info "UV installed successfully: $(uv --version)"
    else
        error "UV installation failed"
    fi
}

# Setup UV environment
setup_uv_environment() {
    info "Setting up UV environment..."
    
    # Add UV to PATH if not already there
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Check Python version
    if [ -f ".python-version" ]; then
        PYTHON_VERSION=$(cat .python-version)
        info "Using Python version: $PYTHON_VERSION"
    else
        PYTHON_VERSION="3.12"
        info "Default Python version: $PYTHON_VERSION"
    fi
    
    # Create UV environment
    if [ ! -d ".venv" ]; then
        info "Creating UV virtual environment..."
        uv venv .venv
    else
        info "Using existing virtual environment"
    fi
    
    # Activate environment
    source .venv/bin/activate
    
    # Install dependencies
    info "Installing dependencies with UV..."
    uv pip install -e .
    
    # Install dev dependencies
    info "Installing dev dependencies..."
    uv pip install -r <(uv pip compile pyproject.toml --extra dev)
    
    info "✓ UV environment setup complete!"
    echo ""
    echo "Activated virtual environment: .venv"
    echo "Python version: $(python --version)"
    echo "UV version: $(uv --version)"
    echo ""
    echo "To activate the environment later:"
    echo "  source .venv/bin/activate"
}

# Main function
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  UV Setup for Mistral Vibe Hybrid"
    echo "==========================================${NC}"
    echo ""
    
    # Check if UV is installed
    if ! check_uv_installed; then
        install_uv
    fi
    
    # Setup UV environment
    setup_uv_environment
    
    echo ""
    info "✅ UV setup complete!"
    info "Run tests with: uv run pytest tests/python/ --cov=src"
    info "Run type checking: uv run mypy src/"
    info "Run code quality: uv run ruff check src/ tests/python/"
}

# Run main function
main "$@"
