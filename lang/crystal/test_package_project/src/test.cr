# Test file to verify the standalone package works
require "wiredtiger"

puts "Testing standalone WiredTiger Crystal bindings package..."

begin
  # Try to open a connection
  db_path = "/tmp/test_package_db_#{Random::Secure.hex(8)}"
  puts "Opening database at: #{db_path}"
  
  conn = WiredTiger::WiredTiger.open(db_path, "create")
  puts "✓ Connection opened successfully"
  
  # Open a session
  session = conn.open_session
  puts "✓ Session opened successfully"
  
  # Create a table
  session.create("table:test", "key_format=S,value_format=S")
  puts "✓ Table created successfully"
  
  # Open a cursor
  cursor = session.open_cursor("table:test")
  puts "✓ Cursor opened successfully"
  
  # Insert a record
  cursor.put_key_string("test_key")
  cursor.put_value_string("test_value")
  cursor.insert
  puts "✓ Record inserted successfully"
  
  # Clean up
  cursor.close
  session.close
  conn.close
  puts "✓ Cleanup completed successfully"
  
  puts "\n🎉 Standalone package test completed successfully!"
  puts "The package is working correctly!"
  
rescue ex : WiredTiger::DB::WiredTigerException
  puts "❌ Error: #{ex.message}"
  puts "Error type: #{ex.class}"
rescue ex : Exception
  puts "❌ Unexpected error: #{ex.message}"
  puts "Error type: #{ex.class}"
end
