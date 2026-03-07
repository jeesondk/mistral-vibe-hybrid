#!/usr/bin/env bash
# =============================================================================
# Mistral Vibe Setup
# =============================================================================
#
# Sets up a hybrid agent architecture: Mistral API for complex tasks,
# local LLM (via vllm/llama.cpp/ollama) as a worker for tool calls.
#
# Prerequisites:
#   - Python 3.8+ with pip
#   - Git & curl
#   - Mistral API key (MISTRAL_API_KEY)
#
# Usage:
#   chmod +x setup_mistral_vibe.sh
#   ./setup_mistral_vibe.sh
#
# =============================================================================

set -eo pipefail

# Get project root from user, default to current directory
read -p "Enter project root path [$PWD]: " PROJECT_ROOT
PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
MODELS_DIR="$HOME/models"
CONFIG_DIR="$HOME/.config/mistral_vibe"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Create necessary directories and offer model download
# ---------------------------------------------------------------------------
info "Creating directories..."
mkdir -p "$MODELS_DIR"
mkdir -p "$CONFIG_DIR"

# Offer to download a small Mistral model if no models exist
if [ -z "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]; then
    read -p "No models found in $MODELS_DIR. Download Mistral-3-3B-Instruct-2512-Q4_K_M.gguf (1.8GB)? [y/N]: " DOWNLOAD_MODEL
    if [[ "$DOWNLOAD_MODEL" =~ ^[Yy]$ ]]; then
        info "Downloading Mistral-3-3B-Instruct-2512-Q4_K_M.gguf..."
        
        # Check if huggingface_hub is available
        if ! python -c "import huggingface_hub" 2>/dev/null; then
            info "Installing huggingface_hub..."
            pip install -q huggingface_hub
        fi
        
        python -c "
from huggingface_hub import hf_hub_download
import os
os.makedirs('$MODELS_DIR', exist_ok=True)
hf_hub_download(
    repo_id='TheBloke/Mistral-3-3B-Instruct-2512-GGUF',
    filename='Mistral-3-3B-Instruct-2512-Q4_K_M.gguf',
    local_dir='$MODELS_DIR',
    local_dir_use_symlinks=False
)
print('Download complete!')
"
        
        # Update the start script to use this model by default
        sed -i "s|mistral-7b-instruct-v0.2.Q4_K_M.gguf|Mistral-3-3B-Instruct-2512-Q4_K_M.gguf|g" "$PROJECT_ROOT/start_llm_server.sh"
    else
        info "Skipping model download. You can manually download models later."
    fi
fi

# ---------------------------------------------------------------------------
# 2. Check for local LLM server
# ---------------------------------------------------------------------------
info "Checking for local LLM server..."

# Try to detect if a server is running on common ports
SERVER_URL=""
for PORT in 8000 8080 11434; do
    if curl -s "http://127.0.0.1:$PORT/v1/models" > /dev/null 2>&1; then
        SERVER_URL="http://127.0.0.1:$PORT"
        info "Found LLM server at $SERVER_URL"
        break
    fi
done

if [ -z "$SERVER_URL" ]; then
    warn "No LLM server detected. You'll need to start one manually."
    warn "Suggested: vllm, llama.cpp, or other OpenAI-compatible server"
    SERVER_URL="http://127.0.0.1:8000"  # Default
fi

# ---------------------------------------------------------------------------
# 3. Create hybrid agent configuration
# ---------------------------------------------------------------------------
info "Creating hybrid agent configuration..."

cat > "$CONFIG_DIR/config.json" << 'CONFIGEOF'
{
  "model": "mistral-vibe",
  "provider": {
    "mistral-api": {
      "name": "Mistral AI API",
      "models": {
        "devstral-medium-latest": {
          "name": "devstral-medium-latest",
          "reasoning": true,
          "tools": true,
          "limit": {
            "context": 32768,
            "output": 8192
          }
        }
      }
    },
    "local-llm": {
      "name": "Local LLM Worker",
      "options": {
        "baseURL": "http://127.0.0.1:8000/v1"
      },
      "models": {
        "mistral-3-3b-worker": {
          "name": "mistral-3-3b-worker",
          "reasoning": true,
          "tools": true,
          "limit": {
            "context": 8192,
            "output": 2048
          }
        }
      }
    }
  },
  "agent": {
    "mistral-vibe": {
      "mode": "primary",
      "description": "Mistral Vibe primary agent. Handles complex tasks, architecture, and planning. Uses Mistral API for high-quality reasoning.",
      "model": "mistral-api/devstral-medium-latest",
      "prompt": "{file:$CONFIG_DIR/agents/mistral-vibe.md}",
      "temperature": 0.1,
      "steps": 12,
      "permission": {
        "task": {
          "worker": "allow"
        }
      }
    },
    "worker": {
      "mode": "subagent",
      "description": "Local worker agent. Handles focused tasks, file edits, and tool execution. Uses local Mistral-3-3B model.",
      "model": "local-llm/mistral-3-3b-worker",
      "prompt": "{file:$CONFIG_DIR/agents/worker.md}",
      "temperature": 0.1,
      "steps": 6
    }
  }
}
CONFIGEOF

# ---------------------------------------------------------------------------
# 4. Create agent prompts from templates
# ---------------------------------------------------------------------------
info "Creating agent prompts from templates..."

mkdir -p "$CONFIG_DIR/agents"

# Use template files if available, otherwise use embedded templates
HYBRID_PRIMARY_TEMPLATE="$PROJECT_ROOT/agent_templates/hybrid_primary.md.template"
HYBRID_WORKER_TEMPLATE="$PROJECT_ROOT/agent_templates/hybrid_worker.md.template"

if [ -f "$HYBRID_PRIMARY_TEMPLATE" ]; then
    info "Using hybrid primary template from $HYBRID_PRIMARY_TEMPLATE"
    cp "$HYBRID_PRIMARY_TEMPLATE" "$CONFIG_DIR/agents/mistral-vibe.md"
else
    info "Using embedded hybrid primary template"
    cat > "$CONFIG_DIR/agents/mistral-vibe.md" << 'PRIMARYEOF'
---
description: "Mistral Vibe primary agent for complex tasks"
mode: primary
model: mistral-api/devstral-medium-latest
temperature: 0.1
---
You are Mistral Vibe, a hybrid coding agent built by Mistral AI. You use a two-agent architecture:

## Architecture
- **You (Primary)**: Mistral API agent for complex reasoning, architecture, and planning
- **Worker**: Local Mistral-3-3B agent for focused tasks and tool execution

## Project Root
The project root is "__PROJECT_ROOT__". Use absolute paths starting with this prefix.

## Task Delegation
**CRITICAL**: Delegate file edits and focused tasks to the worker agent using the Task tool:
- Set `subagent_type` to "worker"
- Provide clear `description` and `prompt`
- NEVER set `task_id` (let the system generate it)

## Workflow
1. **Plan**: You analyze requirements and create execution plans
2. **Delegate**: You assign focused tasks to worker via Task tool
3. **Verify**: You review worker results and ensure quality
4. **Complete**: You confirm task completion to user

## Available Tools (Primary)
- read_file, grep, bash: For analysis and planning
- task: For delegating to worker agent
- search_replace: For simple single-file changes (if faster than delegation)

## Error Recovery
- If worker fails, re-read files and provide clearer instructions
- For complex failures, take over with search_replace
- Never retry identical failed actions

## Build & Test
```bash
# Project-specific commands will be added here during setup
```
PRIMARYEOF
fi

if [ -f "$HYBRID_WORKER_TEMPLATE" ]; then
    info "Using hybrid worker template from $HYBRID_WORKER_TEMPLATE"
    cp "$HYBRID_WORKER_TEMPLATE" "$CONFIG_DIR/agents/worker.md"
else
    info "Using embedded hybrid worker template"
    cat > "$CONFIG_DIR/agents/worker.md" << 'WORKEREOF'
---
description: "Local worker agent for focused tasks"
mode: subagent
model: local-llm/mistral-3-3b-worker
temperature: 0.1
---
You are the Worker agent for Mistral Vibe. You handle focused, well-defined tasks:

## Your Role
- Execute specific file edits requested by primary agent
- Run tools and commands as instructed
- Provide clear, concise results
- Never make decisions - follow instructions precisely

## Project Root
The project root is "__PROJECT_ROOT__". ALWAYS use absolute paths.

## Available Tools
- read_file: Read file content before editing
- write_file: Create or overwrite files
- search_replace: Edit files with exact SEARCH/REPLACE blocks
- grep: Search for patterns
- bash: Run shell commands

## Critical Rules
1. **Exact Paths**: Always use absolute paths starting with __PROJECT_ROOT__
2. **Read First**: Always read files before modifying
3. **Precise Execution**: Follow instructions exactly
4. **Error Handling**: If a tool fails, stop and report the error

## Example Workflow
1. Receive task with clear instructions
2. Read relevant files
3. Execute requested changes
4. Verify changes were applied
5. Report completion or errors

## Build & Test
```bash
# Use commands provided by primary agent
```
WORKEREOF
fi

# ---------------------------------------------------------------------------
# 5. Replace project root placeholder in both agent files
# ---------------------------------------------------------------------------
info "Replacing project root placeholder..."
sed -i "s|__PROJECT_ROOT__|$PROJECT_ROOT|g" "$CONFIG_DIR/agents/mistral-vibe.md"
sed -i "s|__PROJECT_ROOT__|$PROJECT_ROOT|g" "$CONFIG_DIR/agents/worker.md"

info "Copying scripts from source..."

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cp "$SCRIPT_DIR/start_llm_server.sh" "$PROJECT_ROOT/start_llm_server.sh"
cp "$SCRIPT_DIR/change_worker_model.sh" "$PROJECT_ROOT/change_worker_model.sh"
cp "$SCRIPT_DIR/toggle_hybrid_mode.sh" "$PROJECT_ROOT/toggle_hybrid_mode.sh"
chmod +x "$PROJECT_ROOT"/{start_llm_server,change_worker_model,toggle_hybrid_mode}.sh

# ---------------------------------------------------------------------------
# 8. Verify hybrid setup
# ---------------------------------------------------------------------------
echo ""
info "=========================================="
info "  Mistral Vibe Hybrid Setup Complete"
info "=========================================="
echo ""
echo "  Primary Agent:   $CONFIG_DIR/agents/mistral-vibe.md (Mistral API)"
echo "  Worker Agent:    $CONFIG_DIR/agents/worker.md (Local Mistral-3-3B)"
echo "  Config:          $CONFIG_DIR/config.json"
echo "  Start Script:    $PROJECT_ROOT/start_llm_server.sh"
echo "  Model Changer:   $PROJECT_ROOT/change_worker_model.sh"
echo "  Mode Toggle:    $PROJECT_ROOT/toggle_hybrid_mode.sh"
echo "  Worker Server:   $SERVER_URL (for local worker)"
echo "  Project Root:    $PROJECT_ROOT"
echo ""

# Check if model was downloaded
if [ -f "$MODELS_DIR/Mistral-3-3B-Instruct-2512-Q4_K_M.gguf" ]; then
    info "✓ Worker model ready: Mistral-3-3B-Instruct-2512-Q4_K_M.gguf"
    echo ""
    echo "  Next steps:"
    echo "    1. Start worker server: ./start_llm_server.sh"
    echo "    2. Configure Mistral API key for primary agent"
    echo "    3. Use Mistral Vibe hybrid architecture"
    echo ""
    echo "  Mode Management:"
    echo "    ./toggle_hybrid_mode.sh           # Toggle between hybrid/single"
    echo "    ./toggle_hybrid_mode.sh status   # Check current mode"
    echo ""
    echo "  Model Management:"
    echo "    ./change_worker_model.sh          # Interactive menu"
    echo "    ./change_worker_model.sh --list   # List available models"
    echo "    ./change_worker_model.sh /path/to/model.gguf  # Direct change"
else
    echo ""
    echo "  Next steps:"
    echo "    1. Download Mistral-3-3B model or use existing model"
    echo "    2. Start worker server: ./start_llm_server.sh /path/to/model.gguf"
    echo "    3. Configure Mistral API key for primary agent"
    echo "    4. Use Mistral Vibe hybrid architecture"
    echo ""
    echo "  Mode Management:"
    echo "    ./toggle_hybrid_mode.sh           # Toggle between hybrid/single"
    echo "    ./toggle_hybrid_mode.sh single    # Use single local model only"
    echo ""
    echo "  Model Management:"
    echo "    ./change_worker_model.sh --list   # List available models"
    echo "    ./change_worker_model.sh /path/to/model.gguf  # Change model"
fi
echo ""

# ---------------------------------------------------------------------------
# Hybrid Architecture Notes:
# ---------------------------------------------------------------------------
# PRIMARY AGENT (Mistral API):
# - Uses devstral-medium-latest via Mistral API
# - Handles complex reasoning, architecture, and planning
# - Requires Mistral API key configuration
#
# WORKER AGENT (Local LLM):
# - Uses Mistral-3-3B-Instruct-2512-Q4_K_M.gguf (~1.8GB) by default
# - Handles focused tasks, file edits, and tool execution
# - Runs locally via vLLM/llama.cpp server on port 8000
#
# WORKFLOW:
# 1. Primary agent analyzes requirements and creates plans
# 2. Primary agent delegates focused tasks to worker via Task tool
# 3. Worker executes tasks and returns results
# 4. Primary agent verifies results and ensures quality
#
# SETUP TIPS:
# - The script automatically downloads Mistral-3-3B worker model
# - You need to manually configure Mistral API key for primary agent
# - Start worker server before using the hybrid system
#
# MODEL MANAGEMENT:
# - Use change_worker_model.sh to switch between different local models
# - Supports interactive menu, direct path specification, and model listing
# - Automatically stops/restarts vLLM server when changing models
# - Updates configuration files automatically
#
# USAGE EXAMPLES:
#   ./change_worker_model.sh                    # Interactive menu
#   ./change_worker_model.sh --list             # List available models
#   ./change_worker_model.sh /path/to/model.gguf # Direct change
#
# MODE TOGGLE EXAMPLES:
#   ./toggle_hybrid_mode.sh                    # Show current mode
#   ./toggle_hybrid_mode.sh hybrid             # Enable hybrid (API + worker)
#   ./toggle_hybrid_mode.sh single             # Enable single (local only)
#   ./toggle_hybrid_mode.sh status             # Check current mode
# ---------------------------------------------------------------------------
