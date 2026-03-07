# .gitignore Guide

## 📄 Purpose

The `.gitignore` file specifies which files and directories Git should ignore. This keeps the repository clean by excluding:
- Generated files (build artifacts, cache, etc.)
- IDE/editor specific files
- OS-specific files
- Environment files
- Test artifacts

## 📁 What's Ignored

### Python
```
__pycache__/
*.py[cod]
*.pyc
*.pyo
*.pyd
.Python
build/
dist/
*.egg-info/
```

### Testing
```
htmlcov/
.tox/
.coverage
*.cover
.pytest_cache/
/tests/coverage/
```

### Environments
```
.env
.venv/
ENV/
venv/
```

### IDE/Editor
```
.idea/
.vscode/
*.swp
*.swo
```

### OS-Specific
```
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
```

### Build Tools
```
develop-eggs/
eggs/
.libs/
lib/
lib64/
parts/
sdist/
var/
wheels/
```

### Logs & Runtime
```
logs/
*.log
pids/
*.pid
*.seed
*.pid.lock
```

## 🎯 Best Practices

1. **Keep repository clean**: Ignore generated files
2. **Share .gitignore**: Commit to repository
3. **Update regularly**: Add new ignore patterns
4. **Test**: Verify ignored files with `git status`

## 🚀 Usage

### Check ignored files
```bash
git status --ignored
```

### Test .gitignore
```bash
git check-ignore -v path/to/file
```

### Update .gitignore
```bash
echo "new_pattern" >> .gitignore
git rm -r --cached .  # Remove cached files
git add .
```

## 📚 Resources

- [GitHub .gitignore templates](https://github.com/github/gitignore)
- [Git Documentation](https://git-scm.com/docs/gitignore)
- [Atlassian .gitignore guide](https://www.atlassian.com/git/tutorials/saving-changes/gitignore)

**The .gitignore file keeps the repository clean and efficient!** 🚀