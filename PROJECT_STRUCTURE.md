# Project Structure

## 🗂️ Overall Organization

```
mistral-vibe-hybrid/
├── .github/                  # GitHub Actions workflows
│   └── workflows/            # CI/CD pipelines
│       ├── ci-test.yml       # Test workflow
│       └── release.yml       # Release workflow
├── .python-version           # Python 3.12
├── CHANGELOG.md              # Version history (root)
├── CONTRIBUTING.md           # Contribution guidelines (root)
├── LICENSE                   # MIT License (root)
├── PROJECT_STRUCTURE.md     # This file
├── README.md                # Main documentation (root)
├── pyproject.toml            # Python project config
├── setup_uv.sh               # UV setup script
├── test_python312.sh         # Migration test script
├── agent_templates/         # Agent prompt templates
│   ├── hybrid_primary.md.template
│   ├── hybrid_worker.md.template
│   └── single_agent.md.template
├── config/                  # Configuration
│   └── setup_config.json    # Setup configuration
├── docs/                   # Comprehensive documentation
│   ├── CI_CD_GUIDE.md       # CI/CD guide
│   ├── DISTRIBUTION_GUIDE.md # Distribution guide
│   ├── OPEN_SOURCE_SUMMARY.md # Open source overview
│   ├── STRUCTURE.md        # Documentation structure
│   ├── TESTING_GUIDE.md    # Testing guide
│   └── UV_GUIDE.md        # UV guide
├── scripts/                # Management scripts
│   ├── change_worker_model.sh
│   ├── install.sh
│   ├── package.sh
│   ├── sign_scripts.sh
│   ├── setup_mistral_vibe.sh
│   ├── start_vllm.sh
│   └── toggle_hybrid_mode.sh
├── src/                   # Python package
│   ├── __init__.py        # Package initialization
│   ├── load_vibe_extensions.py
│   └── vibe_custom_commands.py
├── tests/                 # Testing
│   ├── python/            # Python tests
│   │   └── test_vibe_commands.py
│   ├── pytest.ini         # pytest config
│   └── run_tests.sh       # Test runner
```

## 🎯 Key Components

### 1. Core System
- **`setup_mistral_vibe.sh`** - Main setup script
- **`agent_templates/`** - Modular agent prompts
- **`config/setup_config.json`** - Centralized configuration

### 2. Python Package
- **`src/`** - Python modules
- **`pyproject.toml`** - Project configuration
- **`pytest.ini`** - Test configuration

### 3. Documentation
- **Root**: CONTRIBUTING, CHANGELOG, LICENSE, README
- **docs/**: Comprehensive guides for all aspects

### 4. Scripts
- **Management**: install, package, sign scripts
- **Agent**: change_worker_model, toggle_hybrid_mode
- **Server**: start_vllm

### 5. Testing
- **Shell tests**: 9 tests in run_tests.sh
- **Python tests**: 4 pytest tests
- **Type checking**: mypy strict mode
- **Code quality**: ruff checking

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/your-repo/mistral-vibe-hybrid.git
cd mistral-vibe-hybrid

# Run setup
./setup_mistral_vibe.sh

# Start worker server
./start_vllm.sh

# Use extended Vibe
./vibe-extended
```

## 📦 Distribution

### Files
- **Install script**: `install.sh` (primary method)
- **Packages**: tar.gz, zip (offline install)
- **CI/CD**: GitHub Actions workflows

### Documentation
- **Root docs**: Essential files (CONTRIBUTING, CHANGELOG, LICENSE)
- **docs/**: Comprehensive guides for all features

## 🎓 Architecture

### Hybrid Mode
```
Primary Agent (Mistral API)
       ↓ Delegates to
Worker Agent (Local LLM)
```

### Single Mode
```
Single Agent (Local LLM)
```

### Key Features
- ✅ Hybrid agent architecture
- ✅ Model management
- ✅ Mode toggle
- ✅ Vibe extension
- ✅ CI/CD integration
- ✅ Comprehensive testing

## 📚 Documentation Structure

**Root Level (Common Files):**
- `README.md` - Main documentation
- `CONTRIBUTING.md` - Contribution guidelines
- `CHANGELOG.md` - Version history
- `LICENSE` - MIT License

**docs/ (Comprehensive Guides):**
- `CI_CD_GUIDE.md` - CI/CD documentation
- `DISTRIBUTION_GUIDE.md` - Distribution options
- `OPEN_SOURCE_SUMMARY.md` - Project overview
- `TESTING_GUIDE.md` - Testing strategy
- `UV_GUIDE.md` - UV setup guide
- `STRUCTURE.md` - Documentation organization

## 🎯 Best Practices

1. **Keep root clean**: Only essential files
2. **Organize docs**: Comprehensive guides in docs/
3. **Separate concerns**: Scripts, config, source, tests
4. **Document everything**: Clear and complete docs
5. **Test thoroughly**: CI/CD integration

**The project structure is organized, scalable, and well-documented!** 🚀