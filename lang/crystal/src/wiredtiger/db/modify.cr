module WiredTiger
  module DB
    # Represents a WiredTiger item (data with size)
    struct Item
      # Pointer to the data
      @data : Pointer(Void)
      # Size of the data
      @size : LibC::SizeT
      # Flags
      @flags : UInt32
      # Memory management
      @mem : Pointer(Void)
      @memsize : LibC::SizeT
      
      def initialize(@data, @size, @flags = 0_u32, @mem = Pointer(Void).null, @memsize = 0_u64)
      end
      
      # Create an Item from a string
      def self.from_string(str : String) : Item
        data = str.to_unsafe.as(Pointer(Void))
        size = LibC::SizeT.new(str.bytesize)
        Item.new(data, size)
      end
      
      # Create an Item from bytes
      def self.from_bytes(bytes : Bytes) : Item
        data = bytes.to_unsafe.as(Pointer(Void))
        size = LibC::SizeT.new(bytes.size)
        Item.new(data, size)
      end
      
      # Get the data pointer
      def data : Pointer(Void)
        @data
      end
      
      # Get the size
      def size : LibC::SizeT
        @size
      end
      
      # Get the flags
      def flags : UInt32
        @flags
      end
    end
    
    # Represents a WiredTiger modify operation
    struct Modify
      # The data to insert/replace
      @data : Item
      # Offset in the value where the modification occurs
      @offset : LibC::SizeT
      # Number of bytes to replace (0 for insert)
      @size : LibC::SizeT
      
      def initialize(@data, @offset, @size)
      end
      
      # Create a Modify for inserting data at an offset
      def self.insert(data : String, offset : Int) : Modify
        item = Item.from_string(data)
        Modify.new(item, LibC::SizeT.new(offset), LibC::SizeT.new(0))
      end
      
      # Create a Modify for replacing data at an offset
      def self.replace(data : String, offset : Int, size : Int) : Modify
        item = Item.from_string(data)
        Modify.new(item, LibC::SizeT.new(offset), LibC::SizeT.new(size))
      end
      
      # Create a Modify for removing data at an offset
      def self.remove(offset : Int, size : Int) : Modify
        item = Item.new(Pointer(Void).null, LibC::SizeT.new(0))
        Modify.new(item, LibC::SizeT.new(offset), LibC::SizeT.new(size))
      end
      
      # Get the data item
      def data : Item
        @data
      end
      
      # Get the offset
      def offset : LibC::SizeT
        @offset
      end
      
      # Get the size
      def size : LibC::SizeT
        @size
      end
    end
  end
end
