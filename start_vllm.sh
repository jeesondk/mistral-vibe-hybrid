#!/usr/bin/env bash
set -euo pipefail

# Start vLLM server for Mistral Vibe
# Usage: ./start_vllm.sh [MODEL_PATH] [PORT]

MODEL_PATH="${1:-$HOME/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf}"
PORT="${2:-8000}"

echo "Starting vLLM server..."
echo "Model: $MODEL_PATH"
echo "Port: $PORT"
echo ""

# Check if model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model not found at $MODEL_PATH"
    echo "Please download a model first or specify the correct path"
    exit 1
fi

# Start vLLM server
python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_PATH" \
    --port "$PORT" \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.9
