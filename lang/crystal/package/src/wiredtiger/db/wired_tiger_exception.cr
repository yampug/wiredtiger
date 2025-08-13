module WiredTiger
  module DB
    # Exception class for WiredTiger operations
    class WiredTigerException < Exception
      # Create a new WiredTigerException with the given message
      # @param message [String] Error message
      def initialize(message : String)
        super(message)
      end
      
      # Create a new WiredTigerException with the given message and cause
      # @param message [String] Error message
      # @param cause [Exception] Cause exception
      def initialize(message : String, cause : Exception)
        super(message, cause: cause)
      end
    end
  end
end
