# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- Hybrid agent architecture
- Vibe extension system
- Distribution scripts

### Changed
- Nothing yet

### Fixed
- Nothing yet

## [1.0.0] - 2024-03-07

### Added
- **Core System**: Complete hybrid agent setup with Mistral API + Local LLM
- **Agent Templates**: Modular template system for hybrid and single agents
- **Management Scripts**:
  - `setup_mistral_vibe.sh`: Main setup script
  - `start_vllm.sh`: Worker server management
  - `change_worker_model.sh`: Model switching
  - `toggle_hybrid_mode.sh`: Mode toggle
- **Vibe Extension**:
  - `vibe_custom_commands.py`: Custom command implementations
  - `load_vibe_extensions.py`: Extension loader
  - `vibe-extended`: Convenience wrapper
- **Distribution System**:
  - `install.sh`: One-liner installer
  - `package.sh`: Package creation
  - `sign_scripts.sh`: Security signing
- **Documentation**:
  - `README.md`: Complete usage guide
  - `CONTRIBUTING.md`: Contribution guidelines
  - `DISTRIBUTION_GUIDE.md`: Distribution instructions
  - `OPEN_SOURCE_SUMMARY.md`: Project overview
- **CI/CD**: GitHub Actions workflows for testing and releases
- **Configuration**: Centralized JSON configuration

### Features
- ✅ Hybrid agent architecture (Primary + Worker)
- ✅ Single agent mode support
- ✅ Model management system
- ✅ Mode toggle functionality
- ✅ Vibe internal commands (`/use_hybrid_mode`, `/change_worker_model`)
- ✅ Multiple distribution methods
- ✅ Script signing and verification
- ✅ Automated packaging
- ✅ CI/CD pipeline

### Technical Details
- **Primary Agent**: Mistral API (`devstral-medium-latest`)
- **Worker Agent**: Local Mistral-3-3B model
- **Vibe Extension**: Monkey-patching for command integration
- **Package Formats**: tar.gz, zip, signed packages
- **Security**: GPG signatures, SHA256 checksums
- **CI/CD**: GitHub Actions with automatic releases

### Breaking Changes
- None (initial release)

### Known Issues
- GPG signing is simulated in scripts (needs real implementation)
- NPX package is optional (not fully implemented)
- Some error handling could be improved

### Deprecated
- Nothing (initial release)

### Removed
- Nothing (initial release)

### Security
- Scripts include basic security checks
- Signature verification system in place
- Checksum validation available

## [0.1.0] - 2024-03-07

### Added
- Initial project structure
- Basic setup script
- Agent templates
- Documentation skeleton

[Unreleased]: https://github.com/your-repo/mistral-vibe-hybrid/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-repo/mistral-vibe-hybrid/releases/tag/v1.0.0
[0.1.0]: https://github.com/your-repo/mistral-vibe-hybrid/releases/tag/v0.1.0