# WiredTiger Crystal Bindings - Standalone Package

This is a standalone package of the WiredTiger Crystal bindings.

## Quick Installation

```bash
# Install dependencies and build
./install-standalone.sh

# Or manually:
shards install
shards run build
```

## Usage in Your Project

### Option 1: Use this package directly
```yaml
dependencies:
  wiredtiger:
    path: /path/to/this/package
```

### Option 2: Install system-wide
```bash
shards run install
```

Then use in any project:
```yaml
dependencies:
  wiredtiger:
    path: /usr/local/include/wiredtiger/crystal
```

## What's Included

- Crystal source files
- Native library (built for your system)
- Build and installation scripts
- Complete documentation
- Test suite

## Requirements

- Crystal 1.0.0+
- WiredTiger C library
- GCC or Clang compiler
