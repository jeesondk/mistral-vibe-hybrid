# Mistral Vibe Hybrid Setup

This repository contains a hybrid agent setup for Mistral Vibe with:

- **Primary Agent**: Mistral API (`devstral-medium-latest`) for complex reasoning
- **Worker Agent**: Local LLM (Mistral-3-3B) for tool calls and simple tasks

## Quick Start

```bash
# Run the setup script
./setup_mistral_vibe.sh

# Start the worker server
./start_vllm.sh

# Configure Mistral API key for primary agent
# (implementation-specific - add your API key)

# Use the hybrid system
# Primary agent will automatically delegate to worker
```

## Usage

### Basic Setup
```bash
# Run the setup script
./setup_mistral_vibe.sh

# Start the worker server
./start_vllm.sh

# Configure Mistral API key for primary agent
# (implementation-specific - add your API key)

# Use the hybrid system
# Primary agent will automatically delegate to worker
```

### Extended Vibe with Custom Commands
```bash
# Use the extended Vibe with custom commands
./vibe-extended

# Now you can use the custom commands inside Vibe:
/use_hybrid_mode hybrid    # Enable hybrid mode
/use_hybrid_mode single    # Enable single mode
/use_hybrid_mode           # Show current mode

/change_worker_model --list          # List available models
/change_worker_model /path/to/model.gguf  # Change model
```

## Mode Management (External Scripts)

Toggle between hybrid and single-agent modes using external scripts:

```bash
# Check current mode
./toggle_hybrid_mode.sh

# Enable hybrid mode (Mistral API + Local Worker)
./toggle_hybrid_mode.sh hybrid

# Enable single mode (Local Model Only)
./toggle_hybrid_mode.sh single

# Check status
./toggle_hybrid_mode.sh status
```

## Model Management

The setup includes a model changer script for the worker agent:

```bash
# List available models
./change_worker_model.sh --list

# Interactive model selection
./change_worker_model.sh

# Direct model change
./change_worker_model.sh /path/to/your-model.gguf
```

## Architecture

### Hybrid Mode (Default)
- **Primary Agent**: Mistral API (`devstral-medium-latest`) for complex reasoning
- **Worker Agent**: Local LLM (Mistral-3-3B) for tool calls and simple tasks
- **Workflow**: Primary delegates tasks to worker, verifies results

### Single Mode
- **Single Agent**: Local model only (no Mistral API dependency)
- **Workflow**: One agent handles all tasks
- **Use Case**: When Mistral API is unavailable or for simpler projects

## Files

- `setup_mistral_vibe.sh` - Main setup script
- `start_vllm.sh` - Worker server start script
- `change_worker_model.sh` - Model management script
- `toggle_hybrid_mode.sh` - Mode toggle script
- `vibe-extended` - Extended Vibe with custom commands
- `load_vibe_extensions.py` - Vibe extension loader
- `vibe_custom_commands.py` - Custom command implementations
- `~/.config/mistral_vibe/` - Configuration and agent prompts

## Requirements

- Python 3.8+
- vLLM or llama.cpp for local serving
- Mistral API key (for primary agent)
- GGUF models in `~/models/` directory

## Vibe Extension System

The setup includes a custom extension for Mistral Vibe that adds internal commands:

### Custom Commands Available

- **`/use_hybrid_mode [hybrid|single]`** - Toggle between hybrid and single agent modes
  - `/use_hybrid_mode hybrid` - Enable hybrid mode (Mistral API + Local Worker)
  - `/use_hybrid_mode single` - Enable single mode (Local Model Only)
  - `/use_hybrid_mode` - Show current mode status

- **`/change_worker_model [model_path|--list]`** - Manage worker models
  - `/change_worker_model --list` - List available models
  - `/change_worker_model /path/to/model.gguf` - Change to specific model
  - `/change_worker_model` - Show interactive menu

### How It Works

The extension uses **monkey patching** to extend Vibe's command registry:

1. **Command Registration**: Adds new commands to `CommandRegistry`
2. **Handler Methods**: Adds command handler methods to `VibeApp`
3. **Runtime Execution**: Calls external scripts and reloads configuration
4. **Seamless Integration**: Works like native Vibe commands

### Usage

```bash
# Start extended Vibe
./vibe-extended

# Inside Vibe, use the commands:
/use_hybrid_mode hybrid
/change_worker_model --list
```

## Customization

Edit the configuration files in `~/.config/mistral_vibe/` to:
- Adjust agent parameters
- Modify prompts
- Change model settings
