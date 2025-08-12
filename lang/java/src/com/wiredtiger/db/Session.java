package com.wiredtiger.db;

public class Session {
    protected long nativeHandle;
    
    protected Session(long handle) {
        this.nativeHandle = handle;
    }
    
    public void create(String uri, String config) {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public Cursor open_cursor(String uri, Cursor to_dup, String config) {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public void close(String config) {
        throw new UnsupportedOperationException("Native implementation required");
    }
}
