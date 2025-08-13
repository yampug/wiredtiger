# Makefile for WiredTiger Crystal Bindings

# Configuration
CRYSTAL = crystal
CRYSTAL_FLAGS = --release
LIBRARY_NAME = libwiredtiger_crystal
CRYSTAL_SRC_DIR = src
BUILD_DIR = build
LIB_DIR = lib

# Default target
all: build

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(LIB_DIR):
	mkdir -p $(LIB_DIR)

# Build the C extension
$(BUILD_DIR)/$(LIBRARY_NAME).o: wiredtiger_crystal.c | $(BUILD_DIR)
	$(CC) -c -fPIC -I$(shell pwd)/../../src/include -o $@ $<

# Build the shared library
$(LIB_DIR)/$(LIBRARY_NAME).$(DLEXT): $(BUILD_DIR)/$(LIBRARY_NAME).o | $(LIB_DIR)
	$(CC) -shared -o $@ $< -L$(shell pwd)/../../build_posix/.libs -lwiredtiger

# Build the Crystal library
build: $(LIB_DIR)/$(LIBRARY_NAME).$(DLEXT)
	$(CRYSTAL) build $(CRYSTAL_FLAGS) -o $(BUILD_DIR)/wiredtiger_crystal $(CRYSTAL_SRC_DIR)/wiredtiger.cr

# Install the library
install: build
	install -d $(DESTDIR)$(libdir)
	install -m 755 $(LIB_DIR)/$(LIBRARY_NAME).$(DLEXT) $(DESTDIR)$(libdir)/
	install -d $(DESTDIR)$(includedir)/wiredtiger/crystal
	install -m 644 $(CRYSTAL_SRC_DIR)/*.cr $(DESTDIR)$(includedir)/wiredtiger/crystal/

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(LIB_DIR)

# Run tests
test: build
	$(CRYSTAL) spec

# Show build info
info:
	@echo "Crystal bindings build configuration:"
	@echo "  CRYSTAL: $(CRYSTAL)"
	@echo "  BUILD_DIR: $(BUILD_DIR)"
	@echo "  LIB_DIR: $(LIB_DIR)"
	@echo "  LIBRARY_NAME: $(LIBRARY_NAME)"

.PHONY: all build install clean test info
