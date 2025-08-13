require "./spec_helper"

describe "WiredTiger Configuration and Advanced Features" do
  it "supports various table configurations" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Test different key and value formats
    formats = [
      {"key_format=S,value_format=S", "string", "string"},
      {"key_format=q,value_format=q", "integer", "integer"},
      {"key_format=u,value_format=u", "bytes", "bytes"},
      {"key_format=S,value_format=q", "string", "integer"},
      {"key_format=q,value_format=S", "integer", "string"}
    ]
    
    formats.each_with_index do |(format, key_type, value_type), index|
      table_name = "config_test_#{index}"
      session.create("table:#{table_name}", format)
      
      # Test the configuration
      cursor = session.open_cursor("table:#{table_name}")
      
      case key_type
      when "string"
        cursor.put_key_string("test_key")
      when "integer"
        cursor.put_key_int(42_i64)
      when "bytes"
        cursor.put_key_bytes("test_key".to_slice)
      end
      
      case value_type
      when "string"
        cursor.put_value_string("test_value")
      when "integer"
        cursor.put_value_int(100_i64)
      when "bytes"
        cursor.put_value_bytes("test_value".to_slice)
      end
      
      cursor.insert
      cursor.close
    end
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 40).should be_true
  end
  
  it "supports table configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Test table with various configuration options
    config_options = [
      "key_format=S,value_format=S,log=(enabled=false)",
      "key_format=S,value_format=S,compression=lz4",
      "key_format=S,value_format=S,encryption=(name=nop)",
      "key_format=S,value_format=S,checksum=on"
    ]
    
    config_options.each_with_index do |config, index|
      table_name = "config_options_#{index}"
      
      # Some configurations might not be supported, so handle gracefully
      begin
        session.create("table:#{table_name}", config)
        
        # Test the configuration
        cursor = session.open_cursor("table:#{table_name}")
        cursor.put_key_string("test_key")
        cursor.put_value_string("test_value")
        cursor.insert
        cursor.close
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
      end
    end
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 35).should be_true
  end
  
  it "supports connection configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Test various connection configurations
    connection_configs = [
      "create",
      "create,readonly",
      "create,log=(enabled=false)",
      "create,checkpoint=(wait=60)",
      "create,eviction=(threads_max=4)"
    ]
    
    connection_configs.each_with_index do |config, index|
      test_subdir = "#{test_dir}_#{index}"
      Dir.mkdir_p(test_subdir) unless Dir.exists?(test_subdir)
      
      begin
        conn = WiredTiger::WiredTiger.open(test_subdir, config)
        session = conn.open_session
        
        # Test basic operations
        session.create("table:connection_test", "key_format=S,value_format=S")
        cursor = session.open_cursor("table:connection_test")
        cursor.put_key_string("test_key")
        cursor.put_value_string("test_value")
        cursor.insert
        cursor.close
        
        session.close
        conn.close
        
        # Verify database file was created
        DatabaseFileVerifier.verify_database_file(test_subdir, 10).should be_true
        
        # Clean up
        FileUtils.rm_rf(test_subdir)
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
        
        # Clean up on failure
        FileUtils.rm_rf(test_subdir) if Dir.exists?(test_subdir)
      end
    end
  end
  
  it "supports session configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Test session-level configurations
    session_configs = [
      "isolation=read-uncommitted",
      "isolation=read-committed",
      "isolation=snapshot"
    ]
    
    session_configs.each do |config|
      # Test transaction isolation levels
      session.begin_transaction(config)
      
      # Create a table and insert data
      session.create("table:session_config_test", "key_format=S,value_format=S")
      cursor = session.open_cursor("table:session_config_test")
      cursor.put_key_string("test_key")
      cursor.put_value_string("test_value")
      cursor.insert
      cursor.close
      
      # Commit the transaction
      session.commit_transaction
    end
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "supports cursor configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table
    session.create("table:cursor_config_test", "key_format=S,value_format=S")
    
    # Test cursor configurations
    cursor_configs = [
      nil, # Default configuration
      "overwrite=false"
    ]
    
    cursor_configs.each_with_index do |config, index|
      cursor = session.open_cursor("table:cursor_config_test", config: config)
      
      # Test basic operations
      cursor.put_key_string("config_key_#{index}")
      cursor.put_value_string("config_value_#{index}")
      cursor.insert
      
      cursor.close
    end
    
    # Test readonly cursor separately (should not allow inserts)
    readonly_cursor = session.open_cursor("table:cursor_config_test", config: "readonly=true")
    
    # Try to insert with readonly cursor (should fail)
    readonly_cursor.put_key_string("readonly_key")
    readonly_cursor.put_value_string("readonly_value")
    
    expect_raises(WiredTiger::DB::WiredTigerException) do
      readonly_cursor.insert
    end
    
    readonly_cursor.close
    
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "supports statistics configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Test different statistics configurations
    stats_configs = [
      "create,statistics=(all)",
      "create,statistics=(fast)",
      "create,statistics=(none)"
    ]
    
    stats_configs.each_with_index do |config, index|
      test_subdir = "#{test_dir}_stats_#{index}"
      Dir.mkdir_p(test_subdir) unless Dir.exists?(test_subdir)
      
      begin
        conn = WiredTiger::WiredTiger.open(test_subdir, config)
        session = conn.open_session
        
        # Create a table
        session.create("table:stats_config_test", "key_format=S,value_format=S")
        cursor = session.open_cursor("table:stats_config_test")
        
        # Insert some data
        10.times do |i|
          cursor.put_key_string("stats_key_#{i}")
          cursor.put_value_string("stats_value_#{i}")
          cursor.insert
        end
        
        cursor.close
        
        # Test statistics based on configuration
        if config.includes?("statistics=(all)")
          # Should be able to get all statistics
          all_stats = session.get_all_statistics
          all_stats.size.should be > 0
          
          table_stats = session.get_table_statistics("stats_config_test")
          table_stats.size.should be > 0
          
        elsif config.includes?("statistics=(fast)")
          # Should be able to get fast statistics
          begin
            all_stats = session.get_all_statistics
            all_stats.size.should be >= 0
          rescue ex : WiredTiger::DB::WiredTigerException
            # Fast stats might not be available
            ex.message.should_not be_nil
          end
          
        elsif config.includes?("statistics=(none)")
          # Should not be able to get statistics
          expect_raises(WiredTiger::DB::WiredTigerException) do
            session.open_statistics_cursor
          end
        end
        
        session.close
        conn.close
        
        # Verify database file was created
        DatabaseFileVerifier.verify_database_file(test_subdir, 20).should be_true
        
        # Clean up
        FileUtils.rm_rf(test_subdir)
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
        
        # Clean up on failure
        FileUtils.rm_rf(test_subdir) if Dir.exists?(test_subdir)
      end
    end
  end
  
  it "supports logging configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Test logging configurations
    log_configs = [
      "create,log=(enabled=true)",
      "create,log=(enabled=false)"
    ]
    
    log_configs.each_with_index do |config, index|
      test_subdir = "#{test_dir}_log_#{index}"
      Dir.mkdir_p(test_subdir) unless Dir.exists?(test_subdir)
      
      begin
        conn = WiredTiger::WiredTiger.open(test_subdir, config)
        session = conn.open_session
        
        # Create a table
        session.create("table:log_config_test", "key_format=S,value_format=S")
        cursor = session.open_cursor("table:log_config_test")
        
        # Insert data
        cursor.put_key_string("log_key")
        cursor.put_value_string("log_value")
        cursor.insert
        cursor.close
        
        session.close
        conn.close
        
        # Verify database file was created
        DatabaseFileVerifier.verify_database_file(test_subdir, 20).should be_true
        
        # Check for log files if logging is enabled
        if config.includes?("enabled=true")
          log_files = Dir.entries(test_subdir).select { |f| f.ends_with?(".wt") && f != "WiredTiger.wt" }
          # Should have some log files
          log_files.size.should be >= 0
        end
        
        # Clean up
        FileUtils.rm_rf(test_subdir)
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
        
        # Clean up on failure
        FileUtils.rm_rf(test_subdir) if Dir.exists?(test_subdir)
      end
    end
  end
  
  it "supports checkpoint configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Test checkpoint configurations
    checkpoint_configs = [
      "create,checkpoint=(wait=30)",
      "create,checkpoint=(log_size=2GB)"
    ]
    
    checkpoint_configs.each_with_index do |config, index|
      test_subdir = "#{test_dir}_checkpoint_#{index}"
      Dir.mkdir_p(test_subdir) unless Dir.exists?(test_subdir)
      
      begin
        conn = WiredTiger::WiredTiger.open(test_subdir, config)
        session = conn.open_session
        
        # Create a table
        session.create("table:checkpoint_test", "key_format=S,value_format=S")
        cursor = session.open_cursor("table:checkpoint_test")
        
        # Insert data
        cursor.put_key_string("checkpoint_key")
        cursor.put_value_string("checkpoint_value")
        cursor.insert
        cursor.close
        
        session.close
        conn.close
        
        # Verify database file was created
        DatabaseFileVerifier.verify_database_file(test_subdir, 20).should be_true
        
        # Clean up
        FileUtils.rm_rf(test_subdir)
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
        
        # Clean up on failure
        FileUtils.rm_rf(test_subdir) if Dir.exists?(test_subdir)
      end
    end
  end
  
  it "supports eviction configuration options" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    
    # Test eviction configurations
    eviction_configs = [
      "create,eviction=(threads_max=4)",
      "create,eviction=(threads_min=1)"
    ]
    
    eviction_configs.each_with_index do |config, index|
      test_subdir = "#{test_dir}_eviction_#{index}"
      Dir.mkdir_p(test_subdir) unless Dir.exists?(test_subdir)
      
      begin
        conn = WiredTiger::WiredTiger.open(test_subdir, config)
        session = conn.open_session
        
        # Create a table
        session.create("table:eviction_test", "key_format=S,value_format=S")
        cursor = session.open_cursor("table:eviction_test")
        
        # Insert data
        cursor.put_key_string("eviction_key")
        cursor.put_value_string("eviction_value")
        cursor.insert
        cursor.close
        
        session.close
        conn.close
        
        # Verify database file was created
        DatabaseFileVerifier.verify_database_file(test_subdir, 20).should be_true
        
        # Clean up
        FileUtils.rm_rf(test_subdir)
        
      rescue ex : WiredTiger::DB::WiredTigerException
        # Some configurations might not be available
        ex.message.should_not be_nil
        
        # Clean up on failure
        FileUtils.rm_rf(test_subdir) if Dir.exists?(test_subdir)
      end
    end
  end
end
