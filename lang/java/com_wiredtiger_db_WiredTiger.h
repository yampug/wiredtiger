#include <jni.h>
#ifndef _Included_com_wiredtiger_db_WiredTiger
#define _Included_com_wiredtiger_db_WiredTiger
#ifdef __cplusplus
extern "C" {
#endif
JNIEXPORT jobject JNICALL Java_com_wiredtiger_db_WiredTiger_open
  (JNIEnv *, jclass, jstring, jstring);
#ifdef __cplusplus
}
#endif
#endif
