

require "./modify"

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
        
        # Transaction operations
        fun session_begin_transaction(session : Void*, config : Char*) : Int32
        fun session_commit_transaction(session : Void*, config : Char*) : Int32
        fun session_rollback_transaction(session : Void*, config : Char*) : Int32
        
        # Modify calculation
        fun crystal_calc_modify(session : Void*, oldv : Void*, newv : Void*, maxdiff : LibC::SizeT, entries : Void*, nentriesp : Int32*) : Int32
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
      
      # Begin a transaction
      # @param config [String?] Configuration string (optional)
      # @raise [WiredTigerException] if transaction cannot be started
      def begin_transaction(config : String? = nil)
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        ret = LibSession.session_begin_transaction(@native_handle, config_ptr)
        raise WiredTigerException.new("Failed to begin transaction") if ret != 0
      end
      
      # Commit the current transaction
      # @param config [String?] Configuration string (optional)
      # @raise [WiredTigerException] if transaction cannot be committed
      def commit_transaction(config : String? = nil)
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        ret = LibSession.session_commit_transaction(@native_handle, config_ptr)
        raise WiredTigerException.new("Failed to commit transaction") if ret != 0
      end
      
      # Rollback the current transaction
      # @param config [String?] Configuration string (optional)
      # @raise [WiredTigerException] if transaction cannot be rolled back
      def rollback_transaction(config : String? = nil)
        config_ptr = config ? config.to_unsafe.as(Pointer(Char)) : Pointer(Char).null
        
        ret = LibSession.session_rollback_transaction(@native_handle, config_ptr)
        raise WiredTigerException.new("Failed to rollback transaction") if ret != 0
      end
      
      # Calculate modify operations between old and new values
      # @param old_value [String] The old value
      # @param new_value [String] The new value
      # @param max_diff [Int] Maximum bytes difference
      # @param max_entries [Int] Maximum number of modify entries
      # @return [Array(Modify)] Array of modifications
      def calc_modify(old_value : String, new_value : String, max_diff : Int, max_entries : Int) : Array(Modify)
        # Create WT_ITEM structures
        old_item = Item.from_string(old_value)
        new_item = Item.from_string(new_value)
        
        # Allocate space for modify entries
        entries = Pointer(Void).malloc(max_entries * sizeof(Modify))
        nentries = max_entries
        
        ret = LibSession.crystal_calc_modify(
          @native_handle,
          pointerof(old_item),
          pointerof(new_item),
          LibC::SizeT.new(max_diff),
          entries,
          pointerof(nentries)
        )
        
        raise WiredTigerException.new("Failed to calculate modify operations") if ret != 0
        
        # Convert C array back to Crystal array
        result = [] of Modify
        nentries.times do |i|
          entry_ptr = entries + (i * sizeof(Modify))
          entry = entry_ptr.as(Pointer(Modify)).value
          result << entry
        end
        
        result
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
