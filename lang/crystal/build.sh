#!/bin/bash

# Build script for WiredTiger Crystal bindings
# This script builds the C extension and Crystal library

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIREDTIGER_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CRYSTAL_DIR="$SCRIPT_DIR"
BUILD_DIR="$CRYSTAL_DIR/build"
LIB_DIR="$CRYSTAL_DIR/lib"

echo -e "${GREEN}Building WiredTiger Crystal bindings...${NC}"
echo "Script directory: $SCRIPT_DIR"
echo "WiredTiger root: $WIREDTIGER_ROOT"
echo "Crystal directory: $CRYSTAL_DIR"

# Check dependencies
echo -e "\n${YELLOW}Checking dependencies...${NC}"

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

# Determine library extension
if [[ "$OSTYPE" == "darwin"* ]]; then
    LIB_EXT="dylib"
else
    LIB_EXT="so"
fi

# Build shared library
echo -e "\n${YELLOW}Building shared library...${NC}"
gcc -shared \
    -o "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT" \
    "$BUILD_DIR/libwiredtiger_crystal.o" \
    -L"$WIREDTIGER_ROOT/.libs" \
    -lwiredtiger

# Build Crystal library
echo -e "\n${YELLOW}Building Crystal library...${NC}"
cd "$CRYSTAL_DIR"
crystal build --release -o "$BUILD_DIR/wiredtiger_crystal" src/wiredtiger.cr

# Verify build
echo -e "\n${YELLOW}Verifying build...${NC}"
if [ -f "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT" ]; then
    echo -e "${GREEN}✓ C extension built successfully${NC}"
    ls -la "$LIB_DIR/libwiredtiger_crystal.$LIB_EXT"
else
    echo -e "${RED}✗ C extension build failed${NC}"
    exit 1
fi

if [ -f "$BUILD_DIR/wiredtiger_crystal" ]; then
    echo -e "${GREEN}✓ Crystal library built successfully${NC}"
    ls -la "$BUILD_DIR/wiredtiger_crystal"
else
    echo -e "${RED}✗ Crystal library build failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 WiredTiger Crystal bindings built successfully!${NC}"
echo ""
echo "Files created:"
echo "  C extension: $LIB_DIR/libwiredtiger_crystal.$LIB_EXT"
echo "  Crystal library: $BUILD_DIR/wiredtiger_crystal"
echo ""
echo "To test the bindings:"
echo "  cd $CRYSTAL_DIR"
echo "  crystal spec"
echo ""
echo "To run examples:"
echo "  crystal examples/basic_usage.cr"
echo "  crystal examples/advanced_usage.cr"
