#include <jni.h>
#include <wiredtiger.h>
#include <string.h>
#include <stdlib.h>

#include "com_wiredtiger_db_WiredTiger.h"
#include "com_wiredtiger_db_Connection.h"
#include "com_wiredtiger_db_Session.h"
#include "com_wiredtiger_db_Cursor.h"

// Helper function to get the native handle from a Java object
static jlong get_native_handle(JNIEnv *env, jobject obj) {
    jclass cls = (*env)->GetObjectClass(env, obj);
    jfieldID fid = (*env)->GetFieldID(env, cls, "nativeHandle", "J");
    return (*env)->GetLongField(env, obj, fid);
}

// Helper function to set the native handle in a Java object
static void set_native_handle(JNIEnv *env, jobject obj, jlong handle) {
    jclass cls = (*env)->GetObjectClass(env, obj);
    jfieldID fid = (*env)->GetFieldID(env, cls, "nativeHandle", "J");
    (*env)->SetLongField(env, obj, fid, handle);
}

// Helper function to create a Java object and set its native handle
static jobject create_java_object(JNIEnv *env, const char *className, jlong handle) {
    jclass cls = (*env)->FindClass(env, className);
    if (!cls) return NULL;
    
    jmethodID constructor = (*env)->GetMethodID(env, cls, "<init>", "(J)V");
    if (!constructor) return NULL;
    
    return (*env)->NewObject(env, cls, constructor, handle);
}

// WiredTiger.open implementation
JNIEXPORT jobject JNICALL Java_com_wiredtiger_db_WiredTiger_open
  (JNIEnv *env, jclass cls, jstring home, jstring config) {
    
    const char *home_str = (*env)->GetStringUTFChars(env, home, NULL);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    
    WT_CONNECTION *conn;
    int ret = wiredtiger_open(home_str, NULL, config_str, &conn);
    
    (*env)->ReleaseStringUTFChars(env, home, home_str);
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    if (ret != 0) {
        // TODO: Throw appropriate Java exception
        return NULL;
    }
    
    return create_java_object(env, "com/wiredtiger/db/Connection", (jlong)conn);
}

// Connection.open_session implementation
JNIEXPORT jobject JNICALL Java_com_wiredtiger_db_Connection_open_1session
  (JNIEnv *env, jobject obj, jstring config) {
    
    WT_CONNECTION *conn = (WT_CONNECTION *)get_native_handle(env, obj);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    
    WT_SESSION *session;
    int ret = conn->open_session(conn, NULL, config_str, &session);
    
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    if (ret != 0) {
        // TODO: Throw appropriate Java exception
        return NULL;
    }
    
    return create_java_object(env, "com/wiredtiger/db/Session", (jlong)session);
}

// Connection.close implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Connection_close
  (JNIEnv *env, jobject obj, jstring config) {
    
    WT_CONNECTION *conn = (WT_CONNECTION *)get_native_handle(env, obj);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    
    int ret = conn->close(conn, config_str);
    
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    // Set handle to 0 to indicate closed
    set_native_handle(env, obj, 0);
    
    // TODO: Handle return value
}

// Session.create implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Session_create
  (JNIEnv *env, jobject obj, jstring uri, jstring config) {
    
    WT_SESSION *session = (WT_SESSION *)get_native_handle(env, obj);
    const char *uri_str = (*env)->GetStringUTFChars(env, uri, NULL);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    
    int ret = session->create(session, uri_str, config_str);
    
    (*env)->ReleaseStringUTFChars(env, uri, uri_str);
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    // TODO: Handle return value
}

// Session.open_cursor implementation
JNIEXPORT jobject JNICALL Java_com_wiredtiger_db_Session_open_1cursor
  (JNIEnv *env, jobject obj, jstring uri, jobject to_dup, jstring config) {
    
    WT_SESSION *session = (WT_SESSION *)get_native_handle(env, obj);
    const char *uri_str = (*env)->GetStringUTFChars(env, uri, NULL);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    WT_CURSOR *dup_cursor = to_dup ? (WT_CURSOR *)get_native_handle(env, to_dup) : NULL;
    
    WT_CURSOR *cursor;
    int ret = session->open_cursor(session, uri_str, dup_cursor, config_str, &cursor);
    
    (*env)->ReleaseStringUTFChars(env, uri, uri_str);
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    if (ret != 0) {
        // TODO: Throw appropriate Java exception
        return NULL;
    }
    
    return create_java_object(env, "com/wiredtiger/db/Cursor", (jlong)cursor);
}

// Session.close implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Session_close
  (JNIEnv *env, jobject obj, jstring config) {
    
    WT_SESSION *session = (WT_SESSION *)get_native_handle(env, obj);
    const char *config_str = config ? (*env)->GetStringUTFChars(env, config, NULL) : NULL;
    
    int ret = session->close(session, config_str);
    
    if (config_str) {
        (*env)->ReleaseStringUTFChars(env, config, config_str);
    }
    
    // Set handle to 0 to indicate closed
    set_native_handle(env, obj, 0);
    
    // TODO: Handle return value
}

// Cursor.putKeyString implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Cursor_putKeyString
  (JNIEnv *env, jobject obj, jstring key) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    const char *key_str = (*env)->GetStringUTFChars(env, key, NULL);
    
    // Make a copy of the string to ensure it stays valid
    size_t len = strlen(key_str);
    char *key_copy = malloc(len + 1);
    if (key_copy != NULL) {
        strcpy(key_copy, key_str);
        cursor->set_key(cursor, key_copy);
        // Note: We're intentionally leaking this memory for now
        // In a production system, we'd need a way to free it after operations
    } else {
        cursor->set_key(cursor, key_str);
    }
    
    (*env)->ReleaseStringUTFChars(env, key, key_str);
}

// Cursor.putValueString implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Cursor_putValueString
  (JNIEnv *env, jobject obj, jstring value) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    const char *value_str = (*env)->GetStringUTFChars(env, value, NULL);
    
    // Make a copy of the string to ensure it stays valid
    size_t len = strlen(value_str);
    char *value_copy = malloc(len + 1);
    if (value_copy != NULL) {
        strcpy(value_copy, value_str);
        cursor->set_value(cursor, value_copy);
        // Note: We're intentionally leaking this memory for now
        // In a production system, we'd need a way to free it after insert
    } else {
        cursor->set_value(cursor, value_str);
    }
    
    (*env)->ReleaseStringUTFChars(env, value, value_str);
}

// Cursor.insert implementation
JNIEXPORT jint JNICALL Java_com_wiredtiger_db_Cursor_insert
  (JNIEnv *env, jobject obj) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    return cursor->insert(cursor);
}

// Cursor.reset implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Cursor_reset
  (JNIEnv *env, jobject obj) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    cursor->reset(cursor);
}

// Cursor.search implementation
JNIEXPORT jint JNICALL Java_com_wiredtiger_db_Cursor_search
  (JNIEnv *env, jobject obj) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    return cursor->search(cursor);
}

// Cursor.getValueString implementation
JNIEXPORT jstring JNICALL Java_com_wiredtiger_db_Cursor_getValueString
  (JNIEnv *env, jobject obj) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    const char *value = NULL;
    int ret;
    
    // Get the value from the cursor
    ret = cursor->get_value(cursor, &value);
    if (ret != 0) {
        // Return empty string on error
        return (*env)->NewStringUTF(env, "");
    }
    
    // Check if value is null and return appropriate result
    if (value == NULL) {
        return (*env)->NewStringUTF(env, "");
    }
    
    return (*env)->NewStringUTF(env, value);
}

// Cursor.close implementation
JNIEXPORT void JNICALL Java_com_wiredtiger_db_Cursor_close
  (JNIEnv *env, jobject obj) {
    
    WT_CURSOR *cursor = (WT_CURSOR *)get_native_handle(env, obj);
    int ret = cursor->close(cursor);
    
    // Set handle to 0 to indicate closed
    set_native_handle(env, obj, 0);
    
    // TODO: Handle return value
}
