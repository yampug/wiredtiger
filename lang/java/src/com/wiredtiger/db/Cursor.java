package com.wiredtiger.db;

public class Cursor {
    protected long nativeHandle;
    
    protected Cursor(long handle) {
        this.nativeHandle = handle;
    }
    
    /**
     * Set the cursor's string key.
     * @param key Key string
     */
    public native void putKeyString(String key);
    
    /**
     * Set the cursor's string value.
     * @param value Value string
     */
    public native void putValueString(String value);
    
    /**
     * Insert a record.
     * @return 0 on success, non-zero on error
     */
    public native int insert();
    
    /**
     * Reset the cursor.
     */
    public native void reset();
    
    /**
     * Search for a record.
     * @return 0 if found, WT_NOTFOUND if not found
     */
    public native int search();
    
    /**
     * Get the cursor's string value.
     * @return Value string
     */
    public native String getValueString();
    
    /**
     * Close the cursor.
     */
    public native void close();
}