require "./src/wiredtiger"

puts "Testing new data type support..."

begin
  # Create a test database
  test_dir = "/tmp/wiredtiger_data_types_test_#{Random::Secure.hex(8)}"
  puts "Creating database at: #{test_dir}"
  
  # Create the directory first
  Dir.mkdir_p(test_dir)
  puts "✓ Directory created"
  
  conn = WiredTiger::WiredTiger.open(test_dir, "create")
  puts "✓ Connection opened successfully"
  
  session = conn.open_session
  puts "✓ Session opened successfully"
  
  # Test integer table
  puts "\n--- Testing Integer Support ---"
  session.create("table:integers", "key_format=q,value_format=q")
  cursor = session.open_cursor("table:integers")
  
  cursor.put_key_int(42_i64)
  cursor.put_value_int(100_i64)
  cursor.insert
  puts "✓ Integer data inserted"
  
  cursor.put_key_int(42_i64)
  cursor.search
  retrieved_key = cursor.get_key_int
  retrieved_value = cursor.get_value_int
  puts "✓ Retrieved: key=#{retrieved_key}, value=#{retrieved_value}"
  
  cursor.close
  
  # Test float table
  puts "\n--- Testing Float Support ---"
  puts "Note: WiredTiger doesn't support float format strings natively"
  puts "Floats would need to be stored as strings or integers"
  # session.create("table:floats", "key_format=f,value_format=f")
  # cursor = session.open_cursor("table:floats")
  
  # cursor.put_key_float(3.14_f64)
  # cursor.put_value_float(2.718_f64)
  # cursor.insert
  # puts "✓ Float data inserted"
  
  # cursor.put_key_float(3.14_f64)
  # cursor.search
  # retrieved_key = cursor.get_key_float
  # retrieved_value = cursor.get_value_float
  # puts "✓ Retrieved: key=#{retrieved_key}, value=#{retrieved_value}"
  
  # cursor.close
  
  # Test bytes table
  puts "\n--- Testing Bytes Support ---"
  session.create("table:bytes", "key_format=u,value_format=u")
  cursor = session.open_cursor("table:bytes")
  
  key_data = "hello".to_slice
  value_data = "world".to_slice
  
  cursor.put_key_bytes(key_data)
  cursor.put_value_bytes(value_data)
  cursor.insert
  puts "✓ Bytes data inserted"
  
  cursor.put_key_bytes(key_data)
  cursor.search
  retrieved_key = cursor.get_key_bytes
  retrieved_value = cursor.get_value_bytes
  puts "✓ Retrieved: key=#{String.new(retrieved_key)}, value=#{String.new(retrieved_value)}"
  
  cursor.close
  
  # Clean up
  session.close
  conn.close
  puts "\n✓ All tests completed successfully!"
  
  # Clean up test directory
  system("rm -rf #{test_dir}")
  puts "✓ Test directory cleaned up"
  
rescue ex : WiredTiger::DB::WiredTigerException
  puts "❌ WiredTiger error: #{ex.message}"
rescue ex : Exception
  puts "❌ Unexpected error: #{ex.message}"
  puts "Error type: #{ex.class}"
end
