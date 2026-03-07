#!/usr/bin/env bash
set -euo pipefail

# Start LLM server for Mistral Vibe
# Supports vLLM, llama.cpp, and ollama backends
# Usage: ./start_llm_server.sh [BACKEND] [MODEL_PATH] [PORT]
# Backends: vllm, llamacpp, ollama

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: ./start_llm_server.sh [BACKEND] [MODEL_PATH] [PORT]"
    echo ""
    echo "Backends:"
    echo "  vllm      - Use vLLM (default)"
    echo "  llamacpp  - Use llama.cpp"
    echo "  ollama    - Use ollama"
    echo ""
    echo "Examples:"
    echo "  ./start_llm_server.sh vllm /path/to/model.gguf 8000"
    echo "  ./start_llm_server.sh llamacpp /path/to/model.gguf 8000"
    echo "  ./start_llm_server.sh ollama mistral:latest 8000"
    exit 0
fi

BACKEND="${1:-vllm}"
MODEL_PATH="${2:-$HOME/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf}"
PORT="${3:-8000}"

echo "Starting $BACKEND server..."
echo "Model: $MODEL_PATH"
echo "Port: $PORT"
echo ""

# Check if model exists (except for ollama which manages its own models)
if [ "$BACKEND" != "ollama" ] && [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model not found at $MODEL_PATH"
    echo "Please download a model first or specify the correct path"
    exit 1
fi

case "$BACKEND" in
    vllm)
        echo "Starting vLLM server..."
        python -m vllm.entrypoints.openai.api_server \
            --model "$MODEL_PATH" \
            --port "$PORT" \
            --max-model-len 8192 \
            --gpu-memory-utilization 0.9
        ;;
    
    llamacpp)
        echo "Starting llama.cpp server..."
        # Check if llama.cpp server is available
        if ! command -v llama-server &> /dev/null; then
            echo "Error: llama-server command not found. Please install llama.cpp first."
            exit 1
        fi
        
        llama-server \
            --model "$MODEL_PATH" \
            --port "$PORT" \
            --n-gpu-layers 100 \
            --context-size 8192
        ;;
    
    ollama)
        echo "Starting ollama server..."
        # Check if ollama is available
        if ! command -v ollama &> /dev/null; then
            echo "Error: ollama command not found. Please install ollama first."
            exit 1
        fi
        
        # Start ollama server in the background
        ollama serve &
        OLLAMA_PID=$!
        
        # Wait a bit for server to start
        sleep 3
        
        # Pull the model if not already available
        if ! ollama list | grep -q "$MODEL_PATH"; then
            echo "Pulling model $MODEL_PATH..."
            ollama pull "$MODEL_PATH"
        fi
        
        echo "Ollama server started (PID: $OLLAMA_PID)"
        echo "Model: $MODEL_PATH is ready to use"
        
        # Keep the script running
        wait $OLLAMA_PID
        ;;
    
    *)
        echo "Error: Unknown backend '$BACKEND'"
        echo "Supported backends: vllm, llamacpp, ollama"
        exit 1
        ;;
esac
