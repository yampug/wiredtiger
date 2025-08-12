package com.wiredtiger.jbindingstest;

import com.wiredtiger.db.Connection;
import com.wiredtiger.db.Session;
import com.wiredtiger.db.WiredTiger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class SmokeTest {
    private Path homeDir;

    @BeforeEach
    void setUp() throws IOException {
        homeDir = Files.createTempDirectory("wt-java-smoke-");
    }

    @AfterEach
    void tearDown() throws IOException {
        if (homeDir != null) {
            // best-effort cleanup
            try (var paths = Files.walk(homeDir)) {
                paths.sorted((a, b) -> b.compareTo(a)).forEach(p -> {
                    try { Files.deleteIfExists(p); } catch (IOException ignore) {}
                });
            }
        }
    }

    @Test
    void canOpenConnectionAndInsert() {
        Connection conn = null;
        Session session = null;
        try {
            conn = WiredTiger.open(homeDir.toString(), "create,cache_size=64MB");
            session = conn.open_session(null);
            session.create("table:smoke", "key_format=S,value_format=S");

            var cursor = session.open_cursor("table:smoke", null, null);
            try {
                cursor.putKeyString("k1");
                cursor.putValueString("v1");
                cursor.insert();

                cursor.reset();
                cursor.putKeyString("k1");
                Assertions.assertEquals(0, cursor.search());
                Assertions.assertEquals("v1", cursor.getValueString());
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


