# Repository Maintenance Guide

This guide explains how to keep the WiredTiger Crystal bindings repository clean and organized.

## 🧹 Keeping the Repository Clean

### Why Cleanliness Matters

A clean repository:
- **Prevents accidental commits** of build artifacts and temporary files
- **Reduces repository size** by excluding regeneratable files
- **Improves collaboration** by avoiding merge conflicts from build files
- **Maintains professional appearance** and makes development easier

### What Gets Cleaned

The cleanup tools remove:
- **Build directories**: `build/`, `lib/`, `bin/`, `tmp/`
- **Native libraries**: `*.dylib`, `*.so`, `*.dll`, `*.a`, `*.o`
- **Package files**: `*.tar.gz`, `*.zip`, `*.tar`
- **Database files**: `*.wt`, `*.wtcheckpoint`, `*.wtlog`, etc.
- **Test artifacts**: `test_*`, `*_test`, `memory_stress_test_*`, etc.
- **Log files**: `*.log`, `*.out`, `*.err`
- **OS files**: `.DS_Store`, `Thumbs.db`, `*~`
- **Temporary files**: `*.tmp`, `*.temp`, `*.bak`, etc.

## 🛠️ Cleanup Tools

### 1. Manual Cleanup Script

The `clean.sh` script provides comprehensive cleanup:

```bash
# Run from the lang/crystal directory
./clean.sh
```

**Features:**
- Safe removal with confirmation
- Detailed progress reporting
- Preserves essential source files
- Cross-platform compatibility

### 2. Taskfile Integration

Use the Taskfile for easy cleanup:

```bash
# Clean Crystal bindings only
task clean-crystal

# Clean all build artifacts
task clean-all
```

### 3. Pre-commit Hook (Optional)

Automatically check for build artifacts before committing:

```bash
# Install the pre-commit hook
cp .git/hooks/pre-commit.example .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**What it does:**
- Detects build artifacts before commit
- Offers automatic cleanup
- Prevents accidental commits of temporary files

## 📋 Best Practices

### Regular Maintenance

1. **After building**: Run `./clean.sh` or `task clean-crystal`
2. **Before committing**: Check for build artifacts
3. **Weekly**: Review repository for any missed files
4. **After testing**: Clean up test databases and logs

### Development Workflow

```bash
# 1. Build the project
task build-crystal

# 2. Run tests
task test-crystal

# 3. Clean up before committing
task clean-crystal

# 4. Commit your changes
git add .
git commit -m "Your commit message"
```

### CI/CD Integration

Include cleanup in your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Clean build artifacts
  run: |
    cd lang/crystal
    ./clean.sh
```

## 🔍 Monitoring Repository Health

### Check Repository Size

```bash
# Check repository size
git count-objects -vH

# Check for large files
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sed -n 's/^blob //p' | sort -nr -k2 | head -10
```

### Identify Build Artifacts

```bash
# Check what would be cleaned
find . -name "*.dylib" -o -name "*.so" -o -name "build" -o -name "lib" -o -name "tmp"
```

### Review .gitignore

Regularly review `.gitignore` to ensure it covers:
- New build tools and outputs
- Platform-specific files
- Development environment artifacts

## 🚨 Troubleshooting

### Common Issues

#### "Permission Denied" Errors

```bash
# Fix permissions
chmod +x clean.sh
chmod +x .git/hooks/pre-commit
```

#### Build Artifacts Not Being Cleaned

```bash
# Check if files are tracked by git
git ls-files | grep -E "\.(dylib|so|dll|a|o)$"

# If tracked, remove from git (but keep locally)
git rm --cached filename
```

#### Pre-commit Hook Not Working

```bash
# Check hook location
ls -la .git/hooks/pre-commit

# Check hook permissions
chmod +x .git/hooks/pre-commit

# Test manually
.git/hooks/pre-commit
```

### Manual Cleanup

If automated tools fail:

```bash
# Remove common build directories
rm -rf build/ lib/ bin/ tmp/

# Remove native libraries
find . -name "*.dylib" -delete
find . -name "*.so" -delete
find . -name "*.dll" -delete
find . -name "*.a" -delete
find . -name "*.o" -delete

# Remove package files
rm -f *.tar.gz *.zip *.tar

# Remove database files
rm -f *.wt *.wtcheckpoint *.wtlog *.wtmetadata *.wtbackup
```

## 📚 Related Documentation

- [Memory Safety Guide](MEMORY_SAFETY.md) - Memory management best practices
- [Installation Guide](INSTALL.md) - Setup and configuration
- [README](README.md) - Main project documentation
- [Taskfile Help](../../Taskfile.yml) - Complete task reference

## 🎯 Success Metrics

A well-maintained repository should have:
- ✅ **Clean git status** after running `./clean.sh`
- ✅ **No build artifacts** in `git ls-files`
- ✅ **Reasonable repository size** (under 100MB for source code)
- ✅ **Fast clone times** for new developers
- ✅ **No merge conflicts** from build files

## 🔄 Continuous Improvement

### Feedback and Updates

- **Report issues** with cleanup tools
- **Suggest new patterns** for `.gitignore`
- **Contribute improvements** to cleanup scripts
- **Share best practices** with the community

### Regular Reviews

- **Monthly**: Review `.gitignore` effectiveness
- **Quarterly**: Update cleanup scripts
- **Annually**: Review overall repository organization

---

**Remember**: A clean repository is a happy repository! 🧹✨
