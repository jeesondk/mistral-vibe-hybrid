# Documentation Structure

## 📁 Folder Organization

```
docs/
├── CHANGELOG.md          # Version history and release notes
├── CI_CD_GUIDE.md         # CI/CD pipeline documentation
├── CONTRIBUTING.md        # Contribution guidelines
├── DISTRIBUTION_GUIDE.md  # Distribution and packaging guide
├── OPEN_SOURCE_SUMMARY.md # Open source project overview
├── STRUCTURE.md           # This file (documentation structure)
├── TESTING_GUIDE.md       # Testing strategy and coverage
├── UV_GUIDE.md           # UV setup and usage guide
└── (README.md moved to root)
```

## 📚 Documentation Guide

### For Users

1. **Start Here**: `README.md` (in project root)
   - Quick start guide
   - Feature overview
   - Installation instructions

2. **Setup & Configuration**: `docs/DISTRIBUTION_GUIDE.md`
   - Distribution options
   - Package management
   - Installation methods

3. **Usage**: `README.md` (in project root)
   - Basic setup
   - Advanced features
   - Examples

### For Contributors

1. **Contributing**: `docs/CONTRIBUTING.md`
   - How to contribute
   - Development setup
   - Pull request process

2. **Testing**: `docs/TESTING_GUIDE.md`
   - Test suite overview
   - Running tests
   - Test coverage

3. **CI/CD**: `docs/CI_CD_GUIDE.md`
   - Pipeline overview
   - Workflow details
   - Release process

### For Maintainers

1. **Open Source**: `docs/OPEN_SOURCE_SUMMARY.md`
   - Project overview
   - Architecture
   - Customization points

2. **UV Setup**: `docs/UV_GUIDE.md`
   - UV installation
   - Usage guide
   - Performance benefits

3. **Releases**: `docs/DISTRIBUTION_GUIDE.md`
   - Release process
   - Packaging
   - Distribution

## 🎯 Documentation Standards

### Writing Guidelines

1. **Clear and Concise**: Explain concepts simply
2. **Example-Driven**: Include code examples
3. **Up-to-Date**: Keep docs in sync with code
4. **Well-Structured**: Use headings and lists
5. **Complete**: Cover all use cases

### Format

```markdown
## Section Header

### Subsection

- Bullet points for
- Key information

```bash
# Code examples
command_here
```

**Bold** for important notes
```

### Maintenance

- **Update with code changes**: Docs should reflect current state
- **Review regularly**: Keep information accurate
- **Add new guides**: As features are added
- **Deprecate old**: Mark outdated information

## 🚀 Navigation Tips

```bash
# List all documentation
ls -la docs/

# Read specific guide
cat docs/CONTRIBUTING.md

# Search documentation
grep -r "keyword" docs/
```

## 📝 Documentation Workflow

1. **Add new feature** → Update relevant guide
2. **Fix bug** → Update documentation if needed
3. **Release version** → Update CHANGELOG.md
4. **Review PRs** → Check documentation updates

**Keep documentation and code in sync!** 📚