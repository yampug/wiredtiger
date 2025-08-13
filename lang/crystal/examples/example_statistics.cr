#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger Statistics with Memory Safety
puts "🚀 WiredTiger Statistics Example (Memory Safe)"
puts "==============================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_statistics_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

# Memory-safe statistics operations with guaranteed cleanup
def run_statistics_example(db_dir : String)
  conn = nil
  session = nil
  
  begin
    # Open connection
    puts "\n📁 Opening database at: #{db_dir}"
    conn = WiredTiger::WiredTiger.open(db_dir, "create,statistics=(all)")
    session = conn.open_session
    
    puts "✅ Connection and session created successfully"
    
    # Create tables and insert data
    puts "\n🏗️  Creating tables and inserting data..."
    session.create("table:users", "key_format=S,value_format=S")
    session.create("table:products", "key_format=S,value_format=S")
    
    # Insert sample data
    cursor = session.open_cursor("table:users")
    begin
      (1..100).each do |i|
        cursor.put_key_string("user_#{i}")
        cursor.put_value_string("User #{i} Data" * 10)  # Create some data volume
        cursor.insert
      end
      puts "  👥 Inserted 100 users"
    ensure
      cursor.safe_close
    end
    
    cursor = session.open_cursor("table:products")
    begin
      (1..50).each do |i|
        cursor.put_key_string("product_#{i}")
        cursor.put_value_string("Product #{i} Description" * 5)  # Create some data volume
        cursor.insert
      end
      puts "  📦 Inserted 50 products"
    ensure
      cursor.safe_close
    end
    
    puts "✅ Sample data created successfully"
    
    # Example 1: Connection Statistics
    puts "\n📊 Example 1: Connection Statistics"
    puts "Getting comprehensive connection statistics..."
    
    begin
      # Connection statistics are available through session
      stats = session.get_all_statistics
      puts "  🔗 Connection Statistics:"
      stats.each do |description, value|
        puts "    #{description}: #{value}"
      end
    rescue ex : WiredTiger::DB::WiredTigerException
      puts "  ❌ Failed to get connection statistics: #{ex.message}"
    end
    
    # Example 2: Session Statistics
    puts "\n📊 Example 2: Session Statistics"
    puts "Getting session-specific statistics..."
    
    begin
      stats = session.get_session_statistics
      puts "  📝 Session Statistics:"
      stats.each do |description, value|
        puts "    #{description}: #{value}"
      end
    rescue ex : WiredTiger::DB::WiredTigerException
      puts "  ❌ Failed to get session statistics: #{ex.message}"
    end
    
    # Example 3: Table Statistics
    puts "\n📊 Example 3: Table Statistics"
    puts "Getting statistics for specific tables..."
    
    ["users", "products"].each do |table_name|
      begin
        stats = session.get_table_statistics(table_name)
        puts "  📋 #{table_name.capitalize} Table Statistics:"
        stats.each do |description, value|
          puts "    #{description}: #{value}"
        end
      rescue ex : WiredTiger::DB::WiredTigerException
        puts "  ❌ Failed to get #{table_name} statistics: #{ex.message}"
      end
    end
    
    # Example 4: Custom Statistics Query
    puts "\n📊 Example 4: Custom Statistics Query"
    puts "Querying specific statistics with custom configuration..."
    
    cursor = session.open_statistics_cursor("statistics=(all)")
    begin
      puts "  🔍 Custom Statistics Query Results:"
      cursor.each do |stat|
        puts "    #{stat.description}: #{stat.printable_value}"
      end
    ensure
      cursor.close
    end
    
    # Example 5: Statistics with Filtering
    puts "\n📊 Example 5: Statistics with Filtering"
    puts "Getting statistics for specific categories..."
    
    # Get statistics for data-related metrics
    cursor = session.open_statistics_cursor("statistics=(data)")
    begin
      puts "  💾 Data Statistics:"
      cursor.each do |stat|
        puts "    #{stat.description}: #{stat.printable_value}"
      end
    ensure
      cursor.close
    end
    
    # Example 6: Performance Statistics
    puts "\n📊 Example 6: Performance Statistics"
    puts "Getting performance-related statistics..."
    
    # Get statistics for cache and performance metrics
    cursor = session.open_statistics_cursor("statistics=(cache,performance)")
    begin
      puts "  ⚡ Performance Statistics:"
      cursor.each do |stat|
        puts "    #{stat.description}: #{stat.printable_value}"
      end
    ensure
      cursor.close
    end
    
    # Example 7: Statistics Comparison
    puts "\n📊 Example 7: Statistics Comparison"
    puts "Comparing statistics before and after operations..."
    
    # Get initial statistics
    initial_stats = session.get_session_statistics
    puts "  📈 Initial session statistics:"
    initial_stats.each do |description, value|
      puts "    #{description}: #{value}"
    end
    
    # Perform some operations
    puts "  🔄 Performing operations to change statistics..."
    cursor = session.open_cursor("table:users")
    begin
      # Insert more data
      (101..110).each do |i|
        cursor.put_key_string("user_#{i}")
        cursor.put_value_string("Additional User #{i} Data")
        cursor.insert
      end
      puts "    ✅ Inserted 10 more users"
    ensure
      cursor.safe_close
    end
    
    # Get updated statistics
    updated_stats = session.get_session_statistics
    puts "  📈 Updated session statistics:"
    updated_stats.each do |description, value|
      puts "    #{description}: #{value}"
    end
    
    # Example 8: Error Handling in Statistics
    puts "\n📊 Example 8: Error Handling in Statistics"
    puts "Demonstrating robust error handling for statistics operations..."
    
    begin
      # Try to get statistics for non-existent table
      stats = session.get_table_statistics("nonexistent_table")
      puts "  ❌ This should not execute"
    rescue ex : WiredTiger::DB::WiredTigerException
      puts "  ✅ Correctly caught error: #{ex.message}"
    end
    
    # Example 9: Statistics Cursor Management
    puts "\n📊 Example 9: Statistics Cursor Management"
    puts "Demonstrating safe cursor management for statistics..."
    
    # Create multiple cursors safely
    cursors = [] of WiredTiger::DB::StatisticsCursor
    
    begin
      # Open multiple statistics cursors
      cursors << session.open_statistics_cursor("statistics=(all)")
      cursors << session.open_statistics_cursor("statistics=(data)")
      cursors << session.open_statistics_cursor("statistics=(cache)")
      
      puts "  🔍 Opened #{cursors.size} statistics cursors"
      
      # Use each cursor
      cursors.each_with_index do |cursor, index|
        puts "  📊 Cursor #{index + 1} statistics:"
        count = 0
        cursor.each do |stat|
          puts "    #{stat.description}: #{stat.printable_value}"
          count += 1
          break if count >= 3  # Limit output
        end
        cursor.reset
      end
      
    ensure
      # Safely close all cursors
      cursors.each(&.close)
      puts "  ✅ All cursors safely closed"
    end
    
    puts "\n🎉 All statistics examples completed successfully!"
    
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

# Run the example with memory safety
begin
  run_statistics_example(db_dir)
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
