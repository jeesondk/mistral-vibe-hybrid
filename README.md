# Mistral Vibe Hybrid Setup 🤖

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)

**Open Source Hybrid Agent Architecture for Mistral Vibe**

This project provides a complete hybrid agent system that combines:

- **Primary Agent**: Mistral API (`devstral-medium-latest`) for complex reasoning
- **Worker Agent**: Local LLM (Mistral-3-3B) for tool calls and simple tasks
- **Vibe Extension**: Custom commands integrated into Mistral Vibe

## 🌟 Features

✅ **Hybrid Architecture** - Best of both worlds: API quality + local speed
✅ **Model Management** - Easy worker model switching
✅ **Mode Toggle** - Switch between hybrid and single-agent modes
✅ **Vibe Integration** - Custom commands inside Mistral Vibe
✅ **Open Source Ready** - MIT License, templates, and documentation
✅ **Modular Design** - Easy to extend and customize

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

## 🚀 Installation Options

### Option 1: Quick Install (Recommended)
```bash
# Simple one-liner installation
curl -sSL https://raw.githubusercontent.com/your-repo/mistral-vibe-hybrid/main/install.sh | bash
```

### Option 2: Manual Install
```bash
# Clone and setup manually
git clone https://github.com/your-repo/mistral-vibe-hybrid.git
cd mistral-vibe-hybrid
./setup_mistral_vibe.sh
```

### Option 3: Package Download
```bash
# Download pre-built package
curl -LO https://github.com/your-repo/mistral-vibe-hybrid/releases/download/v1.0.0/mistral-vibe-hybrid-1.0.0.tar.gz

# Extract and install
tar -xzf mistral-vibe-hybrid-1.0.0.tar.gz
cd mistral-vibe-hybrid
./install.sh
```

### Option 4: Verified Install (Security Conscious)
```bash
# Download and verify checksums
curl -LO https://github.com/your-repo/mistral-vibe-hybrid/releases/download/v1.0.0/mistral-vibe-hybrid-1.0.0.tar.gz
curl -LO https://github.com/your-repo/mistral-vibe-hybrid/releases/download/v1.0.0/checksums.txt

# Verify integrity
sha256sum -c checksums.txt

# Extract and install
tar -xzf mistral-vibe-hybrid-1.0.0.tar.gz
cd mistral-vibe-hybrid
./install.sh
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

## 📁 Project Structure

```
mistral-vibe-hybrid/
├── agent_templates/              # 📝 Agent prompt templates (modular)
│   ├── hybrid_primary.md.template
│   ├── hybrid_worker.md.template
│   └── single_agent.md.template
├── config/                       # ⚙️ Configuration files
│   └── setup_config.json         # Project configuration
├── agent_templates/              # 📝 Agent prompt templates
├── scripts/                      # 🎬 Management scripts
│   ├── setup_mistral_vibe.sh      # 🎯 Main setup (31KB)
│   ├── start_vllm.sh             # 🚀 Worker server (660B)
│   ├── change_worker_model.sh    # 🔄 Model management (3.8KB)
│   └── toggle_hybrid_mode.sh     # ⚡ Mode toggle (7.5KB)
├── src/                          # 🐍 Python extensions
│   ├── vibe_custom_commands.py   # 🤖 Command implementations (7.2KB)
│   └── load_vibe_extensions.py   # 🔌 Extension loader (1.7KB)
├── vibe-extended                 # 🎛️ Extended Vibe wrapper
├── LICENSE                       # 📄 MIT License
├── CONTRIBUTING.md               # 🤝 Contribution guide
└── README.md                     # 📖 This documentation

Runtime config: ~/.config/mistral_vibe/
Model storage: ~/models/
```

## 📦 Distribution Options

This project supports multiple distribution methods:

### 1. **Install Script (Recommended)** ✅
- Single command installation
- Automatic dependency checking
- Interactive setup process
- Best for most users

**Usage:**
```bash
curl -sSL https://raw.githubusercontent.com/your-repo/mistral-vibe-hybrid/main/install.sh | bash
```

### 2. **Pre-built Packages** 📦
- Tarball (.tar.gz) packages
- ZIP archives
- Checksums for verification
- Best for offline installation

**Create packages:**
```bash
./package.sh tar.gz      # Create tar.gz package
./package.sh zip         # Create zip package
./package.sh all         # Create all formats
```

### 3. **Script Signing** 🔒
- GPG signatures for security
- SHA256 checksums
- Integrity verification
- Best for security-conscious users

**Sign scripts:**
```bash
./sign_scripts.sh --all      # Sign all scripts
./sign_scripts.sh --verify   # Verify signatures
```

### 4. **NPX Package (Optional)** 📦
- npm package for convenience
- Global installation
- Version management
- Best for Node.js users

**Install:**
```bash
npx mistral-vibe-hybrid
```

## 🤖 CI/CD System

This project includes a complete CI/CD pipeline using GitHub Actions:

### Continuous Integration
- **Trigger**: Runs on every push to `main`/`dev` and pull requests
- **Jobs**: Linting, testing, and verification
- **Features**:
  - Shell script syntax checking
  - Python syntax validation
  - Install script testing
  - Package creation testing
  - Setup script verification

**Workflow File**: `.github/workflows/ci-test.yml`

### Automated Releases
- **Trigger**: Creates release when version tag is pushed (`v1.0.0`)
- **Features**:
  - Automatic package creation (tar.gz, zip)
  - Checksum generation
  - GitHub Release creation
  - Professional release notes
  - Asset upload

**Workflow File**: `.github/workflows/release.yml`

### Release Process

```bash
# 1. Update version in files
sed -i "s/VERSION=.*/VERSION=1.0.1/" install.sh

# 2. Commit changes
git add .
git commit -m "Bump version to 1.0.1"

# 3. Create and push tag
git tag v1.0.1
git push origin v1.0.1

# 4. GitHub Actions automatically:
#    - Runs CI tests
#    - Creates packages
#    - Generates release notes
#    - Creates GitHub Release
```

### CI/CD Badges

Add these to your README:

```markdown
[![CI Status](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/ci-test.yml/badge.svg)](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/ci-test.yml)
[![Release](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/release.yml/badge.svg)](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/release.yml)
```

## 🎯 Open Source Ready

This project is designed for open source contribution:

- **MIT License** - Permissive open source license
- **Modular Templates** - Easy to customize agent prompts
- **Configuration File** - Centralized settings management
- **Contribution Guide** - Clear contribution process
- **Documentation** - Comprehensive setup and usage guides

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
