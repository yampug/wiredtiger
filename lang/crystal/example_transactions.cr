#!/usr/bin/env crystal

require "./src/wiredtiger"
require "file_utils"

# Example demonstrating WiredTiger transaction functionality
puts "🚀 WiredTiger Transaction Example"
puts "=================================="

# Create a unique database directory
db_dir = "/tmp/wiredtiger_transaction_example_#{Random::Secure.hex(8)}"
Dir.mkdir_p(db_dir)

begin
  # Open connection
  puts "\n📁 Opening database at: #{db_dir}"
  conn = WiredTiger::WiredTiger.open(db_dir, "create")
  session = conn.open_session
  
  puts "✅ Connection and session created successfully"
  
  # Create tables
  puts "\n🏗️  Creating tables..."
  session.create("table:accounts", "key_format=S,value_format=i")
  session.create("table:transactions", "key_format=S,value_format=S")
  puts "✅ Tables created successfully"
  
  # Initialize account data
  puts "\n💰 Initializing account data..."
  cursor = session.open_cursor("table:accounts")
  
  cursor.put_key_string("account1")
  cursor.put_value_int(1000_i64)
  cursor.insert
  
  cursor.put_key_string("account2")
  cursor.put_value_int(500_i64)
  cursor.insert
  
  cursor.put_key_string("account3")
  cursor.put_value_int(750_i64)
  cursor.insert
  
  cursor.close
  puts "✅ Account data initialized"
  
  # Display initial balances
  puts "\n📊 Initial Account Balances:"
  cursor = session.open_cursor("table:accounts")
  while cursor.next == 0
    account = cursor.get_key_string
    balance = cursor.get_value_int
    puts "  #{account}: $#{balance}"
  end
  cursor.close
  
  # Example 1: Simple transaction
  puts "\n🔄 Example 1: Simple Transaction"
  puts "Transferring $100 from account1 to account2..."
  
  session.begin_transaction
  
  # Read current balances
  cursor = session.open_cursor("table:accounts")
  
  cursor.put_key_string("account1")
  cursor.search
  balance1 = cursor.get_value_int
  
  cursor.put_key_string("account2")
  cursor.search
  balance2 = cursor.get_value_int
  
  # Update balances
  cursor.put_key_string("account1")
  cursor.put_value_int(balance1 - 100)
  cursor.update
  
  cursor.put_key_string("account2")
  cursor.put_value_int(balance2 + 100)
  cursor.update
  
  cursor.close
  
  # Commit transaction
  session.commit_transaction
  puts "✅ Transaction committed successfully"
  
  # Example 2: Transaction with rollback
  puts "\n🔄 Example 2: Transaction with Rollback"
  puts "Attempting to transfer $2000 from account3 (insufficient funds)..."
  
  session.begin_transaction
  
  cursor = session.open_cursor("table:accounts")
  
  cursor.put_key_string("account3")
  cursor.search
  balance3 = cursor.get_value_int
  
  if balance3 >= 2000
    cursor.put_value_int(balance3 - 2000)
    cursor.update
    puts "  ✅ Transfer would succeed"
  else
    puts "  ❌ Insufficient funds: $#{balance3} < $2000"
    puts "  🔄 Rolling back transaction..."
    session.rollback_transaction
    puts "  ✅ Transaction rolled back"
  end
  
  cursor.close
  
  # Example 3: Transaction with isolation levels
  puts "\n🔄 Example 3: Transaction with Isolation Levels"
  
  # Snapshot isolation
  session.begin_transaction("isolation=snapshot")
  cursor = session.open_cursor("table:accounts")
  cursor.put_key_string("account1")
  cursor.search
  snapshot_balance = cursor.get_value_int
  cursor.close
  session.commit_transaction
  puts "  ✅ Snapshot isolation transaction completed"
  
  # Read-committed isolation
  session.begin_transaction("isolation=read-committed")
  cursor = session.open_cursor("table:accounts")
  cursor.put_key_string("account2")
  cursor.search
  committed_balance = cursor.get_value_int
  cursor.close
  session.commit_transaction
  puts "  ✅ Read-committed isolation transaction completed"
  
  # Example 4: Complex transaction with multiple tables
  puts "\n🔄 Example 4: Complex Transaction with Multiple Tables"
  puts "Recording transaction history..."
  
  session.begin_transaction
  
  # Update account balances
  cursor = session.open_cursor("table:accounts")
  cursor.put_key_string("account1")
  cursor.search
  balance1 = cursor.get_value_int
  cursor.put_value_int(balance1 - 50)
  cursor.update
  
  cursor.put_key_string("account3")
  cursor.search
  balance3 = cursor.get_value_int
  cursor.put_value_int(balance3 + 50)
  cursor.update
  cursor.close
  
  # Record transaction
  cursor = session.open_cursor("table:transactions")
  transaction_id = "txn_#{Time.utc.to_unix}"
  cursor.put_key_string(transaction_id)
  cursor.put_value_string("Transfer $50 from account1 to account3")
  cursor.insert
  cursor.close
  
  # Commit all changes atomically
  session.commit_transaction
  puts "✅ Complex transaction committed successfully"
  
  # Display final balances
  puts "\n📊 Final Account Balances:"
  cursor = session.open_cursor("table:accounts")
  while cursor.next == 0
    account = cursor.get_key_string
    balance = cursor.get_value_int
    puts "  #{account}: $#{balance}"
  end
  cursor.close
  
  # Display transaction history
  puts "\n📝 Transaction History:"
  cursor = session.open_cursor("table:transactions")
  while cursor.next == 0
    txn_id = cursor.get_key_string
    description = cursor.get_value_string
    puts "  #{txn_id}: #{description}"
  end
  cursor.close
  
  puts "\n🎉 All transaction examples completed successfully!"
  
rescue ex : Exception
  puts "\n❌ Error occurred: #{ex.message}"
  puts ex.backtrace.join("\n")
  
ensure
  # Clean up
  puts "\n🧹 Cleaning up..."
  if session && !session.closed?
    session.close
  end
  if conn && !conn.closed?
    conn.close
  end
  
  # Remove database directory
  if Dir.exists?(db_dir)
    FileUtils.rm_rf(db_dir)
    puts "✅ Database directory removed: #{db_dir}"
  end
end

puts "\n✨ Transaction example completed!"
