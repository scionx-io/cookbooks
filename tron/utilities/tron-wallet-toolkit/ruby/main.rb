#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'base58'
require 'digest'
require 'dotenv/load' if File.exist?('.env')

class TronWalletToolkit
  def initialize
    @api_key = ENV['TRONGRID_API_KEY']
    @tronscan_api_key = ENV['TRONSCAN_API_KEY']
    @wallet_address = ENV['TRON_WALLET_ADDRESS'] || ARGV[0] || ''
    
    @tron_web_url = 'https://api.trongrid.io'
  end

  def format_balance(raw_balance, decimals)
    balance = raw_balance.to_i
    divisor = 10 ** decimals
    whole = balance / divisor
    fraction = balance % divisor
    "#{whole}.#{fraction.to_s.rjust(decimals, '0')}"
  end

  def get_trx_balance(address)
    puts "getTrxBalance address: #{address}"
    uri = URI("#{@tron_web_url}/v1/accounts/#{address}")
    
    headers = {}
    headers['TRON-PRO-API-KEY'] = @api_key if @api_key
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      balance_raw = data['data'][0]['balance'] || 0
      format_balance(balance_raw, 6)
    else
      raise "API Error: #{response.code}"
    end
  end

  def get_all_trc20_balances(address)
    url = "https://apilist.tronscanapi.com/api/account/wallet?address=#{address}&asset_type=1"
    
    headers = { 'accept' => 'application/json' }
    headers['TRON-PRO-API-KEY'] = @tronscan_api_key if @tronscan_api_key

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)

    if response.code == '200'
      data = JSON.parse(response.body)
      # Filter TRC20 tokens (token_type 20) with balance > 0
      (data['data'] || [])
        .select { |token| token['token_type'] == 20 && token['balance'].to_f > 0 }
        .map do |token|
          {
            symbol: token['token_abbr'] || token['token_name'],
            name: token['token_name'],
            balance: token['balance'].to_f,
            decimals: token['token_decimal'].to_i,
            address: token['token_id']
          }
        end
    else
      raise "API Error: #{response.code}"
    end
  end

  def get_account_resources(address)
    # Using the same approach as TronWeb - get account resources info
    uri = URI("#{@tron_web_url}/wallet/getaccountresource")
    
    headers = {}
    headers['TRON-PRO-API-KEY'] = @api_key if @api_key
    headers['Content-Type'] = 'application/json'
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # Use POST request with JSON body as TronWeb does, with visible flag
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = { "address" => address, "visible" => true }.to_json
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      
      # Check if there's an error in the response instead of data
      if data.key?('Error')
        puts "API returned error: #{data['Error']}"
        return {
          bandwidth: 0,
          bandwidth_limit: 0,
          energy: 0,
          energy_limit: 0,
          storage: 0,
          storage_limit: 0,
          total_free_bandwidth: 0,
          total_free_bandwidth_limit: 0
        }
      end
      
      # The response structure from getaccountresource endpoint has direct fields (not in a 'data' array)
      # Extract resource info from the response structure
      free_net_limit = data['freeNetLimit']&.to_i || 0
      free_net_used = data['freeNetUsed']&.to_i || 0
      total_net_limit = data['TotalNetLimit']&.to_i || 0
      energy_limit = data['EnergyLimit']&.to_i || 0
      energy_used = data['EnergyUsed']&.to_i || 0
      
      # Calculate available resources
      # For foundation/exchange wallets, there might not be usage data, only limits
      available_bandwidth = [0, free_net_limit - free_net_used].max
      available_energy = [0, energy_limit - energy_used].max
      available_total_net = [0, total_net_limit].max  # For foundation wallets, usage might not be tracked separately
      
      # Storage fields - these might not always be in the getaccountresource response
      # The getaccountresource response might not contain all fields for all account types
      {
        bandwidth: available_bandwidth,
        bandwidthLimit: free_net_limit,
        energy: available_energy,
        energyLimit: energy_limit,
        storage: 0,  # Storage might need to come from getaccount call
        storageLimit: 0,
        totalFreeBandwidth: available_total_net,
        totalFreeBandwidthLimit: total_net_limit
      }
    else
      # Log the error for debugging
      puts "getaccountresource API Error: #{response.code} - #{response.body}"
      # If getaccountresource fails, try getaccount endpoint
      get_account_resources_fallback(address)
    end
  rescue => e
    # If both fail, return zeros and log the error
    puts "Error getting account resources: #{e.message}"
    {
      bandwidth: 0,
      bandwidth_limit: 0,
      energy: 0,
      energy_limit: 0,
      storage: 0,
      storage_limit: 0,
      total_free_bandwidth: 0,
      total_free_bandwidth_limit: 0
    }
  end

  # Fallback method to get resources from getaccount endpoint
  def get_account_resources_fallback(address)
    uri = URI("#{@tron_web_url}/wallet/getaccount")
    
    headers = {}
    headers['TRON-PRO-API-KEY'] = @api_key if @api_key
    headers['Content-Type'] = 'application/json'
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = { "address" => address, "visible" => true }.to_json
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      
      # Extract resource info from account data
      account_data = data['data']&.first || {}
      
      # Get resource usage from the account data
      free_net_limit = account_data['freeNetLimit']&.to_i || 0
      free_net_used = account_data['freeNetUsed']&.to_i || 0
      energy_limit = account_data['EnergyLimit']&.to_i || 0
      energy_used = account_data['EnergyUsed']&.to_i || 0
      storage_limit = account_data['StorageLimit']&.to_i || 0
      storage_used = account_data['StorageUsed']&.to_i || 0
      
      {
        bandwidth: [0, free_net_limit - free_net_used].max,
        bandwidthLimit: free_net_limit,
        energy: [0, energy_limit - energy_used].max,
        energyLimit: energy_limit,
        storage: [0, storage_limit - storage_used].max,
        storageLimit: storage_limit,
        totalFreeBandwidth: 0,
        totalFreeBandwidthLimit: 0
      }
    else
      puts "getaccount API Error: #{response.code} - #{response.body}"
      # If both methods fail, return zeros
      {
        bandwidth: 0,
        bandwidth_limit: 0,
        energy: 0,
        energy_limit: 0,
        storage: 0,
        storage_limit: 0,
        total_free_bandwidth: 0,
        total_free_bandwidth_limit: 0
      }
    end
  end

  def get_token_price(token = 'trx')
    url = "https://apilist.tronscanapi.com/api/token/price?token=#{token}"
    headers = { 'accept' => 'application/json' }
    headers['TRON-PRO-API-KEY'] = @tronscan_api_key if @tronscan_api_key

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      warn "Warning: Could not fetch price for #{token}: #{response.code}"
      nil
    end
  rescue => e
    warn "Warning: Could not fetch price for #{token}: #{e.message}"
    nil
  end

  def get_all_token_prices
    url = "https://apilist.tronscanapi.com/api/getAssetWithPriceList"
    headers = { 'accept' => 'application/json' }
    headers['TRON-PRO-API-KEY'] = @tronscan_api_key if @tronscan_api_key

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      warn "Warning: Could not fetch token price list: #{response.code}"
      nil
    end
  rescue => e
    warn "Warning: Could not fetch token price list: #{e.message}"
    nil
  end

  def check_balances(address)
    raise 'Invalid TRON address.' if address.empty? || !address.start_with?('T')

    puts '═' * 60
    puts 'TRON WALLET BALANCE CHECKER'
    puts '═' * 60
    puts "Wallet: #{address}\n\n"

    puts 'TRX Balance:'
    puts "  #{get_trx_balance(address)} TRX\n\n"

    puts 'TRC20 Token Balances:'
    tokens = get_all_trc20_balances(address)
    if tokens.empty?
      puts '  (No token balances found)'
    else
      tokens.each { |t| puts "  #{t[:symbol].ljust(10)} #{sprintf("%.#{t[:decimals]}f", t[:balance])}" }
    end

    puts "\nAccount Resources:"
    res = get_account_resources(address)
    puts "  Bandwidth: #{format_number(res[:bandwidth]).ljust(15)} / #{format_number(res[:bandwidthLimit])}"
    puts "  Energy:    #{format_number(res[:energy]).ljust(15)} / #{format_number(res[:energyLimit])}"
    puts '═' * 60
  end

  def get_wallet_balance(address)
    raise 'Invalid TRON address.' if address.empty? || !address.start_with?('T')

    trx_balance = get_trx_balance(address)
    trc20_balances = get_all_trc20_balances(address)

    {
      address: address,
      trx_balance: trx_balance,
      trc20_tokens: trc20_balances
    }
  end

  private

  def format_number(num)
    num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def self.run_cli
    toolkit = TronWalletToolkit.new
    wallet_address = toolkit.instance_variable_get(:@wallet_address)

    if wallet_address.empty?
      puts 'Error: No wallet address provided'
      exit 1
    end

    toolkit.check_balances(wallet_address)
  end
end

if __FILE__ == $0
  TronWalletToolkit.run_cli
end

# Export functions for use as a module
module TronWalletFunctions
  def self.get_trx_balance(address)
    toolkit = TronWalletToolkit.new
    toolkit.get_trx_balance(address)
  end

  def self.get_all_trc20_balances(address)
    toolkit = TronWalletToolkit.new
    toolkit.get_all_trc20_balances(address)
  end

  def self.get_account_resources(address)
    toolkit = TronWalletToolkit.new
    toolkit.get_account_resources(address)
  end

  def self.get_token_price(token = 'trx')
    toolkit = TronWalletToolkit.new
    toolkit.get_token_price(token)
  end

  def self.get_all_token_prices
    toolkit = TronWalletToolkit.new
    toolkit.get_all_token_prices
  end

  def self.get_wallet_balance(address)
    toolkit = TronWalletToolkit.new
    toolkit.get_wallet_balance(address)
  end

  def self.check_balances(address)
    toolkit = TronWalletToolkit.new
    toolkit.check_balances(address)
  end
end