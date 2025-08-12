package com.wiredtiger.db;

public class WiredTiger {
    static {
        try {
            System.loadLibrary("wiredtiger_java");
        } catch (UnsatisfiedLinkError e) {
            System.err.println("Failed to load WiredTiger JNI library: " + e.getMessage());
            throw e;
        }
    }

    /**
     * Open a connection to a WiredTiger database.
     * @param home Database home directory
     * @param config Configuration string
     * @return Connection object
     */
    public static native Connection open(String home, String config);
}
