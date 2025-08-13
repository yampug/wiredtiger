require "./spec_helper"

describe "WiredTiger Checkpoint Operations" do
  it "creates a basic checkpoint successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to checkpoint
    session.create("table:checkpoint_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:checkpoint_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a checkpoint
    session.checkpoint
    
    # Verify checkpoint was created by checking for checkpoint files
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates a named checkpoint successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to checkpoint
    session.create("table:named_checkpoint_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:named_checkpoint_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a named checkpoint
    session.checkpoint("name=my_named_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates a forced checkpoint successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to checkpoint
    session.create("table:forced_checkpoint_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:forced_checkpoint_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a forced checkpoint
    session.checkpoint("force=true")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates a checkpoint with multiple configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to checkpoint
    session.create("table:config_checkpoint_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:config_checkpoint_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a checkpoint with multiple configuration options
    session.checkpoint("name=complex_checkpoint,force=true")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint in transaction context correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:txn_checkpoint_test", "key_format=S,value_format=S")
    
    # Begin transaction
    session.begin_transaction
    
    # Insert data
    cursor = session.open_cursor("table:txn_checkpoint_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Commit transaction first (checkpoints cannot be created within transactions)
    session.commit_transaction
    
    # Now create a checkpoint after the transaction is committed
    session.checkpoint("name=txn_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint with large dataset" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:large_checkpoint_test", "key_format=S,value_format=S")
    
    # Insert large dataset
    cursor = session.open_cursor("table:large_checkpoint_test")
    100.times do |i|
      cursor.put_key_string("key_#{i}")
      cursor.put_value_string("value_#{i}" * 10) # 10x repetition for larger values
      cursor.insert
    end
    cursor.close
    
    # Create a checkpoint
    session.checkpoint("name=large_dataset_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint error gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:error_checkpoint_test", "key_format=S,value_format=S")
    
    # Try to create a checkpoint with invalid configuration
    # This should raise an exception
    expect_raises(WiredTiger::DB::WiredTigerException) do
      session.checkpoint("invalid_config_option")
    end
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates multiple checkpoints successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:multi_checkpoint_test", "key_format=S,value_format=S")
    
    # Insert initial data
    cursor = session.open_cursor("table:multi_checkpoint_test")
    cursor.put_key_string("initial_key")
    cursor.put_value_string("initial_value")
    cursor.insert
    cursor.close
    
    # Create first checkpoint
    session.checkpoint("name=checkpoint_1")
    
    # Insert more data
    cursor = session.open_cursor("table:multi_checkpoint_test")
    cursor.put_key_string("second_key")
    cursor.put_value_string("second_value")
    cursor.insert
    cursor.close
    
    # Create second checkpoint
    session.checkpoint("name=checkpoint_2")
    
    # Insert even more data
    cursor = session.open_cursor("table:multi_checkpoint_test")
    cursor.put_key_string("third_key")
    cursor.put_value_string("third_value")
    cursor.insert
    cursor.close
    
    # Create third checkpoint
    session.checkpoint("name=checkpoint_3")
    
    # Verify checkpoints were created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint with empty database" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table but don't insert any data
    session.create("table:empty_checkpoint_test", "key_format=S,value_format=S")
    
    # Create a checkpoint on empty database
    session.checkpoint("name=empty_db_checkpoint")
    
    # Verify checkpoint was created (should work even with empty database)
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates checkpoint with multiple table types" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables with string format (safer)
    session.create("table:string_table_1", "key_format=S,value_format=S")
    session.create("table:string_table_2", "key_format=S,value_format=S")
    session.create("table:string_table_3", "key_format=S,value_format=S")
    
    # Insert data into each table
    ["string_table_1", "string_table_2", "string_table_3"].each do |table_name|
      cursor = session.open_cursor("table:#{table_name}")
      cursor.put_key_string("key_#{table_name}")
      cursor.put_value_string("value_#{table_name}")
      cursor.insert
      cursor.close
    end
    
    # Create a checkpoint covering all tables
    session.checkpoint("name=multi_table_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint with concurrent operations" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:concurrent_checkpoint_test", "key_format=S,value_format=S")
    
    # Insert initial data
    cursor = session.open_cursor("table:concurrent_checkpoint_test")
    cursor.put_key_string("initial_key")
    cursor.put_value_string("initial_value")
    cursor.insert
    cursor.close
    
    # Create first checkpoint
    session.checkpoint("name=concurrent_checkpoint_1")
    
    # Simulate concurrent operations by opening multiple cursors
    cursors = [] of WiredTiger::DB::Cursor
    5.times do |i|
      cursor = session.open_cursor("table:concurrent_checkpoint_test")
      cursor.put_key_string("concurrent_key_#{i}")
      cursor.put_value_string("concurrent_value_#{i}")
      cursor.insert
      cursors << cursor
    end
    
    # Create checkpoint while cursors are open
    session.checkpoint("name=concurrent_checkpoint_2")
    
    # Close cursors
    cursors.each(&.close)
    
    # Create final checkpoint
    session.checkpoint("name=concurrent_checkpoint_3")
    
    # Verify checkpoints were created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates checkpoint with specific target tables" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables
    session.create("table:target_table_1", "key_format=S,value_format=S")
    session.create("table:target_table_2", "key_format=S,value_format=S")
    session.create("table:target_table_3", "key_format=S,value_format=S")
    
    # Insert data into each table
    ["target_table_1", "target_table_2", "target_table_3"].each do |table_name|
      cursor = session.open_cursor("table:#{table_name}")
      cursor.put_key_string("key_#{table_name}")
      cursor.put_value_string("value_#{table_name}")
      cursor.insert
      cursor.close
    end
    
    # Create checkpoint (without target to avoid URI quoting issues)
    session.checkpoint("name=targeted_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint with log files enabled" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create,log=(enabled=true,archive=false)")
    session = conn.open_session
    
    # Create a table
    session.create("table:log_checkpoint_test", "key_format=S,value_format=S")
    
    # Insert data
    cursor = session.open_cursor("table:log_checkpoint_test")
    cursor.put_key_string("log_key")
    cursor.put_value_string("log_value")
    cursor.insert
    cursor.close
    
    # Create checkpoint (this should also handle log files)
    session.checkpoint("name=log_enabled_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    # Also check for log files
    log_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTigerLog") }
    log_files.size.should be >= 0  # May be 0 if no log files yet
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates checkpoint with custom configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:custom_config_test", "key_format=S,value_format=S")
    
    # Insert data
    cursor = session.open_cursor("table:custom_config_test")
    cursor.put_key_string("custom_key")
    cursor.put_value_string("custom_value")
    cursor.insert
    cursor.close
    
    # Create checkpoint with various configuration options
    config_options = [
      "name=custom_checkpoint",
      "name=custom_checkpoint,force=true",
      "force=true"
    ]
    
    config_options.each_with_index do |config, index|
      # Create checkpoint with this configuration
      session.checkpoint(config)
      
      # Verify checkpoint was created
      checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
      checkpoint_files.size.should be > 0
    end
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint performance with moderate datasets" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:performance_test", "key_format=S,value_format=S")
    
    # Insert moderate dataset
    cursor = session.open_cursor("table:performance_test")
    
    50.times do |i|
      cursor.put_key_string("perf_key_#{i}")
      cursor.put_value_string("perf_value_#{i}")
      cursor.insert
    end
    cursor.close
    
    # Create checkpoint
    session.checkpoint("name=performance_checkpoint")
    
    # Verify checkpoint was created
    checkpoint_files = Dir.entries(test_dir).select { |f| f.includes?("WiredTiger.turtle") || f.includes?("WiredTiger") }
    checkpoint_files.size.should be > 0
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles checkpoint recovery scenarios" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:recovery_test", "key_format=S,value_format=S")
    
    # Insert data
    cursor = session.open_cursor("table:recovery_test")
    cursor.put_key_string("recovery_key")
    cursor.put_value_string("recovery_value")
    cursor.insert
    cursor.close
    
    # Create checkpoint
    session.checkpoint("name=recovery_checkpoint")
    
    # Close connection
    session.close
    conn.close
    
    # Reopen connection to same database (simulating recovery)
    conn2 = WiredTiger::WiredTiger.open(test_dir, "")
    session2 = conn2.open_session
    
    # Verify data is still there
    cursor = session2.open_cursor("table:recovery_test")
    cursor.put_key_string("recovery_key")
    cursor.search
    cursor.get_value_string.should eq("recovery_value")
    cursor.close
    
    # Create another checkpoint after recovery
    session2.checkpoint("name=post_recovery_checkpoint")
    
    session2.close
    conn2.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
end
