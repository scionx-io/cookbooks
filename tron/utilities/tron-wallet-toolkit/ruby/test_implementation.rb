#!/usr/bin/env ruby

require_relative './main'

# Test with a public TRON address to see if API calls work
# Using a public exchange address for testing
test_address = "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"  # Tron foundation wallet (public)

puts "Testing Ruby implementation with address: #{test_address}"

toolkit = TronWalletToolkit.new

begin
  # Test TRX balance
  puts "\nTesting TRX balance..."
  trx_balance = toolkit.get_trx_balance(test_address)
  puts "TRX Balance: #{trx_balance}"

  # Test TRC20 balances
  puts "\nTesting TRC20 balances..."
  trc20_balances = toolkit.get_all_trc20_balances(test_address)
  puts "TRC20 Balances found: #{trc20_balances.length}"
  trc20_balances.each { |token| puts "  #{token[:symbol]}: #{token[:balance]} (#{token[:decimals]} decimals)" }

  # Test account resources
  puts "\nTesting account resources..."
  resources = toolkit.get_account_resources(test_address)
  puts "Resources: #{resources}"

  # Test the full check_balances function
  puts "\nTesting full check_balances function..."
  toolkit.check_balances(test_address)

rescue => e
  puts "Error occurred: #{e.message}"
  puts e.backtrace
end