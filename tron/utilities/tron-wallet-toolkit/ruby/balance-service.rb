#!/usr/bin/env ruby

require_relative './tron_wallet_toolkit'

if __FILE__ == $0
  wallet_address = ARGV[0]
  if wallet_address.nil? || wallet_address.empty?
    puts 'Error: No wallet address provided.'
    puts 'Usage: ruby balance-service.rb <TRON_WALLET_ADDRESS>'
    exit 1
  end

  begin
    balance_result = TronWalletFunctions.get_wallet_balance(wallet_address)
    puts JSON.pretty_generate(balance_result)
  rescue => e
    puts "Error: #{e.message}"
  end
end