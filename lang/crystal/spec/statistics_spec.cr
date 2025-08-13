require "./spec_helper"

describe "WiredTiger Statistics Support" do
  it "supports database-wide statistics cursor" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data to generate statistics
    session.create("table:stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:stats_test")
    
    # Insert some data
    10.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 10)
      cursor.insert
    end
    
    cursor.close
    session.close
    
    # Reopen session and check statistics
    session = conn.open_session
    
    # Open statistics cursor
    stats_cursor = session.open_statistics_cursor
    
    # Verify we can iterate through statistics
    stats_count = 0
    stats_cursor.each do |stat|
      stats_count += 1
      stat.key.should be_a(Int32)
      stat.description.should be_a(String)
      stat.printable_value.should be_a(String)
      stat.value.should be_a(Int64)
    end
    
    # Should have some statistics
    stats_count.should be > 0
    
    # Test specific statistics
    all_stats = session.get_all_statistics
    all_stats.size.should be > 0
    
    # Check for common connection statistics
    # Note: Different WiredTiger versions may have different statistics available
    has_file_open = all_stats.any? { |desc, _| desc.includes?("file open") }
    has_cache_pages = all_stats.any? { |desc, _| desc.includes?("cache pages") }
    has_connection = all_stats.any? { |desc, _| desc.includes?("connection") }
    has_session = all_stats.any? { |desc, _| desc.includes?("session") }
    
    # At least one of these common statistics should be available
    (has_file_open || has_cache_pages || has_connection || has_session).should be_true
    
    stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports table-specific statistics cursor" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:table_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:table_stats_test")
    
    # Insert some data
    5.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 20)
      cursor.insert
    end
    
    cursor.close
    
    # Get table statistics
    table_stats = session.get_table_statistics("table_stats_test")
    
    # Should have some table statistics
    table_stats.size.should be > 0
    
    # Check for table-specific statistics
    has_entries = table_stats.any? { |desc, _| desc.includes?("entries") }
    has_insert = table_stats.any? { |desc, _| desc.includes?("insert") }
    
    (has_entries || has_insert).should be_true
    
    # Test statistics cursor directly
    table_stats_cursor = session.open_table_statistics_cursor("table_stats_test")
    
    stats_count = 0
    table_stats_cursor.each do |stat|
      stats_count += 1
      stat.description.should_not be_empty
      stat.value.should be >= 0
    end
    
    stats_count.should be > 0
    
    table_stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports session-specific statistics cursor" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and perform some operations to generate session statistics
    session.create("table:session_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:session_stats_test")
    
    # Insert data
    cursor.put_key_string("key1")
    cursor.put_value_string("value1" * 30)
    cursor.insert
    
    # Read data
    cursor.put_key_string("key1")
    cursor.search
    cursor.get_value_string
    
    cursor.close
    
    # Get session statistics
    session_stats = session.get_session_statistics
    
    # Should have some session statistics
    session_stats.size.should be > 0
    
    # Check for session-specific statistics
    has_bytes_read = session_stats.any? { |desc, _| desc.includes?("bytes read") }
    has_bytes_write = session_stats.any? { |desc, _| desc.includes?("bytes write") }
    
    (has_bytes_read || has_bytes_write).should be_true
    
    # Test statistics cursor directly
    session_stats_cursor = session.open_session_statistics_cursor
    
    stats_count = 0
    session_stats_cursor.each do |stat|
      stats_count += 1
      stat.description.should_not be_empty
      stat.value.should be >= 0
    end
    
    stats_count.should be > 0
    
    session_stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports statistics configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(fast)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:config_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:config_stats_test")
    
    # Insert some data
    3.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 15)
      cursor.insert
    end
    
    cursor.close
    
    # Test different statistics configurations
    fast_stats = session.get_table_statistics("config_stats_test", "fast")
    all_stats = session.get_table_statistics("config_stats_test", "all")
    
    # Fast stats should be a subset of all stats
    fast_stats.size.should be <= all_stats.size
    
    # Test clear configuration
    clear_stats_cursor = session.open_table_statistics_cursor("config_stats_test", "clear")
    clear_stats = clear_stats_cursor.to_a
    
    clear_stats.size.should be > 0
    
    clear_stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports getting specific statistics by key" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:specific_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:specific_stats_test")
    
    # Insert some data
    7.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 25)
      cursor.insert
    end
    
    cursor.close
    
    # Get specific statistics by key
    entries_stat = session.get_statistic(WiredTiger::DB::StatKeys::TABLE_BTREE_ENTRIES)
    if entries_stat
      entries_stat.should be >= 0
    end
    
    insert_stat = session.get_statistic(WiredTiger::DB::StatKeys::TABLE_BTREE_INSERT)
    if insert_stat
      insert_stat.should be >= 0
    end
    
    # Test with table-specific statistics
    table_stats = session.get_table_statistics("specific_stats_test")
    table_stats.size.should be > 0
    
    # Find any available numeric statistic
    numeric_stat = table_stats.values.find { |v| v.is_a?(Int64) && v >= 0 }
    numeric_stat.should_not be_nil
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "handles statistics cursor reset correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:reset_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:reset_stats_test")
    
    # Insert some data
    4.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 35)
      cursor.insert
    end
    
    cursor.close
    
    # Open statistics cursor
    stats_cursor = session.open_table_statistics_cursor("reset_stats_test")
    
    # Get initial statistics
    initial_stats = stats_cursor.to_a
    initial_stats.size.should be > 0
    
    # Reset the cursor
    stats_cursor.reset
    
    # Get statistics after reset
    reset_stats = stats_cursor.to_a
    reset_stats.size.should be > 0
    
    # The statistics should be the same after reset
    initial_stats.size.should eq(reset_stats.size)
    
    stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "handles statistics cursor close correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:close_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:close_stats_test")
    
    # Insert some data
    6.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 40)
      cursor.insert
    end
    
    cursor.close
    
    # Open statistics cursor
    stats_cursor = session.open_table_statistics_cursor("close_stats_test")
    
    # Verify cursor is not closed initially
    stats_cursor.closed?.should be_false
    
    # Get some statistics
    stats = stats_cursor.to_a
    stats.size.should be > 0
    
    # Close the cursor
    stats_cursor.close
    
    # Verify cursor is closed
    stats_cursor.closed?.should be_true
    
    # Attempting to use a closed cursor should not crash
    stats_cursor.close.should eq(0)
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "provides meaningful statistics information" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    # Enable statistics for the database
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create a table and insert some data
    session.create("table:meaningful_stats_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:meaningful_stats_test")
    
    # Insert data
    8.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 50)
      cursor.insert
    end
    
    cursor.close
    
    # Get all statistics
    all_stats = session.get_all_statistics
    table_stats = session.get_table_statistics("meaningful_stats_test")
    session_stats = session.get_session_statistics
    
    # Verify we have meaningful statistics
    all_stats.size.should be > 0
    table_stats.size.should be > 0
    session_stats.size.should be > 0
    
    # Check that statistics contain meaningful information
    all_stats.each do |desc, value|
      desc.should_not be_empty
      value.should be >= 0
    end
    
    table_stats.each do |desc, value|
      desc.should_not be_empty
      value.should be >= 0
    end
    
    session_stats.each do |desc, value|
      desc.should_not be_empty
      value.should be >= 0
    end
    
    # Test statistics cursor iteration
    stats_cursor = session.open_table_statistics_cursor("meaningful_stats_test")
    
    stats_count = 0
    stats_cursor.each do |stat|
      stats_count += 1
      stat.key.should be_a(Int32)
      stat.description.should_not be_empty
      stat.printable_value.should_not be_empty
      stat.value.should be >= 0
      
      # Test to_s method
      stat.to_s.should_not be_empty
      stat.to_s.size.should be > 0
    end
    
    stats_count.should be > 0
    
    stats_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
end
