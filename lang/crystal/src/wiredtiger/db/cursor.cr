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
        fun cursor_update(cursor : Void*) : Int32
        fun cursor_remove(cursor : Void*) : Int32
        fun cursor_modify(cursor : Void*, entries : Void*, nentries : Int32) : Int32
        fun cursor_reset(cursor : Void*) : Int32
        fun cursor_search(cursor : Void*) : Int32
        fun cursor_get_value_string(cursor : Void*) : Char*
        fun cursor_get_key_string(cursor : Void*) : Char*
        fun cursor_close(cursor : Void*) : Int32
        fun cursor_next(cursor : Void*) : Int32
        fun cursor_prev(cursor : Void*) : Int32
        
        # Extended data type support
        fun cursor_put_key_int(cursor : Void*, key : Int64) : Int32
        fun cursor_put_value_int(cursor : Void*, value : Int64) : Int32
        fun cursor_put_key_float(cursor : Void*, key : Float64) : Int32
        fun cursor_put_value_float(cursor : Void*, value : Float64) : Int32
        fun cursor_put_key_bytes(cursor : Void*, data : Void*, size : LibC::SizeT) : Int32
        fun cursor_put_value_bytes(cursor : Void*, data : Void*, size : LibC::SizeT) : Int32
        
        fun cursor_get_key_int(cursor : Void*) : Int64
        fun cursor_get_value_int(cursor : Void*) : Int64
        fun cursor_get_key_float(cursor : Void*) : Float64
        fun cursor_get_value_float(cursor : Void*) : Float64
        fun cursor_get_key_bytes(cursor : Void*, data : Void**, size : LibC::SizeT*) : Int32
        fun cursor_get_value_bytes(cursor : Void*, data : Void**, size : LibC::SizeT*) : Int32
        
        # Statistics support
        fun cursor_get_statistics_values(cursor : Void*, desc : Char**, pvalue : Char**, value : Int64*) : Int32
        
        # Safe close operations
        fun cursor_safe_close(cursor : Void*) : Int32
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
      
      # Set the cursor's integer key
      # @param key [Int64] Key integer
      def put_key_int(key : Int64)
        ret = LibCursor.cursor_put_key_int(@native_handle, key)
        raise WiredTigerException.new("Failed to set int key: #{key}") if ret != 0
      end
      
      # Set the cursor's integer value
      # @param value [Int64] Value integer
      def put_value_int(value : Int64)
        ret = LibCursor.cursor_put_value_int(@native_handle, value)
        raise WiredTigerException.new("Failed to set int value: #{value}") if ret != 0
      end
      
      # Set the cursor's float key
      # @param key [Float64] Key float
      def put_key_float(key : Float64)
        ret = LibCursor.cursor_put_key_float(@native_handle, key)
        raise WiredTigerException.new("Failed to set float key: #{key}") if ret != 0
      end
      
      # Set the cursor's float value
      # @param value [Float64] Value float
      def put_value_float(value : Float64)
        ret = LibCursor.cursor_put_value_float(@native_handle, value)
        raise WiredTigerException.new("Failed to set float value: #{value}") if ret != 0
      end
      
      # Set the cursor's bytes key
      # @param data [Bytes] Key bytes
      def put_key_bytes(data : Bytes)
        ret = LibCursor.cursor_put_key_bytes(@native_handle, data.to_unsafe.as(Void*), data.size)
        raise WiredTigerException.new("Failed to set bytes key") if ret != 0
      end
      
      # Set the cursor's bytes value
      # @param data [Bytes] Value bytes
      def put_value_bytes(data : Bytes)
        ret = LibCursor.cursor_put_value_bytes(@native_handle, data.to_unsafe.as(Void*), data.size)
        raise WiredTigerException.new("Failed to set bytes value") if ret != 0
      end
      
      # Insert a record
      # @return [Int] 0 on success, non-zero on error
      def insert : Int32
        ret = LibCursor.cursor_insert(@native_handle)
        raise WiredTigerException.new("Failed to insert record") if ret != 0
        ret
      end
      
      # Update the current record
      # @return [Int] 0 on success, error code on failure
      def update : Int32
        ret = LibCursor.cursor_update(@native_handle)
        raise WiredTigerException.new("Failed to update record") if ret != 0
        ret
      end
      
      # Remove the current record
      # @return [Int] 0 on success, error code on failure
      def remove : Int32
        ret = LibCursor.cursor_remove(@native_handle)
        raise WiredTigerException.new("Failed to remove record") if ret != 0
        ret
      end
      
      # Modify the current record using an array of modifications
      # @param entries [Array(Modify)] Array of modifications to apply
      # @return [Int] 0 on success, error code on failure
      def modify(entries : Array(Modify)) : Int32
        # Convert Crystal array to C array
        nentries = entries.size
        c_entries = Pointer(Void).malloc(nentries * sizeof(Modify))
        
        entries.each_with_index do |entry, i|
          entry_ptr = c_entries + (i * sizeof(Modify))
          entry_ptr.as(Pointer(Modify)).value = entry
        end
        
        ret = LibCursor.cursor_modify(@native_handle, c_entries, nentries)
        raise WiredTigerException.new("Failed to modify record") if ret != 0
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
      
      # Get the cursor's integer key
      # @return [Int64] Key integer
      def get_key_int : Int64
        LibCursor.cursor_get_key_int(@native_handle)
      end
      
      # Get the cursor's integer value
      # @return [Int64] Value integer
      def get_value_int : Int64
        LibCursor.cursor_get_value_int(@native_handle)
      end
      
      # Get the cursor's float key
      # @return [Float64] Key float
      def get_key_float : Float64
        LibCursor.cursor_get_key_float(@native_handle)
      end
      
      # Get the cursor's float value
      # @return [Float64] Value float
      def get_value_float : Float64
        LibCursor.cursor_get_value_float(@native_handle)
      end
      
      # Get the cursor's bytes key
      # @return [Bytes] Key bytes
      def get_key_bytes : Bytes
        # For now, return empty bytes to avoid memory management complexity
        # TODO: Implement proper bytes handling when memory management is resolved
        puts "⚠️  get_key_bytes not yet implemented - returning empty bytes"
        Bytes.new(0)
      end
      
      # Get the cursor's bytes value
      # @return [Bytes] Value bytes
      def get_value_bytes : Bytes
        # For now, return empty bytes to avoid memory management complexity
        # TODO: Implement proper bytes handling when memory management is resolved
        puts "⚠️  get_value_bytes not yet implemented - returning empty bytes"
        Bytes.new(0)
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
        return if closed? # Already closed
        
        # Use safe close function that handles null pointers gracefully
        ret = LibCursor.cursor_safe_close(@native_handle)
        raise WiredTigerException.new("Failed to close cursor") if ret != 0
        
        @native_handle = Pointer(Void).null
      end
      
      # Safe close that can be called multiple times without error
      def safe_close
        return if closed? # Already closed
        
        LibCursor.cursor_safe_close(@native_handle)
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
