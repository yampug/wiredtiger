#!/usr/bin/env crystal

# Simple example demonstrating WiredTiger Crystal bindings
# This file shows basic database operations

require "./src/wiredtiger"

puts "WiredTiger Crystal Bindings Example"
puts "==================================="

begin
  # Open a connection to a new database
  puts "Opening database connection..."
  conn = WiredTiger.open("testdb", "create")
  
  # Open a session
  puts "Opening session..."
  session = conn.open_session
  
  # Create a table
  puts "Creating table..."
  session.create("table:users", "key_format=S,value_format=S")
  
  # Open a cursor for writing
  puts "Opening cursor for writing..."
  cursor = session.open_cursor("table:users")
  
  # Insert some data
  puts "Inserting data..."
  cursor.put_key_string("user1")
  cursor.put_value_string("John Doe")
  cursor.insert
  
  cursor.put_key_string("user2")
  cursor.put_value_string("Jane Smith")
  cursor.insert
  
  cursor.put_key_string("user3")
  cursor.put_value_string("Bob Johnson")
  cursor.insert
  
  cursor.close
  
  # Open a cursor for reading
  puts "Opening cursor for reading..."
  cursor = session.open_cursor("table:users")
  
  # Iterate through all records
  puts "\nAll users:"
  while cursor.next == 0
    # Note: In a real implementation, you'd need to get the key as well
    puts "  - #{cursor.get_value_string}"
  end
  
  cursor.close
  
  # Search for a specific user
  puts "\nSearching for user1..."
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user1")
  
  if cursor.search == 0
    puts "Found: #{cursor.get_value_string}"
  else
    puts "User not found"
  end
  
  cursor.close
  
  # Clean up
  puts "\nCleaning up..."
  session.close
  conn.close
  
  puts "Example completed successfully!"
  
rescue ex : WiredTiger::WiredTigerException
  puts "WiredTiger error: #{ex.message}"
rescue ex : Exception
  puts "Unexpected error: #{ex.message}"
  puts ex.backtrace.join("\n")
end
