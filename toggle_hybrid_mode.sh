#!/usr/bin/env bash
set -euo pipefail

# Hybrid Mode Toggle for Mistral Vibe
# Usage: ./toggle_hybrid_mode.sh [hybrid|single]

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

# Check current mode
get_current_mode() {
    if grep -q "mistral-api" "$CONFIG_DIR/config.json" 2>/dev/null; then
        echo "hybrid"
    else
        echo "single"
    fi
}

# Backup current config
backup_config() {
    cp "$CONFIG_DIR/config.json" "$CONFIG_DIR/config.json.bak"
    info "Backed up current configuration"
}

# Restore from backup
restore_config() {
    if [ -f "$CONFIG_DIR/config.json.bak" ]; then
        cp "$CONFIG_DIR/config.json.bak" "$CONFIG_DIR/config.json"
        info "Restored configuration from backup"
    fi
}

# Switch to hybrid mode
switch_to_hybrid() {
    info "Switching to HYBRID mode (Mistral API + Local Worker)..."
    
    # Create hybrid configuration
    cat > "$CONFIG_DIR/config.json" << 'HYBRIDCONFIG'
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
HYBRIDCONFIG

    # Ensure both agent prompts exist
    if [ ! -f "$CONFIG_DIR/agents/worker.md" ]; then
        cat > "$CONFIG_DIR/agents/worker.md" << 'WORKEREOF'
---
description: "Local worker agent for focused tasks"
mode: subagent
model: local-llm/mistral-3-3b-worker
temperature: 0.1
---
You are the Worker agent for Mistral Vibe. You handle focused, well-defined tasks.

## Your Role
- Execute specific file edits requested by primary agent
- Run tools and commands as instructed
- Provide clear, concise results
- Never make decisions - follow instructions precisely

## Project Root
The project root is "$PROJECT_ROOT". ALWAYS use absolute paths.

## Available Tools
- read_file, write_file, search_replace, grep, bash

## Critical Rules
1. **Exact Paths**: Always use absolute paths starting with $PROJECT_ROOT
2. **Read First**: Always read files before modifying
3. **Precise Execution**: Follow instructions exactly
4. **Error Handling**: If a tool fails, stop and report the error
WORKEREOF
    fi
    
    info "✓ Hybrid mode enabled"
    echo "  - Primary agent: Mistral API (devstral-medium-latest)"
    echo "  - Worker agent: Local Mistral-3-3B"
    echo "  - Worker server required on port 8000"
}

# Switch to single mode
switch_to_single() {
    info "Switching to SINGLE mode (Local Mistral only)..."
    
    # Get current worker model from start script
    local model_path=$(grep -oP 'MODEL_PATH="\K[^"]+' "$PROJECT_ROOT/start_llm_server.sh" 2>/dev/null)
    local model_name="mistral-vibe"
    
    if [ -n "$model_path" ]; then
        model_name=$(basename "$model_path" .gguf)-vibe
    fi
    
    # Create single-agent configuration
    cat > "$CONFIG_DIR/config.json" << EOF
{
  "model": "$model_name",
  "provider": {
    "local-llm": {
      "name": "Local LLM",
      "options": {
        "baseURL": "http://127.0.0.1:8000/v1"
      },
      "models": {
        "$model_name": {
          "name": "$model_name",
          "reasoning": true,
          "tools": true,
          "limit": {
            "context": 32768,
            "output": 8192
          }
        }
      }
    }
  },
  "agent": {
    "mistral-vibe": {
      "mode": "primary",
      "description": "Mistral Vibe single agent. Handles all tasks using local model.",
      "model": "local-llm/$model_name",
      "prompt": "You are Mistral Vibe, a CLI coding agent built by Mistral AI. You interact with a local codebase through tools. Follow the system prompt instructions carefully.",
      "temperature": 0.1,
      "steps": 12
    }
  }
}
EOF

    # Update primary agent prompt for single mode
    cat > "$CONFIG_DIR/agents/mistral-vibe.md" << 'SINGLEEOF'
---
description: "Mistral Vibe single agent for all tasks"
mode: primary
model: local-llm/$model_name
temperature: 0.1
---
You are Mistral Vibe, a CLI coding agent built by Mistral AI. You interact with a local codebase through tools.

## Mode: SINGLE AGENT
You handle ALL tasks yourself - no worker agent available.

## Project Root
The project root is "$PROJECT_ROOT". Use absolute paths starting with this prefix.

## Available Tools
- read_file, write_file, search_replace, grep, bash

## Key Instructions
1. **Read First**: Always read files before modifying them
2. **Minimal Changes**: Only modify what was requested
3. **Verify**: Confirm changes work before claiming completion
4. **No Commit**: Never run git commit unless explicitly asked

## Error Recovery
- If an edit fails, re-read the file to see actual content
- Never retry the same failed action
- Use write_file instead of search_replace if needed
SINGLEEOF

    info "✓ Single mode enabled"
    echo "  - Single agent: Local model only"
    echo "  - Server required on port 8000"
    echo "  - No Mistral API dependency"
}

# Main logic
if [ $# -eq 0 ]; then
    # Show current status
    current_mode=$(get_current_mode)
    echo "Mistral Vibe Mode Toggle"
    echo "========================"
    echo ""
    echo "Current mode: $current_mode"
    echo ""
    echo "Usage:"
    echo "  ./toggle_hybrid_mode.sh hybrid    # Enable hybrid mode"
    echo "  ./toggle_hybrid_mode.sh single    # Enable single mode"
    echo "  ./toggle_hybrid_mode.sh status    # Show current mode"
    echo ""
    exit 0
fi

# Handle commands
case "$1" in
    "hybrid")
        backup_config
        switch_to_hybrid
        ;;
    "single")
        backup_config
        switch_to_single
        ;;
    "status")
        current_mode=$(get_current_mode)
        echo "Current mode: $current_mode"
        if [ "$current_mode" = "hybrid" ]; then
            echo "  - Using Mistral API + Local Worker"
        else
            echo "  - Using Local Model Only"
        fi
        ;;
    *)
        error "Unknown command: $1. Use 'hybrid', 'single', or 'status'."
        ;;
esac
