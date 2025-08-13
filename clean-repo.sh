#!/bin/bash

# =============================================================================
# WiredTiger Repository - Comprehensive Cleanup Script
# =============================================================================
# This script cleans up build artifacts, temporary files, and generated files
# from the entire WiredTiger repository to keep it clean and professional.

set -e

echo "🧹 WiredTiger Repository - Comprehensive Cleanup"
echo "================================================"

# Function to safely remove directories
safe_remove() {
    local dir="$1"
    local description="$2"
    if [ -d "$dir" ]; then
        echo "🗑️  Removing $description: $dir/"
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

# Function to safely remove single files
safe_remove_file() {
    local file="$1"
    local description="$2"
    if [ -f "$file" ]; then
        echo "🗑️  Removing $description: $file"
        rm -f "$file"
    fi
}

echo ""
echo "🔧 Cleaning build artifacts and libraries..."
safe_remove ".libs" "compiled libraries directory"
safe_remove "build_posix" "POSIX build artifacts"
safe_remove "build_win" "Windows build artifacts"

echo ""
echo "☕ Cleaning Java artifacts..."
safe_remove "temp_java_build" "Java build artifacts"
safe_remove "jbindingstest" "Java bindings test artifacts"
safe_remove_files "*.jar" "Java JAR files"

echo ""
echo "📋 Cleaning task runner cache..."
safe_remove ".task" "Task runner cache"

echo ""
echo "📦 Cleaning distribution files..."
safe_remove "dist" "generated distribution files"

echo ""
echo "🔨 Cleaning generated and backup files..."
safe_remove_file "configure~" "configure backup file"
safe_remove_file "wiredtiger_config.h" "generated config header"
safe_remove_file "wiredtiger_ext.h" "generated extension header"
safe_remove_file "wt" "compiled executable"

echo ""
echo "🧪 Cleaning Crystal bindings..."
if [ -d "lang/crystal" ]; then
    echo "   📁 Found Crystal bindings directory"
    if [ -f "lang/crystal/clean.sh" ]; then
        echo "   🧹 Running Crystal cleanup script..."
        cd lang/crystal
        ./clean.sh
        cd - > /dev/null
    else
        echo "   ⚠️  Crystal cleanup script not found"
    fi
else
    echo "   📁 Crystal bindings directory not found"
fi

echo ""
echo "🔍 Cleaning autotools artifacts..."
safe_remove "autom4te.cache" "autotools cache"
safe_remove_file "config.log" "autotools log"
safe_remove_file "config.status" "autotools status"
safe_remove_file "libtool" "libtool script"
safe_remove_file "stamp-h1" "build timestamp"
safe_remove_file "Makefile" "generated Makefile"
safe_remove_file "Makefile.in" "Makefile template"

echo ""
echo "💾 Cleaning temporary and generated files..."
safe_remove_files "*.tmp" "temporary files"
safe_remove_files "*.temp" "temporary files"
safe_remove_files "*.bak" "backup files"
safe_remove_files "*.backup" "backup files"
safe_remove_files "*.old" "old files"
safe_remove_files "*.orig" "original files"
safe_remove_files "*.rej" "rejected files"

echo ""
echo "🖥️  Cleaning OS-specific files..."
safe_remove_files ".DS_Store" "macOS system files"
safe_remove_files "Thumbs.db" "Windows system files"
safe_remove_files "*~" "editor backup files"

echo ""
echo "✅ Repository cleanup completed successfully!"
echo ""
echo "📋 What was cleaned:"
echo "   • Build artifacts (.libs/, build_posix/, build_win/)"
echo "   • Java artifacts (temp_java_build/, jbindingstest/, *.jar)"
echo "   • Task runner cache (.task/)"
echo "   • Distribution files (dist/)"
echo "   • Generated files (configure~, *.h, wt executable)"
echo "   • Autotools artifacts (autom4te.cache/, config.*, libtool, etc.)"
echo "   • Crystal bindings (via lang/crystal/clean.sh)"
echo "   • Temporary and OS-specific files"
echo ""
echo "💡 Tip: Run this script regularly to keep your repository clean!"
echo "   You can also add it to your pre-commit hooks or CI/CD pipeline."
echo ""
echo "🔒 Note: Essential source files are preserved:"
echo "   • Source code (src/, lang/, examples/, bench/, test/)"
echo "   • Configuration files (.gitignore, Makefile.am, configure.ac)"
echo "   • Documentation (README, LICENSE, INSTALL)"
echo "   • Essential scripts (autogen.sh, build-and-test.sh)"
echo ""
echo "📊 Repository status:"
echo "   • Current directory: $(pwd)"
echo "   • Git status:"
git status --porcelain | head -10 || echo "   (Git status unavailable)"
echo ""
echo "🎯 Next steps:"
echo "   1. Review git status to see what was cleaned"
echo "   2. Commit the cleanup if desired: git add . && git commit -m 'Clean repository'"
echo "   3. Run this script regularly to maintain cleanliness"
