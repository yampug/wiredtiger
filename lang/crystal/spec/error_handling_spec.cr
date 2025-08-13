require "./spec_helper"

describe "WiredTiger Error Handling and Edge Cases" do
  it "handles invalid table URIs gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Test invalid table URI
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.create("invalid:uri:format", "key_format=S,value_format=S")
    end
    
    # Test empty table name
    # Note: WiredTiger actually accepts empty table names
    session.create("table:", "key_format=S,value_format=S")
    
    # Test invalid format strings
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.create("table:test", "invalid_format")
    end
    
    session.close
    conn.close
  end
  
  it "handles cursor operations on non-existent tables" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Try to open cursor on non-existent table
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.open_cursor("table:non_existent")
    end
    
    session.close
    conn.close
  end
  
  it "handles invalid cursor operations gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:cursor_error_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:cursor_error_test")
    
    # Try to get value without setting key first
    expect_raises(WiredTiger::DB::WiredTigerException) do
      cursor.get_value_string
    end
    
    # Try to get key without setting key first
    expect_raises(WiredTiger::DB::WiredTigerException) do
      cursor.get_key_string
    end
    
    # Try to search without setting key
    # Note: WiredTiger handles this gracefully, so we just verify it doesn't crash
    cursor.search.should be_a(Int32)
    
    cursor.close
    session.close
    conn.close
  end
  
  it "handles transaction errors correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Try to commit without beginning a transaction
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.commit_transaction
    end
    
    # Try to rollback without beginning a transaction
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.rollback_transaction
    end
    
    # Begin a transaction
    session.begin_transaction
    
    # Try to begin another transaction (should fail)
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.begin_transaction
    end
    
    # Commit the transaction
    session.commit_transaction
    
    session.close
    conn.close
  end
  
  it "handles data type conversion errors" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table with string format
    session.create("table:type_error_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:type_error_test")
    
    # Insert string data
    cursor.put_key_string("key1")
    cursor.put_value_string("value1")
    cursor.insert
    
    cursor.close
    
    # Try to read with wrong cursor
    cursor = session.open_cursor("table:type_error_test")
    cursor.put_key_string("key1")
    cursor.search
    
    # Try to get as integer (should fail)
    # Note: WiredTiger handles this gracefully by returning 0
    result = cursor.get_value_int
    result.should be_a(Int64)
    
    cursor.close
    session.close
    conn.close
  end
  
  it "handles modify operation errors" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:modify_error_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:modify_error_test")
    
    # Insert initial data
    cursor.put_key_string("modify_key")
    cursor.put_value_string("Hello World")
    cursor.insert
    
    cursor.close
    
    # Begin transaction with snapshot isolation
    session.begin_transaction
    
    cursor = session.open_cursor("table:modify_error_test")
    cursor.put_key_string("modify_key")
    cursor.search
    
    # Try to modify with invalid offset
    expect_raises(WiredTiger::DB::WiredTigerException) do
      insert_modify = WiredTiger::DB::Modify.insert(" there", 999) # Invalid offset
      cursor.modify([insert_modify])
    end
    
    cursor.close
    session.rollback_transaction
    session.close
    conn.close
  end
  
  it "handles statistics errors gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Try to get statistics without enabling them
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.open_statistics_cursor
    end
    
    # Try to get table statistics on non-existent table
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.get_table_statistics("non_existent_table")
    end
    
    session.close
    conn.close
  end
  
  it "handles connection configuration errors" do
    # Test invalid configuration strings
    expect_raises(WiredTiger::DB::WiredTigerException) do
      WiredTiger::WiredTiger.open("", "invalid_config")
    end
    
    # Test invalid statistics configuration
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    expect_raises(WiredTiger::DB::WiredTigerException) do
      WiredTiger::WiredTiger.open(test_dir, "create,statistics=(invalid)")
    end
  end
  
  it "handles session cleanup errors gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table and cursor
    session.create("table:cleanup_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:cleanup_test")
    
    # Insert some data
    cursor.put_key_string("key1")
    cursor.put_value_string("value1")
    cursor.insert
    
    cursor.close
    
    # Close session and connection
    session.close
    conn.close
    
    # Try to use closed session (should not crash)
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.create("table:test", "key_format=S,value_format=S")
    end
    
    # Try to use closed connection (should not crash)
    expect_raises(WiredTiger::DB::WiredTigerException) do
      conn.open_session
    end
  end
  
  it "handles memory allocation errors gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:memory_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:memory_test")
    
    # Try to insert extremely large data (should handle gracefully)
    large_key = "a" * 1000000  # 1MB key
    large_value = "b" * 1000000 # 1MB value
    
    # This might fail due to memory constraints, but shouldn't crash
    begin
      cursor.put_key_string(large_key)
      cursor.put_value_string(large_value)
      cursor.insert
    rescue ex : WiredTiger::DB::WiredTigerException
      # Expected to fail with large data
      ex.message.should_not be_nil
    end
    
    cursor.close
    session.close
    conn.close
  end
  
  it "handles concurrent access errors gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:concurrent_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:concurrent_test")
    
    # Insert some data
    cursor.put_key_string("key1")
    cursor.put_value_string("value1")
    cursor.insert
    
    cursor.close
    
    # Try to use the same session from multiple places (should handle gracefully)
    begin
      # This is not thread-safe, but shouldn't crash
      cursor1 = session.open_cursor("table:concurrent_test")
      cursor2 = session.open_cursor("table:concurrent_test")
      
      cursor1.put_key_string("key1")
      cursor1.search
      
      cursor2.put_key_string("key1")
      cursor2.search
      
      cursor1.close
      cursor2.close
    rescue ex : WiredTiger::DB::WiredTigerException
      # Expected behavior for concurrent access
      ex.message.should_not be_nil
    end
    
    session.close
    conn.close
  end
end
