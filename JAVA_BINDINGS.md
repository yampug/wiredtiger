# WiredTiger Java Bindings

This document provides comprehensive information about building, installing, and using the WiredTiger Java bindings.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Building](#building)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Overview

The WiredTiger Java bindings provide a Java API for the WiredTiger embedded database. The bindings use JNI (Java Native Interface) to call the native WiredTiger C library, providing full access to WiredTiger's functionality from Java applications.

### Features

- ✅ Full WiredTiger C API coverage
- ✅ Native performance through JNI
- ✅ Java 11+ compatibility
- ✅ Thread-safe operations
- ✅ Automatic resource management
- ✅ Comprehensive error handling

## Prerequisites

### System Requirements

- **Operating System**: macOS, Linux, or Windows
- **Java**: JDK 11 or later
- **Build Tools**: 
  - GCC or Clang compiler
  - GNU Make
  - [Task](https://taskfile.dev/) (optional, for build scripts)

### macOS Specific

```bash
# Install Xcode command line tools
xcode-select --install

# Set JAVA_HOME (if not already set)
export JAVA_HOME=$(/usr/libexec/java_home)
```

### Verify Prerequisites

```bash
# Check Java installation
java -version
javac -version

# Check compiler
gcc --version

# Check that JAVA_HOME is set
echo $JAVA_HOME
ls $JAVA_HOME/include/jni.h
```

## Building

### Using Task (Recommended)

The easiest way to build the Java bindings is using the provided Taskfile:

```bash
# Setup and check environment
task setup

# Build everything (core library + Java bindings)
task build-all

# Show build information
task info
```

### Manual Build Process

If you prefer to build manually:

```bash
# 1. Build WiredTiger core library
./configure
make -j4

# 2. Build Java bindings
cd lang/java

# 3. Compile Java classes and generate JNI headers
javac -h . -d . src/com/wiredtiger/db/*.java

# 4. Compile JNI library
mkdir -p .libs
gcc -shared -fPIC \
  -I$JAVA_HOME/include \
  -I$JAVA_HOME/include/darwin \
  -I../../src/include \
  -L../../.libs \
  -lwiredtiger \
  wiredtiger_java.c \
  -o .libs/libwiredtiger_java.dylib

# 5. Create JAR file
jar cf ../../wiredtiger.jar -C . com/
```

### Build Outputs

After a successful build, you should have:

- `wiredtiger.jar` - Java classes
- `lang/java/.libs/libwiredtiger_java.dylib` - JNI library  
- `.libs/libwiredtiger.dylib` - Core WiredTiger library

## Installation

### For Applications

1. **Add JAR to classpath**:
   ```bash
   # Copy to your project
   cp wiredtiger.jar /path/to/your/project/lib/
   
   # Add to classpath
   java -cp ".:lib/wiredtiger.jar" YourApplication
   ```

2. **Set library path**:
   ```bash
   # Set JVM library path
   java -Djava.library.path="/path/to/wiredtiger/lang/java/.libs:/path/to/wiredtiger/.libs" \
        -cp ".:lib/wiredtiger.jar" \
        YourApplication
   ```

### For Maven Projects

```xml
<dependency>
    <groupId>com.wiredtiger</groupId>
    <artifactId>wiredtiger</artifactId>
    <version>1.0.0</version>
    <scope>system</scope>
    <systemPath>${project.basedir}/lib/wiredtiger.jar</systemPath>
</dependency>
```

### For Gradle Projects

```gradle
dependencies {
    implementation files('lib/wiredtiger.jar')
}

// Set library path for tests/runs
test {
    systemProperty 'java.library.path', '/path/to/wiredtiger/lang/java/.libs:/path/to/wiredtiger/.libs'
}
```

## Usage

### Basic Example

```java
import com.wiredtiger.db.*;

public class WiredTigerExample {
    public static void main(String[] args) {
        Connection conn = null;
        Session session = null;
        
        try {
            // Open database
            conn = WiredTiger.open("mydb", "create,cache_size=64MB");
            
            // Open session
            session = conn.open_session(null);
            
            // Create table
            session.create("table:users", "key_format=S,value_format=S");
            
            // Insert data
            Cursor cursor = session.open_cursor("table:users", null, null);
            try {
                cursor.putKeyString("user1");
                cursor.putValueString("John Doe");
                cursor.insert();
                
                // Search for data
                cursor.reset();
                cursor.putKeyString("user1");
                if (cursor.search() == 0) {
                    String value = cursor.getValueString();
                    System.out.println("Found: " + value);
                }
            } finally {
                cursor.close();
            }
            
        } finally {
            // Clean up resources
            if (session != null) {
                try { session.close(null); } catch (Exception e) {}
            }
            if (conn != null) {
                try { conn.close(null); } catch (Exception e) {}
            }
        }
    }
}
```

### Advanced Configuration

```java
// Database configuration
String config = "create,cache_size=512MB,eviction_target=80,eviction_trigger=95";
Connection conn = WiredTiger.open("/path/to/db", config);

// Session configuration
String sessionConfig = "isolation=snapshot";
Session session = conn.open_session(sessionConfig);

// Table with complex schema
session.create("table:products", 
    "key_format=i,value_format=SSi," +
    "columns=(id,name,category,price)");

// Index creation
session.create("index:products:by_category", 
    "columns=(category)");
```

## API Reference

### WiredTiger

Static entry point for opening database connections.

```java
public class WiredTiger {
    public static Connection open(String home, String config);
}
```

**Parameters:**
- `home` - Database home directory path
- `config` - Configuration string (can be null)

**Returns:** `Connection` object

### Connection

Represents a database connection.

```java
public class Connection {
    public Session open_session(String config);
    public void close(String config);
}
```

**Methods:**
- `open_session(config)` - Open a new session
- `close(config)` - Close the connection

### Session

Represents a database session for operations.

```java
public class Session {
    public void create(String uri, String config);
    public Cursor open_cursor(String uri, Cursor to_dup, String config);
    public void close(String config);
}
```

**Methods:**
- `create(uri, config)` - Create table, index, or other object
- `open_cursor(uri, to_dup, config)` - Open cursor for data access
- `close(config)` - Close the session

### Cursor

Provides data access and manipulation.

```java
public class Cursor {
    // Key/Value operations
    public void putKeyString(String key);
    public void putValueString(String value);
    public String getValueString();
    
    // Navigation and search
    public int insert();
    public int search();
    public void reset();
    
    // Resource management
    public void close();
}
```

**Methods:**
- `putKeyString(key)` - Set cursor key
- `putValueString(value)` - Set cursor value
- `getValueString()` - Get cursor value
- `insert()` - Insert record, returns 0 on success
- `search()` - Search for record, returns 0 if found
- `reset()` - Reset cursor position

## Examples

### Complete CRUD Operations

```java
public class CRUDExample {
    public static void main(String[] args) {
        Connection conn = WiredTiger.open("cruddb", "create");
        Session session = conn.open_session(null);
        
        // Create table
        session.create("table:inventory", 
            "key_format=S,value_format=Si,columns=(item,description,quantity)");
        
        Cursor cursor = session.open_cursor("table:inventory", null, null);
        
        try {
            // CREATE
            cursor.putKeyString("laptop");
            cursor.putValueString("Dell Laptop");
            cursor.putValueInt(10);
            cursor.insert();
            
            // READ
            cursor.reset();
            cursor.putKeyString("laptop");
            if (cursor.search() == 0) {
                System.out.println("Item: " + cursor.getKeyString());
                System.out.println("Description: " + cursor.getValueString());
            }
            
            // UPDATE
            cursor.putValueString("Updated Dell Laptop");
            cursor.putValueInt(15);
            cursor.update();
            
            // DELETE
            cursor.remove();
            
        } finally {
            cursor.close();
            session.close(null);
            conn.close(null);
        }
    }
}
```

### Transaction Example

```java
public void transactionExample() {
    Connection conn = WiredTiger.open("txndb", "create");
    Session session = conn.open_session(null);
    
    session.create("table:accounts", "key_format=S,value_format=i");
    
    try {
        // Begin transaction
        session.begin_transaction(null);
        
        Cursor cursor = session.open_cursor("table:accounts", null, null);
        
        // Transfer money between accounts
        cursor.putKeyString("account1");
        cursor.search();
        int balance1 = cursor.getValueInt();
        
        cursor.putKeyString("account2");
        cursor.search();
        int balance2 = cursor.getValueInt();
        
        // Update balances
        cursor.putKeyString("account1");
        cursor.putValueInt(balance1 - 100);
        cursor.update();
        
        cursor.putKeyString("account2");
        cursor.putValueInt(balance2 + 100);
        cursor.update();
        
        // Commit transaction
        session.commit_transaction(null);
        
        cursor.close();
        
    } catch (Exception e) {
        // Rollback on error
        session.rollback_transaction(null);
        throw e;
    } finally {
        session.close(null);
        conn.close(null);
    }
}
```

## Troubleshooting

### Common Issues

#### 1. UnsatisfiedLinkError

```
java.lang.UnsatisfiedLinkError: no wiredtiger_java in java.library.path
```

**Solution:** Set the correct library path:
```bash
java -Djava.library.path="/path/to/wiredtiger/lang/java/.libs:/path/to/wiredtiger/.libs" YourApp
```

#### 2. Class Version Errors

```
bad class file: class file has wrong version 67.0, should be 55.0
```

**Solution:** Recompile with correct Java target:
```bash
javac -target 11 -source 11 -d . src/com/wiredtiger/db/*.java
```

#### 3. Database Lock Errors

```
WiredTiger.lock: handle-open: open: No such file or directory
```

**Solution:** Create the database directory:
```bash
mkdir -p /path/to/database/directory
```

#### 4. Permission Errors

**Solution:** Ensure proper permissions:
```bash
chmod 755 /path/to/database/directory
chmod 644 /path/to/database/directory/*
```

### Debugging

Enable WiredTiger verbose logging:

```java
Connection conn = WiredTiger.open("mydb", 
    "create,verbose=[api,fileops,transaction]");
```

## Development

### Running Tests

```bash
# Run smoke tests
task test

# Run JUnit tests
task test-junit

# Development cycle (build + test)
task dev
```

### Making Changes

1. **Modify Java classes** in `lang/java/src/com/wiredtiger/db/`
2. **Update JNI code** in `lang/java/wiredtiger_java.c` if needed
3. **Rebuild**: `task build-all`
4. **Test**: `task test`

### Adding New Methods

1. Add native method declaration to Java class:
   ```java
   public native int newMethod(String param);
   ```

2. Regenerate headers: `task generate-headers`

3. Implement in `wiredtiger_java.c`:
   ```c
   JNIEXPORT jint JNICALL Java_com_wiredtiger_db_ClassName_newMethod
     (JNIEnv *env, jobject obj, jstring param) {
       // Implementation
   }
   ```

4. Rebuild: `task build-all`

### Build Scripts Reference

```bash
task setup           # Check environment and dependencies
task clean           # Clean all build artifacts  
task build-all       # Build everything
task test            # Run smoke tests
task test-junit      # Run JUnit tests
task info            # Show build information
task package         # Create distribution package
task dev             # Quick development cycle
```

## Performance Notes

- **Connection Pooling**: Reuse connections when possible
- **Session Management**: Use sessions efficiently, don't create too many
- **Cursor Reuse**: Reset and reuse cursors instead of creating new ones
- **Bulk Loading**: Use bulk cursors for large data imports
- **Cache Tuning**: Adjust cache_size based on your data size

## License

WiredTiger Java bindings are released under the same license as WiredTiger itself. See the main WiredTiger documentation for license details.

## Support

For issues and questions:

1. Check this documentation
2. Review the troubleshooting section
3. Check the main WiredTiger documentation
4. File issues in the WiredTiger project repository
