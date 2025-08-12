/*
 * wiredtiger_java.i
 * SWIG interface file for WiredTiger Java bindings
 */

%module wiredtiger

%{
#include "wiredtiger.h"
%}

/* Basic string handling for Java */
%include "various.i"
%include "typemaps.i"

/* Handle output parameters for connections, sessions, and cursors */
%typemap(in, numinputs=0) WT_CONNECTION ** (WT_CONNECTION *temp = NULL) {
    $1 = &temp;
}

%typemap(argout) WT_CONNECTION ** {
    $result = SWIG_NewPointerObj(SWIG_as_voidptr(*$1), SWIGTYPE_p___wt_connection, 0);
}

%typemap(in, numinputs=0) WT_SESSION ** (WT_SESSION *temp = NULL) {
    $1 = &temp;
}

%typemap(argout) WT_SESSION ** {
    $result = SWIG_NewPointerObj(SWIG_as_voidptr(*$1), SWIGTYPE_p___wt_session, 0);
}

%typemap(in, numinputs=0) WT_CURSOR ** (WT_CURSOR *temp = NULL) {
    $1 = &temp;
}

%typemap(argout) WT_CURSOR ** {
    $result = SWIG_NewPointerObj(SWIG_as_voidptr(*$1), SWIGTYPE_p___wt_cursor, 0);
}

/* Include the main WiredTiger header */
%include "wiredtiger.h"