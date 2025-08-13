module WiredTiger
  module DB
    # Represents a single statistics entry
    struct Statistic
      # The statistic key (integer identifier)
      @key : Int32
      # Human-readable description of the statistic
      @description : String
      # Printable version of the value
      @printable_value : String
      # The actual numeric value
      @value : Int64
      
      def initialize(@key, @description, @printable_value, @value)
      end
      
      # Get the statistic key
      def key : Int32
        @key
      end
      
      # Get the description
      def description : String
        @description
      end
      
      # Get the printable value
      def printable_value : String
        @printable_value
      end
      
      # Get the numeric value
      def value : Int64
        @value
      end
      
      # Convert to string representation
      def to_s : String
        "#{@description}=#{@printable_value}"
      end
    end
    
    # Statistics cursor for iterating through statistics
    class StatisticsCursor
      @native_handle : Void*
      @closed : Bool = false
      
      # FFI function definitions for statistics cursor operations
      lib LibStatsCursor
        fun cursor_next(cursor : Void*) : Int32
        fun cursor_get_key_int(cursor : Void*) : Int64
        fun cursor_get_statistics_values(cursor : Void*, desc : Char**, pvalue : Char**, value : Int64*) : Int32
        fun cursor_reset(cursor : Void*) : Int32
        fun cursor_close(cursor : Void*) : Int32
      end
      
      def initialize(@native_handle)
      end
      
      # Get the next statistic entry
      # @return [Statistic?] The next statistic or nil if no more
      def next_statistic : Statistic?
        return nil if @closed
        
        ret = LibStatsCursor.cursor_next(@native_handle)
        return nil if ret != 0
        
        get_current_statistic
      end
      
      # Get the current statistic entry
      # @return [Statistic?] The current statistic or nil if none
      def get_current_statistic : Statistic?
        return nil if @closed
        
        # For statistics cursors, we need to get the key and values
        # The key is the statistic identifier
        key = LibStatsCursor.cursor_get_key_int(@native_handle)
        return nil if key == -1
        
        # Get the description, printable value, and numeric value
        desc_ptr = Pointer(Pointer(Char)).malloc(1)
        pvalue_ptr = Pointer(Pointer(Char)).malloc(1)
        value_ptr = Pointer(Int64).malloc(1)
        
        ret = LibStatsCursor.cursor_get_statistics_values(@native_handle, desc_ptr, pvalue_ptr, value_ptr)
        return nil if ret != 0
        
        description = desc_ptr.value ? String.new(desc_ptr.value.as(Pointer(UInt8))) : ""
        printable_value = pvalue_ptr.value ? String.new(pvalue_ptr.value.as(Pointer(UInt8))) : ""
        value = value_ptr.value
        
        Statistic.new(key.to_i32, description, printable_value, value)
      end
      
      # Reset the statistics cursor (reloads values)
      def reset : Int32
        return -1 if @closed
        
        ret = LibStatsCursor.cursor_reset(@native_handle)
        raise WiredTigerException.new("Failed to reset statistics cursor") if ret != 0
        ret
      end
      
      # Close the statistics cursor
      def close : Int32
        return 0 if @closed
        
        ret = LibStatsCursor.cursor_close(@native_handle)
        @closed = true
        raise WiredTigerException.new("Failed to close statistics cursor") if ret != 0
        ret
      end
      
      # Check if the cursor is closed
      def closed? : Bool
        @closed
      end
      
      # Iterate through all statistics
      def each : Nil
        loop do
          stat = next_statistic
          break if stat.nil?
          yield stat.not_nil!
        end
      end
      
      # Collect all statistics into an array
      def to_a : Array(Statistic)
        result = [] of Statistic
        each { |stat| result << stat }
        result
      end
      
      # Convert to a hash mapping descriptions to values
      def to_h : Hash(String, Int64)
        result = {} of String => Int64
        each { |stat| result[stat.description] = stat.value }
        result
      end
    end
    
    # Common statistics keys for easy access
    module StatKeys
      # Connection statistics
      CONN_FILE_OPEN = 100
      CONN_FILE_READ = 101
      CONN_FILE_WRITE = 102
      CONN_CACHE_BYTES_READ = 103
      CONN_CACHE_BYTES_WRITE = 104
      CONN_CACHE_OVERFLOW = 105
      CONN_CACHE_PAGES_EVICTED = 106
      CONN_CACHE_PAGES_INUSE = 107
      CONN_CACHE_PAGES_MAX = 108
      CONN_CACHE_PAGES_READ = 109
      CONN_CACHE_PAGES_WRITE = 110
      
      # Session statistics
      SESSION_BYTES_READ = 4000
      SESSION_BYTES_WRITE = 4001
      SESSION_LOCK_DHANDLE_WAIT = 4002
      SESSION_READ_TIME = 4003
      SESSION_WRITE_TIME = 4004
      SESSION_LOCK_SCHEMA_WAIT = 4005
      SESSION_CACHE_TIME = 4006
      
      # Table statistics
      TABLE_BTREE_ENTRIES = 2000
      TABLE_BTREE_INSERT = 2001
      TABLE_BTREE_REMOVE = 2002
      TABLE_BTREE_UPDATE = 2003
      TABLE_BTREE_OVERFLOW = 2004
      TABLE_BTREE_ROW_INTERNAL = 2005
      TABLE_BTREE_ROW_LEAF = 2006
      TABLE_BTREE_KEY_INTERNAL = 2007
      TABLE_BTREE_KEY_LEAF = 2008
      TABLE_BTREE_VALUE_INTERNAL = 2009
      TABLE_BTREE_VALUE_LEAF = 2010
    end
  end
end
