# WiredTiger Crystal Bindings

Native Crystal bindings for the WiredTiger embedded database engine.

## Quick Start

### Prerequisites
- Crystal 1.0.0+
- GCC/Clang compiler
- WiredTiger development libraries
- [Task](https://taskfile.dev/) (optional)

### Build
```bash
# From WiredTiger root directory
task build-all

# Or from the crystal directory
make
```

### Test
```bash
# From the crystal directory
make test

# Or using Crystal directly
crystal spec
```

### Use in Your Project

```crystal
require "wiredtiger"

# Open a connection
conn = WiredTiger.open("mydb", "create")

# Open a session
session = conn.open_session

# Create a table
session.create("table:test", "key_format=S,value_format=S")

# Open a cursor
cursor = session.open_cursor("table:test")

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

## Installation

### From Source
```bash
git clone https://github.com/wiredtiger/wiredtiger.git
cd wiredtiger/lang/crystal
make install
```

### Using Shards
Add to your `shard.yml`:
```yaml
dependencies:
  wiredtiger:
    github: wiredtiger/wiredtiger
    version: ~> 1.0.0
```

## API Reference

### WiredTiger
Main class for database operations.

- `WiredTiger.open(home : String, config : String? = nil) : Connection`

### Connection
Manages database connections and sessions.

- `open_session(config : String? = nil) : Session`
- `close(config : String? = nil)`
- `closed? : Bool`

### Session
Manages database sessions and cursors.

- `create(uri : String, config : String? = nil)`
- `open_cursor(uri : String, to_dup : Cursor? = nil, config : String? = nil) : Cursor`
- `close(config : String? = nil)`
- `closed? : Bool`

### Cursor
Handles data operations and navigation.

- `put_key_string(key : String)`
- `put_value_string(value : String)`
- `insert : Int32`
- `reset`
- `search : Int32`
- `get_value_string : String`
- `next : Int32`
- `prev : Int32`
- `close`
- `closed? : Bool`

## Error Handling

The bindings use `WiredTigerException` for error handling:

```crystal
begin
  conn = WiredTiger.open("nonexistent")
rescue ex : WiredTigerException
  puts "Error: #{ex.message}"
end
```

## Error Codes

Common WiredTiger error codes are available as constants:

```crystal
WiredTiger::DB::Error::WT_NOTFOUND      # -31803
WiredTiger::DB::Error::WT_PANIC         # -31804
WiredTiger::DB::Error::WT_RUN_RECOVERY  # -31805
WiredTiger::DB::Error::WT_CACHE_FULL    # -31806
WiredTiger::DB::Error::WT_DEADLOCK      # -31808
WiredTiger::DB::Error::WT_ROLLBACK      # -31809
```

## Examples

### Basic CRUD Operations
```crystal
require "wiredtiger"

# Open database
conn = WiredTiger.open("testdb", "create")
session = conn.open_session

# Create table
session.create("table:users", "key_format=S,value_format=S")

# Insert data
cursor = session.open_cursor("table:users")
cursor.put_key_string("user1")
cursor.put_value_string("John Doe")
cursor.insert
cursor.close

# Query data
cursor = session.open_cursor("table:users")
cursor.put_key_string("user1")
if cursor.search == 0
  puts "User: #{cursor.get_value_string}"
end
cursor.close

# Clean up
session.close
conn.close
```

### Iterating Through Records
```crystal
cursor = session.open_cursor("table:users")

# Iterate forward
while cursor.next == 0
  puts "Key: #{cursor.get_key_string}, Value: #{cursor.get_value_string}"
end

# Iterate backward
cursor.reset
while cursor.prev == 0
  puts "Key: #{cursor.get_key_string}, Value: #{cursor.get_value_string}"
end

cursor.close
```

## Build Commands

```bash
make          # Build everything
make install  # Install the library
make clean    # Clean build artifacts
make test     # Run tests
make info     # Show build info
```

## Development

### Project Structure
```
lang/crystal/
├── src/                    # Crystal source code
│   ├── wiredtiger.cr      # Main entry point
│   ├── db.cr              # Main module
│   └── db/                # Database classes
│       ├── wired_tiger.cr
│       ├── connection.cr
│       ├── session.cr
│       ├── cursor.cr
│       └── wired_tiger_exception.cr
├── wiredtiger_crystal.c   # C extension
├── Makefile               # Build configuration
├── shard.yml              # Crystal package config
└── README.md              # This file
```

### Adding New Features
1. Add the C function to `wiredtiger_crystal.c`
2. Add the FFI binding to the appropriate Crystal class
3. Add the Crystal method that uses the binding
4. Update tests and documentation

## Troubleshooting

### Common Issues

**Library not found**: Ensure WiredTiger is installed and the library path is correct.
```bash
export LD_LIBRARY_PATH=/path/to/wiredtiger/lib:$LD_LIBRARY_PATH
```

**Compilation errors**: Check that Crystal and the C compiler are properly installed.
```bash
crystal --version
gcc --version
```

**Runtime errors**: Verify the native library is built and accessible.
```bash
ls -la lib/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

Apache License 2.0 - see the main WiredTiger repository for details.

## Support

- [WiredTiger Documentation](https://source.wiredtiger.com/)
- [Crystal Documentation](https://crystal-lang.org/docs/)
- [GitHub Issues](https://github.com/wiredtiger/wiredtiger/issues)
