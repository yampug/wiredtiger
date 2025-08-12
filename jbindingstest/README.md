jbindingstest: Java bindings smoke tests

This subproject provides a minimal Gradle setup to verify the WiredTiger Java bindings via a simple smoke test and a runnable example.

Prerequisites
- Build WiredTiger with Java bindings to produce the JAR and JNI library
  - Typical POSIX build (in-tree):
    - sh autogen.sh
    - ./configure --enable-java
    - make -j
  - This should produce:
    - wiredtiger.jar (usually in the repository root when built in-tree)
    - libwiredtiger_java (JNI library; typically under lang/java/.libs/) and core libwiredtiger

Configure environment variables for this project
- WT_JAVA_JAR: absolute path to wiredtiger.jar
- WT_JNI_LIB_DIR: absolute path to the directory containing the JNI library

Example (from the WiredTiger repo root)
```sh
export WT_JAVA_JAR="$PWD/wiredtiger.jar"
export WT_JNI_LIB_DIR="$PWD/lang/java/.libs"
```

Build and run tests
- Requires Gradle on your PATH (or use your local Gradle wrapper if available)
```sh
cd jbindingstest
gradle test
```

Run the sample program
```sh
gradle run --args="$PWD/.wt-java-smoke"
```

Notes
- The build.gradle defaults to look for wiredtiger.jar in the repository root (../wiredtiger.jar) and the JNI library in ../.libs if environment variables are not set. Overriding via WT_JAVA_JAR and WT_JNI_LIB_DIR is recommended.
- On macOS, you may need to ensure DYLD_LIBRARY_PATH includes WT_JNI_LIB_DIR; Gradle config sets java.library.path for runtime and tests.


