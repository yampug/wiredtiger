#!/bin/bash

# =============================================================================
# WiredTiger Crystal Bindings - Repository Cleanup Script
# =============================================================================
# This script helps keep the repository clean by removing build artifacts
# and temporary files that should not be committed.

set -e

echo "🧹 WiredTiger Crystal Bindings - Repository Cleanup"
echo "=================================================="

# Function to safely remove directories
safe_remove() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "🗑️  Removing $dir/"
        rm -rf "$dir"
    fi
}

# Function to safely remove files
safe_remove_files() {
    local pattern="$1"
    local description="$2"
    if ls $pattern 1> /dev/null 2>&1; then
        echo "🗑️  Removing $description"
        # Handle both files and directories
        for item in $pattern; do
            if [ -f "$item" ]; then
                rm -f "$item"
            elif [ -d "$item" ]; then
                # Skip directories for file patterns
                echo "   ⚠️  Skipping directory: $item"
            fi
        done
    fi
}

echo ""
echo "📁 Cleaning build directories..."
safe_remove "build"
safe_remove "lib"
safe_remove "bin"
safe_remove "tmp"

echo ""
echo "🔧 Cleaning native libraries..."
safe_remove_files "*.dylib" "dynamic libraries"
safe_remove_files "*.so" "shared objects"
safe_remove_files "*.dll" "dynamic link libraries"
safe_remove_files "*.a" "static libraries"
safe_remove_files "*.o" "object files"

echo ""
echo "📦 Cleaning package files..."
safe_remove_files "*.tar.gz" "tar.gz packages"
safe_remove_files "*.zip" "zip packages"
safe_remove_files "*.tar" "tar packages"
safe_remove "dist"
safe_remove "packages"

echo ""
echo "🗄️  Cleaning database files..."
safe_remove "wiredtiger"
safe_remove_files "*.wt" "WiredTiger database files"
safe_remove_files "*.wtcheckpoint" "checkpoint files"
safe_remove_files "*.wtlog" "log files"
safe_remove_files "*.wtmetadata" "metadata files"
safe_remove_files "*.wtbackup" "backup files"

echo ""
echo "🧪 Cleaning test artifacts..."
safe_remove_files "test_*" "test files"
safe_remove_files "*_test" "test files"
safe_remove_files "memory_stress_test_*" "memory stress test files"
safe_remove_files "asan_test_*" "ASan test files"
safe_remove_files "valgrind_*" "Valgrind test files"

echo ""
echo "📝 Cleaning log files..."
safe_remove_files "*.log" "log files"
safe_remove_files "*.out" "output files"
safe_remove_files "*.err" "error files"

echo ""
echo "🔍 Cleaning Crystal cache..."
safe_remove ".crystal"
safe_remove ".shards"

echo ""
echo "💾 Cleaning temporary files..."
safe_remove_files "*.tmp" "temporary files"
safe_remove_files "*.temp" "temporary files"
safe_remove_files "*.bak" "backup files"
safe_remove_files "*.backup" "backup files"
safe_remove_files "*.old" "old files"
safe_remove_files "*.orig" "original files"
safe_remove_files "*.rej" "rejected files"

echo ""
echo "🖥️  Cleaning OS files..."
safe_remove_files ".DS_Store" "macOS system files"
safe_remove_files "Thumbs.db" "Windows system files"
safe_remove_files "*~" "editor backup files"

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "📋 What was cleaned:"
echo "   • Build directories (build/, lib/, bin/, tmp/)"
echo "   • Native libraries (*.dylib, *.so, *.dll, *.a, *.o)"
echo "   • Package files (*.tar.gz, *.zip, *.tar)"
echo "   • Database files (*.wt, *.wtcheckpoint, etc.)"
echo "   • Test artifacts and temporary files"
echo "   • Log files and output files"
echo "   • Crystal cache (.crystal/, .shards/)"
echo "   • OS-specific files (.DS_Store, Thumbs.db, etc.)"
echo ""
echo "💡 Tip: Run this script regularly to keep your repository clean!"
echo "   You can also add it to your pre-commit hooks."
echo ""
echo "🔒 Note: Essential source files are preserved:"
echo "   • Source code (src/)"
echo "   • Documentation (docs/)"
echo "   • Examples (examples/)"
echo "   • Tests (spec/)"
echo "   • Build scripts (build.sh, install.sh, etc.)"
echo "   • Configuration files (shard.yml, .gitignore, etc.)"
