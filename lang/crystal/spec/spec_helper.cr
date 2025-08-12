require "spec"
require "file_utils"

# Spec helper for WiredTiger Crystal bindings
# This file sets up the testing environment

# Add the src directory to the load path
require "../src/wiredtiger"

# Test configuration
Spec.before_each do
  # Clean up any test databases before each test
  test_dir = File.join("tmp", "wiredtiger_test_#{Random::Secure.hex(8)}")
  Dir.mkdir_p(test_dir) unless Dir.exists?(test_dir)
  ENV["WIREDTIGER_TEST_DIR"] = test_dir
end

Spec.after_each do
  # Clean up after each test
  if test_dir = ENV["WIREDTIGER_TEST_DIR"]?
    FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
  end
end
