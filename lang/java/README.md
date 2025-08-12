# WiredTiger Java Bindings

Native Java bindings for the WiredTiger embedded database.

## Quick Start

### Prerequisites
- Java 11+
- GCC/Clang compiler
- [Task](https://taskfile.dev/) (optional)

### Build
```bash
# From WiredTiger root directory
task build-all
```

### Test
```bash
task test
```

### Use in Your Project

```java
import com.wiredtiger.db.*;

Connection conn = WiredTiger.open("mydb", "create");
Session session = conn.open_session(null);
session.create("table:test", "key_format=S,value_format=S");

Cursor cursor = session.open_cursor("table:test", null, null);
cursor.putKeyString("key1");
cursor.putValueString("value1");
cursor.insert();

cursor.reset();
cursor.putKeyString("key1");
if (cursor.search() == 0) {
    System.out.println("Found: " + cursor.getValueString());
}

cursor.close();
session.close(null);
conn.close(null);
```

## Files

- `src/com/wiredtiger/db/` - Java source code
- `wiredtiger_java.c` - JNI implementation
- `*.h` - Generated JNI headers
- `.libs/libwiredtiger_java.dylib` - Compiled JNI library

## Documentation

See [JAVA_BINDINGS.md](../../JAVA_BINDINGS.md) for complete documentation.

## Build Commands

```bash
task setup          # Check environment
task build-all      # Build everything
task test           # Run tests
task clean          # Clean build artifacts
task info           # Show build info
```
