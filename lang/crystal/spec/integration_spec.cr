require "./spec_helper"

describe "WiredTiger Integration Scenarios" do
  it "handles complex transaction scenarios with multiple tables" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables
    session.create("table:users", "key_format=S,value_format=S")
    session.create("table:orders", "key_format=S,value_format=S")
    session.create("table:products", "key_format=S,value_format=S")
    
    # Begin transaction
    session.begin_transaction
    
    # Insert data into multiple tables
    user_cursor = session.open_cursor("table:users")
    user_cursor.put_key_string("user1")
    user_cursor.put_value_string("John Doe")
    user_cursor.insert
    user_cursor.close
    
    product_cursor = session.open_cursor("table:products")
    product_cursor.put_key_string("prod1")
    product_cursor.put_value_string("Laptop")
    product_cursor.insert
    product_cursor.close
    
    order_cursor = session.open_cursor("table:orders")
    order_cursor.put_key_string("order1")
    order_cursor.put_value_string("user1:prod1")
    order_cursor.insert
    order_cursor.close
    
    # Commit transaction
    session.commit_transaction
    
    # Verify all data was committed
    user_cursor = session.open_cursor("table:users")
    user_cursor.put_key_string("user1")
    user_cursor.search
    user_cursor.get_value_string.should eq("John Doe")
    user_cursor.close
    
    product_cursor = session.open_cursor("table:products")
    product_cursor.put_key_string("prod1")
    product_cursor.search
    product_cursor.get_value_string.should eq("Laptop")
    product_cursor.close
    
    order_cursor = session.open_cursor("table:orders")
    order_cursor.put_key_string("order1")
    order_cursor.search
    order_cursor.get_value_string.should eq("user1:prod1")
    order_cursor.close
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 35).should be_true
  end
  
  it "handles nested transaction scenarios" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:nested_txn", "key_format=S,value_format=S")
    
    # Insert initial data
    cursor = session.open_cursor("table:nested_txn")
    cursor.put_key_string("initial")
    cursor.put_value_string("initial_value")
    cursor.insert
    cursor.close
    
    # Begin outer transaction
    session.begin_transaction
    
    # Insert data in outer transaction
    cursor = session.open_cursor("table:nested_txn")
    cursor.put_key_string("outer")
    cursor.put_value_string("outer_value")
    cursor.insert
    cursor.close
    
    # Begin inner transaction (this should fail, but handle gracefully)
    begin
      session.begin_transaction
      
      cursor = session.open_cursor("table:nested_txn")
      cursor.put_key_string("inner")
      cursor.put_value_string("inner_value")
      cursor.insert
      cursor.close
      
      session.commit_transaction
      
    rescue ex : WiredTiger::DB::WiredTigerException
      # Expected behavior - nested transactions not supported
      ex.message.should_not be_nil
      
      # Rollback the outer transaction since it's now in a failed state
      session.rollback_transaction
      
      # Begin a new transaction for the outer operations
      session.begin_transaction
      
      # Re-insert the outer data
      cursor = session.open_cursor("table:nested_txn")
      cursor.put_key_string("outer")
      cursor.put_value_string("outer_value")
      cursor.insert
      cursor.close
    end
    
    # Commit outer transaction
    session.commit_transaction
    
    # Verify data
    cursor = session.open_cursor("table:nested_txn")
    cursor.put_key_string("initial")
    cursor.search
    cursor.get_value_string.should eq("initial_value")
    
    cursor.put_key_string("outer")
    cursor.search
    cursor.get_value_string.should eq("outer_value")
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles complex modify operations with transactions" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:complex_modify", "key_format=S,value_format=S")
    
    # Insert initial data
    cursor = session.open_cursor("table:complex_modify")
    cursor.put_key_string("complex_key")
    cursor.put_value_string("Hello World")
    cursor.insert
    cursor.close
    
    # Begin transaction with snapshot isolation
    session.begin_transaction("isolation=snapshot")
    
    cursor = session.open_cursor("table:complex_modify")
    cursor.put_key_string("complex_key")
    cursor.search
    
    # Perform complex modify operations
    modifications = [
      WiredTiger::DB::Modify.insert(" there", 5),           # Insert at position 5
      WiredTiger::DB::Modify.replace("beautiful", 12, 5),   # Replace "World" with "beautiful" at position 12
      WiredTiger::DB::Modify.insert("!", 21)                # Add exclamation right after "beautiful"
    ]
    
    cursor.modify(modifications)
    cursor.close
    
    # Commit transaction
    session.commit_transaction
    
    # Verify modifications
    cursor = session.open_cursor("table:complex_modify")
    cursor.put_key_string("complex_key")
    cursor.search
    result = cursor.get_value_string
    result.should eq("Hello there beautiful!")
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles statistics with complex operations" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create multiple tables
    session.create("table:stats_integration_1", "key_format=S,value_format=S")
    session.create("table:stats_integration_2", "key_format=S,value_format=S")
    
    # Perform operations to generate statistics
    tables = ["stats_integration_1", "stats_integration_2"]
    
    tables.each do |table_name|
      cursor = session.open_cursor("table:#{table_name}")
      
      # Insert data
      50.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.put_value_string("value_#{i}" * 10)
        cursor.insert
      end
      
      # Update some data
      25.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.search
        cursor.put_value_string("updated_value_#{i}" * 15)
        cursor.update
      end
      
      # Remove some data
      10.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.search
        cursor.remove
      end
      
      cursor.close
    end
    
    # Collect comprehensive statistics
    all_stats = session.get_all_statistics
    table1_stats = session.get_table_statistics("stats_integration_1")
    table2_stats = session.get_table_statistics("stats_integration_2")
    session_stats = session.get_session_statistics
    
    # Verify statistics are meaningful
    all_stats.size.should be > 0
    table1_stats.size.should be > 0
    table2_stats.size.should be > 0
    session_stats.size.should be > 0
    
    # Check for specific statistics
    has_inserts = table1_stats.any? { |desc, _| desc.includes?("insert") }
    has_updates = table1_stats.any? { |desc, _| desc.includes?("update") }
    has_removes = table1_stats.any? { |desc, _| desc.includes?("remove") }
    
    has_inserts.should be_true
    has_updates.should be_true
    has_removes.should be_true
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 35).should be_true
  end
  
  it "handles mixed data types in complex scenarios" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create tables with different data types
    session.create("table:mixed_strings", "key_format=S,value_format=S")
    session.create("table:mixed_integers", "key_format=q,value_format=q")
    session.create("table:mixed_bytes", "key_format=u,value_format=u")
    
    # Test string operations
    string_cursor = session.open_cursor("table:mixed_strings")
    string_cursor.put_key_string("string_key")
    string_cursor.put_value_string("string_value")
    string_cursor.insert
    string_cursor.close
    
    # Test integer operations
    int_cursor = session.open_cursor("table:mixed_integers")
    int_cursor.put_key_int(42_i64)
    int_cursor.put_value_int(100_i64)
    int_cursor.insert
    int_cursor.close
    
    # Test bytes operations
    bytes_cursor = session.open_cursor("table:mixed_bytes")
    bytes_cursor.put_key_bytes("bytes_key".to_slice)
    bytes_cursor.put_value_bytes("bytes_value".to_slice)
    bytes_cursor.insert
    bytes_cursor.close
    
    # Verify all data types
    string_cursor = session.open_cursor("table:mixed_strings")
    string_cursor.put_key_string("string_key")
    string_cursor.search
    string_cursor.get_value_string.should eq("string_value")
    string_cursor.close
    
    int_cursor = session.open_cursor("table:mixed_integers")
    int_cursor.put_key_int(42_i64)
    int_cursor.search
    int_cursor.get_value_int.should eq(100_i64)
    int_cursor.close
    
    bytes_cursor = session.open_cursor("table:mixed_bytes")
    bytes_cursor.put_key_bytes("bytes_key".to_slice)
    bytes_cursor.search
    bytes_cursor.get_value_bytes.should eq("bytes_value".to_slice)
    bytes_cursor.close
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 40).should be_true
  end
  
  it "handles cursor operations across multiple tables" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables
    session.create("table:cursor_multi_1", "key_format=S,value_format=S")
    session.create("table:cursor_multi_2", "key_format=S,value_format=S")
    session.create("table:cursor_multi_3", "key_format=S,value_format=S")
    
    tables = ["cursor_multi_1", "cursor_multi_2", "cursor_multi_3"]
    
    # Populate all tables
    tables.each_with_index do |table_name, table_index|
      cursor = session.open_cursor("table:#{table_name}")
      
      20.times do |i|
        cursor.put_key_string("table_#{table_index}_key_#{i}")
        cursor.put_value_string("table_#{table_index}_value_#{i}")
        cursor.insert
      end
      
      cursor.close
    end
    
    # Test operations across multiple tables
    cursors = tables.map { |table_name| session.open_cursor("table:#{table_name}") }
    
    # Perform operations on all cursors
    cursors.each_with_index do |cursor, table_index|
      # Navigate to first record
      cursor.put_key_string("table_#{table_index}_key_0")
      cursor.search
      cursor.get_value_string.should eq("table_#{table_index}_value_0")
      
      # Navigate to last record
      cursor.put_key_string("table_#{table_index}_key_19")
      cursor.search
      cursor.get_value_string.should eq("table_#{table_index}_value_19")
    end
    
    # Close all cursors
    cursors.each(&.close)
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 40).should be_true
  end
  
  it "handles error recovery scenarios" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:error_recovery", "key_format=S,value_format=S")
    
    # Test scenario where we encounter errors but continue
    begin
      # Try to create duplicate table (should fail)
      session.create("table:error_recovery", "key_format=S,value_format=S")
    rescue ex : WiredTiger::DB::WiredTigerException
      # Expected error
      ex.message.should_not be_nil
    end
    
    # Continue with normal operations
    cursor = session.open_cursor("table:error_recovery")
    cursor.put_key_string("recovery_key")
    cursor.put_value_string("recovery_value")
    cursor.insert
    cursor.close
    
    # Verify data was inserted despite previous error
    cursor = session.open_cursor("table:error_recovery")
    cursor.put_key_string("recovery_key")
    cursor.search
    cursor.get_value_string.should eq("recovery_value")
    cursor.close
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles resource cleanup in complex scenarios" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables and cursors
    session.create("table:cleanup_test_1", "key_format=S,value_format=S")
    session.create("table:cleanup_test_2", "key_format=S,value_format=S")
    
    cursors = [] of WiredTiger::DB::Cursor
    
    # Create multiple cursors
    5.times do |i|
      cursor = session.open_cursor("table:cleanup_test_1")
      cursors << cursor
      
      cursor.put_key_string("cleanup_key_#{i}")
      cursor.put_value_string("cleanup_value_#{i}")
      cursor.insert
    end
    
    # Close cursors in reverse order
    cursors.reverse.each(&.close)
    
    # Verify cursors are closed
    cursors.each do |cursor|
      cursor.closed?.should be_true
    end
    
    # Continue with new operations
    new_cursor = session.open_cursor("table:cleanup_test_1")
    new_cursor.put_key_string("new_key")
    new_cursor.search.should eq(-31803) # WT_NOTFOUND
    
    new_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 35).should be_true
  end
  
  it "handles concurrent operations gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:concurrent_integration", "key_format=S,value_format=S")
    
    # Test concurrent-like operations (not truly concurrent, but testing the pattern)
    cursors = [] of WiredTiger::DB::Cursor
    
    # Create multiple cursors
    3.times do |i|
      cursor = session.open_cursor("table:concurrent_integration")
      cursors << cursor
      
      # Each cursor performs operations
      cursor.put_key_string("concurrent_key_#{i}")
      cursor.put_value_string("concurrent_value_#{i}")
      cursor.insert
    end
    
    # Verify all operations succeeded
    cursors.each_with_index do |cursor, i|
      cursor.put_key_string("concurrent_key_#{i}")
      cursor.search
      cursor.get_value_string.should eq("concurrent_value_#{i}")
    end
    
    # Close all cursors
    cursors.each(&.close)
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
end
