# WiredTiger Crystal Bindings Example Project

This is an example project demonstrating how to use the WiredTiger Crystal bindings in your own Crystal application.

## What This Example Shows

- **Basic Database Operations**: Creating databases, tables, inserting and querying data
- **Multiple Tables**: Working with related data across different tables
- **Error Handling**: Proper exception handling for database operations
- **Database Statistics**: Checking file sizes and database structure

## Prerequisites

1. **WiredTiger Core Library**: Must be installed on your system
2. **Crystal**: Version 1.0.0 or higher
3. **WiredTiger Crystal Bindings**: Either installed system-wide or available locally

## Quick Start

### Option 1: Use Standalone Package (Recommended)

1. **Get the package**:
   ```bash
   # From the main repository
   cd lang/crystal
   ./package.sh
   ```
   
   This creates a standalone package in the `package/` directory.

2. **Use the package**:
   ```yaml
   dependencies:
     wiredtiger:
       path: /path/to/wiredtiger-crystal-1.0.0
   ```

3. **Install and run**:
   ```bash
   shards install
   crystal run src/example.cr
   ```

### Option 2: Use Local Bindings (For Development)

```yaml
dependencies:
  wiredtiger:
    path: ../
```

Then run:
```bash
shards install
crystal run --link-flags="-L$(pwd)/../lib" src/example.cr
```

## Project Structure

```
```