#!/bin/bash

# Package script for WiredTiger Crystal bindings
# This script creates a standalone package that can be easily distributed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIREDTIGER_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CRYSTAL_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$CRYSTAL_DIR/package"
PACKAGE_NAME="wiredtiger-crystal-1.0.0"

echo -e "${BLUE}=== WiredTiger Crystal Bindings Package Creation ===${NC}"
echo "Script directory: $SCRIPT_DIR"
echo "WiredTIGER root: $WIREDTIGER_ROOT"
echo "Package directory: $PACKAGE_DIR"
echo ""

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

if ! command -v crystal &> /dev/null; then
    echo -e "${RED}Error: Crystal compiler not found${NC}"
    echo "Please install Crystal from https://crystal-lang.org/install/"
    exit 1
fi

if ! command -v gcc &> /dev/null; then
    echo -e "${RED}Error: GCC compiler not found${NC}"
    echo "Please install GCC or another C compiler"
    exit 1
fi

# Build the bindings first
echo -e "\n${YELLOW}Building bindings...${NC}"
./build.sh

# Create package directory
echo -e "\n${YELLOW}Creating package directory...${NC}"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy source files
echo -e "\n${YELLOW}Copying source files...${NC}"
cp -r "$CRYSTAL_DIR/src" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/shard.yml" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/README.md" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/INSTALL.md" "$PACKAGE_DIR/"

# Copy C source files
echo -e "\n${YELLOW}Copying C source files...${NC}"
cp "$CRYSTAL_DIR/wiredtiger_crystal.c" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/wiredtiger_crystal.h" "$PACKAGE_DIR/"

# Copy native library
echo -e "\n${YELLOW}Copying native library...${NC}"
mkdir -p "$PACKAGE_DIR/lib"
cp "$CRYSTAL_DIR/lib/libwiredtiger_crystal.dylib" "$PACKAGE_DIR/lib/" 2>/dev/null || true
cp "$CRYSTAL_DIR/lib/libwiredtiger_crystal.so" "$PACKAGE_DIR/lib/" 2>/dev/null || true

# Copy build scripts
echo -e "\n${YELLOW}Copying build scripts...${NC}"
cp "$CRYSTAL_DIR/build.sh" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/install.sh" "$PACKAGE_DIR/"
cp "$CRYSTAL_DIR/uninstall.sh" "$PACKAGE_DIR/"

# Create a standalone shard.yml for the package
echo -e "\n${YELLOW}Creating standalone shard.yml...${NC}"
cat > "$PACKAGE_DIR/shard.yml" << 'EOF'
name: wiredtiger
version: 1.0.0

description: |
  Crystal bindings for the WiredTiger embedded database engine.
  Provides a high-level interface for database operations including
  connections, sessions, cursors, and transactions.

authors:
  - WiredTiger Team <support@wiredtiger.com>

targets:
  wiredtiger_crystal:
    main: src/wiredtiger.cr

dependencies:
  # No external dependencies required for basic functionality

development_dependencies:
  ameba:
    github: crystal-ameba/ameba
    version: ~> 1.5.0

crystal: ">= 1.0.0"

license: Apache-2.0

repository:
  type: git
  url: https://github.com/yampug/wiredtiger.git

homepage: https://github.com/wiredtiger/wiredtiger

documentation: https://github.com/wiredtiger/wiredtiger/tree/main/lang/crystal

scripts:
  test: crystal spec
  build: ./build.sh
  clean: rm -rf build lib
  install: ./install.sh
  uninstall: ./uninstall.sh

# Installation instructions
install:
  - "This shard requires the WiredTiger C library to be installed on your system."
  - "Run 'shards run build' to build the native library."
  - "Run 'shards run install' to install system-wide."
EOF

# Create a simple installation script
echo -e "\n${YELLOW}Creating installation script...${NC}"
cat > "$PACKAGE_DIR/install-standalone.sh" << 'EOF'
#!/bin/bash

# Standalone installation script for WiredTiger Crystal bindings

set -e

echo "Installing WiredTiger Crystal bindings..."

# Check if Crystal is available
if ! command -v crystal &> /dev/null; then
    echo "Error: Crystal compiler not found"
    echo "Please install Crystal from https://crystal-lang.org/install/"
    exit 1
fi

# Install dependencies
echo "Installing Crystal dependencies..."
shards install

# Build the native library
echo "Building native library..."
shards run build

# Install system-wide (optional)
read -p "Install system-wide? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing system-wide..."
    shards run install
    echo "Installation complete! You can now use 'wiredtiger' in any Crystal project."
else
    echo "Installation complete! You can use this package as a local dependency."
fi
EOF

chmod +x "$PACKAGE_DIR/install-standalone.sh"

# Create a README for the package
echo -e "\n${YELLOW}Creating package README...${NC}"
cat > "$PACKAGE_DIR/README.md" << 'EOF'
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
EOF

# Create a tarball
echo -e "\n${YELLOW}Creating tarball...${NC}"
cd "$CRYSTAL_DIR"
tar -czf "$PACKAGE_NAME.tar.gz" package/

# Verify package
echo -e "\n${YELLOW}Verifying package...${NC}"
if [ -d "$PACKAGE_DIR" ]; then
    echo -e "${GREEN}✓ Package directory created successfully${NC}"
    ls -la "$PACKAGE_DIR"
else
    echo -e "${RED}✗ Package directory creation failed${NC}"
    exit 1
fi

if [ -f "$PACKAGE_NAME.tar.gz" ]; then
    echo -e "${GREEN}✓ Tarball created successfully${NC}"
    ls -la "$PACKAGE_NAME.tar.gz"
else
    echo -e "${RED}✗ Tarball creation failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Package created successfully!${NC}"
echo ""
echo "Package contents:"
echo "  Directory: $PACKAGE_DIR"
echo "  Tarball: $PACKAGE_NAME.tar.gz"
echo ""
echo "To use this package:"
echo "  1. Extract the tarball: tar -xzf $PACKAGE_NAME.tar.gz"
echo "  2. Run: ./install-standalone.sh"
echo "  3. Use in your project with: path: /path/to/package"
echo ""
echo "The package is now ready for distribution!"
