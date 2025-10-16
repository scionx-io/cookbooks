#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
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
    uri = URI("#{@tron_web_url}/wallet/getaccountresource")
    uri.query = URI.encode_www_form(address: address)
    
    headers = {}
    headers['TRON-PRO-API-KEY'] = @api_key if @api_key
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = { address: address }.to_json
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      {
        bandwidth: (data['freeNetLimit'] || 0) - (data['freeNetUsed'] || 0),
        bandwidth_limit: data['freeNetLimit'] || 0,
        energy: (data['EnergyLimit'] || 0) - (data['EnergyUsed'] || 0),
        energy_limit: data['EnergyLimit'] || 0
      }
    else
      raise "API Error: #{response.code}"
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
      tokens.each { |t| puts "  #{t[:symbol].ljust(10)} #{t[:balance].round(t[:decimals]).to_s}" }
    end

    puts "\nAccount Resources:"
    res = get_account_resources(address)
    puts "  Bandwidth: #{format_number(res[:bandwidth])} / #{format_number(res[:bandwidth_limit])}"
    puts "  Energy:    #{format_number(res[:energy])} / #{format_number(res[:energy_limit])}"
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

  def self.check_balances(address)
    toolkit = TronWalletToolkit.new
    toolkit.check_balances(address)
  end
end