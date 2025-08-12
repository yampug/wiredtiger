package com.wiredtiger.db;

public class Cursor {
    protected long nativeHandle;
    
    protected Cursor(long handle) {
        this.nativeHandle = handle;
    }
    
    public void putKeyString(String key) {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public void putValueString(String value) {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public int insert() {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public void reset() {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public int search() {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public String getValueString() {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public void close() {
        throw new UnsupportedOperationException("Native implementation required");
    }
}
