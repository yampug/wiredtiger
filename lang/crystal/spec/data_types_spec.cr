require "./spec_helper"

describe "WiredTiger Data Types" do
  it "supports integer keys and values" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table with integer key and value formats
    session.create("table:integers", "key_format=q,value_format=q")
    cursor = session.open_cursor("table:integers")
    
    # Insert integer data
    cursor.put_key_int(42_i64)
    cursor.put_value_int(100_i64)
    cursor.insert.should eq(0)
    
    cursor.put_key_int(123_i64)
    cursor.put_value_int(456_i64)
    cursor.insert.should eq(0)
    
    # Search and retrieve data
    cursor.put_key_int(42_i64)
    cursor.search.should eq(0)
    cursor.get_key_int.should eq(42_i64)
    cursor.get_value_int.should eq(100_i64)
    
    cursor.put_key_int(123_i64)
    cursor.search.should eq(0)
    cursor.get_key_int.should eq(123_i64)
    cursor.get_value_int.should eq(456_i64)
    
    # Clean up
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  # Float format not supported by WiredTiger natively
  # it "supports float keys and values" do
  #   test_dir = ENV["WIREDTIGER_TEST_DIR"]
  #   conn = WiredTiger::WiredTiger.open(test_dir, "create")
  #   session = conn.open_session
  #   
  #   # Create table with float key and value formats
  #   session.create("table:floats", "key_format=d,value_format=d")
  #   cursor = session.open_cursor("table:floats")
  #   
  #   # Insert float data
  #   cursor.put_key_float(3.14_f64)
  #   cursor.put_value_float(2.718_f64)
  #   cursor.insert.should eq(0)
  #   
  #   cursor.put_key_float(1.618_f64)
  #   cursor.put_value_float(0.577_f64)
  #   cursor.insert.should eq(0)
  #   
  #   # Search and retrieve data
  #   cursor.put_key_float(3.14_f64)
  #   cursor.search.should eq(0)
  #   cursor.get_key_float.should be_close(3.14_f64, 0.001_f64)
  #   cursor.get_key_float.should be_close(2.718_f64, 0.001_f64)
  #   
  #   cursor.put_key_float(1.618_f64)
  #   cursor.search.should eq(0)
  #   cursor.get_key_float.should be_close(1.618_f64, 0.001_f64)
  #   cursor.get_key_float.should be_close(0.577_f64, 0.001_f64)
  #   
  #   # Clean up
  #   cursor.close
  #   session.close
  #   conn.close
  #   
  #   # Verify database file was created with sufficient size
  #   DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  # end
  
  it "supports bytes keys and values" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create table with bytes key and value formats
    session.create("table:bytes", "key_format=u,value_format=u")
    cursor = session.open_cursor("table:bytes")
    
    # Create test bytes data
    key1 = "hello".to_slice
    value1 = "world".to_slice
    key2 = "crystal".to_slice
    value2 = "bindings".to_slice
    
    # Insert bytes data
    cursor.put_key_bytes(key1)
    cursor.put_value_bytes(value1)
    cursor.insert.should eq(0)
    
    cursor.put_key_bytes(key2)
    cursor.put_value_bytes(value2)
    cursor.insert.should eq(0)
    
    # Search and retrieve data
    cursor.put_key_bytes(key1)
    cursor.search.should eq(0)
    retrieved_key1 = cursor.get_key_bytes
    retrieved_value1 = cursor.get_value_bytes
    
    retrieved_key1.should eq(key1)
    retrieved_value1.should eq(value1)
    
    cursor.put_key_bytes(key2)
    cursor.search.should eq(0)
    retrieved_key2 = cursor.get_key_bytes
    retrieved_value2 = cursor.get_value_bytes
    
    retrieved_key2.should eq(key2)
    retrieved_value2.should eq(value2)
    
    # Clean up
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "supports mixed data types in different tables" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables with different data types
    session.create("table:strings", "key_format=S,value_format=S")
    session.create("table:integers", "key_format=q,value_format=q")
    # session.create("table:floats", "key_format=d,value_format=d")  # Float format not supported
    session.create("table:bytes", "key_format=u,value_format=u")
    
    # Test string table
    cursor = session.open_cursor("table:strings")
    cursor.put_key_string("string_key")
    cursor.put_value_string("string_value")
    cursor.insert.should eq(0)
    cursor.close
    
    # Test integer table
    cursor = session.open_cursor("table:integers")
    cursor.put_key_int(42_i64)
    cursor.put_value_int(100_i64)
    cursor.insert.should eq(0)
    cursor.close
    
    # Test float table (commented out - float format not supported)
    # cursor = session.open_cursor("table:floats")
    # cursor.put_key_float(3.14_f64)
    # cursor.put_value_float(2.718_f64)
    # cursor.insert.should eq(0)
    # cursor.close
    
    # Test bytes table
    cursor = session.open_cursor("table:bytes")
    cursor.put_key_bytes("bytes_key".to_slice)
    cursor.put_value_bytes("bytes_value".to_slice)
    cursor.insert.should eq(0)
    cursor.close
    
    # Clean up
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  it "handles large integer values correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    session.create("table:large_ints", "key_format=q,value_format=q")
    cursor = session.open_cursor("table:large_ints")
    
    # Test large integer values
    large_key = 9223372036854775807_i64  # Max int64
    large_value = -9223372036854775808_i64 # Min int64
    
    cursor.put_key_int(large_key)
    cursor.put_value_int(large_value)
    cursor.insert.should eq(0)
    
    # Verify retrieval
    cursor.put_key_int(large_key)
    cursor.search.should eq(0)
    cursor.get_key_int.should eq(large_key)
    cursor.get_value_int.should eq(large_value)
    
    cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  end
  
  # Float format not supported by WiredTiger natively
  # it "handles precision float values correctly" do
  #   test_dir = ENV["WIREDTIGER_TEST_DIR"]
  #   conn = WiredTiger::WiredTiger.open(test_dir, "create")
  #   session = conn.open_session
  #   
  #   session.create("table:precision_floats", "key_format=d,value_format=d")
  #   cursor = session.open_cursor("table:precision_floats")
  #   
  #   # Test precision float values
  #   pi = Math::PI
  #   e = Math::E
  #   
  #   cursor.put_key_float(pi)
  #   cursor.put_value_float(e)
  #   cursor.insert.should eq(0)
  #   
  #   # Verify retrieval with reasonable precision
  #   cursor.put_key_float(pi)
  #   cursor.search.should eq(0)
  #   cursor.get_key_float.should be_close(pi, 0.000001_f64)
  #   cursor.get_key_float.should be_close(e, 0.000001_f64)
  #   
  #   cursor.close
  #   session.close
  #   conn.close
  #   
  #   # Verify database file was created with sufficient size
  #   DatabaseFileVerifier.verify_database_file(test_dir).should be_true
  # end
end
