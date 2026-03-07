#!/usr/bin/env bash
set -euo pipefail

# Start LLM server for Mistral Vibe
# Supports vLLM, llama.cpp, and ollama backends
# Usage: ./start_llm_server.sh [BACKEND] [MODEL_PATH] [PORT]
# Backends: vllm, llamacpp, ollama

# Show help if requested
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: ./start_llm_server.sh [BACKEND] [MODEL_PATH] [PORT]"
    echo ""
    echo "Backends:"
    echo "  vllm      - Use vLLM (default)"
    echo "  llamacpp  - Use llama.cpp (supports local GGUF files)"
    echo "  ollama    - Use ollama (uses ollama model library)"
    echo ""
    echo "Examples:"
    echo "  ./start_llm_server.sh vllm /path/to/model.gguf 8000"
    echo "  ./start_llm_server.sh llamacpp /path/to/model.gguf 8000"
    echo "  ./start_llm_server.sh ollama mistral:7b-instruct-v0.2 8000"
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
            # Try common llama.cpp installation locations
            if [ -f "/home/jesper/llama.cpp/build/bin/llama-server" ]; then
                export PATH="/home/jesper/llama.cpp/build/bin:$PATH"
            elif [ -f "$HOME/llama.cpp/build/bin/llama-server" ]; then
                export PATH="$HOME/llama.cpp/build/bin:$PATH"
            elif [ -f "/usr/local/bin/llama-server" ]; then
                export PATH="/usr/local/bin:$PATH"
            else
                echo "Error: llama-server command not found. Please install llama.cpp first."
                echo "Common installation: git clone https://github.com/ggerganov/llama.cpp && cd llama.cpp && make llama-server"
                exit 1
            fi
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
        
        # Smart model selection for Ollama
        if [ "$MODEL_PATH" = "$HOME/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf" ] || [ -z "$MODEL_PATH" ]; then
            # Auto-select best available model if default or empty path
            echo "Searching for best available model in Ollama library..."
            
            # Common model patterns to search for (priority order)
            declare -a model_patterns=(
                "mistral:7b-instruct"
                "mistral:7b"
                "mistral"
                "llama2"
                "vicuna"
                "codellama"
            )
            
            selected_model=""
            for pattern in "${model_patterns[@]}"; do
                # Search for models containing the pattern
                available_models=$(ollama list 2>/dev/null | grep -i "$pattern" | head -1)
                if [ -n "$available_models" ]; then
                    selected_model=$(echo "$available_models" | awk '{print $1}')
                    echo "Found matching model: $selected_model"
                    break
                fi
            done
            
            # If no model found, try to pull a good default
            if [ -z "$selected_model" ]; then
                echo "No suitable models found locally. Attempting to pull mistral:7b-instruct-v0.2..."
                if ollama pull "mistral:7b-instruct-v0.2" 2>/dev/null; then
                    selected_model="mistral:7b-instruct-v0.2"
                else
                    echo "Failed to pull default model. Please specify an available ollama model."
                    exit 1
                fi
            fi
            
            MODEL_PATH="$selected_model"
        else
            # User specified a model, check if it exists
            if ! ollama list | grep -q "$MODEL_PATH"; then
                echo "Model $MODEL_PATH not found in ollama library."
                echo "Attempting to pull from ollama registry..."
                if ! ollama pull "$MODEL_PATH"; then
                    echo "Failed to pull $MODEL_PATH. Please check the model name."
                    exit 1
                fi
            fi
        fi
        
        # Start ollama server in the background
        ollama serve &
        OLLAMA_PID=$!
        
        # Wait a bit for server to start
        sleep 3
        
        echo "Ollama server started (PID: $OLLAMA_PID)"
        echo "Model: $MODEL_PATH is ready to use on port 11434"
        echo "Note: Ollama uses port 11434 by default, not $PORT"
        
        # Keep the script running
        wait $OLLAMA_PID
        ;;
    
    *)
        echo "Error: Unknown backend '$BACKEND'"
        echo "Supported backends: vllm, llamacpp, ollama"
        exit 1
        ;;
esac
