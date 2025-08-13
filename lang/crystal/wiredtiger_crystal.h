#ifndef WIREDTIGER_CRYSTAL_H
#define WIREDTIGER_CRYSTAL_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Connection operations
void* crystal_wiredtiger_open(const char* home, const char* config);
int crystal_wiredtiger_close(void* conn, const char* config);

// Session operations
void* connection_open_session(void* conn, const char* config);
int connection_close(void* conn, const char* config);

// Transaction operations
int session_begin_transaction(void* session, const char* config);
int session_commit_transaction(void* session, const char* config);
int session_rollback_transaction(void* session, const char* config);

// Table and cursor operations
int session_create(void* session, const char* uri, const char* config);
void* session_open_cursor(void* session, const char* uri, void* to_dup, const char* config);
int session_close(void* session, const char* config);

// Cursor operations
int cursor_put_key_string(void* cursor, const char* key);
int cursor_put_value_string(void* cursor, const char* value);
int cursor_insert(void* cursor);
int cursor_update(void* cursor);
int cursor_remove(void* cursor);
int cursor_modify(void* cursor, void* entries, int nentries);
int cursor_reset(void* cursor);
int cursor_search(void* cursor);
const char* cursor_get_value_string(void* cursor);
const char* cursor_get_key_string(void* cursor);
int cursor_close(void* cursor);
int cursor_next(void* cursor);
int cursor_prev(void* cursor);

// Modify calculation
int crystal_calc_modify(void* session, const void* oldv, const void* newv, size_t maxdiff, void* entries, int* nentriesp);

// Extended data type support
int cursor_put_key_int(void* cursor, int64_t key);
int cursor_put_value_int(void* cursor, int64_t value);
int cursor_put_key_float(void* cursor, double key);
int cursor_put_value_float(void* cursor, double value);
int cursor_put_key_bytes(void* cursor, const void* data, size_t size);
int cursor_put_value_bytes(void* cursor, const void* data, size_t size);

int64_t cursor_get_key_int(void* cursor);
int64_t cursor_get_value_int(void* cursor);
double cursor_get_key_float(void* cursor);
double cursor_get_value_float(void* cursor);
int cursor_get_key_bytes(void* cursor, void** data, size_t* size);
int cursor_get_value_bytes(void* cursor, void** data, size_t* size);

#ifdef __cplusplus
}
#endif

#endif // WIREDTIGER_CRYSTAL_H
