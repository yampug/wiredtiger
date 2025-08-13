# WiredTiger Crystal Bindings

Native Crystal bindings for the WiredTiger embedded database engine.

**⚠️ Important Note**: This is a fork of the official WiredTiger repository that adds Crystal bindings. The original [wiredtiger/wiredtiger](https://github.com/wiredtiger/wiredtiger) repository does not include Crystal support.

## Features

- **Native Crystal Bindings**: Direct bindings to the WiredTiger C library
- **High-Level API**: Easy-to-use interface for database operations
- **Full WiredTiger Support**: Tables, indexes, LSM trees, transactions
- **Error Handling**: Crystal exceptions with proper error messages
- **Cross-Platform**: Works on macOS, Linux, and other Unix-like systems
- **Memory Safety**: Comprehensive memory management and resource cleanup
- **Resource Management**: Safe close operations and exception-safe cleanup

## Quick Start

### Prerequisites
- Crystal 1.0.0+
- GCC/Clang compiler
- WiredTiger development libraries

## Installation

### Option 1: Install from Standalone Package (Recommended)

1. **Download the package**:
   ```bash
   # From the repository
   cd lang/crystal
   ./package.sh
   ```
   
   This creates a standalone package that can be distributed and installed easily.

2. **Use the package**:
   ```yaml
   dependencies:
     wiredtiger:
       path: /path/to/wiredtiger-crystal-1.0.0
   ```

### Option 2: Install from this fork

Add to your project's `shard.yml`:

```yaml
dependencies:
  wiredtiger:
    git: https://github.com/yampug/wiredtiger.git
    subdirectory: lang/crystal
```

Then install:

```bash
shards install
```

**Note**: This method requires the WiredTiger core library to be built in the repository.

### Option 3: Install System-Wide

```bash
# Clone this fork (not the original)
git clone https://github.com/yampug/wiredtiger.git
cd wiredtiger/lang/crystal

# Install the bindings system-wide
./install.sh
```

This will install the native library and Crystal sources to `/usr/local` (or `~/.local` if not running as root).

### Option 4: Use as Local Dependency

```yaml
dependencies:
  wiredtiger:
    path: /path/to/wiredtiger/lang/crystal
```

## Memory Safety and Resource Management

The Crystal bindings implement comprehensive memory safety features to prevent memory leaks and ensure proper resource cleanup.

### 🚨 **Critical Memory Safety Features**

#### **1. Safe Resource Cleanup**
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

#### **2. Memory Leak Prevention**
The bindings prevent memory leaks in bytes operations and other memory-intensive operations:

```crystal
# Memory is automatically managed and freed
cursor.put_key_bytes(Bytes[1, 2, 3, 4])
cursor.put_value_bytes(Bytes[5, 6, 7, 8])
# Memory is automatically freed when cursor goes out of scope
```

#### **3. Safe Close Operations**
All classes provide safe close methods that can be called multiple times without error:

```crystal
cursor.close    # Standard close with error checking
cursor.safe_close  # Safe close that can be called multiple times
cursor.safe_close  # No error, just returns safely
```

### 📋 **Memory Safety Best Practices**

#### **Always Use Ensure Blocks**
```crystal
# ✅ RECOMMENDED: Use ensure blocks for guaranteed cleanup
cursor = session.open_cursor("table:users")
begin
  # ... operations ...
ensure
  cursor.close  # Always executed
end
```

#### **Use Safe Close for Multiple Calls**
```crystal
# ✅ RECOMMENDED: Use safe_close when you might call close multiple times
cursor.safe_close  # Safe to call multiple times
cursor.safe_close  # No error, just returns

# ❌ AVOID: Calling close multiple times can cause errors
cursor.close  # First call - OK
cursor.close  # Second call - might cause errors
```

#### **Handle Exceptions Gracefully**
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

#### **Avoid Manual Memory Management**
```crystal
# ✅ RECOMMENDED: Let the bindings handle memory
cursor.put_key_string("key")      # Memory managed automatically
cursor.put_value_string("value")  # Memory managed automatically

# ❌ AVOID: Manual memory operations
# The bindings handle all memory management internally
```

### 🔒 **Resource Lifecycle Management**

#### **Connection Lifecycle**
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

#### **Session Lifecycle**
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

#### **Cursor Lifecycle**
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

### 🧪 **Memory Safety Testing**

The bindings include comprehensive memory safety tests:

```bash
# Run memory safety tests
crystal spec spec/checkpoint_spec.cr
crystal spec spec/backup_spec.cr
crystal spec spec/integration_spec.cr

# All tests pass with memory safety features enabled
```

## Usage

### Basic Usage with Memory Safety

```crystal
require "wiredtiger"

# Open a connection with automatic cleanup
conn = WiredTiger::WiredTiger.open("mydb", "create")

begin
  # Open a session
  session = conn.open_session
  
  # Create a table
  session.create("table:users", "key_format=S,value_format=S")
  
  # Open a cursor
  cursor = session.open_cursor("table:users")
  
  # Insert data
  cursor.put_key_string("key1")
  cursor.put_value_string("value1")
  cursor.insert
  
  # Search for data
  cursor.reset
  cursor.put_key_string("key1")
  if cursor.search == 0
    puts "Found: #{cursor.get_value_string}"
  end
  
rescue ex : WiredTiger::DB::WiredTigerException
  puts "Database error: #{ex.message}"
ensure
  # All resources are safely cleaned up
  cursor&.safe_close
  session&.safe_close
  conn&.safe_close
end
```

### Advanced Usage with Exception Safety

```crystal
# Complex operations with guaranteed cleanup
def process_user_data(user_id : String, user_data : String)
  conn = nil
  session = nil
  cursor = nil
  
  begin
    conn = WiredTiger.open("userdb", "create")
    session = conn.open_session
    cursor = session.open_cursor("table:users")
    
    # Complex operations that might fail
    cursor.put_key_string(user_id)
    cursor.put_value_string(user_data)
    cursor.insert
    
    # Commit the transaction
    session.commit_transaction
    
    puts "User data processed successfully"
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Failed to process user data: #{ex.message}"
    # Rollback transaction if needed
    session&.rollback_transaction
    raise ex
    
  ensure
    # Guaranteed cleanup regardless of success or failure
    cursor&.safe_close
    session&.safe_close
    conn&.safe_close
  end
end
```

### Working with Bytes Data Safely

```crystal
# Bytes operations are memory-safe
def store_binary_data(key : String, data : Bytes)
  cursor = session.open_cursor("table:binary_data")
  
  begin
    cursor.put_key_string(key)
    cursor.put_value_bytes(data)  # Memory managed automatically
    
    cursor.insert
    
  ensure
    cursor.safe_close
  end
end

def retrieve_binary_data(key : String) : Bytes
  cursor = session.open_cursor("table:binary_data")
  
  begin
    cursor.put_key_string(key)
    
    if cursor.search == 0
      # Memory is automatically managed and freed
      return cursor.get_value_bytes
    else
      return Bytes.new(0)
    end
    
  ensure
    cursor.safe_close
  end
end
```

## API Reference

### Main Classes

#### WiredTiger
Main class for database operations.

```crystal
# Open a connection
conn = WiredTiger.open(home : String, config : String? = nil) : Connection
```

#### Connection
Manages database connections and sessions.

```crystal
# Open a new session
session = conn.open_session(config : String? = nil) : Session

# Close the connection
conn.close(config : String? = nil)        # Standard close with error checking
conn.safe_close                           # Safe close that can be called multiple times

# Check if closed
conn.closed? : Bool
```

#### Session
Manages database sessions and cursors.

```crystal
# Create a table
session.create(name : String, config : String) : Nil

# Open a cursor
cursor = session.open_cursor(name : String, config : String? = nil) : Cursor

# Close the session
session.close : Nil                       # Standard close with error checking
session.safe_close                        # Safe close that can be called multiple times

# Check if closed
session.closed? : Bool
```

#### Cursor
Manages database cursors for data operations.

```crystal
# Insert operations
cursor.put_key_string(key : String) : Nil
cursor.put_value_string(value : String) : Nil
cursor.insert : Int32

# Bytes operations (memory-safe)
cursor.put_key_bytes(data : Bytes) : Nil
cursor.put_value_bytes(data : Bytes) : Nil

# Search operations
cursor.put_key_string(key : String) : Nil
cursor.search : Int32

# Iteration
cursor.next : Int32
cursor.prev : Int32
cursor.reset : Nil

# Data retrieval
cursor.get_key_string : String
cursor.get_value_string : String
cursor.get_key_bytes : Bytes      # Memory-safe
cursor.get_value_bytes : Bytes    # Memory-safe

# Close the cursor
cursor.close : Nil                # Standard close with error checking
cursor.safe_close                 # Safe close that can be called multiple times

# Check if closed
cursor.closed? : Bool
```

### Error Handling

The bindings use Crystal exceptions for error handling with memory safety:

```crystal
begin
  conn = WiredTiger.open("mydb", "create")
  # ... database operations
rescue ex : WiredTiger::DB::WiredTigerException
  puts "Database error: #{ex.message}"
ensure
  # Resources are always cleaned up, even with exceptions
  conn&.safe_close
end
```

### Configuration Strings

WiredTiger configuration strings are passed directly to the C library:

```crystal
# Create a table with string key/value format
session.create("table:users", "key_format=S,value_format=S")

# Create a table with integer key and string value
session.create("table:counts", "key_format=i,value_format=S")

# Open connection with specific configuration
conn = WiredTiger.open("mydb", "create,log=(enabled=true)")

# Enable incremental backups
conn = WiredTiger.open("mydb", "create,log=(enabled=true,archive=false)")
```

## Examples

See the `example_project/` directory for comprehensive examples demonstrating:

- Basic database operations with memory safety
- Working with multiple tables
- Error handling patterns with guaranteed cleanup
- Database statistics and inspection
- Safe resource management patterns

## Development

### Building from Source

```bash
# From the crystal directory
make

# Or using the build script
./build.sh

# Or using Task
task build-crystal
```

### Running Tests

```bash
# Run all tests
crystal spec

# Run with verbose output
crystal spec --verbose

# Run specific test suites
crystal spec spec/checkpoint_spec.cr    # Checkpoint functionality
crystal spec spec/backup_spec.cr        # Backup functionality
crystal spec spec/integration_spec.cr   # Integration tests

# Or using Task
task test-crystal
```

### Project Structure

```
lang/crystal/
├── src/                    # Crystal source files
│   ├── wiredtiger.cr      # Main entry point
│   └── wiredtiger/        # Core modules
│       └── db/            # Database classes with memory safety
├── spec/                   # Test files including memory safety tests
├── examples/               # Example applications
├── example_project/        # Standalone example project
├── wiredtiger_crystal.c   # C extension source with memory safety
├── install.sh             # Installation script
├── uninstall.sh           # Uninstallation script
├── shard.yml              # Shard configuration
└── README.md              # This file
```

## Installation for External Projects

### As a Git Dependency

```yaml
dependencies:
  wiredtiger:
    git: https://github.com/wiredtiger/wiredtiger.git
    version: ~> 1.0.0
```

### As a Local Path Dependency

```yaml
dependencies:
  wiredtiger:
    path: /path/to/wiredtiger/lang/crystal
```

### From System Installation

After running `./install.sh`:

```yaml
dependencies:
  wiredtiger:
    path: /usr/local/include/wiredtiger/crystal
```

## Troubleshooting

### Common Issues

1. **Library not found**: Ensure WiredTiger core library is installed
2. **Compilation errors**: Check Crystal version (requires 1.0.0+)
3. **Permission errors**: Verify write permissions in target directories
4. **Memory issues**: Ensure you're using the memory-safe patterns shown in examples

### Memory Safety Verification

To verify memory safety is working correctly:

```bash
# Run memory-intensive tests
crystal spec spec/checkpoint_spec.cr
crystal spec spec/backup_spec.cr

# Check for memory leaks (if using valgrind or similar tools)
valgrind --leak-check=full crystal spec spec/checkpoint_spec.cr
```

### Getting Help

- Check the [WiredTiger documentation](https://github.com/wiredtiger/wiredtiger)
- Run tests to verify installation: `crystal spec`
- Review the example project in `example_project/`
- Check memory safety examples in this README

## License

This project is licensed under the Apache-2.0 License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure memory safety for all new features
6. Submit a pull request

## Version History

- **1.0.0**: Initial release with basic database operations
  - Support for connections, sessions, cursors, and tables
  - Error handling with Crystal exceptions
  - Comprehensive test suite with file verification
- **1.1.0**: Memory safety and resource management improvements
  - Safe close operations for all resource types
  - Memory leak prevention in bytes operations
  - Exception-safe resource cleanup
  - Comprehensive memory safety documentation
  - Enhanced error handling and resource management
