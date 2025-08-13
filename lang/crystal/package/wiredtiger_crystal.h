#ifndef WIREDTIGER_CRYSTAL_H
#define WIREDTIGER_CRYSTAL_H

#ifdef __cplusplus
extern "C" {
#endif

// Connection operations
void* crystal_wiredtiger_open(const char* home, const char* config);
int crystal_wiredtiger_close(void* conn, const char* config);

// Session operations
void* connection_open_session(void* conn, const char* config);
int connection_close(void* conn, const char* config);

// Table and cursor operations
int session_create(void* session, const char* uri, const char* config);
void* session_open_cursor(void* session, const char* uri, void* to_dup, const char* config);
int session_close(void* session, const char* config);

// Cursor operations
int cursor_put_key_string(void* cursor, const char* key);
int cursor_put_value_string(void* cursor, const char* value);
int cursor_insert(void* cursor);
int cursor_reset(void* cursor);
int cursor_search(void* cursor);
const char* cursor_get_value_string(void* cursor);
const char* cursor_get_key_string(void* cursor);
int cursor_close(void* cursor);
int cursor_next(void* cursor);
int cursor_prev(void* cursor);

#ifdef __cplusplus
}
#endif

#endif // WIREDTIGER_CRYSTAL_H
