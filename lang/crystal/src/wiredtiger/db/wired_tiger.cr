module WiredTiger
  module DB
    # Main WiredTiger class that provides access to the database
    class WiredTiger
      # FFI function definitions
      @[Link("wiredtiger_crystal")]
      lib LibWiredTiger
        fun crystal_wiredtiger_open(home : Char*, config : Char*) : Void*
        fun crystal_wiredtiger_close(conn : Void*, config : Char*) : Int32
      end
      
      # Open a connection to a WiredTiger database
      # @param home [String] Database home directory
      # @param config [String?] Configuration string (optional)
      # @return [Connection] Connection object
      def self.open(home : String, config : String? = nil) : Connection
        home_ptr = home.to_unsafe.as(Pointer(Char))
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        conn_ptr = LibWiredTiger.crystal_wiredtiger_open(home_ptr, config_ptr)
        raise WiredTigerException.new("Failed to open connection") if conn_ptr.null?
        
        Connection.new(conn_ptr)
      end
    end
  end
end
