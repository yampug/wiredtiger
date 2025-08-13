# Simple test to verify basic functionality
require "wiredtiger"

puts "Testing basic WiredTiger functionality..."

begin
  # Try to open a connection with absolute path
  db_path = "/tmp/wiredtiger_test_#{Random::Secure.hex(8)}"
  puts "Opening database at: #{db_path}"
  
  conn = WiredTiger::WiredTiger.open(db_path, "create")
  puts "✓ Connection opened successfully"
  
  # Open a session
  session = conn.open_session
  puts "✓ Session opened successfully"
  
  # Create a simple table
  session.create("table:test", "key_format=S,value_format=S")
  puts "✓ Table created successfully"
  
  # Open a cursor
  cursor = session.open_cursor("table:test")
  puts "✓ Cursor opened successfully"
  
  # Insert a simple record
  cursor.put_key_string("test_key")
  cursor.put_value_string("test_value")
  cursor.insert
  puts "✓ Record inserted successfully"
  
  # Clean up
  cursor.close
  session.close
  conn.close
  puts "✓ Cleanup completed successfully"
  
  # Verify the database file was created
  if Dir.exists?(db_path)
    puts "✓ Database directory created: #{db_path}"
    wt_file = File.join(db_path, "WiredTiger.wt")
    if File.exists?(wt_file)
      file_size = File.size(wt_file)
      puts "✓ Database file created: #{wt_file} (#{file_size} bytes)"
    end
  end
  
  puts "\n🎉 All basic functionality tests passed!"
  
rescue ex : WiredTiger::DB::WiredTigerException
  puts "❌ Error: #{ex.message}"
  puts "Error type: #{ex.class}"
rescue ex : Exception
  puts "❌ Unexpected error: #{ex.message}"
  puts "Error type: #{ex.class}"
end
