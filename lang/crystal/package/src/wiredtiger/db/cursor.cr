

module WiredTiger
  module DB
    # Represents a cursor for navigating and manipulating data in WiredTiger
    class Cursor
      # Native handle to the WiredTiger cursor
      @native_handle : Void*
      
      # Create a new cursor with the given native handle
      def initialize(handle : Void*)
        @native_handle = handle
      end
      
      # FFI function definitions for cursor operations
      lib LibCursor
        fun cursor_put_key_string(cursor : Void*, key : Char*) : Int32
        fun cursor_put_value_string(cursor : Void*, value : Char*) : Int32
        fun cursor_insert(cursor : Void*) : Int32
        fun cursor_reset(cursor : Void*) : Int32
        fun cursor_search(cursor : Void*) : Int32
        fun cursor_get_value_string(cursor : Void*) : Char*
        fun cursor_get_key_string(cursor : Void*) : Char*
        fun cursor_close(cursor : Void*) : Int32
        fun cursor_next(cursor : Void*) : Int32
        fun cursor_prev(cursor : Void*) : Int32
      end
      
      # Set the cursor's string key
      # @param key [String] Key string
      def put_key_string(key : String)
        key_ptr = key.to_unsafe.as(Pointer(Char))
        
        ret = LibCursor.cursor_put_key_string(@native_handle, key_ptr)
        raise WiredTigerException.new("Failed to set key: #{key}") if ret != 0
      end
      
      # Set the cursor's string value
      # @param value [String] Value string
      def put_value_string(value : String)
        value_ptr = value.to_unsafe.as(Pointer(Char))
        
        ret = LibCursor.cursor_put_value_string(@native_handle, value_ptr)
        raise WiredTigerException.new("Failed to set value: #{value}") if ret != 0
      end
      
      # Insert a record
      # @return [Int] 0 on success, non-zero on error
      def insert : Int32
        ret = LibCursor.cursor_insert(@native_handle)
        raise WiredTigerException.new("Failed to insert record") if ret != 0
        ret
      end
      
      # Reset the cursor
      def reset
        ret = LibCursor.cursor_reset(@native_handle)
        raise WiredTigerException.new("Failed to reset cursor") if ret != 0
      end
      
      # Search for a record
      # @return [Int] 0 if found, WT_NOTFOUND if not found
      def search : Int32
        LibCursor.cursor_search(@native_handle)
      end
      
      # Get the cursor's string value
      # @return [String] Value string
      def get_value_string : String
        value_ptr = LibCursor.cursor_get_value_string(@native_handle)
        raise WiredTigerException.new("Failed to get value") if value_ptr.null?
        
        String.new(value_ptr.as(Pointer(UInt8)))
      end
      
      # Get the cursor's string key
      # @return [String] Key string
      def get_key_string : String
        key_ptr = LibCursor.cursor_get_key_string(@native_handle)
        raise WiredTigerException.new("Failed to get key") if key_ptr.null?
        
        String.new(key_ptr.as(Pointer(UInt8)))
      end
      
      # Move to the next record
      # @return [Int] 0 on success, WT_NOTFOUND if no more records
      def next : Int32
        LibCursor.cursor_next(@native_handle)
      end
      
      # Move to the previous record
      # @return [Int] 0 on success, WT_NOTFOUND if no more records
      def prev : Int32
        LibCursor.cursor_prev(@native_handle)
      end
      
      # Close the cursor
      def close
        ret = LibCursor.cursor_close(@native_handle)
        raise WiredTigerException.new("Failed to close cursor") if ret != 0
        
        @native_handle = Pointer(Void).null
      end
      
      # Check if the cursor is closed
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
