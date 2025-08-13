#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger Advanced Cursor Operations with Memory Safety
puts "🚀 WiredTiger Advanced Cursor Operations Example (Memory Safe)"
puts "==============================================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_advanced_cursor_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

# Memory-safe database operations with guaranteed cleanup
def run_advanced_cursor_example(db_dir : String)
  conn = nil
  session = nil
  
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
    
    # Use ensure block for guaranteed cursor cleanup
    cursor = session.open_cursor("table:users")
    begin
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
    ensure
      cursor.safe_close  # Always cleaned up, even with exceptions
    end
    
    # Display initial data with safe cursor management
    puts "  📊 Initial users:"
    display_users(session, "table:users")
    
    # Remove user2 with safe cursor management
    cursor = session.open_cursor("table:users")
    begin
      cursor.put_key_string("user2")
      cursor.search
      cursor.remove
      puts "  ✅ Removed user2"
    ensure
      cursor.safe_close
    end
    
    # Display updated data
    puts "  📊 Users after removal:"
    display_users(session, "table:users")
    
    # Example 2: Simple Modify Operation (Insert)
    puts "\n✏️  Example 2: Simple Modify Operation (Insert)"
    puts "Inserting text into an existing value..."
    
    cursor = session.open_cursor("table:users")
    begin
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
    ensure
      cursor.safe_close
    end
    
    # Verify the modification
    puts "  📊 Users after modification:"
    display_users(session, "table:users")
    
    # Example 3: Complex Modify Operations
    puts "\n🔧 Example 3: Complex Modify Operations"
    puts "Performing multiple modifications in sequence..."
    
    cursor = session.open_cursor("table:users")
    begin
      cursor.put_key_string("user3")
      cursor.search
      current_name = cursor.get_value_string
      puts "  📝 Current name: '#{current_name}'"
      
      session.begin_transaction("isolation=snapshot")
      
      # Multiple modifications: remove "Bob", insert "Robert", append " III"
      modifications = [
        WiredTiger::DB::Modify.remove(0, 3),           # Remove "Bob"
        WiredTiger::DB::Modify.insert("Robert", 0),     # Insert "Robert" at beginning
        WiredTiger::DB::Modify.insert(" III", current_name.size - 3)  # Append " III"
      ]
      
      cursor.modify(modifications)
      session.commit_transaction
      
      puts "  ✅ Applied complex modifications"
    ensure
      cursor.safe_close
    end
    
    # Verify complex modifications
    puts "  📊 Users after complex modifications:"
    display_users(session, "table:users")
    
    # Example 4: Working with Binary Data (Memory Safe)
    puts "\n🔒 Example 4: Working with Binary Data (Memory Safe)"
    puts "Storing and retrieving binary data with automatic memory management..."
    
    cursor = session.open_cursor("table:users")
    begin
      # Store binary data (memory managed automatically)
      cursor.put_key_string("binary_user")
      binary_data = Bytes[0x48, 0x65, 0x6C, 0x6C, 0x6F]  # "Hello" in hex
      cursor.put_value_bytes(binary_data)
      cursor.insert
      
      puts "  💾 Stored binary data: #{binary_data.hexstring}"
      
      # Retrieve binary data (memory managed automatically)
      cursor.reset
      cursor.put_key_string("binary_user")
      if cursor.search == 0
        retrieved_data = cursor.get_value_bytes
        puts "  📥 Retrieved binary data: #{retrieved_data.hexstring}"
        puts "  📏 Data size: #{retrieved_data.size} bytes"
      end
    ensure
      cursor.safe_close
    end
    
    puts "\n🎉 All examples completed successfully!"
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "❌ Database error: #{ex.message}"
    raise ex
    
  rescue ex : Exception
    puts "❌ Unexpected error: #{ex.message}"
    raise ex
    
  ensure
    # Guaranteed cleanup regardless of success or failure
    puts "\n🧹 Cleaning up resources..."
    session.safe_close if session
    conn.safe_close if conn
    puts "✅ Resources cleaned up successfully"
  end
end

# Helper method for displaying users with safe cursor management
def display_users(session : WiredTiger::DB::Session, table_name : String)
  cursor = session.open_cursor(table_name)
  begin
    while cursor.next == 0
      user_id = cursor.get_key_string
      name = cursor.get_value_string
      puts "    #{user_id}: #{name}"
    end
  ensure
    cursor.safe_close  # Always cleaned up
  end
end

# Run the example with memory safety
begin
  run_advanced_cursor_example(db_dir)
rescue ex : Exception
  puts "❌ Example failed: #{ex.message}"
  exit 1
ensure
  # Clean up database directory
  if Dir.exists?(db_dir)
    puts "\n🗑️  Cleaning up database directory: #{db_dir}"
    FileUtils.rm_rf(db_dir)
    puts "✅ Database directory cleaned up"
  end
end
