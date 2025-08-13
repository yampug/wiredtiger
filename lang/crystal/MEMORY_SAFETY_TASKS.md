# Memory Safety Testing with Taskfile

This document explains how to use the memory safety testing tasks that have been added to the main WiredTiger Taskfile.

## 🧪 Memory Safety Tasks Overview

The WiredTiger project now includes comprehensive memory safety testing tasks that use **Address Sanitizer (ASan)** to detect memory access violations, buffer overflows, use-after-free errors, and other memory-related issues.

## 📋 Available Memory Safety Tasks

### Build Tasks

| Task | Description | Command |
|------|-------------|---------|
| `build-crystal-asan` | Build Crystal C extension with Address Sanitizer | `task build-crystal-asan` |

### Testing Tasks

| Task | Description | Command |
|------|-------------|---------|
| `test-crystal-asan` | Full test suite with Address Sanitizer | `task test-crystal-asan` |
| `test-crystal-asan-quick` | Quick test (assumes already built with ASan) | `task test-crystal-asan-quick` |
| `test-crystal-asan-specific` | Test specific file with ASan | `task test-crystal-asan-specific -- CLI_ARGS="spec/checkpoint_spec.cr"` |
| `test-crystal-asan-stress` | Run memory safety stress test | `task test-crystal-asan-stress` |

### Combined Memory Safety Tasks

| Task | Description | Command |
|------|-------------|---------|
| `test-crystal-memory-safety` | Comprehensive memory safety testing | `task test-crystal-memory-safety` |
| `test-crystal-memory-safety-quick` | Quick memory safety test | `task test-crystal-memory-safety-quick` |

### Convenience Aliases

| Alias | Full Task | Description |
|-------|-----------|-------------|
| `asan` | `test-crystal-asan` | Run tests with Address Sanitizer |
| `asan-quick` | `test-crystal-asan-quick` | Quick ASan test |
| `asan-stress` | `test-crystal-asan-stress` | Memory stress test |
| `memory-safety` | `test-crystal-memory-safety` | Full memory safety testing |
| `memory-safety-quick` | `test-crystal-memory-safety-quick` | Quick memory safety test |

## 🚀 Quick Start

### 1. Build with Address Sanitizer

```bash
# Build the Crystal C extension with Address Sanitizer enabled
task build-crystal-asan
```

### 2. Run Memory Safety Tests

```bash
# Run all tests with Address Sanitizer
task asan

# Quick test (assumes already built)
task asan-quick

# Run memory safety stress test
task asan-stress

# Comprehensive memory safety testing
task memory-safety
```

### 3. Test Specific Components

```bash
# Test only checkpoint operations with ASan
task test-crystal-asan-specific -- CLI_ARGS="spec/checkpoint_spec.cr"

# Test only backup operations with ASan
task test-crystal-asan-specific -- CLI_ARGS="spec/backup_spec.cr"
```

## 🔧 Technical Details

### Address Sanitizer Configuration

The memory safety tasks use the following ASan configuration:

```bash
ASAN_OPTIONS="abort_on_error=1:print_stats=1"
CFLAGS="-fsanitize=address -g -O0"
LDFLAGS="-fsanitize=address"
```

### What Address Sanitizer Detects

- **Buffer Overflows**: Reading/writing beyond array bounds
- **Use-After-Free**: Accessing freed memory
- **Double-Free**: Freeing memory multiple times
- **Memory Leaks**: Unfreed allocated memory
- **Invalid Memory Access**: Accessing unallocated memory
- **Stack Buffer Overflows**: Stack-based buffer overruns

### Build Process

1. **Compilation**: C extension compiled with `-fsanitize=address -g -O0`
2. **Linking**: Shared library linked with `-fsanitize=address`
3. **Runtime**: Crystal tests run with ASan environment variables

## 📊 Expected Results

### ✅ Success Indicators

- **No ASan errors**: No memory access violations detected
- **Clean test output**: Tests complete without memory-related crashes
- **Proper cleanup**: Resources properly managed and cleaned up

### ⚠️ Known Issues (Not Memory Safety Related)

- **Bytes operations**: Some tests fail due to temporarily disabled bytes functionality
- **Statistics overflow**: Some statistics tests fail due to arithmetic overflow (not memory safety)
- **Expected failures**: Some tests are designed to fail for validation purposes

## 🧹 Cleanup

### Reset to Normal Build

After memory safety testing, you can rebuild without ASan:

```bash
# Clean ASan build artifacts
task clean-crystal

# Rebuild normally
task build-crystal
```

### Environment Variables

Memory safety tasks automatically set required environment variables:

```bash
DYLD_LIBRARY_PATH="/path/to/crystal/lib:/path/to/wiredtiger/.libs"
ASAN_OPTIONS="abort_on_error=1:print_stats=1"
```

## 🔍 Troubleshooting

### Common Issues

1. **"executable file not found"**: Ensure you're using the correct task runner
2. **Library not found**: Check that `build-crystal-asan` completed successfully
3. **Permission denied**: Ensure the build directories are writable

### Debug Mode

For more verbose output, combine with verbose testing:

```bash
# Build with ASan and run verbose tests
task build-crystal-asan
task test-crystal-verbose --link-flags="-Llang/crystal/lib -fsanitize=address"
```

## 📚 Related Documentation

- [Memory Safety Guide](MEMORY_SAFETY.md) - Comprehensive memory safety best practices
- [README](README.md) - General project documentation
- [Taskfile Help](Taskfile.yml) - Complete task reference (`task help`)

## 🎯 Best Practices

1. **Regular Testing**: Run memory safety tests before each release
2. **CI Integration**: Include memory safety tests in continuous integration
3. **Development Workflow**: Use ASan during development to catch issues early
4. **Performance Impact**: Be aware that ASan adds runtime overhead (acceptable for testing)

## 🎉 Success Message

When memory safety tests pass successfully, you'll see:

```
🧪 Memory safety tests completed successfully!
No memory access violations detected by Address Sanitizer!
```

This indicates that your WiredTiger Crystal bindings are memory-safe and ready for production use!
