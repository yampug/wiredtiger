# WiredTiger Crystal Bindings

Crystal language bindings for the WiredTiger embedded database engine.

## 📚 Documentation

All documentation has been moved to the [`docs/`](docs/) directory for better organization.

**Start here**: [docs/INDEX.md](docs/INDEX.md) - Complete documentation index and navigation guide.

## 🚀 Quick Start

1. **Read the docs**: [docs/README.md](docs/README.md)
2. **Install**: [docs/INSTALL.md](docs/INSTALL.md)
3. **Examples**: [`examples/`](examples/) directory
4. **Memory Safety**: [docs/MEMORY_SAFETY.md](docs/MEMORY_SAFETY.md)

## 🧪 Testing

```bash
# Run all tests
task test-crystal

# Run with memory safety checking
task asan

# Run memory safety stress test
task asan-stress
```

## 📁 Project Structure

```
lang/crystal/
├── 📚 docs/                     # All documentation
├── 🔧 examples/                 # Code examples
├── 🧪 spec/                     # Test specifications
├── 📦 package/                  # Standalone package
├── 🚀 src/                      # Source code
└── 🔨 build scripts             # Build and install scripts
```

## 🔗 Quick Links

- **Documentation**: [docs/](docs/)
- **Examples**: [examples/](examples/)
- **Source**: [src/](src/)
- **Tests**: [spec/](spec/)
- **Package**: [package/](package/)

For detailed information, see [docs/INDEX.md](docs/INDEX.md).
