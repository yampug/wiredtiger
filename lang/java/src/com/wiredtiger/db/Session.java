package com.wiredtiger.db;

public class Session {
    protected long nativeHandle;
    
    protected Session(long handle) {
        this.nativeHandle = handle;
    }
    
    /**
     * Create a table, index or other data source.
     * @param uri URI for the object to create
     * @param config Configuration string
     */
    public native void create(String uri, String config);
    
    /**
     * Open a cursor.
     * @param uri URI of the object to open
     * @param to_dup Cursor to duplicate (can be null)
     * @param config Configuration string
     * @return Cursor object
     */
    public native Cursor open_cursor(String uri, Cursor to_dup, String config);
    
    /**
     * Close the session.
     * @param config Configuration string
     */
    public native void close(String config);
}