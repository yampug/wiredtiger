require "./spec_helper"

describe WiredTiger::WiredTiger do
  describe ".open" do
    it "opens a connection to a new database" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      conn.should be_a(WiredTiger::DB::Connection)
      conn.closed?.should be_false
      
      # Create a table and insert some data to ensure database file is created
      session = conn.open_session
      session.create("table:test", "key_format=S,value_format=S")
      cursor = session.open_cursor("table:test")
      
      # Insert multiple records to ensure sufficient database size
      10.times do |i|
        cursor.put_key_string("key_#{i}")
        cursor.put_value_string("value_#{i}" * 100) # Make values larger
        cursor.insert.should eq(0)
      end
      
      # Clean up
      cursor.close
      session.close
      conn.close
    end
    
    it "raises an exception for invalid database path" do
      expect_raises(WiredTiger::DB::WiredTigerException) do
        WiredTiger::WiredTiger.open("", "create")
      end
    end
  end
end

describe WiredTiger::DB::Connection do
  describe "#open_session" do
    it "opens a new session" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      
      session.should be_a(WiredTiger::DB::Session)
      session.closed?.should be_false
      
      # Create a table and insert data to ensure database file exists
      session.create("table:session_test", "key_format=S,value_format=S")
      cursor = session.open_cursor("table:session_test")
      
      # Insert data to ensure database file size
      5.times do |i|
        cursor.put_key_string("session_key_#{i}")
        cursor.put_value_string("session_value_#{i}" * 200)
        cursor.insert.should eq(0)
      end
      
      # Clean up
      cursor.close
      session.close
      conn.close
    end
  end
  
  describe "#close" do
    it "closes the connection" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      
      # Create some data before closing
      session = conn.open_session
      session.create("table:close_test", "key_format=S,value_format=S")
      cursor = session.open_cursor("table:close_test")
      
      # Insert data
      3.times do |i|
        cursor.put_key_string("close_key_#{i}")
        cursor.put_value_string("close_value_#{i}" * 150)
        cursor.insert.should eq(0)
      end
      
      cursor.close
      session.close
      
      conn.close
      conn.closed?.should be_true
    end
  end
end

describe WiredTiger::DB::Session do
  describe "#create" do
    it "creates a table" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      
      # This should not raise an exception
      session.create("table:test", "key_format=S,value_format=S")
      
      # Insert data to ensure the table actually exists and has content
      cursor = session.open_cursor("table:test")
      8.times do |i|
        cursor.put_key_string("create_key_#{i}")
        cursor.put_value_string("create_value_#{i}" * 120)
        cursor.insert.should eq(0)
      end
      cursor.close
      
      # Clean up
      session.close
      conn.close
    end
  end
  
  describe "#open_cursor" do
    it "opens a cursor on a table" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      session.create("table:test", "key_format=S,value_format=S")
      
      cursor = session.open_cursor("table:test")
      cursor.should be_a(WiredTiger::DB::Cursor)
      cursor.closed?.should be_false
      
      # Insert data through the cursor to ensure database file exists
      6.times do |i|
        cursor.put_key_string("cursor_key_#{i}")
        cursor.put_value_string("cursor_value_#{i}" * 180)
        cursor.insert.should eq(0)
      end
      
      # Clean up
      cursor.close
      session.close
      conn.close
    end
  end
  
  describe "#close" do
    it "closes the session" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      
      # Create and populate a table before closing
      session.create("table:session_close_test", "key_format=S,value_format=S")
      cursor = session.open_cursor("table:session_close_test")
      
      # Insert data
      4.times do |i|
        cursor.put_key_string("session_close_key_#{i}")
        cursor.put_value_string("session_close_value_#{i}" * 160)
        cursor.insert.should eq(0)
      end
      
      cursor.close
      session.close
      session.closed?.should be_true
      
      conn.close
    end
  end
end

describe WiredTiger::DB::Cursor do
  describe "basic operations" do
    it "performs insert and search operations" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      session.create("table:test", "key_format=S,value_format=S")
      
      cursor = session.open_cursor("table:test")
      
      # Insert multiple records to ensure database file size
      15.times do |i|
        cursor.put_key_string("test_key_#{i}")
        cursor.put_value_string("test_value_#{i}" * 100)
        cursor.insert.should eq(0)
      end
      
      # Search for a specific record
      cursor.reset
      cursor.put_key_string("test_key_5")
      cursor.search.should eq(0)
      
      # Get the value
      cursor.get_value_string.should eq("test_value_5" * 100)
      
      # Clean up
      cursor.close
      session.close
      conn.close
    end
  end
  
  describe "#close" do
    it "closes the cursor" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      session = conn.open_session
      session.create("table:test", "key_format=S,value_format=S")
      
      cursor = session.open_cursor("table:test")
      
      # Insert data before closing to ensure database file exists
      7.times do |i|
        cursor.put_key_string("close_cursor_key_#{i}")
        cursor.put_value_string("close_cursor_value_#{i}" * 140)
        cursor.insert.should eq(0)
      end
      
      cursor.close
      cursor.closed?.should be_true
      
      session.close
      conn.close
    end
  end
end

describe WiredTiger::DB::WiredTigerException do
  it "can be created with a message" do
    ex = WiredTiger::DB::WiredTigerException.new("Test error")
    ex.message.should eq("Test error")
  end
  
  it "can be created with a message and cause" do
    cause = Exception.new("Original error")
    ex = WiredTiger::DB::WiredTigerException.new("Test error", cause)
    ex.message.should eq("Test error")
    ex.cause.should eq(cause)
  end
end

describe "Database File Creation" do
  it "creates actual database files on disk with sufficient size" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
    
    # Open connection and create database
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create multiple tables to ensure database complexity
    session.create("table:main_table", "key_format=S,value_format=S")
    session.create("table:secondary_table", "key_format=S,value_format=S")
    session.create("table:index_table", "key_format=S,value_format=S")
    
    # Insert substantial data into each table
    main_cursor = session.open_cursor("table:main_table")
    20.times do |i|
      main_cursor.put_key_string("main_key_#{i}")
      main_cursor.put_value_string("main_value_#{i}" * 200)
      main_cursor.insert.should eq(0)
    end
    main_cursor.close
    
    secondary_cursor = session.open_cursor("table:secondary_table")
    15.times do |i|
      secondary_cursor.put_key_string("secondary_key_#{i}")
      secondary_cursor.put_value_string("secondary_value_#{i}" * 250)
      secondary_cursor.insert.should eq(0)
    end
    secondary_cursor.close
    
    index_cursor = session.open_cursor("table:index_table")
    12.times do |i|
      index_cursor.put_key_string("index_key_#{i}")
      index_cursor.put_value_string("index_value_#{i}" * 300)
      index_cursor.insert.should eq(0)
    end
    index_cursor.close
    
    # Close session and connection to ensure data is flushed
    session.close
    conn.close
    
    # Verify the database file exists and has minimum size
    # This verification will happen in the after_each hook
    # but we can also check here to be explicit
    wt_file = File.join(test_dir, "WiredTiger.wt")
    File.exists?(wt_file).should be_true
    
    # Check that the file has substantial size
    file_size = File.size(wt_file)
    file_size.should be > 5 * 1024 # At least 5KB
    
    puts "Database file verification: #{wt_file} exists with size #{file_size} bytes (#{file_size / 1024.0} KB)"
  end
  
  it "creates database files in unique directories for each test" do
    # This test verifies that each test gets its own database directory
    test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
    
    # The directory should be unique and contain a random component
    test_dir.should contain("wiredtiger_test_")
    test_dir.should contain("tmp")
    
    # Create some data to ensure file creation
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    session.create("table:unique_test", "key_format=S,value_format=S")
    
    cursor = session.open_cursor("table:unique_test")
    5.times do |i|
      cursor.put_key_string("unique_key_#{i}")
      cursor.put_value_string("unique_value_#{i}" * 100)
      cursor.insert.should eq(0)
    end
    cursor.close
    
    session.close
    conn.close
    
    # Verify file exists
    wt_file = File.join(test_dir, "WiredTiger.wt")
    File.exists?(wt_file).should be_true
  end
end
