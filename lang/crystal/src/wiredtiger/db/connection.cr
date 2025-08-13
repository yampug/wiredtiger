module WiredTiger
  module DB
    # Represents a connection to a WiredTiger database
    class Connection
      # Native handle to the WiredTiger connection
      @native_handle : Void*
      
      # Create a new connection with the given native handle
      def initialize(handle : Void*)
        @native_handle = handle
      end
      
      # FFI function definitions for connection operations
      lib LibConnection
        fun connection_open_session(conn : Void*, config : Char*) : Void*
        fun connection_close(conn : Void*, config : Char*) : Int32
        
        # Safe close operations
        fun connection_safe_close(conn : Void*) : Int32
      end
      
      # Open a session on this connection
      # @param config [String?] Configuration string (optional)
      # @return [Session] Session object
      def open_session(config : String? = nil) : Session
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        session_ptr = LibConnection.connection_open_session(@native_handle, config_ptr)
        raise WiredTigerException.new("Failed to open session") if session_ptr.null?
        
        Session.new(session_ptr)
      end
      
      # Close this connection
      # @param config [String?] Configuration string (optional)
      def close(config : String? = nil)
        return if closed? # Already closed
        
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        # Use safe close function that handles null pointers gracefully
        ret = LibConnection.connection_safe_close(@native_handle)
        raise WiredTigerException.new("Failed to close connection") if ret != 0
        
        @native_handle = Pointer(Void).null
      end
      
      # Safe close that can be called multiple times without error
      def safe_close
        return if closed? # Already closed
        
        LibConnection.connection_safe_close(@native_handle)
        @native_handle = Pointer(Void).null
      end
      
      # Check if the connection is closed
      def closed? : Bool
        @native_handle.null?
      end
      
      # Get the native handle (for internal use)
      protected def native_handle : LibC::Void*
        @native_handle
      end
    end
  end
end
