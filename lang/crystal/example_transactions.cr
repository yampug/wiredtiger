#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger Transactions with Memory Safety
puts "🚀 WiredTiger Transactions Example (Memory Safe)"
puts "================================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_transactions_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

# Memory-safe transaction operations with guaranteed cleanup
def run_transaction_example(db_dir : String)
  conn = nil
  session = nil
  
  begin
    # Open connection
    puts "\n📁 Opening database at: #{db_dir}"
    conn = WiredTiger::WiredTiger.open(db_dir, "create")
    session = conn.open_session
    
    puts "✅ Connection and session created successfully"
    
    # Create tables
    puts "\n🏗️  Creating tables..."
    session.create("table:accounts", "key_format=S,value_format=S")
    session.create("table:transactions", "key_format=S,value_format=S")
    puts "✅ Tables created successfully"
    
    # Example 1: Basic Transaction
    puts "\n💳 Example 1: Basic Transaction"
    puts "Creating accounts and performing a transfer..."
    
    # Create initial accounts
    cursor = session.open_cursor("table:accounts")
    begin
      cursor.put_key_string("account1")
      cursor.put_value_string("1000")
      cursor.insert
      
      cursor.put_key_string("account2")
      cursor.put_value_string("500")
      cursor.insert
      
      puts "  💰 Created accounts: account1 ($1000), account2 ($500)"
    ensure
      cursor.safe_close
    end
    
    # Perform a transfer transaction
    puts "  🔄 Performing transfer: $200 from account1 to account2..."
    
    session.begin_transaction
    
    cursor = session.open_cursor("table:accounts")
    begin
      # Deduct from account1
      cursor.put_key_string("account1")
      cursor.search
      balance1 = cursor.get_value_string.to_i
      new_balance1 = (balance1 - 200).to_s
      cursor.put_value_string(new_balance1)
      cursor.update
      
      # Add to account2
      cursor.put_key_string("account2")
      cursor.search
      balance2 = cursor.get_value_string.to_i
      new_balance2 = (balance2 + 200).to_s
      cursor.put_value_string(new_balance2)
      cursor.update
      
      # Log the transaction
      log_cursor = session.open_cursor("table:transactions")
      begin
        log_cursor.put_key_string("txn_001")
        log_cursor.put_value_string("Transfer: $200 from account1 to account2")
        log_cursor.insert
      ensure
        log_cursor.safe_close
      end
      
      session.commit_transaction
      puts "  ✅ Transfer completed successfully"
      
    ensure
      cursor.safe_close
    end
    
    # Display updated balances
    puts "  📊 Updated balances:"
    display_accounts(session, "table:accounts")
    
    # Example 2: Transaction Rollback
    puts "\n🔄 Example 2: Transaction Rollback"
    puts "Demonstrating rollback on insufficient funds..."
    
    session.begin_transaction
    
    cursor = session.open_cursor("table:accounts")
    begin
      # Try to transfer more than available
      cursor.put_key_string("account1")
      cursor.search
      balance1 = cursor.get_value_string.to_i
      
      if balance1 < 1000
        puts "  ❌ Insufficient funds for $1000 transfer (balance: $#{balance1})"
        session.rollback_transaction
        puts "  🔄 Transaction rolled back"
      else
        # This should not execute
        new_balance1 = (balance1 - 1000).to_s
        cursor.put_value_string(new_balance1)
        cursor.update
        session.commit_transaction
      end
    ensure
      cursor.safe_close
    end
    
    # Verify rollback worked
    puts "  📊 Balances after rollback:"
    display_accounts(session, "table:accounts")
    
    # Example 3: Nested Transactions (Not supported by WiredTiger)
    puts "\n⚠️  Example 3: Nested Transactions"
    puts "WiredTiger doesn't support nested transactions..."
    
    begin
      session.begin_transaction
      puts "  📝 Started outer transaction"
      
      # Try to start another transaction
      session.begin_transaction
      puts "  ❌ This should fail"
      
    rescue ex : WiredTiger::DB::WiredTigerException
      puts "  ✅ Correctly caught nested transaction error: #{ex.message}"
      # Rollback the outer transaction
      session.rollback_transaction
      puts "  🔄 Outer transaction rolled back"
    end
    
    # Example 4: Concurrent Transactions
    puts "\n🔄 Example 4: Concurrent Transactions"
    puts "Demonstrating concurrent transaction handling..."
    
    # Start first transaction
    session.begin_transaction
    
    cursor = session.open_cursor("table:accounts")
    begin
      cursor.put_key_string("account1")
      cursor.search
      balance1 = cursor.get_value_string.to_i
      puts "  📝 Transaction 1: Read account1 balance: $#{balance1}"
      
      # Simulate some work
      sleep(0.1)
      
      # Update balance
      new_balance1 = (balance1 + 100).to_s
      cursor.put_value_string(new_balance1)
      cursor.update
      puts "  💰 Transaction 1: Updated account1 balance to: $#{new_balance1}"
      
      session.commit_transaction
      puts "  ✅ Transaction 1 committed"
      
    ensure
      cursor.safe_close
    end
    
    # Start second transaction
    session.begin_transaction
    
    cursor = session.open_cursor("table:accounts")
    begin
      cursor.put_key_string("account2")
      cursor.search
      balance2 = cursor.get_value_string.to_i
      puts "  📝 Transaction 2: Read account2 balance: $#{balance2}"
      
      # Update balance
      new_balance2 = (balance2 + 50).to_s
      cursor.put_value_string(new_balance2)
      cursor.update
      puts "  💰 Transaction 2: Updated account2 balance to: $#{new_balance2}"
      
      session.commit_transaction
      puts "  ✅ Transaction 2 committed"
      
    ensure
      cursor.safe_close
    end
    
    # Display final balances
    puts "  📊 Final balances after concurrent transactions:"
    display_accounts(session, "table:accounts")
    
    # Example 5: Transaction with Error Handling
    puts "\n🛡️  Example 5: Transaction with Error Handling"
    puts "Demonstrating robust error handling in transactions..."
    
    begin
      session.begin_transaction
      
      cursor = session.open_cursor("table:accounts")
      begin
        # Try to access non-existent account
        cursor.put_key_string("nonexistent_account")
        cursor.search
        
        # This should fail
        balance = cursor.get_value_string
        puts "  ❌ This should not execute"
        
      rescue ex : WiredTiger::DB::WiredTigerException
        puts "  ✅ Correctly caught error: #{ex.message}"
        session.rollback_transaction
        puts "  🔄 Transaction rolled back due to error"
      ensure
        cursor.safe_close
      end
      
    rescue ex : Exception
      puts "  ❌ Unexpected error: #{ex.message}"
      session.rollback_transaction
      raise ex
    end
    
    puts "\n🎉 All transaction examples completed successfully!"
    
  rescue ex : WiredTiger::DB::WiredTigerException
    puts "❌ Database error: #{ex.message}"
    raise ex
    
  rescue ex : Exception
    puts "❌ Unexpected error: #{ex.message}"
    raise ex
    
  ensure
    # Guaranteed cleanup regardless of success or failure
    puts "\n🧹 Cleaning up resources..."
    session.safe_close if session
    conn.safe_close if conn
    puts "✅ Resources cleaned up successfully"
  end
end

# Helper method for displaying accounts with safe cursor management
def display_accounts(session : WiredTiger::DB::Session, table_name : String)
  cursor = session.open_cursor(table_name)
  begin
    while cursor.next == 0
      account_id = cursor.get_key_string
      balance = cursor.get_value_string
      puts "    #{account_id}: $#{balance}"
    end
  ensure
    cursor.safe_close  # Always cleaned up
  end
end

# Run the example with memory safety
begin
  run_transaction_example(db_dir)
rescue ex : Exception
  puts "❌ Example failed: #{ex.message}"
  exit 1
ensure
  # Clean up database directory
  if Dir.exists?(db_dir)
    puts "\n🗑️  Cleaning up database directory: #{db_dir}"
    FileUtils.rm_rf(db_dir)
    puts "✅ Database directory cleaned up"
  end
end
