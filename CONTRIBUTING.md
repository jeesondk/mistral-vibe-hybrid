# Contributing to Mistral Vibe Hybrid Setup

Thank you for your interest in contributing to the Mistral Vibe Hybrid Setup project! 🎉

## Ways to Contribute

### 🐛 Bug Reports
- Check existing issues before creating new ones
- Provide clear reproduction steps
- Include system information (OS, Python version, etc.)

### 🚀 Feature Requests
- Describe the use case and benefits
- Explain how it fits with the project goals
- Provide examples if possible

### 💻 Code Contributions
- Fork the repository
- Create a feature branch
- Write clear commit messages
- Submit a pull request

### 📝 Documentation
- Improve existing documentation
- Add examples and tutorials
- Fix typos and clarify explanations

## Development Setup

```bash
# Clone the repository
git clone https://github.com/your-repo/mistral-vibe-hybrid.git
cd mistral-vibe-hybrid

# Make scripts executable
chmod +x *.sh vibe-extended

# Run the setup
./setup_mistral_vibe.sh
```

## Project Structure

```
mistral-vibe-hybrid/
├── agent_templates/          # Agent prompt templates
├── config/                   # Configuration files
├── scripts/                  # Management scripts
├── src/                      # Python extensions
├── tests/                    # Test files
├── LICENSE                    # MIT License
├── CONTRIBUTING.md            # This file
├── README.md                  # Main documentation
└── setup_mistral_vibe.sh       # Main setup script
```

## Agent Template System

Agent templates are located in `agent_templates/` and use placeholders:
- `__PROJECT_ROOT__` - Replaced with actual project root
- `__MODEL_NAME__` - Replaced with current model name

To add a new agent template:
1. Create a new `.template` file in `agent_templates/`
2. Follow the existing format
3. Update `config/setup_config.json` to reference it

## Adding New Commands

To add new Vibe commands:
1. Add command registration in `vibe_custom_commands.py`
2. Implement handler method
3. Add to `CommandRegistry`
4. Test with `./vibe-extended`

## Testing

```bash
# Test basic functionality
./setup_mistral_vibe.sh --test

# Test mode switching
./toggle_hybrid_mode.sh hybrid
./toggle_hybrid_mode.sh single

# Test model changing
./change_worker_model.sh --list
```

## Code Style

- Follow existing code style
- Use clear variable names
- Add comments for complex logic
- Keep functions focused and small

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m 'Add some feature'`
4. Push to branch: `git push origin feature/your-feature`
5. Open a pull request

## Community

- Be respectful and inclusive
- Provide constructive feedback
- Help others with questions
- Follow the Code of Conduct

Thank you for contributing! 🙌