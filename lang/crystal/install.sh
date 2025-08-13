#!/bin/bash

# Installation script for WiredTiger Crystal bindings
# This script builds and installs the native library to system locations

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
BUILD_DIR="$CRYSTAL_DIR/build"
LIB_DIR="$CRYSTAL_DIR/lib"

# Installation paths
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
INSTALL_LIB_DIR="$INSTALL_PREFIX/lib"
INSTALL_INCLUDE_DIR="$INSTALL_PREFIX/include/wiredtiger/crystal"

echo -e "${BLUE}=== WiredTiger Crystal Bindings Installation ===${NC}"
echo "Script directory: $SCRIPT_DIR"
echo "WiredTiger root: $WIREDTIGER_ROOT"
echo "Install prefix: $INSTALL_PREFIX"
echo ""

# Check if running as root for system installation
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Running as root - will install to system locations${NC}"
else
    echo -e "${YELLOW}Not running as root - will install to user locations${NC}"
    INSTALL_PREFIX="$HOME/.local"
    INSTALL_LIB_DIR="$INSTALL_PREFIX/lib"
    INSTALL_INCLUDE_DIR="$INSTALL_PREFIX/include/wiredtiger/crystal"
    echo "User install prefix: $INSTALL_PREFIX"
fi

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

# Check if WiredTiger core library exists
if [ ! -f "$WIREDTIGER_ROOT/.libs/libwiredtiger.dylib" ] && [ ! -f "$WIREDTIGER_ROOT/.libs/libwiredtiger.so" ]; then
    echo -e "${YELLOW}Warning: WiredTiger core library not found${NC}"
    echo "Building core library first..."
    cd "$WIREDTIGER_ROOT"
    ./configure
    make -j4
    cd "$CRYSTAL_DIR"
fi

# Create build directories
echo -e "\n${YELLOW}Creating build directories...${NC}"
mkdir -p "$BUILD_DIR" "$LIB_DIR"

# Build C extension
echo -e "\n${YELLOW}Building C extension...${NC}"
gcc -c -fPIC \
    -I"$WIREDTIGER_ROOT/src/include" \
    -o "$BUILD_DIR/libwiredtiger_crystal.o" \
    "$CRYSTAL_DIR/wiredtiger_crystal.c"

# Determine library extension and build shared library
if [[ "$OSTYPE" == "darwin"* ]]; then
    LIB_EXT="dylib"
    # Build with proper install name and rpath
    gcc -shared \
        -o "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT" \
        "$BUILD_DIR/libwiredtiger_crystal.o" \
        -L"$WIREDTIGER_ROOT/.libs" \
        -lwiredtiger \
        -Wl,-install_name,"$INSTALL_LIB_DIR/libwiredtiger_crystal.$LIB_EXT" \
        -Wl,-rpath,"$INSTALL_LIB_DIR:$WIREDTIGER_ROOT/.libs"
else
    LIB_EXT="so"
    gcc -shared \
        -o "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT" \
        "$BUILD_DIR/libwiredtiger_crystal.o" \
        -L"$WIREDTIGER_ROOT/.libs" \
        -lwiredtiger \
        -Wl,-rpath,"$INSTALL_LIB_DIR:$WIREDTIGER_ROOT/.libs"
fi

# Build Crystal library
echo -e "\n${YELLOW}Building Crystal library...${NC}"
cd "$CRYSTAL_DIR"
crystal build --release -o "$BUILD_DIR/wiredtiger_crystal" src/wiredtiger.cr

# Create installation directories
echo -e "\n${YELLOW}Creating installation directories...${NC}"
mkdir -p "$INSTALL_LIB_DIR" "$INSTALL_INCLUDE_DIR"

# Install the native library
echo -e "\n${YELLOW}Installing native library...${NC}"
cp "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT" "$INSTALL_LIB_DIR/"
chmod 755 "$INSTALL_LIB_DIR/libwiredtiger_crystal.$LIB_EXT"

# Install Crystal source files
echo -e "\n${YELLOW}Installing Crystal source files...${NC}"
cp -r "$CRYSTAL_DIR/src"/* "$INSTALL_INCLUDE_DIR/"

# Install shard.yml
cp "$CRYSTAL_DIR/shard.yml" "$INSTALL_INCLUDE_DIR/"

# Create pkg-config file for easy linking
echo -e "\n${YELLOW}Creating pkg-config file...${NC}"
cat > "$INSTALL_LIB_DIR/pkgconfig/wiredtiger-crystal.pc" << EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: wiredtiger-crystal
Description: Crystal bindings for WiredTiger database engine
Version: 1.0.0
Libs: -L\${libdir} -lwiredtiger_crystal
Cflags: -I\${includedir}/wiredtiger/crystal
Requires: wiredtiger
EOF

# Update library cache on Linux
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "\n${YELLOW}Updating library cache...${NC}"
    ldconfig 2>/dev/null || true
fi

# Verify installation
echo -e "\n${YELLOW}Verifying installation...${NC}"
if [ -f "$INSTALL_LIB_DIR/libwiredtiger_crystal.$LIB_EXT" ]; then
    echo -e "${GREEN}✓ Native library installed successfully${NC}"
    ls -la "$INSTALL_LIB_DIR/libwiredtiger_crystal.$LIB_EXT"
else
    echo -e "${RED}✗ Native library installation failed${NC}"
    exit 1
fi

if [ -d "$INSTALL_INCLUDE_DIR" ]; then
    echo -e "${GREEN}✓ Crystal source files installed successfully${NC}"
    ls -la "$INSTALL_INCLUDE_DIR"
else
    echo -e "${RED}✗ Crystal source files installation failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 WiredTiger Crystal bindings installed successfully!${NC}"
echo ""
echo "Files installed:"
echo "  Native library: $INSTALL_LIB_DIR/libwiredtiger_crystal.$LIB_EXT"
echo "  Crystal sources: $INSTALL_INCLUDE_DIR"
echo "  pkg-config: $INSTALL_LIB_DIR/pkgconfig/wiredtiger-crystal.pc"
echo ""
echo "To use in your Crystal project:"
echo "  1. Add to your shard.yml:"
echo "     dependencies:"
echo "       wiredtiger:"
echo "         path: $INSTALL_INCLUDE_DIR"
echo "  2. Or install from this directory:"
echo "     shards install"
echo ""
echo "The native library is now available system-wide for other projects to use."
