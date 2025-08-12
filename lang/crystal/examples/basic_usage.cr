#!/usr/bin/env crystal

# Basic usage example for WiredTiger Crystal bindings
# This demonstrates the core functionality

require "../src/wiredtiger"

puts "WiredTiger Crystal Bindings - Basic Usage Example"
puts "=================================================="

begin
  # Open a connection to a new database
  puts "1. Opening database connection..."
  conn = WiredTiger.open("example_db", "create")
  puts "   ✓ Connection opened successfully"
  
  # Open a session
  puts "2. Opening session..."
  session = conn.open_session
  puts "   ✓ Session opened successfully"
  
  # Create a table for storing user data
  puts "3. Creating users table..."
  session.create("table:users", "key_format=S,value_format=S")
  puts "   ✓ Table 'users' created successfully"
  
  # Insert some sample data
  puts "4. Inserting sample data..."
  cursor = session.open_cursor("table:users")
  
  users = [
    {"user1", "Alice Johnson"},
    {"user2", "Bob Smith"},
    {"user3", "Carol Davis"},
    {"user4", "David Wilson"}
  ]
  
  users.each do |key, value|
    cursor.put_key_string(key)
    cursor.put_value_string(value)
    cursor.insert
    puts "   ✓ Inserted: #{key} -> #{value}"
  end
  
  cursor.close
  puts "   ✓ All data inserted successfully"
  
  # Query and display all users
  puts "5. Querying all users..."
  cursor = session.open_cursor("table:users")
  
  puts "   Users in database:"
  count = 0
  while cursor.next == 0
    count += 1
    # Note: In a real implementation, you'd get both key and value
    puts "     #{count}. #{cursor.get_value_string}"
  end
  
  cursor.close
  puts "   ✓ Found #{count} users"
  
  # Search for a specific user
  puts "6. Searching for specific user..."
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user2")
  
  if cursor.search == 0
    puts "   ✓ Found user2: #{cursor.get_value_string}"
  else
    puts "   ✗ User 'user2' not found"
  end
  
  cursor.close
  
  # Demonstrate cursor navigation
  puts "7. Demonstrating cursor navigation..."
  cursor = session.open_cursor("table:users")
  
  # Go to first record
  cursor.next
  puts "   First user: #{cursor.get_value_string}"
  
  # Go to last record
  cursor.reset
  while cursor.next == 0
    # Keep going until we reach the end
  end
  cursor.prev
  puts "   Last user: #{cursor.get_value_string}"
  
  cursor.close
  
  # Clean up
  puts "8. Cleaning up..."
  session.close
  conn.close
  puts "   ✓ Cleanup completed"
  
  puts "\n🎉 Example completed successfully!"
  puts "Database 'example_db' created with sample data."
  
rescue ex : WiredTiger::WiredTigerException
  puts "\n❌ WiredTiger error: #{ex.message}"
  puts "This might indicate a configuration or build issue."
rescue ex : Exception
  puts "\n❌ Unexpected error: #{ex.message}"
  puts "Stack trace:"
  puts ex.backtrace.join("\n")
end
