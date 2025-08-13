# Memory Safety Guide for WiredTiger Crystal Bindings

This document provides comprehensive guidance on memory safety and resource management when using the WiredTiger Crystal bindings.

## 🚨 **Critical Memory Safety Features**

### **1. Safe Resource Cleanup**
All resources (connections, sessions, cursors) are automatically cleaned up even when exceptions occur:

```crystal
# Resources are automatically cleaned up even with exceptions
begin
  cursor = session.open_cursor("table:users")
  # ... operations that might raise exceptions ...
ensure
  cursor.safe_close  # Always executed, even with exceptions
end
```

### **2. Memory Leak Prevention**
The bindings prevent memory leaks in bytes operations and other memory-intensive operations:

```crystal
# Memory is automatically managed and freed
cursor.put_key_bytes(Bytes[1, 2, 3, 4])
cursor.put_value_bytes(Bytes[5, 6, 7, 8])
# Memory is automatically freed when cursor goes out of scope
```

### **3. Safe Close Operations**
All classes provide safe close methods that can be called multiple times without error:

```crystal
cursor.close    # Standard close with error checking
cursor.safe_close  # Safe close that can be called multiple times
cursor.safe_close  # No error, just returns safely
```

## 📋 **Memory Safety Best Practices**

### **Always Use Ensure Blocks**
```crystal
# ✅ RECOMMENDED: Use ensure blocks for guaranteed cleanup
cursor = session.open_cursor("table:users")
begin
  # ... operations ...
ensure
  cursor.close  # Always executed
end
```

### **Use Safe Close for Multiple Calls**
```crystal
# ✅ RECOMMENDED: Use safe_close when you might call close multiple times
cursor.safe_close  # Safe to call multiple times
cursor.safe_close  # No error, just returns

# ❌ AVOID: Calling close multiple times can cause errors
cursor.close  # First call - OK
cursor.close  # Second call - might cause errors
```

### **Handle Exceptions Gracefully**
```crystal
# ✅ RECOMMENDED: Exception-safe resource management
begin
  conn = WiredTiger.open("mydb", "create")
  session = conn.open_session
  cursor = session.open_cursor("table:users")
  
  # ... operations that might raise exceptions ...
  
rescue ex : WiredTiger::DB::WiredTigerException
  puts "Database error: #{ex.message}"
ensure
  # All resources are safely closed, even with exceptions
  cursor&.safe_close
  session&.safe_close
  conn&.safe_close
end
```

### **Avoid Manual Memory Management**
```crystal
# ✅ RECOMMENDED: Let the bindings handle memory
cursor.put_key_string("key")      # Memory managed automatically
cursor.put_value_string("value")  # Memory managed automatically

# ❌ AVOID: Manual memory operations
# The bindings handle all memory management internally
```

## 🔒 **Resource Lifecycle Management**

### **Connection Lifecycle**
```crystal
# 1. Create connection
conn = WiredTiger.open("mydb", "create")

# 2. Use connection
session = conn.open_session

# 3. Clean up (choose one method)
conn.close        # Standard close with error checking
conn.safe_close  # Safe close that can be called multiple times

# 4. Check status
conn.closed?     # Returns true if closed
```

### **Session Lifecycle**
```crystal
# 1. Create session
session = conn.open_session

# 2. Use session
cursor = session.open_cursor("table:users")

# 3. Clean up
session.close        # Standard close with error checking
session.safe_close  # Safe close that can be called multiple times

# 4. Check status
session.closed?     # Returns true if closed
```

### **Cursor Lifecycle**
```crystal
# 1. Create cursor
cursor = session.open_cursor("table:users")

# 2. Use cursor
cursor.put_key_string("key")
cursor.put_value_string("value")
cursor.insert

# 3. Clean up
cursor.close        # Standard close with error checking
cursor.safe_close  # Safe close that can be called multiple times

# 4. Check status
cursor.closed?     # Returns true if closed
```

## 🧪 **Memory Safety Testing**

### **Running Memory Safety Tests**
```bash
# Run memory safety tests
crystal spec spec/checkpoint_spec.cr
crystal spec spec/backup_spec.cr
crystal spec spec/integration_spec.cr

# All tests pass with memory safety features enabled
```

### **Memory Leak Detection**
```bash
# Check for memory leaks (if using valgrind or similar tools)
valgrind --leak-check=full crystal spec spec/checkpoint_spec.cr

# Run memory-intensive tests
crystal spec spec/checkpoint_spec.cr --verbose
```

## 💡 **Common Memory Safety Patterns**

### **Pattern 1: Basic Resource Management**
```crystal
def basic_operation
  conn = WiredTiger.open("mydb", "create")
  begin
    session = conn.open_session
    cursor = session.open_cursor("table:users")
    
    # ... operations ...
    
  ensure
    cursor&.safe_close
    session&.safe_close
    conn&.safe_close
  end
end
```

### **Pattern 2: Exception-Safe Operations**
```crystal
def safe_database_operation
  conn = nil
  session = nil
  cursor = nil
  
  begin
    conn = WiredTiger.open("mydb", "create")
    session = conn.open_session
    cursor = session.open_cursor("table:users")
    
    # ... operations that might fail ...
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Operation failed: #{ex.message}"
    raise ex
    
  ensure
    # Guaranteed cleanup regardless of success or failure
    cursor&.safe_close
    session&.safe_close
    conn&.safe_close
  end
end
```

### **Pattern 3: Transaction Safety**
```crystal
def safe_transaction
  conn = WiredTiger.open("mydb", "create")
  begin
    session = conn.open_session
    session.begin_transaction
    
    cursor = session.open_cursor("table:users")
    
    # ... transaction operations ...
    
    session.commit_transaction
    
  rescue ex : WiredTiger::DB::WiredTigerException
    session&.rollback_transaction
    raise ex
    
  ensure
    cursor&.safe_close
    session&.safe_close
    conn&.safe_close
  end
end
```

### **Pattern 4: Bytes Data Safety**
```crystal
def safe_bytes_operation
  cursor = session.open_cursor("table:binary_data")
  
  begin
    # Store binary data (memory managed automatically)
    cursor.put_key_string("key1")
    cursor.put_value_bytes(Bytes[1, 2, 3, 4])
    cursor.insert
    
    # Retrieve binary data (memory managed automatically)
    cursor.reset
    cursor.put_key_string("key1")
    if cursor.search == 0
      data = cursor.get_value_bytes  # Memory managed automatically
      puts "Retrieved #{data.size} bytes"
    end
    
  ensure
    cursor.safe_close
  end
end
```

## ⚠️ **Common Memory Safety Pitfalls**

### **Pitfall 1: Forgetting Ensure Blocks**
```crystal
# ❌ DANGEROUS: No guarantee of cleanup
cursor = session.open_cursor("table:users")
# ... operations ...
cursor.close  # Might not execute if exception occurs

# ✅ SAFE: Always cleaned up
cursor = session.open_cursor("table:users")
begin
  # ... operations ...
ensure
  cursor.safe_close  # Always executed
end
```

### **Pitfall 2: Multiple Close Calls**
```crystal
# ❌ DANGEROUS: Multiple close calls can cause errors
cursor.close
cursor.close  # Error: cursor already closed

# ✅ SAFE: Use safe_close for multiple calls
cursor.safe_close
cursor.safe_close  # No error, just returns
```

### **Pitfall 3: Ignoring Exceptions**
```crystal
# ❌ DANGEROUS: Exceptions can leave resources open
cursor = session.open_cursor("table:users")
# ... operations that might raise exceptions ...
cursor.close  # Never reached if exception occurs

# ✅ SAFE: Exceptions don't prevent cleanup
cursor = session.open_cursor("table:users")
begin
  # ... operations that might raise exceptions ...
ensure
  cursor.safe_close  # Always executed
end
```

## 🔍 **Memory Safety Verification**

### **Code Review Checklist**
- [ ] All resources are opened in `begin...ensure` blocks
- [ ] `safe_close` is used when multiple close calls are possible
- [ ] Exceptions are handled with proper cleanup
- [ ] Bytes operations are used without manual memory management
- [ ] Resource state is checked before operations

### **Testing Checklist**
- [ ] Run all test suites: `crystal spec`
- [ ] Test exception scenarios with resource cleanup
- [ ] Verify memory-intensive operations don't leak
- [ ] Check that resources are properly closed
- [ ] Test multiple close operations

### **Production Deployment Checklist**
- [ ] Memory safety tests pass
- [ ] Resource cleanup patterns are documented
- [ ] Exception handling is comprehensive
- [ ] Monitoring for memory usage is in place
- [ ] Resource limits are configured

## 📚 **Additional Resources**

### **Related Documentation**
- [README.md](README.md) - Main documentation with examples
- [INSTALL.md](INSTALL.md) - Installation and setup guide
- [TODO.md](TODO.md) - Development roadmap and status

### **Example Code**
- `examples/` - Basic usage examples
- `example_project/` - Complete project example
- `spec/` - Comprehensive test suite

### **Memory Safety Features**
- Safe close operations for all resource types
- Memory leak prevention in bytes operations
- Exception-safe resource cleanup
- Comprehensive error handling
- Resource state validation

## 🆘 **Getting Help with Memory Issues**

### **Common Memory Problems**
1. **Resource not closed**: Use `ensure` blocks and `safe_close`
2. **Memory leaks**: Check bytes operations and resource cleanup
3. **Exception handling**: Ensure cleanup happens in `ensure` blocks
4. **Multiple close calls**: Use `safe_close` instead of `close`

### **Debugging Memory Issues**
```bash
# Run with verbose output
crystal spec --verbose

# Check specific test suites
crystal spec spec/checkpoint_spec.cr --verbose

# Use memory profiling tools
valgrind --leak-check=full crystal spec
```

### **Reporting Issues**
When reporting memory-related issues, include:
- Crystal version
- Operating system
- Test case that reproduces the issue
- Memory usage patterns
- Any error messages or stack traces

---

**Remember**: The WiredTiger Crystal bindings are designed to be memory-safe by default. Follow the patterns in this guide to ensure your applications are robust and free from memory leaks.
