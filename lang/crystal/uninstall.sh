#!/bin/bash

# Uninstall script for WiredTiger Crystal bindings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation paths
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
INSTALL_LIB_DIR="$INSTALL_PREFIX/lib"
INSTALL_INCLUDE_DIR="$INSTALL_PREFIX/include/wiredtiger/crystal"

echo -e "${BLUE}=== WiredTiger Crystal Bindings Uninstallation ===${NC}"
echo "Install prefix: $INSTALL_PREFIX"
echo ""

# Check if running as root for system uninstallation
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Running as root - will uninstall from system locations${NC}"
else
    echo -e "${YELLOW}Not running as root - will uninstall from user locations${NC}"
    INSTALL_PREFIX="$HOME/.local"
    INSTALL_LIB_DIR="$INSTALL_PREFIX/lib"
    INSTALL_INCLUDE_DIR="$INSTALL_PREFIX/include/wiredtiger/crystal"
    echo "User install prefix: $INSTALL_PREFIX"
fi

echo ""

# Confirm uninstallation
echo -e "${YELLOW}This will remove the following files:${NC}"
echo "  Native library: $INSTALL_LIB_DIR/libwiredtiger_crystal.*"
echo "  Crystal sources: $INSTALL_INCLUDE_DIR"
echo "  pkg-config: $INSTALL_LIB_DIR/pkgconfig/wiredtiger-crystal.pc"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled.${NC}"
    exit 0
fi

echo ""

# Remove native library
echo -e "${YELLOW}Removing native library...${NC}"
if [ -f "$INSTALL_LIB_DIR/libwiredtiger_crystal.dylib" ]; then
    rm -f "$INSTALL_LIB_DIR/libwiredtiger_crystal.dylib"
    echo -e "${GREEN}✓ Removed libwiredtiger_crystal.dylib${NC}"
elif [ -f "$INSTALL_LIB_DIR/libwiredtiger_crystal.so" ]; then
    rm -f "$INSTALL_LIB_DIR/libwiredtiger_crystal.so"
    echo -e "${GREEN}✓ Removed libwiredtiger_crystal.so${NC}"
else
    echo -e "${YELLOW}No native library found to remove${NC}"
fi

# Remove Crystal source files
echo -e "\n${YELLOW}Removing Crystal source files...${NC}"
if [ -d "$INSTALL_INCLUDE_DIR" ]; then
    rm -rf "$INSTALL_INCLUDE_DIR"
    echo -e "${GREEN}✓ Removed Crystal source files${NC}"
else
    echo -e "${YELLOW}No Crystal source files found to remove${NC}"
fi

# Remove pkg-config file
echo -e "\n${YELLOW}Removing pkg-config file...${NC}"
if [ -f "$INSTALL_LIB_DIR/pkgconfig/wiredtiger-crystal.pc" ]; then
    rm -f "$INSTALL_LIB_DIR/pkgconfig/wiredtiger-crystal.pc"
    echo -e "${GREEN}✓ Removed pkg-config file${NC}"
    
    # Remove empty pkg-config directory if it's empty
    if [ -d "$INSTALL_LIB_DIR/pkgconfig" ] && [ -z "$(ls -A "$INSTALL_LIB_DIR/pkgconfig")" ]; then
        rmdir "$INSTALL_LIB_DIR/pkgconfig"
        echo -e "${GREEN}✓ Removed empty pkg-config directory${NC}"
    fi
else
    echo -e "${YELLOW}No pkg-config file found to remove${NC}"
fi

# Remove empty include directory if it's empty
if [ -d "$INSTALL_PREFIX/include/wiredtiger" ] && [ -z "$(ls -A "$INSTALL_PREFIX/include/wiredtiger")" ]; then
    rmdir "$INSTALL_PREFIX/include/wiredtiger"
    echo -e "${GREEN}✓ Removed empty wiredtiger include directory${NC}"
fi

# Update library cache on Linux
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "\n${YELLOW}Updating library cache...${NC}"
    ldconfig 2>/dev/null || true
fi

echo -e "\n${GREEN}🎉 WiredTiger Crystal bindings uninstalled successfully!${NC}"
echo ""
echo "Note: The WiredTiger core library was not removed."
echo "If you want to remove it as well, you'll need to do so manually."
