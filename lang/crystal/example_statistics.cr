#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger Statistics Support
puts "📊 WiredTiger Statistics Support Example"
puts "========================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_statistics_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

begin
  # Open connection with statistics enabled
  puts "\n📁 Opening database with statistics enabled at: #{db_dir}"
  conn = WiredTiger::WiredTiger.open(db_dir, "create,statistics=(all)")
  session = conn.open_session
  
  puts "✅ Connection and session created successfully with statistics enabled"
  
  # Create tables for testing
  puts "\n🏗️  Creating tables for statistics testing..."
  session.create("table:users", "key_format=S,value_format=S")
  session.create("table:logs", "key_format=S,value_format=S")
  session.create("table:metrics", "key_format=S,value_format=S")
  puts "✅ Tables created successfully"
  
  # Example 1: Database-wide Statistics
  puts "\n📊 Example 1: Database-wide Statistics"
  puts "Performing operations to generate database statistics..."
  
  # Insert data into multiple tables
  cursor = session.open_cursor("table:users")
  100.times do |i|
    cursor.put_key_string("user_#{i}")
    cursor.put_value_string("User #{i} data" * 5)
    cursor.insert
  end
  cursor.close
  
  cursor = session.open_cursor("table:logs")
  50.times do |i|
    cursor.put_key_string("log_#{i}")
    cursor.put_value_string("Log entry #{i} with detailed information" * 3)
    cursor.insert
  end
  cursor.close
  
  cursor = session.open_cursor("table:metrics")
  25.times do |i|
    cursor.put_key_string("metric_#{i}")
    cursor.put_value_string("Performance metric #{i} data" * 4)
    cursor.insert
  end
  cursor.close
  
  puts "  ✅ Inserted data into all tables"
  
  # Get database-wide statistics
  puts "  📈 Gathering database-wide statistics..."
  all_stats = session.get_all_statistics
  
  puts "  📊 Database Statistics Summary:"
  puts "    Total statistics available: #{all_stats.size}"
  
  # Display some key statistics
  key_stats = [
    "file open",
    "cache pages",
    "cache bytes",
    "connection data handles"
  ]
  
  key_stats.each do |stat_name|
    matching_stats = all_stats.select { |desc, _| desc.downcase.includes?(stat_name.downcase) }
    matching_stats.each do |desc, value|
      puts "    #{desc}: #{value}"
    end
  end
  
  # Example 2: Table-specific Statistics
  puts "\n📊 Example 2: Table-specific Statistics"
  puts "Analyzing statistics for individual tables..."
  
  tables = ["users", "logs", "metrics"]
  tables.each do |table_name|
    puts "  📋 Table: #{table_name}"
    table_stats = session.get_table_statistics(table_name)
    
    puts "    Statistics available: #{table_stats.size}"
    
    # Display key table statistics
    key_table_stats = [
      "entries",
      "insert",
      "overflow",
      "row internal",
      "row leaf"
    ]
    
    key_table_stats.each do |stat_name|
      matching_stats = table_stats.select { |desc, _| desc.downcase.includes?(stat_name.downcase) }
      matching_stats.each do |desc, value|
        puts "      #{desc}: #{value}"
      end
    end
  end
  
  # Example 3: Session Statistics
  puts "\n📊 Example 3: Session Statistics"
  puts "Monitoring session performance metrics..."
  
  # Perform some operations to generate session statistics
  puts "  🔄 Performing operations to generate session statistics..."
  
  # Read some data
  cursor = session.open_cursor("table:users")
  cursor.put_key_string("user_1")
  cursor.search
  cursor.get_value_string
  cursor.close
  
  # Update some data
  cursor = session.open_cursor("table:logs")
  cursor.put_key_string("log_1")
  cursor.search
  cursor.put_value_string("Updated log entry 1 with new information")
  cursor.update
  cursor.close
  
  # Get session statistics
  session_stats = session.get_session_statistics
  
  puts "  📈 Session Statistics Summary:"
  puts "    Total session statistics: #{session_stats.size}"
  
  # Display key session statistics
  key_session_stats = [
    "bytes read",
    "bytes write",
    "read time",
    "write time",
    "cache time"
  ]
  
  key_session_stats.each do |stat_name|
    matching_stats = session_stats.select { |desc, _| desc.downcase.includes?(stat_name.downcase) }
    matching_stats.each do |desc, value|
      puts "      #{desc}: #{value}"
    end
  end
  
  # Example 4: Statistics Cursor Iteration
  puts "\n📊 Example 4: Statistics Cursor Iteration"
  puts "Demonstrating direct cursor usage for statistics..."
  
  # Open a statistics cursor for the users table
  puts "  🔍 Opening statistics cursor for users table..."
  stats_cursor = session.open_table_statistics_cursor("users")
  
  puts "  📋 Iterating through all statistics:"
  stats_count = 0
  stats_cursor.each do |stat|
    stats_count += 1
    puts "    [#{stat.key}] #{stat.description} = #{stat.printable_value}"
  end
  
  puts "  ✅ Processed #{stats_count} statistics"
  
  # Example 5: Statistics Configuration Options
  puts "\n📊 Example 5: Statistics Configuration Options"
  puts "Testing different statistics configurations..."
  
  # Test fast statistics
  puts "  ⚡ Testing fast statistics configuration..."
  fast_stats = session.get_table_statistics("users", "fast")
  puts "    Fast statistics available: #{fast_stats.size}"
  
  # Test all statistics
  puts "  🚀 Testing all statistics configuration..."
  all_table_stats = session.get_table_statistics("users", "all")
  puts "    All statistics available: #{all_table_stats.size}"
  
  # Test clear configuration
  puts "  🧹 Testing clear statistics configuration..."
  clear_stats_cursor = session.open_table_statistics_cursor("users", "clear")
  clear_stats = clear_stats_cursor.to_a
  puts "    Clear statistics available: #{clear_stats.size}"
  clear_stats_cursor.close
  
  # Example 6: Specific Statistics by Key
  puts "\n📊 Example 6: Specific Statistics by Key"
  puts "Retrieving specific statistics using predefined keys..."
  
  # Get specific statistics using StatKeys constants
  puts "  🔑 Using predefined statistic keys..."
  
  entries_key = WiredTiger::DB::StatKeys::TABLE_BTREE_ENTRIES
  insert_key = WiredTiger::DB::StatKeys::TABLE_BTREE_INSERT
  
  entries_stat = session.get_statistic(entries_key)
  insert_stat = session.get_statistic(insert_key)
  
  puts "    BTree entries (key #{entries_key}): #{entries_stat || "Not available"}"
  puts "    BTree insert operations (key #{insert_key}): #{insert_stat || "Not available"}"
  
  # Example 7: Statistics Analysis and Insights
  puts "\n📊 Example 7: Statistics Analysis and Insights"
  puts "Analyzing statistics to gain insights..."
  
  # Calculate some derived metrics
  puts "  🧮 Calculating derived metrics..."
  
  # Get table sizes
  users_stats = session.get_table_statistics("users")
  logs_stats = session.get_table_statistics("logs")
  metrics_stats = session.get_table_statistics("metrics")
  
  # Find entry counts
  users_entries = users_stats["btree entries"]? || 0
  logs_entries = logs_stats["btree entries"]? || 0
  metrics_entries = metrics_stats["btree entries"]? || 0
  
  total_entries = users_entries + logs_entries + metrics_entries
  
  puts "    Total entries across all tables: #{total_entries}"
  puts "    Users table entries: #{users_entries}"
  puts "    Logs table entries: #{logs_entries}"
  puts "    Metrics table entries: #{metrics_entries}"
  
  # Check for overflow pages
  users_overflow = users_stats["btree overflow"]? || 0
  logs_overflow = logs_stats["btree overflow"]? || 0
  metrics_overflow = metrics_stats["btree overflow"]? || 0
  
  total_overflow = users_overflow + logs_overflow + metrics_overflow
  
  puts "    Total overflow pages: #{total_overflow}"
  puts "    Overflow percentage: #{(total_overflow.to_f / total_entries * 100).round(2)}%"
  
  # Example 8: Performance Monitoring
  puts "\n📊 Example 8: Performance Monitoring"
  puts "Setting up performance monitoring with statistics..."
  
  # Monitor cache performance
  puts "  💾 Monitoring cache performance..."
  cache_stats = session.get_all_statistics.select { |desc, _| desc.downcase.includes?("cache") }
  
  puts "    Cache-related statistics:"
  cache_stats.each do |desc, value|
    puts "      #{desc}: #{value}"
  end
  
  # Monitor I/O performance
  puts "  📁 Monitoring I/O performance..."
  io_stats = session.get_all_statistics.select { |desc, _| desc.downcase.includes?("file") || desc.downcase.includes?("read") || desc.downcase.includes?("write") }
  
  puts "    I/O-related statistics:"
  io_stats.each do |desc, value|
    puts "      #{desc}: #{value}"
  end
  
  # Close the statistics cursor
  stats_cursor.close
  
  # Final statistics summary
  puts "\n📊 Final Statistics Summary"
  puts "============================"
  
  puts "  🗄️  Database Statistics:"
  final_all_stats = session.get_all_statistics
  puts "    Total statistics available: #{final_all_stats.size}"
  
  puts "  📋 Table Statistics:"
  tables.each do |table_name|
    final_table_stats = session.get_table_statistics(table_name)
    puts "    #{table_name}: #{final_table_stats.size} statistics"
  end
  
  puts "  👤 Session Statistics:"
  final_session_stats = session.get_session_statistics
  puts "    Total session statistics: #{final_session_stats.size}"
  
  puts "\n🎉 All statistics examples completed successfully!"
  
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

puts "\n✨ Statistics support example completed!"
puts ""
puts "💡 Key Features Demonstrated:"
puts "  • Database-wide statistics collection"
puts "  • Table-specific statistics analysis"
puts "  • Session performance monitoring"
puts "  • Statistics cursor iteration"
puts "  • Configuration options (fast, all, clear)"
puts "  • Specific statistics retrieval by key"
puts "  • Performance insights and analysis"
puts "  • Cache and I/O monitoring"
