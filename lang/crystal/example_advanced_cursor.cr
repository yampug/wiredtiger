#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger Advanced Cursor Operations
puts "🚀 WiredTiger Advanced Cursor Operations Example"
puts "=================================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_advanced_cursor_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

begin
  # Open connection
  puts "\n📁 Opening database at: #{db_dir}"
  conn = WiredTiger::WiredTiger.open(db_dir, "create")
  session = conn.open_session
  
  puts "✅ Connection and session created successfully"
  
  # Create tables
  puts "\n🏗️  Creating tables..."
  session.create("table:users", "key_format=S,value_format=S")
  session.create("table:logs", "key_format=S,value_format=S")
  puts "✅ Tables created successfully"
  
  # Example 1: Basic Remove Operation
  puts "\n🗑️  Example 1: Basic Remove Operation"
  puts "Inserting test data and then removing a record..."
  
  cursor = session.open_cursor("table:users")
  
  # Insert test data
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
  
  # Display initial data
  puts "  📊 Initial users:"
  cursor = session.open_cursor("table:users")
  while cursor.next == 0
    user_id = cursor.get_key_string
    name = cursor.get_value_string
    puts "    #{user_id}: #{name}"
  end
  cursor.close
  
  # Remove user2
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user2")
  cursor.search
  cursor.remove
  cursor.close
  
  puts "  ✅ Removed user2"
  
  # Display updated data
  puts "  📊 Users after removal:"
  cursor = session.open_cursor("table:users")
  while cursor.next == 0
    user_id = cursor.get_key_string
    name = cursor.get_value_string
    puts "    #{user_id}: #{name}"
  end
  cursor.close
  
  # Example 2: Simple Modify Operation (Insert)
  puts "\n✏️  Example 2: Simple Modify Operation (Insert)"
  puts "Inserting text into an existing value..."
  
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user1")
  cursor.search
  current_name = cursor.get_value_string
  puts "  📝 Current name: '#{current_name}'"
  
  # Begin transaction with snapshot isolation (required for modify)
  session.begin_transaction("isolation=snapshot")
  
  # Insert " Jr." at the end of the name
  insert_modify = WiredTiger::DB::Modify.insert(" Jr.", current_name.size)
  cursor.modify([insert_modify])
  
  session.commit_transaction
  cursor.close
  
  # Verify the modification
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user1")
  cursor.search
  updated_name = cursor.get_value_string
  puts "  ✅ Updated name: '#{updated_name}'"
  cursor.close
  
  # Example 3: Modify Operation (Replace)
  puts "\n✏️  Example 3: Modify Operation (Replace)"
  puts "Replacing part of a value..."
  
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user3")
  cursor.search
  current_name = cursor.get_value_string
  puts "  📝 Current name: '#{current_name}'"
  
  # Begin transaction
  session.begin_transaction("isolation=snapshot")
  
  # Replace "Bob" with "Robert"
  replace_modify = WiredTiger::DB::Modify.replace("Robert", 0, 3)
  cursor.modify([replace_modify])
  
  session.commit_transaction
  cursor.close
  
  # Verify the modification
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user3")
  cursor.search
  updated_name = cursor.get_value_string
  puts "  ✅ Updated name: '#{updated_name}'"
  cursor.close
  
  # Example 4: Complex Log Management
  puts "\n📝 Example 4: Complex Log Management"
  puts "Managing log entries with modify operations..."
  
  cursor = session.open_cursor("table:logs")
  
  # Insert initial log entry
  cursor.put_key_string("log_001")
  cursor.put_value_string("User login successful")
  cursor.insert
  
  cursor.close
  
  # Display initial log
  puts "  📊 Initial log:"
  cursor = session.open_cursor("table:logs")
  cursor.put_key_string("log_001")
  cursor.search
  log_entry = cursor.get_value_string
  puts "    log_001: #{log_entry}"
  cursor.close
  
  # Begin transaction for complex modifications
  session.begin_transaction("isolation=snapshot")
  
  cursor = session.open_cursor("table:logs")
  cursor.put_key_string("log_001")
  cursor.search
  
  # Multiple modifications:
  # 1. Insert timestamp at the beginning
  # 2. Replace "successful" with "completed"
  # 3. Add status code at the end
  mods = [
    WiredTiger::DB::Modify.insert("[2024-08-13] ", 0),
    WiredTiger::DB::Modify.replace("completed", 25, 9),
    WiredTiger::DB::Modify.insert(" (200)", log_entry.size + 16)  # Adjust for previous modifications
  ]
  
  cursor.modify(mods)
  cursor.close
  
  session.commit_transaction
  
  # Verify complex modification
  puts "  📊 Updated log:"
  cursor = session.open_cursor("table:logs")
  cursor.put_key_string("log_001")
  cursor.search
  updated_log = cursor.get_value_string
  puts "    log_001: #{updated_log}"
  cursor.close
  
  # Example 5: Error Handling
  puts "\n⚠️  Example 5: Error Handling"
  puts "Demonstrating proper error handling for modify operations..."
  
  begin
    # Try to modify without a transaction (should fail)
    cursor = session.open_cursor("table:users")
    cursor.put_key_string("user1")
    cursor.search
    
    insert_modify = WiredTiger::DB::Modify.insert(" Test", 0)
    cursor.modify([insert_modify])
    
    cursor.close
    puts "  ❌ This should have failed!"
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "  ✅ Correctly caught exception: #{ex.message}"
    cursor.close if cursor
  end
  
  # Final display of all data
  puts "\n📊 Final Database State:"
  
  puts "  👥 Users:"
  cursor = session.open_cursor("table:users")
  while cursor.next == 0
    user_id = cursor.get_key_string
    name = cursor.get_value_string
    puts "    #{user_id}: #{name}"
  end
  cursor.close
  
  puts "  📝 Logs:"
  cursor = session.open_cursor("table:logs")
  while cursor.next == 0
    log_id = cursor.get_key_string
    log_entry = cursor.get_value_string
    puts "    #{log_id}: #{log_entry}"
  end
  cursor.close
  
  puts "\n🎉 All advanced cursor operation examples completed successfully!"
  
rescue ex : Exception
  puts "\n❌ Error occurred: #{ex.message}"
  puts ex.backtrace.join("\n")
  
ensure
  # Clean up
  puts "\n🧹 Cleaning up..."
  if session && !session.closed?
    session.close
  end
  if conn && !conn.closed?
    conn.close
  end
  
  # Remove database directory
  if Dir.exists?(db_dir)
    FileUtils.rm_rf(db_dir)
    puts "✅ Database directory removed: #{db_dir}"
  end
end

puts "\n✨ Advanced cursor operations example completed!"
