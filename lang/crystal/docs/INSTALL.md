# Installation Guide for WiredTiger Crystal Bindings

This guide explains how to install and use the WiredTiger Crystal bindings in your projects.

## Prerequisites

Before installing the Crystal bindings, you need:

1. **Crystal Language**: Version 1.0.0 or higher
   ```bash
   # Check your Crystal version
   crystal --version
   
   # Install Crystal if needed
   # macOS: brew install crystal
   # Ubuntu/Debian: https://crystal-lang.org/install/
   ```

2. **WiredTiger Core Library**: The C library must be available
   ```bash
   # From the WiredTiger root directory
   ./configure
   make -j4
   ```

3. **C Compiler**: GCC or Clang
   ```bash
   # Check if available
   gcc --version
   # or
   clang --version
   ```

## Installation Methods

### Method 1: Install as a Shard (Recommended)

This is the easiest way to use the bindings in your Crystal project.

1. **Add to your project's `shard.yml`**:
   ```yaml
   dependencies:
     wiredtiger:
       git: https://github.com/yampug/wiredtiger.git
       subdirectory: lang/crystal
   ```

2. **Install the dependency**:
   ```bash
   shards install
   ```

3. **Use in your code**:
   ```crystal
   require "wiredtiger"
   
   conn = WiredTiger::WiredTiger.open("mydb", "create")
   # ... your database operations
   ```

### Method 2: System-Wide Installation

This method installs the bindings system-wide, making them available to all projects.

1. **Clone the repository**:
   ```bash
   git clone https://github.com/wiredtiger/wiredtiger.git
   cd wiredtiger/lang/crystal
   ```

2. **Run the installation script**:
   ```bash
   ./install.sh
   ```
   
   This will:
   - Build the native library
   - Install to `/usr/local` (or `~/.local` if not root)
   - Create pkg-config files
   - Make the library available system-wide

3. **Use in your projects**:
   ```yaml
   # In your shard.yml
   dependencies:
     wiredtiger:
       path: /usr/local/include/wiredtiger/crystal
   ```

### Method 3: Local Development Installation

For development or when you want to modify the bindings:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/wiredtiger/wiredtiger.git
   cd wiredtiger/lang/crystal
   ```

2. **Build the bindings**:
   ```bash
   ./build.sh
   # or
   make
   ```

3. **Use in your projects**:
   ```yaml
   # In your shard.yml
   dependencies:
     wiredtiger:
       path: /path/to/wiredtiger/lang/crystal
   ```

## Verification

After installation, verify everything works:

```bash
# From the crystal directory
crystal spec

# Or run the example project
cd example_project
shards install
crystal run src/example.cr
```

## Usage Examples

### Basic Database Operations

```crystal
require "wiredtiger"

# Open a database
conn = WiredTiger.open("mydb", "create")
session = conn.open_session

# Create a table
session.create("table:users", "key_format=S,value_format=S")

# Insert data
cursor = session.open_cursor("table:users")
cursor.put_key_string("user1")
cursor.put_value_string("John Doe")
cursor.insert

# Query data
cursor.reset
cursor.put_key_string("user1")
if cursor.search == 0
  puts "Found: #{cursor.get_value_string}"
end

# Clean up
cursor.close
session.close
conn.close
```

### Working with Multiple Tables

```crystal
# Create multiple related tables
session.create("table:users", "key_format=S,value_format=S")
session.create("table:profiles", "key_format=S,value_format=S")

# Insert related data
users_cursor = session.open_cursor("table:users")
profiles_cursor = session.open_cursor("table:profiles")

users_cursor.put_key_string("user1")
users_cursor.put_value_string("Alice")
users_cursor.insert

profiles_cursor.put_key_string("user1")
profiles_cursor.put_value_string("Software Engineer")
profiles_cursor.insert

users_cursor.close
profiles_cursor.close
```

## Troubleshooting

### Common Issues

1. **"Library not found" errors**:
   ```bash
   # Check if the library exists
   ls -la /usr/local/lib/libwiredtiger_crystal*
   
   # Check library dependencies
   otool -L /usr/local/lib/libwiredtiger_crystal.dylib  # macOS
   ldd /usr/local/lib/libwiredtiger_crystal.so          # Linux
   ```

2. **Compilation errors**:
   ```bash
   # Verify Crystal version
   crystal --version
   
   # Check if WiredTiger core library is built
   ls -la ../../.libs/libwiredtiger*
   ```

3. **Permission errors**:
   ```bash
   # Check write permissions
   ls -la /usr/local/lib/
   
   # Use user installation if needed
   INSTALL_PREFIX=$HOME/.local ./install.sh
   ```

### Getting Help

- Run the tests: `crystal spec`
- Check the example project: `cd example_project && crystal run src/example.cr`
- Review the main README.md
- Check the WiredTiger documentation

## Uninstallation

To remove system-wide installations:

```bash
cd wiredtiger/lang/crystal
./uninstall.sh
```

This will remove:
- The native library
- Crystal source files
- pkg-config files
- Empty directories

## Development

For developers who want to contribute:

1. **Fork the repository**
2. **Set up development environment**:
   ```bash
   git clone <your-fork>
   cd wiredtiger/lang/crystal
   ./build.sh
   crystal spec
   ```

3. **Make your changes**
4. **Test thoroughly**:
   ```bash
   crystal spec --verbose
   cd example_project && crystal run src/example.cr
   ```

5. **Submit a pull request**

## Support

- **Documentation**: This README and the example project
- **Tests**: Run `crystal spec` to verify functionality
- **Issues**: Report problems on the GitHub repository
- **Community**: Crystal and WiredTiger communities

## License

The WiredTiger Crystal bindings are licensed under the Apache-2.0 License.
