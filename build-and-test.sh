#!/bin/bash
# WiredTiger Java Bindings - Complete Build and Test Script
set -e

echo "🚀 WiredTiger Java Bindings - Build and Test"
echo "============================================="

# Check if Task is available
if ! command -v task &> /dev/null; then
    echo "❌ Task is not installed. Please install it from https://taskfile.dev/"
    echo "   On macOS: brew install go-task/tap/go-task"
    exit 1
fi

# Setup and check environment
echo "📋 Checking environment..."
task setup

echo ""
echo "🔧 Building WiredTiger Java bindings..."
task build-all

echo ""
echo "📊 Build information:"
task info

echo ""
echo "🧪 Running tests..."
task test

echo ""
echo "✅ All tests completed!"
echo ""
echo "📖 Usage Examples:"
echo "=================="
echo ""
echo "1. Build everything:"
echo "   task build-all"
echo ""
echo "2. Run tests:"
echo "   task test"
echo "   task test-junit"
echo ""
echo "3. Development cycle:"
echo "   task dev"
echo ""
echo "4. Clean and rebuild:"
echo "   task clean"
echo "   task build-all"
echo ""
echo "5. Create distribution package:"
echo "   task package"
echo ""
echo "📚 For complete documentation, see:"
echo "   - JAVA_BINDINGS.md (comprehensive guide)"
echo "   - lang/java/README.md (quick start)"
echo ""
echo "🎉 WiredTiger Java bindings are ready to use!"
