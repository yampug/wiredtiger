#include "wiredtiger_crystal.h"
#include "../../wiredtiger.h"
#include <string.h>
#include <stdlib.h>

// Crystal FFI bindings for WiredTiger

// Open a connection to a WiredTiger database
void* crystal_wiredtiger_open(const char* home, const char* config) {
    if (!home) return NULL;
    
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
    if (!session || !uri) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->create(wt_session, uri, config);
    
    return ret;
}

// Open a cursor
void* session_open_cursor(void* session, const char* uri, void* to_dup, const char* config) {
    if (!session || !uri) return NULL;
    
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

// Begin a transaction
int session_begin_transaction(void* session, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->begin_transaction(wt_session, config);
    
    return ret;
}

// Commit a transaction
int session_commit_transaction(void* session, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->commit_transaction(wt_session, config);
    
    return ret;
}

// Rollback a transaction
int session_rollback_transaction(void* session, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->rollback_transaction(wt_session, config);
    
    return ret;
}

// Create a checkpoint
int session_checkpoint(void* session, const char* config) {
    if (!session) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->checkpoint(wt_session, config);
    
    return ret;
}

// Open a backup cursor
void* session_open_backup_cursor(void* session, const char* config) {
    if (!session) return NULL;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    WT_CURSOR *cursor;
    int ret = wt_session->open_cursor(wt_session, "backup:", NULL, config, &cursor);
    
    if (ret != 0) {
        return NULL;
    }
    
    return (void*)cursor;
}

// Truncate a collection
int session_truncate(void* session, const char* uri, const char* start, const char* stop, const char* config) {
    if (!session || !uri) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->truncate(wt_session, uri, (WT_CURSOR*)start, (WT_CURSOR*)stop, config);
    
    return ret;
}

// Set the cursor's string key
int cursor_put_key_string(void* cursor, const char* key) {
    if (!cursor || !key) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_key(wt_cursor, key);
    
    return 0;
}

// Set the cursor's string value
int cursor_put_value_string(void* cursor, const char* value) {
    if (!cursor || !value) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_value(wt_cursor, value);
    
    return 0;
}

// Update the current record
int cursor_update(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->update(wt_cursor);
    
    return ret;
}

// Remove the current record
int cursor_remove(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->remove(wt_cursor);
    
    return ret;
}

// Modify the current record
int cursor_modify(void* cursor, void* entries, int nentries) {
    if (!cursor || !entries || nentries <= 0) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    WT_MODIFY *wt_entries = (WT_MODIFY*)entries;
    int ret = wt_cursor->modify(wt_cursor, wt_entries, nentries);
    
    return ret;
}

// Insert a record
int cursor_insert(void* cursor) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->insert(wt_cursor);
    
    return ret;
}

// Calculate modify operations
int crystal_calc_modify(void* session, const void* oldv, const void* newv, size_t maxdiff, void* entries, int* nentriesp) {
    if (!session || !oldv || !newv || !entries || !nentriesp || maxdiff == 0) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    WT_ITEM *wt_oldv = (WT_ITEM*)oldv;
    WT_ITEM *wt_newv = (WT_ITEM*)newv;
    WT_MODIFY *wt_entries = (WT_MODIFY*)entries;
    
    int ret = wiredtiger_calc_modify(wt_session, wt_oldv, wt_newv, maxdiff, wt_entries, nentriesp);
    
    return ret;
}

// Open a statistics cursor
int session_open_statistics_cursor(void* session, const char* uri, void** cursorp) {
    if (!session || !uri || !cursorp) return -1;
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    WT_CURSOR *wt_cursor;
    
    int ret = wt_session->open_cursor(wt_session, uri, NULL, NULL, &wt_cursor);
    if (ret == 0) {
        *cursorp = (void*)wt_cursor;
    }
    
    return ret;
}

// Get statistics values from a cursor
int cursor_get_statistics_values(void* cursor, const char** desc, const char** pvalue, int64_t* value) {
    if (!cursor || !desc || !pvalue || !value) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    
    int ret = wt_cursor->get_value(wt_cursor, desc, pvalue, value);
    
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

// Set the cursor's integer key
int cursor_put_key_int(void* cursor, int64_t key) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_key(wt_cursor, key);
    
    return 0;
}

// Set the cursor's integer value
int cursor_put_value_int(void* cursor, int64_t value) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_value(wt_cursor, value);
    
    return 0;
}

// Set the cursor's float key
int cursor_put_key_float(void* cursor, double key) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_key(wt_cursor, key);
    
    return 0;
}

// Set the cursor's float value
int cursor_put_value_float(void* cursor, double value) {
    if (!cursor) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    wt_cursor->set_value(wt_cursor, value);
    
    return 0;
}

// Set the cursor's bytes key
int cursor_put_key_bytes(void* cursor, const void* data, size_t size) {
    if (!cursor || !data || size == 0) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    WT_ITEM item;
    item.data = data;
    item.size = size;
    wt_cursor->set_key(wt_cursor, &item);
    
    return 0;
}

// Set the cursor's bytes value
int cursor_put_value_bytes(void* cursor, const void* data, size_t size) {
    if (!cursor || !data || size == 0) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    WT_ITEM item;
    item.data = data;
    item.size = size;
    wt_cursor->set_value(wt_cursor, &item);
    
    return 0;
}

// Get the cursor's integer key
int64_t cursor_get_key_int(void* cursor) {
    if (!cursor) return 0;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int64_t key;
    int ret = wt_cursor->get_key(wt_cursor, &key);
    
    if (ret != 0) {
        return 0;
    }
    
    return key;
}

// Get the cursor's integer value
int64_t cursor_get_value_int(void* cursor) {
    if (!cursor) return 0;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int64_t value;
    int ret = wt_cursor->get_value(wt_cursor, &value);
    
    if (ret != 0) {
        return 0;
    }
    
    return value;
}

// Get the cursor's float key
double cursor_get_key_float(void* cursor) {
    if (!cursor) return 0.0;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    double key;
    int ret = wt_cursor->get_key(wt_cursor, &key);
    
    if (ret != 0) {
        return 0.0;
    }
    
    return key;
}

// Get the cursor's float value
double cursor_get_value_float(void* cursor) {
    if (!cursor) return 0.0;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    double value;
    int ret = wt_cursor->get_value(wt_cursor, &value);
    
    if (ret != 0) {
        return 0.0;
    }
    
    return value;
}

// Get the cursor's bytes key
int cursor_get_key_bytes(void* cursor, void** data, size_t* size) {
    if (!cursor || !data || !size) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    WT_ITEM item;
    int ret = wt_cursor->get_key(wt_cursor, &item);
    
    if (ret != 0) {
        return ret;
    }
    
    if (item.data == NULL || item.size == 0) {
        *data = NULL;
        *size = 0;
        return 0;
    }
    
    *data = (void*)item.data;
    *size = item.size;
    
    return 0;
}

// Get the cursor's bytes value
int cursor_get_value_bytes(void* cursor, void** data, size_t* size) {
    if (!cursor || !data || !size) return -1;
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    WT_ITEM item;
    int ret = wt_cursor->get_value(wt_cursor, &item);
    
    if (ret != 0) {
        return ret;
    }
    
    if (item.data == NULL || item.size == 0) {
        *data = NULL;
        *size = 0;
        return 0;
    }
    
    *data = (void*)item.data;
    *size = item.size;
    
    return 0;
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

// Safe cursor close with error handling
int cursor_safe_close(void* cursor) {
    if (!cursor) return 0; // Already closed or invalid
    
    WT_CURSOR *wt_cursor = (WT_CURSOR*)cursor;
    int ret = wt_cursor->close(wt_cursor);
    
    return ret;
}

// Safe session close with error handling
int session_safe_close(void* session) {
    if (!session) return 0; // Already closed or invalid
    
    WT_SESSION *wt_session = (WT_SESSION*)session;
    int ret = wt_session->close(wt_session, NULL);
    
    return ret;
}

// Safe connection close with error handling
int connection_safe_close(void* conn) {
    if (!conn) return 0; // Already closed or invalid
    
    WT_CONNECTION *wt_conn = (WT_CONNECTION*)conn;
    int ret = wt_conn->close(wt_conn, NULL);
    
    return ret;
}

// Safe cursor operation wrapper with error handling
int cursor_safe_operation(void* cursor, int (*operation)(void*)) {
    if (!cursor || !operation) return -1;
    
    int ret = operation(cursor);
    
    return ret;
}

// Safe session operation wrapper with error handling
int session_safe_operation(void* session, int (*operation)(void*)) {
    if (!session || !operation) return -1;
    
    int ret = operation(session);
    
    return ret;
}

// Memory-safe string copy (if needed for future use)
char* safe_strdup(const char* str) {
    if (!str) return NULL;
    
    size_t len = strlen(str);
    char* new_str = (char*)malloc(len + 1);
    if (!new_str) return NULL;
    
    strcpy(new_str, str);
    return new_str;
}

// Safe memory cleanup
void safe_free(void* ptr) {
    if (ptr) {
        free(ptr);
    }
}
