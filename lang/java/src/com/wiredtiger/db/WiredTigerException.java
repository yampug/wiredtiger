package com.wiredtiger.db;

public class WiredTigerException extends Exception {
    public WiredTigerException(String message) {
        super(message);
    }
    
    public WiredTigerException(String message, Throwable cause) {
        super(message, cause);
    }
}
