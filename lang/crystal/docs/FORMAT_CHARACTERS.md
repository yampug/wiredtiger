# WiredTiger Format Characters Reference

## Overview

This document catalogs the format characters supported by WiredTiger for defining table schemas and data types. These format characters are used in the `key_format` and `value_format` parameters when creating tables with `session.create()`.

## Format String Syntax

Format strings follow this pattern:
```
"key_format=FORMAT,value_format=FORMAT"
```

Where `FORMAT` can be:
- A single character for simple types
- A string with size prefix (e.g., `"10s"` for 10-byte string)
- Multiple characters for compound types

## Supported Format Characters

### 🔤 **String Types**

| Character | Description | Size | Example | Notes |
|-----------|-------------|------|---------|-------|
| `S` | Variable-length string | Dynamic | `"key_format=S"` | UTF-8 string, null-terminated |
| `s` | Fixed-length string | Specified | `"key_format=10s"` | Fixed-length string, must be ≥1 byte |

**Usage Examples:**
```crystal
# Variable-length strings
session.create("table:users", "key_format=S,value_format=S")

# Fixed-length strings (10 bytes)
session.create("table:fixed", "key_format=10s,value_format=20s")
```

### 🔢 **Integer Types**

| Character | Description | Size | Range | Example |
|-----------|-------------|------|-------|---------|
| `b` | Signed 8-bit integer | 1 byte | -128 to 127 | `"key_format=b"` |
| `B` | Unsigned 8-bit integer | 1 byte | 0 to 255 | `"key_format=B"` |
| `h` | Signed 16-bit integer | 2 bytes | -32,768 to 32,767 | `"key_format=h"` |
| `H` | Unsigned 16-bit integer | 2 bytes | 0 to 65,535 | `"key_format=H"` |
| `i` | Signed 32-bit integer | 4 bytes | -2³¹ to 2³¹-1 | `"key_format=i"` |
| `I` | Unsigned 32-bit integer | 4 bytes | 0 to 2³²-1 | `"key_format=I"` |
| `l` | Signed 32-bit integer | 4 bytes | -2³¹ to 2³¹-1 | `"key_format=l"` |
| `L` | Unsigned 32-bit integer | 4 bytes | 0 to 2³²-1 | `"key_format=L"` |
| `q` | Signed 64-bit integer | 8 bytes | -2⁶³ to 2⁶³-1 | `"key_format=q"` |
| `Q` | Unsigned 64-bit integer | 8 bytes | 0 to 2⁶⁴-1 | `"key_format=Q"` |
| `r` | Signed 32-bit record number | 4 bytes | -2³¹ to 2³¹-1 | `"key_format=r"` |
| `R` | Unsigned 32-bit record number | 4 bytes | 0 to 2³²-1 | `"key_format=R"` |

**Usage Examples:**
```crystal
# 64-bit integer keys and values
session.create("table:counters", "key_format=q,value_format=q")

# Mixed types: string key, integer value
session.create("table:mixed", "key_format=S,value_format=i")

# Record numbers
session.create("table:records", "key_format=r,value_format=S")
```

### 📦 **Bytes/Item Types**

| Character | Description | Size | Example | Notes |
|-----------|-------------|------|---------|-------|
| `u` | Variable-length bytes | Dynamic | `"key_format=u"` | Raw binary data |
| `U` | Fixed-length bytes | Specified | `"key_format=10u"` | Fixed-length binary data |

**Usage Examples:**
```crystal
# Variable-length binary data
session.create("table:blobs", "key_format=S,value_format=u")

# Fixed-length binary keys
session.create("table:hashes", "key_format=32u,value_format=S")
```

### 🔧 **Special Types**

| Character | Description | Size | Example | Notes |
|-----------|-------------|------|---------|-------|
| `x` | Padding/alignment | Specified | `"key_format=4x"` | Skip bytes, no data |
| `t` | Bitfield | 1-8 bits | `"key_format=8t"` | Bit-level precision |

**Usage Examples:**
```crystal
# Bitfield for flags
session.create("table:flags", "key_format=S,value_format=8t")

# Padding for alignment
session.create("table:aligned", "key_format=S,value_format=4xS")
```

## Compound Format Strings

You can combine multiple format characters to create compound types:

```crystal
# Multiple fields in key
session.create("table:compound", "key_format=Si,value_format=S")

# This creates a key with:
# - String field (S)
# - Integer field (i)
# And a value with:
# - String field (S)
```

## Size Prefixes

For fixed-length types, you can specify the size:

```crystal
# Fixed-length strings
session.create("table:fixed", "key_format=20s,value_format=100s")

# Fixed-length integers (array of 5 integers)
session.create("table:arrays", "key_format=S,value_format=5i")

# Mixed fixed and variable
session.create("table:mixed", "key_format=10s,value_format=Su")
```

## Crystal Implementation Status

### ✅ **Fully Implemented**

- **Strings**: `S`, `s` (with size prefixes)
- **Integers**: `q` (Int64), `Q` (UInt64)
- **Bytes**: `u`, `U` (with size prefixes)

### ❌ **Not Yet Implemented**

- **Smaller Integers**: `b`, `B`, `h`, `H`, `i`, `I`, `l`, `L`, `r`, `R`
- **Bitfields**: `t`
- **Padding**: `x`
- **Compound Types**: Multiple format characters

### 🔍 **Research Findings**

During implementation, I discovered that:

1. **Float Support**: WiredTiger doesn't support float/double format characters natively
2. **Format Validation**: The `__pack_next` function validates format strings at runtime
3. **Memory Safety**: Proper pointer handling is critical for bytes operations

## Float Workarounds

Since WiredTiger doesn't support float format characters, here are alternatives:

### Option 1: Store as Strings
```crystal
session.create("table:floats", "key_format=S,value_format=S")
cursor.put_key_string("3.14")
cursor.put_value_string("2.718")
```

### Option 2: Store as Scaled Integers
```crystal
session.create("table:floats", "key_format=q,value_format=q")
# Store 3.14 as 314 (multiply by 100)
cursor.put_key_int(314_i64)
cursor.put_value_int(2718_i64)
```

### Option 3: Custom Packing
```crystal
# Use WiredTiger's packing functions for custom float handling
# This requires implementing custom pack/unpack logic
```

## Best Practices

1. **Choose Appropriate Types**: Use the smallest integer type that fits your data
2. **Consider Performance**: Fixed-length types can be faster than variable-length
3. **Plan for Growth**: Use 64-bit integers (`q`/`Q`) for IDs that might grow large
4. **Handle Floats Carefully**: Since they're not natively supported, plan your approach
5. **Test Format Strings**: Invalid formats will cause runtime errors

## Error Messages

Common format-related errors:

```
WT_SESSION.create: __pack_next, 203: Invalid type 'f' found in format 'f'
```

This indicates that `'f'` is not a valid format character.

## References

- **Source Code**: `src/packing/pack_impl.c` - Format validation logic
- **Header Files**: `src/include/packing_inline.h` - Format character definitions
- **Python Bindings**: `lang/python/wiredtiger.i` - SWIG interface examples
- **Crystal Implementation**: `src/wiredtiger/db/cursor.cr` - Current implementation

---

*Last Updated: August 2024*
*Based on WiredTiger source code analysis and Crystal implementation*
