#!/usr/bin/env bash
set -euo pipefail

# Worker Model Changer for Mistral Vibe Hybrid Setup
# Usage: ./change_worker_model.sh [new_model.gguf]

MODELS_DIR="$HOME/models"
CONFIG_DIR="$HOME/.config/mistral_vibe"
PROJECT_ROOT="$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as command or interactive
if [[ "$1" == "--list" ]]; then
    # List available models
    echo "Available models in $MODELS_DIR:"
    echo ""
    for i in $(find "$MODELS_DIR" -name "*.gguf" -type f | sort); do
        size=$(du -h "$i" | cut -f1)
        filename=$(basename "$i")
        echo "  $filename ($size)"
    done
    exit 0
fi

# Find running LLM server (vLLM, llama.cpp, or ollama)
find_llm_pid() {
    local pid=""
    
    # Try to find vLLM process
    if command -v pgrep >/dev/null 2>&1; then
        pid=$(pgrep -f "vllm.entrypoints.openai.api_server" || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    else
        pid=$(ps aux | grep "vllm.entrypoints.openai.api_server" | grep -v grep | awk '{print $2}' || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    fi
    
    # Try to find llama.cpp server process
    if command -v pgrep >/dev/null 2>&1; then
        pid=$(pgrep -f "llama-server" || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    else
        pid=$(ps aux | grep "llama-server" | grep -v grep | awk '{print $2}' || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    fi
    
    # Try to find ollama process
    if command -v pgrep >/dev/null 2>&1; then
        pid=$(pgrep -f "ollama serve" || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    else
        pid=$(ps aux | grep "ollama serve" | grep -v grep | awk '{print $2}' || true)
        if [ -n "$pid" ]; then
            echo "$pid"
            return
        fi
    fi
    
    echo ""
}

# Main logic
if [ $# -eq 0 ]; then
    # Interactive mode - show menu
    echo "Mistral Vibe Worker Model Changer"
    echo "=================================="
    echo ""
    
    # List available models
    models=($MODELS_DIR/*.gguf 2>/dev/null)
    if [ ${#models[@]} -eq 0 ]; then
        error "No GGUF models found in $MODELS_DIR"
    fi
    
    echo "Available models:"
    for i in "${!models[@]}"; do
        size=$(du -h "${models[$i]}" | cut -f1)
        filename=$(basename "${models[$i]}")
        echo "  $((i+1)). $filename ($size)"
    done
    echo ""
    
    # Get current model from start script
    current_model=$(grep -oP 'MODEL_PATH="\K[^"]+' "$PROJECT_ROOT/start_llm_server.sh" 2>/dev/null || echo "None")
    if [ "$current_model" != "None" ]; then
        current_name=$(basename "$current_model")
        echo "Current model: $current_name"
    else
        echo "Current model: None (server not configured)"
    fi
    echo ""
    
    read -p "Select model number (1-${#models[@]}): " selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#models[@]} ]; then
        error "Invalid selection"
    fi
    
    selected_model="${models[$((selection-1))]}"
else
    # Command line argument provided
    if [ ! -f "$1" ]; then
        error "Model not found: $1"
    fi
    selected_model="$(realpath "$1")"
fi

# Get model filename
model_name=$(basename "$selected_model")
info "Changing worker model to: $model_name"

# Check if LLM server is running
llm_pid=$(find_llm_pid)
if [ -n "$llm_pid" ]; then
    info "Stopping current LLM server (PID: $llm_pid)..."
    kill "$llm_pid" || warn "Failed to stop LLM server, continuing anyway..."
    sleep 2
fi

# Update start script with new model
info "Updating start script..."
sed -i "s|MODEL_PATH=".*"|MODEL_PATH=\"$selected_model\"|" "$PROJECT_ROOT/start_llm_server.sh"

# Update configuration to reference the new model name
info "Updating configuration..."
sed -i "s|mistral-3-3b-worker|${model_name%.gguf}-worker|g" "$CONFIG_DIR/config.json"
sed -i "s|mistral-3-3b-worker|${model_name%.gguf}-worker|g" "$CONFIG_DIR/agents/worker.md"

# Restart LLM server
info "Restarting LLM server with new model..."
cd "$PROJECT_ROOT"

# Get current backend from start script
current_backend=$(grep -oP 'BACKEND="\K[^"]+' "$PROJECT_ROOT/start_llm_server.sh" 2>/dev/null || echo "vllm")

./start_llm_server.sh "$current_backend" "$selected_model" &

# Wait a bit for server to start
sleep 3

# Check if server started successfully
if curl -s "http://127.0.0.1:8000/v1/models" > /dev/null 2>&1; then
    info "✓ Worker model changed successfully!"
    info "New model: $model_name"
    info "Server running on: http://127.0.0.1:8000"
else
    warn "⚠ Server may not have started properly. Check logs."
fi
