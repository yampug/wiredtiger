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
