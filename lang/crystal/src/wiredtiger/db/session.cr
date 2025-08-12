

module WiredTiger
  module DB
    # Represents a session within a WiredTiger connection
    class Session
      # Native handle to the WiredTiger session
      @native_handle : Void*
      
      # Create a new session with the given native handle
      def initialize(handle : Void*)
        @native_handle = handle
      end
      
      # FFI function definitions for session operations
      lib LibSession
        fun session_create(session : Void*, uri : Char*, config : Char*) : Int32
        fun session_open_cursor(session : Void*, uri : Char*, to_dup : Void*, config : Char*) : Void*
        fun session_close(session : Void*, config : Char*) : Int32
      end
      
      # Create a table, index or other data source
      # @param uri [String] URI for the object to create
      # @param config [String?] Configuration string (optional)
      def create(uri : String, config : String? = nil)
        uri_ptr = uri.to_unsafe.as(Pointer(Char))
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        ret = LibSession.session_create(@native_handle, uri_ptr, config_ptr)
        raise WiredTigerException.new("Failed to create object: #{uri}") if ret != 0
      end
      
      # Open a cursor
      # @param uri [String] URI of the object to open
      # @param to_dup [Cursor?] Cursor to duplicate (optional)
      # @param config [String?] Configuration string (optional)
      # @return [Cursor] Cursor object
      def open_cursor(uri : String, to_dup : Cursor? = nil, config : String? = nil) : Cursor
        uri_ptr = uri.to_unsafe.as(Pointer(Char))
        to_dup_ptr = to_dup ? to_dup.native_handle : Pointer(Void).null
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        cursor_ptr = LibSession.session_open_cursor(@native_handle, uri_ptr, to_dup_ptr, config_ptr)
        raise WiredTigerException.new("Failed to open cursor: #{uri}") if cursor_ptr.null?
        
        Cursor.new(cursor_ptr)
      end
      
      # Close this session
      # @param config [String?] Configuration string (optional)
      def close(config : String? = nil)
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        ret = LibSession.session_close(@native_handle, config_ptr)
        raise WiredTigerException.new("Failed to close session") if ret != 0
        
        @native_handle = Pointer(Void).null
      end
      
      # Check if the session is closed
      def closed? : Bool
        @native_handle.null?
      end
      
      # Get the native handle (for internal use)
      protected def native_handle : Void*
        @native_handle
      end
    end
  end
end
