# CI/CD Guide for Mistral Vibe Hybrid Setup

## 🎯 Overview

This guide explains the CI/CD (Continuous Integration/Continuous Deployment) system for the Mistral Vibe Hybrid Setup project. The system uses GitHub Actions to automate testing, packaging, and releases.

## 📁 CI/CD Files

```
.github/workflows/
├── ci-test.yml        # Continuous Integration tests
├── release.yml        # Automated release workflow
└── ci.yml             # Original CI workflow (deprecated)
```

## 🤖 Continuous Integration (CI)

### Workflow: `ci-test.yml`

**Trigger:** Runs on every push to `main`/`dev` branches and pull requests

**Jobs:**

#### 1. Lint Job
- **Purpose**: Code quality checking
- **Steps**:
  - Checkout repository
  - Run shellcheck on all shell scripts
  - Check Python syntax

#### 2. Test Job
- **Purpose**: Functional testing
- **Steps**:
  - Checkout repository
  - Set up Python 3.12
  - Install dependencies (curl, git, gnupg, shellcheck)
  - Make scripts executable
  - Test install script (`--help`, `--version`)
  - Test package creation
  - Test setup script
  - Verify created files
  - Cleanup

**Example CI Run:**
```bash
# This happens automatically on push
# 1. Checkout code
# 2. Run lint job
# 3. Run test job (if lint passes)
# 4. Report success/failure
```

## 🚀 Automated Releases

### Workflow: `release.yml`

**Trigger:** Push of version tag (e.g., `v1.0.0`)

**Process:**

1. **Extract Version**: Get version from tag (`v1.0.0` → `1.0.0`)
2. **Create Packages**: Run `package.sh all --checksums`
3. **Generate Release Notes**: Create professional markdown notes
4. **Create GitHub Release**: Upload assets and publish

**Release Assets:**
- `mistral-vibe-hybrid-1.0.0-YYYYMMDD.tar.gz`
- `mistral-vibe-hybrid-1.0.0-YYYYMMDD.zip`
- `checksums.txt`

**Example Release Process:**

```bash
# 1. Update version in install.sh
sed -i "s/VERSION=.*/VERSION=1.0.1/" install.sh

# 2. Commit changes
git add install.sh
git commit -m "Bump version to 1.0.1"

# 3. Create and push tag
git tag v1.0.1
git push origin v1.0.1

# 4. GitHub Actions automatically:
#    - Runs CI tests (ci-test.yml)
#    - If tests pass, runs release workflow
#    - Creates packages
#    - Generates release notes
#    - Creates GitHub Release with assets
```

## 🎓 Using the CI/CD System

### For Developers

**Before Pushing:**
```bash
# Run tests locally
./install.sh --help
./package.sh tar.gz

# Check shell scripts
shellcheck *.sh

# Check Python syntax
python3 -m py_compile vibe_custom_commands.py
```

**Creating a Release:**
```bash
# Update version
sed -i "s/VERSION=.*/VERSION=1.0.1/" install.sh

# Update CHANGELOG.md
# Add new entry for version 1.0.1

# Commit and tag
git add install.sh CHANGELOG.md
git commit -m "Prepare v1.0.1 release"
git tag v1.0.1
git push origin main --tags
```

### For Maintainers

**Monitoring CI/CD:**
- Check CI status: `https://github.com/your-repo/mistral-vibe-hybrid/actions`
- View test results
- Debug failures

**Manual Release (if needed):**
```bash
# Manually trigger release workflow
gh workflow run release.yml -f tag=v1.0.1
```

## 🔧 Customizing CI/CD

### Modifying CI Tests

Edit `.github/workflows/ci-test.yml`:
- Add new test steps
- Change Python version
- Add additional dependencies

### Modifying Release Process

Edit `.github/workflows/release.yml`:
- Change package formats
- Modify release notes template
- Add additional assets

### Adding New Workflows

Create new workflow files in `.github/workflows/`:
- Nightly builds
- Documentation generation
- Security scanning

## 📊 CI/CD Badges

Add these to your README:

```markdown
[![CI Status](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/ci-test.yml/badge.svg)](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/ci-test.yml)
[![Release](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/release.yml/badge.svg)](https://github.com/your-repo/mistral-vibe-hybrid/actions/workflows/release.yml)
```

## 🚨 Troubleshooting

### CI Failures

**Common Issues:**

1. **Shellcheck errors**: Fix syntax in shell scripts
2. **Python syntax errors**: Fix Python files
3. **Missing dependencies**: Update CI workflow
4. **Permission errors**: Check file permissions

**Debugging:**
```bash
# Check CI logs on GitHub
# Reproduce locally:
docker run -it ubuntu:latest bash
apt update && apt install -y curl git gnupg shellcheck python3
# Run the failing commands manually
```

### Release Failures

**Common Issues:**

1. **Tag format incorrect**: Use `v1.0.0` format
2. **Package creation fails**: Check package.sh
3. **GitHub token missing**: Check repository secrets
4. **Asset upload fails**: Check file permissions

## 🧪 Enhanced Testing System

The CI/CD system now includes comprehensive testing with:

### 1. pytest with Coverage
- **pytest**: Python testing framework
- **pytest-cov**: Coverage plugin for pytest
- **Coverage Types**: Line coverage, branch coverage
- **Reports**: Terminal, HTML, XML

### 2. Type Checking with mypy
- **Strict mode**: Enabled by default
- **Type annotations**: Required for all functions
- **Configuration**: `mypy.ini`

### 3. Code Quality with ruff
- **PEP 8 compliance**: Enforced
- **Import sorting**: Automatic
- **Code style**: Consistent

### 4. Shell Script Testing
- **shellcheck**: Syntax validation
- **Functional tests**: Help/version commands
- **Integration tests**: Complete workflows

## 🎯 Best Practices

### For CI
- ✅ Run tests on every push
- ✅ Test on multiple Python versions (if needed)
- ✅ Include linting in CI
- ✅ Test installation process
- ✅ Verify created files

### For Releases
- ✅ Use semantic versioning
- ✅ Tag commits properly
- ✅ Generate good release notes
- ✅ Include checksums
- ✅ Test release process

### For Security
- ✅ Don't store secrets in workflows
- ✅ Use GitHub secrets for tokens
- ✅ Sign release assets
- ✅ Verify checksums
- ✅ Rotate tokens regularly

## 🚀 Future Enhancements

### CI Improvements
- Add more test coverage
- Test on multiple OS (Ubuntu, macOS, Windows)
- Add integration tests
- Include performance tests

### Release Improvements
- Automatic CHANGELOG generation
- Signed releases with GPG
- Multi-platform packages
- Delta updates

### Advanced Features
- Nightly builds
- Canary releases
- Automated documentation
- Security scanning
- Dependency updates

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [ShellCheck](https://www.shellcheck.net/)

**The CI/CD system is fully operational and ready for production use!** 🚀