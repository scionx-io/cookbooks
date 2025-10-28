#!/usr/bin/env ruby

# Example script to test the Tron gem with the get_wallet_portfolio method
# Test address: TCPh7Qd7DwHvphmfJGCQQgCGRP7aY4drEV

# Load environment variables from .env file
require 'dotenv/load' if File.exist?('.env')

# Load the gem
require 'bundler/setup' if File.exist?('Gemfile')
require 'tron'

# Configure the Tron gem
Tron.configure do |config|
  # Set API keys (replace with your actual API keys)
  config.api_key = ENV['TRONGRID_API_KEY'] # or Rails.application.credentials.trongrid_api_key
  config.tronscan_api_key = ENV['TRONSCAN_API_KEY'] # or Rails.application.credentials.tronscan_api_key
  config.network = :mainnet
  config.timeout = 30
  # Set up caching with your preferences
  config.cache = {
    enabled: true,
    ttl: 30,           # Cache fresh for 30 seconds
    max_stale: 300     # Serve stale data for up to 5 minutes if API fails
  }
end

# Create client instance
client = Tron::Client.new(
  api_key: ENV['TRONGRID_API_KEY'],
  tronscan_api_key: ENV['TRONSCAN_API_KEY'],
  network: :mainnet,
  timeout: 30,
  cache: {
    enabled: true,
    ttl: 30,
    max_stale: 300
  }
)

# Test address
test_address = ENV['TRON_WALLET_ADDRESS'] || 'TCPh7Qd7DwHvphmfJGCQQgCGRP7aY4drEV'

puts "Testing Tron wallet portfolio for address: #{test_address}"
puts "Using API keys: #{ENV['TRONGRID_API_KEY'] ? 'Yes' : 'No (Using defaults)'}"
puts "=" * 60

begin
  # Get the full wallet portfolio with retry logic for rate limiting
  portfolio = nil
  max_retries = 3
  retry_count = 0
  
  begin
    portfolio = client.get_wallet_portfolio(test_address)
  rescue => e
    if e.message.include?('429') && retry_count < max_retries
      puts "Rate limit exceeded (429). Retrying in #{2 ** retry_count} seconds... (Attempt #{retry_count + 1}/#{max_retries})"
      sleep(2 ** retry_count)  # Exponential backoff
      retry_count += 1
      retry
    elsif e.message.include?('429')
      puts "Rate limit exceeded (429). Maximum retries reached."
      raise e
    else
      raise e  # Re-raise if it's a different error
    end
  end

  if portfolio
    puts "Portfolio for #{test_address}:"
    puts "Total Value (USD): $#{portfolio[:total_value_usd].round(2)}"
    puts "\nTokens:"
    portfolio[:tokens].each do |token|
      # Format the token balance to avoid scientific notation in display
      formatted_balance = if token[:token_balance].abs < 1e-4 && token[:token_balance] != 0
                            # For very small balances, format to show full decimal without scientific notation
                            sprintf("%.#{token[:decimals] || 6}f", token[:token_balance]).gsub(/0+$/, '')
                          else
                            token[:token_balance].to_s
                          end
      puts "  #{token[:symbol]}: #{formatted_balance} (Price: $#{token[:price_usd] ? token[:price_usd].round(4) : 'N/A'}, Value: $#{token[:usd_value] ? token[:usd_value].round(2) : 'N/A'})"
    end

    puts "\nCache Statistics:"
    cache_stats = client.cache_stats
    puts "  Price service cache - Hits: #{cache_stats[:price][:hits]}, Misses: #{cache_stats[:price][:misses]}, Hit Rate: #{cache_stats[:price][:hit_rate]}%"
    puts "  Balance service cache - Hits: #{cache_stats[:balance][:hits]}, Misses: #{cache_stats[:balance][:misses]}, Hit Rate: #{cache_stats[:balance][:hit_rate]}%"
  end

rescue => e
  puts "Error occurred: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5)}" # Show the first 5 lines of backtrace
end

puts "\n" + "=" * 60
puts "Test completed."