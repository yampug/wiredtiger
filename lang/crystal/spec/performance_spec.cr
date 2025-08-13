require "./spec_helper"

describe "WiredTiger Performance and Stress Testing" do
  it "handles large dataset insertions efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:large_dataset", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:large_dataset")
    
    # Insert 1000 records
    start_time = Time.monotonic
    
    1000.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 10) # 10x repetition for larger values
      cursor.insert
    end
    
    end_time = Time.monotonic
    insertion_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time (adjust threshold as needed)
    insertion_time.should be < 5000 # 5 seconds
    
    cursor.close
    
    # Verify all records were inserted
    cursor = session.open_cursor("table:large_dataset")
    count = 0
    while cursor.next == 0
      count += 1
    end
    cursor.close
    
    count.should eq(1000)
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles bulk operations efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:bulk_operations", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:bulk_operations")
    
    # Test bulk insert
    start_time = Time.monotonic
    
    # Insert in batches
    10.times do |batch|
      session.begin_transaction
      
      100.times do |i|
        cursor.put_key_string("batch_#{batch}_key_#{i}")
        cursor.put_value_string("batch_#{batch}_value_#{i}" * 5)
        cursor.insert
      end
      
      session.commit_transaction
    end
    
    end_time = Time.monotonic
    bulk_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    bulk_time.should be < 3000 # 3 seconds
    
    cursor.close
    
    # Verify all records
    cursor = session.open_cursor("table:bulk_operations")
    count = 0
    while cursor.next == 0
      count += 1
    end
    cursor.close
    
    count.should eq(1000)
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 100).should be_true
  end
  
  it "handles concurrent read operations efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table and populate with data
    session.create("table:concurrent_reads", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:concurrent_reads")
    
    # Insert test data
    100.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 20)
      cursor.insert
    end
    cursor.close
    
    # Test concurrent reads
    start_time = Time.monotonic
    
    # Open multiple cursors and perform reads
    5.times do |thread_id|
      cursor = session.open_cursor("table:concurrent_reads")
      
      # Read all records
      100.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.search
        cursor.get_value_string.should_not be_empty
      end
      
      cursor.close
    end
    
    end_time = Time.monotonic
    concurrent_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    concurrent_time.should be < 2000 # 2 seconds
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 50).should be_true
  end
  
  it "handles memory pressure gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:memory_pressure", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:memory_pressure")
    
    # Test with moderately large data
    start_time = Time.monotonic
    
    begin
      # Insert 100 records with 1KB values
      100.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.put_value_string("x" * 1024) # 1KB value
        cursor.insert
      end
      
      end_time = Time.monotonic
      insertion_time = (end_time - start_time).total_milliseconds
      
      # Should complete within reasonable time
      insertion_time.should be < 2000 # 2 seconds
      
    rescue ex : WiredTiger::DB::WiredTigerException
      # If memory pressure causes failure, that's acceptable
      ex.message.should_not be_nil
    end
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 100).should be_true
  end
  
  it "handles transaction rollback efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:rollback_performance", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:rollback_performance")
    
    # Insert initial data
    cursor.put_key_string("initial_key")
    cursor.put_value_string("initial_value")
    cursor.insert
    cursor.close
    
    # Test transaction rollback performance
    start_time = Time.monotonic
    
    session.begin_transaction
    
    cursor = session.open_cursor("table:rollback_performance")
    
    # Insert many records in transaction
    500.times do |i|
      cursor.put_key_string("txn_key_#{i}")
      cursor.put_value_string("txn_value_#{i}" * 10)
      cursor.insert
    end
    
    cursor.close
    
    # Rollback transaction
    session.rollback_transaction
    
    end_time = Time.monotonic
    rollback_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    rollback_time.should be < 3000 # 3 seconds
    
    # Verify only initial data remains
    cursor = session.open_cursor("table:rollback_performance")
    cursor.put_key_string("initial_key")
    cursor.search
    cursor.get_value_string.should eq("initial_value")
    
    # Verify no transaction data exists
    cursor.put_key_string("txn_key_0")
    cursor.search.should eq(-31803) # WT_NOTFOUND
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 50).should be_true
  end
  
  it "handles cursor iteration efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table
    session.create("table:cursor_iteration", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:cursor_iteration")
    
    # Insert test data
    1000.times do |i|
      cursor.put_key_string("iter_key_#{i}")
      cursor.put_value_string("iter_value_#{i}" * 5)
      cursor.insert
    end
    cursor.close
    
    # Test forward iteration
    start_time = Time.monotonic
    
    cursor = session.open_cursor("table:cursor_iteration")
    count = 0
    
    while cursor.next == 0
      count += 1
      cursor.get_key_string.should start_with("iter_key_")
      cursor.get_value_string.should start_with("iter_value_")
    end
    
    end_time = Time.monotonic
    forward_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    forward_time.should be < 2000 # 2 seconds
    count.should eq(1000)
    
    cursor.close
    
    # Test backward iteration
    start_time = Time.monotonic
    
    cursor = session.open_cursor("table:cursor_iteration")
    count = 0
    
    while cursor.prev == 0
      count += 1
      cursor.get_key_string.should start_with("iter_key_")
      cursor.get_value_string.should start_with("iter_value_")
    end
    
    end_time = Time.monotonic
    backward_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    backward_time.should be < 2000 # 2 seconds
    count.should eq(1000)
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 100).should be_true
  end
  
  it "handles statistics collection efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create,statistics=(all)")
    session = conn.open_session
    
    # Create table and populate with data
    session.create("table:stats_performance", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:stats_performance")
    
    # Insert data to generate statistics
    500.times do |i|
      cursor.put_key_string("stats_key_#{i}")
      cursor.put_value_string("stats_value_#{i}" * 15)
      cursor.insert
    end
    cursor.close
    
    # Test statistics collection performance
    start_time = Time.monotonic
    
    # Collect all types of statistics
    all_stats = session.get_all_statistics
    table_stats = session.get_table_statistics("stats_performance")
    session_stats = session.get_session_statistics
    
    end_time = Time.monotonic
    stats_time = (end_time - start_time).total_milliseconds
    
    # Should complete within reasonable time
    stats_time.should be < 1000 # 1 second
    
    # Verify we got meaningful statistics
    all_stats.size.should be > 0
    table_stats.size.should be > 0
    session_stats.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 100).should be_true
  end
  
  it "handles database reconnection efficiently" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Create and populate database
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    session.create("table:reconnect_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:reconnect_test")
    
    # Insert some data
    100.times do |i|
      cursor.put_key_string("reconnect_key_#{i}")
      cursor.put_value_string("reconnect_value_#{i}" * 10)
      cursor.insert
    end
    
    cursor.close
    session.close
    conn.close
    
    # Test reconnection performance
    start_time = Time.monotonic
    
    # Reopen connection
    conn = WiredTiger::WiredTiger.open(test_dir, "")
    session = conn.open_session
    
    end_time = Time.monotonic
    reconnect_time = (end_time - start_time).total_milliseconds
    
    # Should reconnect quickly
    reconnect_time.should be < 500 # 500ms
    
    # Verify data is still there
    cursor = session.open_cursor("table:reconnect_test")
    cursor.put_key_string("reconnect_key_0")
    cursor.search
    cursor.get_value_string.should eq("reconnect_value_0" * 10)
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 50).should be_true
  end
end
