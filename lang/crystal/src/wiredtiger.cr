# WiredTiger Crystal Bindings
# 
# This module provides Crystal bindings for the WiredTiger embedded database.
# It includes classes for managing connections, sessions, and cursors.

require "./wiredtiger/db/wired_tiger_exception"
require "./wiredtiger/db/wired_tiger"
require "./wiredtiger/db/connection"
require "./wiredtiger/db/session"
require "./wiredtiger/db/cursor"
require "./wiredtiger/db/backup_cursor"

module WiredTiger
  module DB
    # Version of the Crystal bindings
    VERSION = "1.0.0"
    
    # Error codes from WiredTiger
    module Error
      WT_NOTFOUND = -31803
      WT_PANIC = -31804
      WT_RUN_RECOVERY = -31805
      WT_CACHE_FULL = -31806
      WT_PREPARE_CONFLICT = -31807
      WT_DEADLOCK = -31808
      WT_ROLLBACK = -31809
    end
  end
  
  # Main WiredTiger class - provides static methods for database operations
  class WiredTiger
    # Open a connection to a WiredTiger database
    # @param home [String] Database home directory
    # @param config [String?] Configuration string (optional)
    # @return [DB::Connection] Connection object
    def self.open(home : String, config : String? = nil) : DB::Connection
      DB::WiredTiger.open(home, config)
    end
  end
  
  # Alias for convenience
  alias Connection = DB::Connection
  alias Session = DB::Session
  alias Cursor = DB::Cursor
  alias WiredTigerException = DB::WiredTigerException
  alias BackupCursor = DB::BackupCursor
end
