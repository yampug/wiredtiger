package com.wiredtiger.db;

public class Connection {
    protected long nativeHandle;
    
    protected Connection(long handle) {
        this.nativeHandle = handle;
    }
    
    /**
     * Open a session.
     * @param config Configuration string
     * @return Session object
     */
    public native Session open_session(String config);
    
    /**
     * Close the connection.
     * @param config Configuration string
     */
    public native void close(String config);
}