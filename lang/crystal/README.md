# WiredTiger Crystal Bindings

Native Crystal bindings for the WiredTiger embedded database engine.

**⚠️ Important Note**: This is a fork of the official WiredTiger repository that adds Crystal bindings. The original [wiredtiger/wiredtiger](https://github.com/wiredtiger/wiredtiger) repository does not include Crystal support.

## Features

- **Native Crystal Bindings**: Direct bindings to the WiredTiger C library
- **High-Level API**: Easy-to-use interface for database operations
- **Full WiredTiger Support**: Tables, indexes, LSM trees, transactions
- **Error Handling**: Crystal exceptions with proper error messages
- **Cross-Platform**: Works on macOS, Linux, and other Unix-like systems

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

### Usage

```crystal
require "wiredtiger"

# Open a connection
conn = WiredTiger::WiredTiger.open("mydb", "create")

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

# Clean up
cursor.close
session.close
conn.close
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
conn.close(config : String? = nil)

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
session.close : Nil

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

# Close the cursor
cursor.close : Nil

# Check if closed
cursor.closed? : Bool
```

### Error Handling

The bindings use Crystal exceptions for error handling:

```crystal
begin
  conn = WiredTiger.open("mydb", "create")
  # ... database operations
rescue ex : WiredTiger::DB::WiredTigerException
  puts "Database error: #{ex.message}"
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
```

## Examples

See the `example_project/` directory for comprehensive examples demonstrating:

- Basic database operations
- Working with multiple tables
- Error handling patterns
- Database statistics and inspection

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

# Or using Task
task test-crystal
```

### Project Structure

```
lang/crystal/
├── src/                    # Crystal source files
│   ├── wiredtiger.cr      # Main entry point
│   └── wiredtiger/        # Core modules
│       └── db/            # Database classes
├── spec/                   # Test files
├── examples/               # Example applications
├── example_project/        # Standalone example project
├── wiredtiger_crystal.c   # C extension source
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

### Getting Help

- Check the [WiredTiger documentation](https://github.com/wiredtiger/wiredtiger)
- Run tests to verify installation: `crystal spec`
- Review the example project in `example_project/`

## License

This project is licensed under the Apache-2.0 License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Version History

- **1.0.0**: Initial release with basic database operations
- Support for connections, sessions, cursors, and tables
- Error handling with Crystal exceptions
- Comprehensive test suite with file verification
