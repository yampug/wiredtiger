package com.wiredtiger.db;

public class Connection {
    protected long nativeHandle;
    
    protected Connection(long handle) {
        this.nativeHandle = handle;
    }
    
    public Session open_session(String config) {
        throw new UnsupportedOperationException("Native implementation required");
    }
    
    public void close(String config) {
        throw new UnsupportedOperationException("Native implementation required");
    }
}
