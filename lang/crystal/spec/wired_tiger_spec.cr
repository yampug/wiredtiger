require "./spec_helper"

describe WiredTiger::WiredTiger do
  describe ".open" do
    it "opens a connection to a new database" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
      conn.should be_a(WiredTiger::DB::Connection)
      conn.closed?.should be_false
      
      # Clean up
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
      
      # Clean up
      session.close
      conn.close
    end
  end
  
  describe "#close" do
    it "closes the connection" do
      test_dir = ENV["WIREDTIGER_TEST_DIR"]? || "testdb"
      conn = WiredTiger::WiredTiger.open(test_dir, "create")
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
      
      # Insert a record
      cursor.put_key_string("test_key")
      cursor.put_value_string("test_value")
      cursor.insert.should eq(0)
      
      # Search for the record
      cursor.reset
      cursor.put_key_string("test_key")
      cursor.search.should eq(0)
      
      # Get the value
      cursor.get_value_string.should eq("test_value")
      
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
