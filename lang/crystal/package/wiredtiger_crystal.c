#include "wiredtiger_crystal.h"
#include "../../wiredtiger.h"
#include <string.h>
#include <stdlib.h>

// Crystal FFI bindings for WiredTiger

// Open a connection to a WiredTiger database
void* crystal_wiredtiger_open(const char* home, const char* config) {
    WT_CONNECTION *conn;
    int ret = wiredtiger_open(home, NULL, config, &conn);
    
    if (ret != 0) {
        return NULL;
    }
    
    return (void*)conn;
}

// Close a WiredTiger connection
int crystal_wiredtiger_close(void* conn, const char* config) {
    if (!conn) return -1;
    
    WT_CONNECTION *wt_conn = (WT_CONNECTION*)conn;
    int ret = wt_conn->close(wt_conn, config);
    
    return ret;
}

// Open a session on a connection
void* connection_open_session(void* conn, const char* config) {
    if (!conn) return NULL;
    
    WT_CONNECTION *wt_conn = (WT_CONNECTION*)conn;
    WT_SESSION *session;
    int ret = wt_conn->open_session(wt_conn, NULL, config, &session);
    
    if (ret != 0) {
        return NULL;
    }
    
    return (void*)session;
}

// Close a connection
int connection_close(void* conn, const char* config) {
    return crystal_wiredtiger_close(conn, config);
}

// Create a table, index or other data source
int session_create(void* session, const char* uri, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->create(wt_session, uri, config);
    
    return ret;
}

// Open a cursor
void* session_open_cursor(void* session, const char* uri, void* to_dup, const char* config) {
    if (!session) return NULL;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    WT_CURSOR *cursor;
    int ret = wt_session->open_cursor(wt_session, uri, (WT_CURSOR*)to_dup, config, &cursor);
    
    if (ret != 0) {
        return NULL;
    }
    
    return (void*)cursor;
}

// Close a session
int session_close(void* session, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->close(wt_session, config);
    
    return ret;
}

// Set the cursor's string key
int cursor_put_key_string(void* cursor, const char* key) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_key(wt_cursor, key);
    
    return 0;
}

// Set the cursor's string value
int cursor_put_value_string(void* cursor, const char* value) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_value(wt_cursor, value);
    
    return 0;
}

// Insert a record
int cursor_insert(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->insert(wt_cursor);
    
    return ret;
}

// Reset the cursor
int cursor_reset(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->reset(wt_cursor);
    
    return ret;
}

// Search for a record
int cursor_search(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->search(wt_cursor);
    
    return ret;
}

// Get the cursor's string value
const char* cursor_get_value_string(void* cursor) {
    if (!cursor) return NULL;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    const char* value;
    int ret = wt_cursor->get_value(wt_cursor, &value);
    
    if (ret != 0) {
        return NULL;
    }
    
    return value;
}

// Get the cursor's string key
const char* cursor_get_key_string(void* cursor) {
    if (!cursor) return NULL;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    const char* key;
    int ret = wt_cursor->get_key(wt_cursor, &key);
    
    if (ret != 0) {
        return NULL;
    }
    
    return key;
}

// Close the cursor
int cursor_close(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->close(wt_cursor);
    
    return ret;
}

// Move to the next record
int cursor_next(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->next(wt_cursor);
    
    return ret;
}

// Move to the previous record
int cursor_prev(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->prev(wt_cursor);
    
    return ret;
}
