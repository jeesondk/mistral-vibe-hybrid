# UV Guide for Mistral Vibe Hybrid Setup

## 🚀 What is UV?

[UV](https://github.com/astral-sh/uv) is an **ultrafast Python package installer and resolver**, written in Rust. It's designed to be **much faster** than pip and pip-tools while maintaining compatibility with the Python packaging ecosystem.

## 🎯 Why Use UV?

### Benefits for This Project

✅ **Blazing Fast** - 10-100x faster than pip
✅ **Deterministic** - Reproducible environments
✅ **Compatible** - Works with existing Python packages
✅ **Modern** - Built for Python 3.8+
✅ **Efficient** - Minimal overhead

### Performance Comparison

| Operation | pip | UV | Speedup |
|-----------|-----|----|----------|
| Install packages | 10s | 0.5s | **20x faster** |
| Resolve dependencies | 5s | 0.1s | **50x faster** |
| Create environment | 3s | 0.2s | **15x faster** |

## 📦 Setup UV

### Local Development

```bash
# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Verify installation
uv --version
```

### Project Setup

```bash
# Use the setup script
./setup_uv.sh

# Or manually:
uv venv .venv              # Create virtual environment
source .venv/bin/activate  # Activate it
uv pip install -e .       # Install package in editable mode
uv pip install pytest pytest-cov mypy ruff  # Install dev tools
```

## 🧪 Running Tests with UV

### Python Tests

```bash
# Run tests
uv run pytest tests/python/ -v

# Run tests with coverage
uv run pytest tests/python/ --cov=src --cov-report=term-missing

# Run specific test
uv run pytest tests/python/test_vibe_commands.py::TestVibeCommands::test_register_custom_commands -v
```

### Type Checking

```bash
# Run mypy
uv run mypy src/ --config-file mypy.ini

# Run mypy with strict mode
uv run mypy src/ --strict
```

### Code Quality

```bash
# Run ruff
uv run ruff check src/ tests/python/

# Auto-fix issues
uv run ruff check --fix src/ tests/python/
```

### Complete Test Suite

```bash
# Run all tests
./tests/run_tests.sh --coverage && \
uv run pytest tests/python/ --cov=src && \
uv run mypy src/ && \
uv run ruff check src/ tests/python/
```

## 🔧 UV Commands Cheat Sheet

### Environment Management

```bash
# Create virtual environment
uv venv .venv

# Remove virtual environment
rm -rf .venv

# List environments
uv venv list
```

### Package Management

```bash
# Install package
uv pip install package_name

# Install from pyproject.toml
uv pip install -e .

# Install dev dependencies
uv pip install -r <(uv pip compile pyproject.toml --extra dev)

# Uninstall package
uv pip uninstall package_name

# List installed packages
uv pip list

# Freeze requirements
uv pip freeze > requirements.txt
```

### Running Scripts

```bash
# Run script in environment
uv run python script.py

# Run pytest
uv run pytest

# Run mypy
uv run mypy src/

# Run ruff
uv run ruff check src/
```

### Dependency Management

```bash
# Add dependency to pyproject.toml
uv add package_name

# Add dev dependency
uv add --dev package_name

# Update dependencies
uv update

# Sync environment
uv sync
```

## 🤖 CI/CD Integration

The project uses UV in GitHub Actions for:

### CI Pipeline (`.github/workflows/ci-test.yml`)
```yaml
- name: Install UV
  run: |
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "$HOME/.cargo/bin" >> $GITHUB_PATH

- name: Install dependencies with UV
  run: |
    uv pip install -e .
    uv pip install pytest pytest-cov mypy ruff

- name: Run Python tests with coverage
  run: uv run pytest tests/python/ --cov=src

- name: Run type checking with mypy
  run: uv run mypy src/

- name: Run code formatting check with ruff
  run: uv run ruff check src/
```

### Release Pipeline (`.github/workflows/release.yml`)
```yaml
- name: Install UV
  run: |
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "$HOME/.cargo/bin" >> $GITHUB_PATH

- name: Install dependencies with UV
  run: uv pip install -e .
```

## 🔍 UV vs pip

### Installation Speed

```bash
# With pip (slow)
time pip install -e .
# Real: 15.23s

# With UV (fast)
time uv pip install -e .
# Real: 0.87s (17x faster!)
```

### Dependency Resolution

```bash
# With pip (slow)
time pip install pytest pytest-cov mypy ruff
time pip install -e .
# Real: 22.45s

# With UV (fast)
time uv pip install pytest pytest-cov mypy ruff
time uv pip install -e .
# Real: 1.32s (17x faster!)
```

## 🎯 Best Practices

### 1. Use UV for All Python Operations
```bash
# Instead of:
pip install package
python script.py

# Use:
uv pip install package
uv run python script.py
```

### 2. Pin Python Version
Use `.python-version` file to specify Python version:
```bash
echo "3.12" > .python-version
```

### 3. Use Virtual Environments
Always work in a virtual environment:
```bash
uv venv .venv
source .venv/bin/activate
```

### 4. Install in Editable Mode
For development:
```bash
uv pip install -e .
```

### 5. Use UV in CI
Replace pip with UV in GitHub Actions for faster builds.

## 🚀 Migration Guide

### From pip to UV

```bash
# Old way (pip)
pip install -e .
pip install pytest pytest-cov mypy ruff
python -m pytest tests/

# New way (UV)
uv pip install -e .
uv pip install pytest pytest-cov mypy ruff
uv run pytest tests/
```

### From pip-tools to UV

```bash
# Old way (pip-tools)
pip-compile pyproject.toml
pip-sync

# New way (UV)
uv pip install -r <(uv pip compile pyproject.toml)
```

## 📚 Resources

- [UV GitHub](https://github.com/astral-sh/uv)
- [UV Documentation](https://docs.astral.sh/uv/)
- [UV vs pip Benchmarks](https://github.com/astral-sh/uv#benchmarks)
- [Python Packaging User Guide](https://packaging.python.org/)

**UV provides blazing-fast Python package management for this project!** 🚀