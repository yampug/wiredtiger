# Example application demonstrating WiredTiger Crystal bindings
# This shows how to use the bindings in your own Crystal project

require "wiredtiger"

# Example 1: Basic database operations
def basic_example
  puts "=== Basic Database Operations ==="
  
  # Create a database
  db_path = "example_db"
  conn = WiredTiger::WiredTiger.open(db_path, "create")
  
  begin
    # Open a session
    session = conn.open_session
    
    # Create a table
    session.create("table:users", "key_format=S,value_format=S")
    
    # Open a cursor
    cursor = session.open_cursor("table:users")
    
    # Insert some data
    users = [
      {"john", "John Doe"},
      {"jane", "Jane Smith"},
      {"bob", "Bob Johnson"}
    ]
    
    users.each do |key, value|
      cursor.put_key_string(key)
      cursor.put_value_string(value)
      cursor.insert
      puts "Inserted user: #{key} -> #{value}"
    end
    
    # Search for a user
    puts "\nSearching for user 'jane'..."
    cursor.reset
    cursor.put_key_string("jane")
    
    if cursor.search == 0
      found_value = cursor.get_value_string
      puts "Found: jane -> #{found_value}"
    else
      puts "User 'jane' not found"
    end
    
    # List all users
    puts "\nAll users:"
    cursor.reset
    while cursor.next == 0
      key = cursor.get_key_string
      value = cursor.get_value_string
      puts "  #{key} -> #{value}"
    end
    
    # Clean up
    cursor.close
    session.close
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Error: #{ex.message}"
  end
  
  conn.close
  puts "Basic example completed.\n"
end

# Example 2: Working with multiple tables
def multiple_tables_example
  puts "=== Multiple Tables Example ==="
  
  db_path = "example_db_multi"
  conn = WiredTiger::WiredTiger.open(db_path, "create")
  
  begin
    session = conn.open_session
    
    # Create users table
    session.create("table:users", "key_format=S,value_format=S")
    session.create("table:profiles", "key_format=S,value_format=S")
    session.create("table:settings", "key_format=S,value_format=S")
    
    # Insert data into users table
    users_cursor = session.open_cursor("table:users")
    users_cursor.put_key_string("user1")
    users_cursor.put_value_string("Alice Brown")
    users_cursor.insert
    users_cursor.close
    
    # Insert data into profiles table
    profiles_cursor = session.open_cursor("table:profiles")
    profiles_cursor.put_key_string("user1")
    profiles_cursor.put_value_string("Software Engineer")
    profiles_cursor.insert
    profiles_cursor.close
    
    # Insert data into settings table
    settings_cursor = session.open_cursor("table:settings")
    settings_cursor.put_key_string("user1")
    settings_cursor.put_value_string("theme=dark,notifications=enabled")
    settings_cursor.insert
    settings_cursor.close
    
    puts "Created multiple tables with data"
    
    # Query across tables
    puts "\nUser profile information:"
    users_cursor = session.open_cursor("table:users")
    profiles_cursor = session.open_cursor("table:profiles")
    settings_cursor = session.open_cursor("table:settings")
    
    users_cursor.reset
    while users_cursor.next == 0
      user_id = users_cursor.get_key_string
      user_name = users_cursor.get_value_string
      
      # Get profile
      profiles_cursor.reset
      profiles_cursor.put_key_string(user_id)
      profile = profiles_cursor.search == 0 ? profiles_cursor.get_value_string : "No profile"
      
      # Get settings
      settings_cursor.reset
      settings_cursor.put_key_string(user_id)
      settings = settings_cursor.search == 0 ? settings_cursor.get_value_string : "No settings"
      
      puts "  User: #{user_name}"
      puts "    Profile: #{profile}"
      puts "    Settings: #{settings}"
    end
    
    users_cursor.close
    profiles_cursor.close
    settings_cursor.close
    session.close
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Error: #{ex.message}"
  end
  
  conn.close
  puts "Multiple tables example completed.\n"
end

# Example 3: Error handling
def error_handling_example
  puts "=== Error Handling Example ==="
  
  begin
    # Try to open a database with invalid path
    puts "Attempting to open database with empty path..."
    conn = WiredTiger::WiredTiger.open("", "create")
    puts "This should not be reached"
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Caught expected error: #{ex.message}"
  end
  
  begin
    # Try to create a table with invalid format
    db_path = "error_test_db"
    conn = WiredTiger::WiredTiger.open(db_path, "create")
    session = conn.open_session
    
    puts "Attempting to create table with invalid format..."
    session.create("table:test", "invalid_format")
    puts "This should not be reached"
    
    session.close
    conn.close
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Caught expected error: #{ex.message}"
  end
  
  puts "Error handling example completed.\n"
end

# Example 4: Database statistics
def statistics_example
  puts "=== Database Statistics Example ==="
  
  db_path = "stats_db"
  conn = WiredTiger::WiredTiger.open(db_path, "create")
  
  begin
    session = conn.open_session
    
    # Create a table and insert data
    session.create("table:data", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:data")
    
    # Insert 100 records
    100.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 10) # Make values larger
      cursor.insert
    end
    
    cursor.close
    session.close
    
    # Get database statistics
    puts "Database created with 100 records"
    puts "Database path: #{db_path}"
    
    # Check if database files exist
    if Dir.exists?(db_path)
      wt_file = File.join(db_path, "WiredTiger.wt")
      if File.exists?(wt_file)
        file_size = File.size(wt_file)
        puts "Database file size: #{file_size} bytes (#{file_size / 1024.0} KB)"
      end
      
      # List all .wt files
      wt_files = Dir.entries(db_path).select { |f| f.ends_with?(".wt") }
      puts "Database files: #{wt_files.join(", ")}"
    end
    
    conn.close
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "Error: #{ex.message}"
  end
  
  puts "Statistics example completed.\n"
end

# Main execution
puts "WiredTiger Crystal Bindings Example"
puts "==================================="
puts ""

# Run examples
basic_example
multiple_tables_example
error_handling_example
statistics_example

puts "All examples completed successfully!"
puts ""
puts "Note: Database files have been created in the current directory."
puts "You can inspect them to see the actual WiredTiger database structure."
