require "./cursor"

module WiredTiger
  module DB
    # Represents a backup cursor for creating database backups
    class BackupCursor < Cursor
      # Get the next backup file
      # @return [String?] The filename of the next backup file, or nil if no more files
      def next_file : String?
        ret = self.next
        return nil if ret != 0
        
        get_key_string
      end
      
      # Get all backup files as an array
      # @return [Array(String)] Array of backup filenames
      def all_files : Array(String)
        files = [] of String
        
        reset
        while (filename = next_file)
          files << filename
        end
        
        files
      end
      
      # Copy backup files to a target directory
      # @param target_dir [String] The target directory for the backup
      # @param source_dir [String] The source directory (usually the database home)
      # @return [Array(String)] Array of copied filenames
      def copy_files(target_dir : String, source_dir : String) : Array(String)
        copied_files = [] of String
        
        reset
        while (filename = next_file)
          source_path = File.join(source_dir, filename)
          target_path = File.join(target_dir, filename)
          
          if File.exists?(source_path)
            # Ensure target directory exists
            Dir.mkdir_p(File.dirname(target_path)) unless Dir.exists?(File.dirname(target_path))
            File.copy(source_path, target_path)
            copied_files << filename
          end
        end
        
        copied_files
      end
      
      # Take a full backup by copying all files to a target directory
      # @param target_dir [String] The target directory for the backup
      # @param source_dir [String] The source directory (usually the database home)
      # @return [Array(String)] Array of copied filenames
      def take_full_backup(target_dir : String, source_dir : String) : Array(String)
        # Ensure target directory exists
        Dir.mkdir_p(target_dir) unless Dir.exists?(target_dir)
        
        # Copy all files
        copy_files(target_dir, source_dir)
      end
      
      # Take an incremental backup by copying only log files to a target directory
      # @param target_dir [String] The target directory for the backup
      # @param source_dir [String] The source directory (usually the database home)
      # @return [Array(String)] Array of copied filenames
      def take_incremental_backup(target_dir : String, source_dir : String) : Array(String)
        # Ensure target directory exists
        Dir.mkdir_p(target_dir) unless Dir.exists?(target_dir)
        
        # For incremental backup, we only want log files
        # This is typically done by setting target=("log:") in the cursor config
        copy_files(target_dir, source_dir)
      end
      
      # Truncate the backup cursor to archive processed files
      # This is typically called after a successful incremental backup
      # @param session [Session] The session to use for truncation
      def truncate_after_backup(session : Session)
        # Truncate log files after successful backup
        # This archives the log files that have been processed
        session.truncate("log:", self, nil, nil)
      end
    end
  end
end
