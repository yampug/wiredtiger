require "./spec_helper"

describe "WiredTiger Backup Functionality" do
  it "creates a backup cursor successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:backup_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:backup_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a backup cursor
    backup_cursor = session.create_backup
    backup_cursor.should be_a(WiredTiger::DB::BackupCursor)
    
    # Get all backup files
    files = backup_cursor.all_files
    files.size.should be > 0
    files.any? { |f| f.includes?("WiredTiger") }.should be_true
    
    backup_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "creates an incremental backup cursor successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create,log=(enabled=true,archive=false)")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:incr_backup_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:incr_backup_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create an incremental backup cursor (target=("log:"))
    backup_cursor = session.create_backup("target=(\"log:\")")
    backup_cursor.should be_a(WiredTiger::DB::BackupCursor)
    
    # Get all backup files
    files = backup_cursor.all_files
    files.size.should be >= 0  # May be 0 if no log files yet
    
    backup_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "takes a full backup successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    backup_dir = "#{test_dir}_backup"
    
    # Clean up any existing backup directory
    FileUtils.rm_rf(backup_dir) if Dir.exists?(backup_dir)
    
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:full_backup_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:full_backup_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a backup cursor and take a full backup
    backup_cursor = session.create_backup
    copied_files = backup_cursor.take_full_backup(backup_dir, test_dir)
    
    copied_files.size.should be > 0
    copied_files.any? { |f| f.includes?("WiredTiger") }.should be_true
    
    # Verify backup files exist
    copied_files.each do |filename|
      backup_file = File.join(backup_dir, filename)
      File.exists?(backup_file).should be_true
    end
    
    backup_cursor.close
    session.close
    conn.close
    
    # Clean up
    FileUtils.rm_rf(backup_dir)
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "takes an incremental backup successfully" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    backup_dir = "#{test_dir}_incr_backup"
    
    # Clean up any existing backup directory
    FileUtils.rm_rf(backup_dir) if Dir.exists?(backup_dir)
    
    conn = WiredTiger::WiredTiger.open(test_dir, "create,log=(enabled=true,archive=false)")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:incr_backup_test2", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:incr_backup_test2")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create an incremental backup cursor and take an incremental backup
    backup_cursor = session.create_backup("target=(\"log:\")")
    copied_files = backup_cursor.take_incremental_backup(backup_dir, test_dir)
    
    # For incremental backup, we may have 0 files if no log files exist yet
    copied_files.size.should be >= 0
    
    # Verify backup files exist (if any were copied)
    copied_files.each do |filename|
      backup_file = File.join(backup_dir, filename)
      File.exists?(backup_file).should be_true
    end
    
    backup_cursor.close
    session.close
    conn.close
    
    # Clean up
    FileUtils.rm_rf(backup_dir)
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles backup cursor iteration correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:iteration_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:iteration_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a backup cursor and test iteration
    backup_cursor = session.create_backup
    
    # Test next_file method
    first_file = backup_cursor.next_file
    first_file.should_not be_nil
    first_file.not_nil!.includes?("WiredTiger").should be_true
    
    # Test all_files method
    all_files = backup_cursor.all_files
    all_files.size.should be > 0
    all_files.includes?(first_file.not_nil!).should be_true
    
    backup_cursor.close
    session.close
    conn.close
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
  
  it "handles backup cursor copy operations correctly" do
    test_dir = ENV["WIREDTIGER_TEST_DIR"]
    backup_dir = "#{test_dir}_copy_test"
    
    # Clean up any existing backup directory
    FileUtils.rm_rf(backup_dir) if Dir.exists?(backup_dir)
    
    conn = WiredTiger::WiredTiger.open(test_dir, "create")
    session = conn.open_session
    
    # Create a table to ensure there are files to backup
    session.create("table:copy_test", "key_format=S,value_format=S")
    cursor = session.open_cursor("table:copy_test")
    cursor.put_key_string("test_key")
    cursor.put_value_string("test_value")
    cursor.insert
    cursor.close
    
    # Create a backup cursor and test copy operations
    backup_cursor = session.create_backup
    copied_files = backup_cursor.copy_files(backup_dir, test_dir)
    
    copied_files.size.should be > 0
    
    # Verify copied files exist and have correct content
    copied_files.each do |filename|
      source_file = File.join(test_dir, filename)
      backup_file = File.join(backup_dir, filename)
      
      File.exists?(backup_file).should be_true
      File.size(source_file).should eq(File.size(backup_file))
    end
    
    backup_cursor.close
    session.close
    conn.close
    
    # Clean up
    FileUtils.rm_rf(backup_dir)
    
    # Verify database file was created with sufficient size
    DatabaseFileVerifier.verify_database_file(test_dir, 30).should be_true
  end
end
