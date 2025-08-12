package com.wiredtiger.jbindingstest;

import com.wiredtiger.db.Connection;
import com.wiredtiger.db.Session;
import com.wiredtiger.db.WiredTiger;

public class SmokeMain {
    public static void main(String[] args) {
        String home = args.length > 0 ? args[0] : ".wt-java-smoke";
        Connection conn = null;
        Session session = null;
        try {
            conn = WiredTiger.open(home, "create,cache_size=64MB");
            session = conn.open_session(null);
            session.create("table:smoke", "key_format=S,value_format=S");
            var cursor = session.open_cursor("table:smoke", null, null);
            try {
                cursor.putKeyString("k1");
                cursor.putValueString("v1");
                cursor.insert();

                cursor.reset();
                cursor.putKeyString("k1");
                if (cursor.search() == 0) {
                    String value = cursor.getValueString();
                    System.out.println("Read back: " + value);
                }
            } finally {
                cursor.close();
            }
        } finally {
            if (session != null) {
                try { session.close(null); } catch (Exception ignore) {}
            }
            if (conn != null) {
                try { conn.close(null); } catch (Exception ignore) {}
            }
        }
    }
}


