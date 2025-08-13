# WiredTiger Repository Maintenance Guide

This guide explains how to keep the entire WiredTiger repository clean and organized, covering all bindings and build artifacts.

## 🧹 Keeping the Repository Clean

### Why Repository Cleanliness Matters

A clean repository:
- **Prevents accidental commits** of build artifacts and temporary files
- **Reduces repository size** by excluding regeneratable files
- **Improves collaboration** by avoiding merge conflicts from build files
- **Maintains professional appearance** and makes development easier
- **Speeds up operations** like cloning, fetching, and merging

### What Gets Cleaned

The cleanup tools remove:
- **Build artifacts**: `.libs/`, `build_posix/`, `build_win/`
- **Java artifacts**: `*.jar`, `temp_java_build/`, `jbindingstest/`
- **Task runner cache**: `.task/`
- **Distribution files**: `dist/` (generated documentation)
- **Generated files**: `configure~`, `wiredtiger_config.h`, `wiredtiger_ext.h`, `wt`
- **Autotools artifacts**: `autom4te.cache/`, `config.log`, `config.status`, `libtool`
- **Temporary files**: `*.tmp`, `*.temp`, `*.bak`, `*.backup`, `*.old`, `*.orig`, `*.rej`
- **OS files**: `.DS_Store`, `Thumbs.db`, `*~`

## 🛠️ Cleanup Tools

### 1. Repository-Wide Cleanup Script

The `clean-repo.sh` script provides comprehensive cleanup for the entire repository:

```bash
# Run from the repository root
./clean-repo.sh
```

**Features:**
- Cleans all build artifacts across the entire repository
- Delegates Crystal-specific cleanup to `lang/crystal/clean.sh`
- Safe removal with detailed progress reporting
- Preserves essential source files and configuration
- Cross-platform compatibility

### 2. Crystal Bindings Cleanup

For Crystal-specific cleanup:

```bash
# Run from the repository root
task clean-crystal

# Or run directly from lang/crystal directory
cd lang/crystal
./clean.sh
```

### 3. Taskfile Integration

Use the Taskfile for convenient cleanup:

```bash
# Clean Crystal bindings only
task clean-crystal

# Clean entire repository
task clean-repo

# Clean all (alias for clean-repo)
task clean-all
```

### 4. Pre-commit Hook (Optional)

Automatically check for build artifacts before committing:

```bash
# Install the pre-commit hook for Crystal bindings
cp lang/crystal/.git/hooks/pre-commit.example lang/crystal/.git/hooks/pre-commit
chmod +x lang/crystal/.git/hooks/pre-commit
```

## 📋 Best Practices

### Regular Maintenance

1. **After building**: Run `./clean-repo.sh` or `task clean-repo`
2. **Before committing**: Check for build artifacts
3. **Weekly**: Review repository for any missed files
4. **After testing**: Clean up test databases and logs
5. **After CI/CD runs**: Clean up any artifacts left by automated builds

### Development Workflow

```bash
# 1. Build the project
task build-all

# 2. Run tests
task test-all

# 3. Clean up before committing
task clean-repo

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
    ./clean-repo.sh
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
find . -name "*.dylib" -o -name "*.so" -o -name "build*" -o -name ".libs" -o -name "dist" -o -name "temp_*" -o -name ".task"
```

### Review .gitignore

Regularly review both `.gitignore` files to ensure they cover:
- New build tools and outputs
- Platform-specific files
- Development environment artifacts
- Language-specific build artifacts

## 🚨 Troubleshooting

### Common Issues

#### "Permission Denied" Errors

```bash
# Fix permissions
chmod +x clean-repo.sh
chmod +x lang/crystal/clean.sh
chmod +x .git/hooks/pre-commit
```

#### Build Artifacts Not Being Cleaned

```bash
# Check if files are tracked by git
git ls-files | grep -E "\.(dylib|so|dll|a|o|jar)$"

# If tracked, remove from git (but keep locally)
git rm --cached filename
```

#### Pre-commit Hook Not Working

```bash
# Check hook location
ls -la lang/crystal/.git/hooks/pre-commit

# Check hook permissions
chmod +x lang/crystal/.git/hooks/pre-commit

# Test manually
lang/crystal/.git/hooks/pre-commit
```

### Manual Cleanup

If automated tools fail:

```bash
# Remove common build directories
rm -rf .libs/ build_posix/ build_win/ dist/ temp_java_build/ jbindingstest/ .task/

# Remove native libraries
find . -name "*.dylib" -delete
find . -name "*.so" -delete
find . -name "*.dll" -delete
find . -name "*.a" -delete
find . -name "*.o" -delete

# Remove Java artifacts
find . -name "*.jar" -delete

# Remove generated files
rm -f configure~ wiredtiger_config.h wiredtiger_ext.h wt
rm -f config.log config.status libtool stamp-h1 Makefile Makefile.in
```

## 📚 Related Documentation

- [Crystal Bindings Maintenance](lang/crystal/docs/MAINTENANCE.md) - Crystal-specific maintenance
- [Memory Safety Guide](lang/crystal/docs/MEMORY_SAFETY.md) - Memory management best practices
- [Installation Guide](lang/crystal/docs/INSTALL.md) - Setup and configuration
- [README](lang/crystal/docs/README.md) - Main project documentation
- [Taskfile Help](Taskfile.yml) - Complete task reference

## 🎯 Success Metrics

A well-maintained repository should have:
- ✅ **Clean git status** after running `./clean-repo.sh`
- ✅ **No build artifacts** in `git ls-files`
- ✅ **Reasonable repository size** (under 200MB for source code)
- ✅ **Fast clone times** for new developers
- ✅ **No merge conflicts** from build files
- ✅ **Professional appearance** with organized structure

## 🔄 Continuous Improvement

### Feedback and Updates

- **Report issues** with cleanup tools
- **Suggest new patterns** for `.gitignore` files
- **Contribute improvements** to cleanup scripts
- **Share best practices** with the community

### Regular Reviews

- **Monthly**: Review `.gitignore` effectiveness
- **Quarterly**: Update cleanup scripts
- **Annually**: Review overall repository organization
- **After major changes**: Update cleanup patterns for new build tools

## 🏗️ Repository Structure

### What Gets Cleaned

```
wiredtiger/
├── .libs/                    # ❌ Compiled libraries (cleaned)
├── build_posix/              # ❌ POSIX build artifacts (cleaned)
├── build_win/                # ❌ Windows build artifacts (cleaned)
├── dist/                     # ❌ Generated documentation (cleaned)
├── temp_java_build/          # ❌ Java build artifacts (cleaned)
├── jbindingstest/            # ❌ Java test artifacts (cleaned)
├── .task/                    # ❌ Task runner cache (cleaned)
├── autom4te.cache/           # ❌ Autotools cache (cleaned)
├── *.jar                     # ❌ Java JAR files (cleaned)
├── configure~                 # ❌ Backup files (cleaned)
├── wiredtiger_config.h       # ❌ Generated headers (cleaned)
├── wiredtiger_ext.h          # ❌ Generated headers (cleaned)
├── wt                        # ❌ Compiled executable (cleaned)
└── [Essential files preserved] ✅
```

### What Gets Preserved

```
wiredtiger/
├── src/                      # ✅ Source code
├── lang/                     # ✅ Language bindings
├── examples/                 # ✅ Example code
├── bench/                    # ✅ Benchmarks
├── test/                     # ✅ Test code
├── ext/                      # ✅ Extensions
├── tools/                    # ✅ Tools
├── .gitignore               # ✅ Configuration
├── Makefile.am              # ✅ Build configuration
├── configure.ac             # ✅ Autotools configuration
├── autogen.sh               # ✅ Build scripts
├── build-and-test.sh        # ✅ Build scripts
├── README                   # ✅ Documentation
├── LICENSE                  # ✅ License
└── INSTALL                  # ✅ Installation guide
```

## 🎉 Success Message

When repository cleanup is successful, you'll see:

```
✅ Repository cleanup completed successfully!

📋 What was cleaned:
   • Build artifacts (.libs/, build_posix/, build_win/)
   • Java artifacts (temp_java_build/, jbindingstest/, *.jar)
   • Task runner cache (.task/)
   • Distribution files (dist/)
   • Generated files (configure~, *.h, wt executable)
   • Autotools artifacts (autom4te.cache/, config.*, libtool, etc.)
   • Crystal bindings (via lang/crystal/clean.sh)
   • Temporary and OS-specific files
```

This indicates that your WiredTiger repository is clean and ready for development!

---

**Remember**: A clean repository is a happy repository! 🧹✨
