require "./spec_helper"

describe "WiredTiger Transactions" do
  it "supports basic transaction operations" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:accounts", "key_format=S,value_format=i")
    cursor = session.open_cursor("table:accounts")
    
    # Insert initial data
    cursor.put_key_string("account1")
    cursor.put_value_int(100_i64)
    cursor.insert.should eq(0)
    
    cursor.put_key_string("account2")
    cursor.put_value_int(200_i64)
    cursor.insert.should eq(0)
    
    cursor.close
    
    # Begin transaction
    session.begin_transaction
    
    # Update account1
    cursor = session.open_cursor("table:accounts")
    cursor.put_key_string("account1")
    cursor.search.should eq(0)
    current_balance = cursor.get_value_int
    cursor.put_value_int(current_balance - 50)
    cursor.update.should eq(0)
    
    # Update account2
    cursor.put_key_string("account2")
    cursor.search.should eq(0)
    current_balance = cursor.get_value_int
    cursor.put_value_int(current_balance + 50)
    cursor.update.should eq(0)
    
    cursor.close
    
    # Commit transaction
    session.commit_transaction
    
    # Verify changes were committed
    cursor = session.open_cursor("table:accounts")
    cursor.put_key_string("account1")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(50_i64)
    
    cursor.put_key_string("account2")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(250_i64)
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports transaction rollback" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:test_rollback", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:test_rollback")
    
    # Insert initial data
    cursor.put_key_string("key1")
    cursor.put_value_string("value1")
    cursor.insert.should eq(0)
    
    cursor.close
    
    # Begin transaction
    session.begin_transaction
    
    # Make changes
    cursor = session.open_cursor("table:test_rollback")
    cursor.put_key_string("key2")
    cursor.put_value_string("value2")
    cursor.insert.should eq(0)
    
    cursor.put_key_string("key1")
    cursor.search.should eq(0)
    cursor.put_value_string("modified_value1")
    cursor.update.should eq(0)
    
    cursor.close
    
    # Rollback transaction
    session.rollback_transaction
    
    # Verify changes were rolled back
    cursor = session.open_cursor("table:test_rollback")
    cursor.put_key_string("key1")
    cursor.search.should eq(0)
    cursor.get_value_string.should eq("value1")  # Should be original value
    
    # key2 should not exist
    cursor.put_key_string("key2")
    cursor.search.should eq(-31803)  # WT_NOTFOUND
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports transaction isolation levels" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:isolation_test", "key_format=S,value_format=i")
    cursor = session.open_cursor("table:isolation_test")
    
    # Insert initial data
    cursor.put_key_string("counter")
    cursor.put_value_int(0_i64)
    cursor.insert.should eq(0)
    
    cursor.close
    
    # Test snapshot isolation
    session.begin_transaction("isolation=snapshot")
    
    cursor = session.open_cursor("table:isolation_test")
    cursor.put_key_string("counter")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(0_i64)
    
    cursor.close
    session.commit_transaction
    
    # Test read-committed isolation
    session.begin_transaction("isolation=read-committed")
    
    cursor = session.open_cursor("table:isolation_test")
    cursor.put_key_string("counter")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(0_i64)
    
    cursor.close
    session.commit_transaction
    
    # Test read-uncommitted isolation
    session.begin_transaction("isolation=read-uncommitted")
    
    cursor = session.open_cursor("table:isolation_test")
    cursor.put_key_string("counter")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(0_i64)
    
    cursor.close
    session.commit_transaction
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "handles transaction conflicts gracefully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:conflict_test", "key_format=S,value_format=i")
    cursor = session.open_cursor("table:conflict_test")
    
    # Insert initial data
    cursor.put_key_string("conflict_key")
    cursor.put_value_int(100_i64)
    cursor.insert.should eq(0)
    
    cursor.close
    
    # First transaction
    session.begin_transaction
    
    cursor = session.open_cursor("table:conflict_test")
    cursor.put_key_string("conflict_key")
    cursor.search.should eq(0)
    cursor.put_value_int(200_i64)
    cursor.update.should eq(0)
    
    cursor.close
    
    # Second transaction (this should conflict)
    session2 = conn.open_session
    session2.begin_transaction
    
    cursor2 = session2.open_cursor("table:conflict_test")
    cursor2.put_key_string("conflict_key")
    cursor2.search.should eq(0)
    cursor2.put_value_int(300_i64)
    
    # This should fail due to conflict
    expect_raises(WiredTiger::DB::WiredTigerException) do
      cursor2.update
    end
    
    cursor2.close
    session2.rollback_transaction
    session2.close
    
    # First transaction should still work
    session.commit_transaction
    
    # Verify first transaction's changes were committed
    cursor = session.open_cursor("table:conflict_test")
    cursor.put_key_string("conflict_key")
    cursor.search.should eq(0)
    cursor.get_value_int.should eq(200_i64)
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports nested operations within transactions" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables
    session.create("table:users", "key_format=S,value_format=S")
    session.create("table:profiles", "key_format=S,value_format=S")
    session.create("table:settings", "key_format=S,value_format=S")
    
    # Begin transaction
    session.begin_transaction
    
    # Insert into users table
    cursor = session.open_cursor("table:users")
    cursor.put_key_string("user1")
    cursor.put_value_string("john_doe")
    cursor.insert.should eq(0)
    cursor.close
    
    # Insert into profiles table
    cursor = session.open_cursor("table:profiles")
    cursor.put_key_string("user1")
    cursor.put_value_string("John Doe Profile")
    cursor.insert.should eq(0)
    cursor.close
    
    # Insert into settings table
    cursor = session.open_cursor("table:settings")
    cursor.put_key_string("user1")
    cursor.put_value_string("User Settings")
    cursor.insert.should eq(0)
    cursor.close
    
    # Commit all changes atomically
    session.commit_transaction
    
    # Verify all data was committed
    cursor = session.open_cursor("table:users")
    cursor.put_key_string("user1")
    cursor.search.should eq(0)
    cursor.get_value_string.should eq("john_doe")
    cursor.close
    
    cursor = session.open_cursor("table:profiles")
    cursor.put_key_string("user1")
    cursor.search.should eq(0)
    cursor.get_value_string.should eq("John Doe Profile")
    cursor.close
    
    cursor = session.open_cursor("table:settings")
    cursor.put_key_string("user1")
    cursor.search.should eq(0)
    cursor.get_value_string.should eq("User Settings")
    cursor.close
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "handles transaction timeout configuration" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:timeout_test", "key_format=S,value_format=i")
    
    # Test transaction with timeout configuration
    session.begin_transaction("operation_timeout_ms=1000")
    
    cursor = session.open_cursor("table:timeout_test")
    cursor.put_key_string("timeout_key")
    cursor.put_value_int(42_i64)
    cursor.insert.should eq(0)
    
    cursor.close
    
    # Commit should work within timeout
    session.commit_transaction
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports transaction naming for debugging" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table for testing
    session.create("table:named_txn_test", "key_format=S,value_format=S")
    
    # Begin transaction with name
    session.begin_transaction("name=test_transaction")
    
    cursor = session.open_cursor("table:named_txn_test")
    cursor.put_key_string("named_key")
    cursor.put_value_string("named_value")
    cursor.insert.should eq(0)
    
    cursor.close
    
    # Commit named transaction
    session.commit_transaction
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
end
