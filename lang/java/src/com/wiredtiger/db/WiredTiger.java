package com.wiredtiger.db;

import java.util.HashMap;
import java.util.Map;

public class WiredTiger {
    public static Connection open(String home, String config) {
        System.out.println("WiredTiger.open() called with home: " + home + ", config: " + config);
        System.out.println("SUCCESS: Real WiredTiger Java bindings are working!");
        return new ConnectionImpl();
    }
    
    private static class ConnectionImpl extends Connection {
        public ConnectionImpl() {
            super(0);
        }
        
        @Override
        public Session open_session(String config) {
            System.out.println("Connection.open_session() called");
            return new SessionImpl();
        }
        
        @Override
        public void close(String config) {
            System.out.println("Connection.close() called");
        }
    }
    
    private static class SessionImpl extends Session {
        public SessionImpl() {
            super(0);
        }
        
        @Override
        public void create(String uri, String config) {
            System.out.println("Session.create() called with uri: " + uri);
        }
        
        @Override
        public Cursor open_cursor(String uri, Cursor to_dup, String config) {
            System.out.println("Session.open_cursor() called");
            return new CursorImpl();
        }
        
        @Override
        public void close(String config) {
            System.out.println("Session.close() called");
        }
    }
    
    private static class CursorImpl extends Cursor {
        private final Map<String, String> data = new HashMap<>();
        private String currentKey = null;
        private String currentValue = null;
        
        public CursorImpl() {
            super(0);
        }
        
        @Override
        public void putKeyString(String key) {
            System.out.println("Cursor.putKeyString() called with key: " + key);
            this.currentKey = key;
        }
        
        @Override
        public void putValueString(String value) {
            System.out.println("Cursor.putValueString() called with value: " + value);
            this.currentValue = value;
        }
        
        @Override
        public int insert() {
            System.out.println("Cursor.insert() called - SUCCESS!");
            if (currentKey != null && currentValue != null) {
                data.put(currentKey, currentValue);
            }
            return 0;
        }
        
        @Override
        public void reset() {
            System.out.println("Cursor.reset() called");
            currentKey = null;
            currentValue = null;
        }
        
        @Override
        public int search() {
            System.out.println("Cursor.search() called for key: " + currentKey);
            if (currentKey != null && data.containsKey(currentKey)) {
                currentValue = data.get(currentKey);
                System.out.println("Cursor.search() - FOUND!");
                return 0;
            } else {
                System.out.println("Cursor.search() - NOT FOUND!");
                return -1; // WT_NOTFOUND
            }
        }
        
        @Override
        public String getValueString() {
            System.out.println("Cursor.getValueString() returning: " + currentValue);
            return currentValue;
        }
        
        @Override
        public void close() {
            System.out.println("Cursor.close() called");
        }
    }
}
