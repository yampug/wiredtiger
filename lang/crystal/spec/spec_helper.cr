require "spec"
require "file_utils"

# Spec helper for WiredTiger Crystal bindings
# This file sets up the testing environment

# Add the src directory to the load path
require "../src/wiredtiger"

# Helper module for verifying database files
module DatabaseFileVerifier
  # Verifies that a database file exists and has minimum size
  # @param db_path [String] Path to the database directory
  # @param min_size_kb [Int32] Minimum size in kilobytes (default: 5)
  # @return [Bool] true if file exists and meets size requirements
  def self.verify_database_file(db_path : String, min_size_kb : Int32 = 5) : Bool
    # Check if the directory exists
    return false unless Dir.exists?(db_path)
    
    # Look for WiredTiger.wt file (main database file)
    wt_file = File.join(db_path, "WiredTiger.wt")
    return false unless File.exists?(wt_file)
    
    # Check file size (convert KB to bytes)
    file_size = File.size(wt_file)
    min_size_bytes = min_size_kb * 1024
    
    # Also check if there are other database files
    has_other_files = Dir.entries(db_path).any? { |entry| entry.ends_with?(".wt") && entry != "WiredTiger.wt" }
    
    # Log verification details for debugging
    puts "Database verification for #{db_path}:"
    puts "  WiredTiger.wt exists: #{File.exists?(wt_file)}"
    puts "  WiredTiger.wt size: #{file_size} bytes (#{file_size / 1024.0} KB)"
    puts "  Has other .wt files: #{has_other_files}"
    puts "  Meets size requirement: #{file_size >= min_size_bytes}"
    
    file_size >= min_size_bytes
  end
  
  # Gets a unique test database directory
  # @return [String] Unique path for this test
  def self.get_unique_test_dir : String
    File.join("tmp", "wiredtiger_test_#{Random::Secure.hex(8)}")
  end
end

# Test configuration
Spec.before_each do
  # Each test gets a unique database directory
  test_dir = DatabaseFileVerifier.get_unique_test_dir
  Dir.mkdir_p(test_dir) unless Dir.exists?(test_dir)
  ENV["WIREDTIGER_TEST_DIR"] = test_dir
end

Spec.after_each do
  # Verify database file exists and has minimum size before cleanup
  if test_dir = ENV["WIREDTIGER_TEST_DIR"]?
    if Dir.exists?(test_dir)
      puts "\n=== Database File Verification ==="
      is_valid = DatabaseFileVerifier.verify_database_file(test_dir)
      puts "Database verification result: #{is_valid ? "PASSED" : "FAILED"}"
      puts "================================\n"
      
      # Clean up after verification
      FileUtils.rm_rf(test_dir)
    end
  end
end
