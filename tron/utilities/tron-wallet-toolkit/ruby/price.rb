#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load' if File.exist?('.env')

class TokenPriceService
  def initialize
    @tronscan_api_key = ENV['TRONSCAN_API_KEY']
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
      data = JSON.parse(response.body)
      # The API response structure might be different than expected
      # If the response contains price_usd or priceInUsd directly, return it
      # Otherwise, return the full response
      if data.key?('priceInUsd') || data.key?('price_usd') || data.is_a?(Hash)
        data
      else
        data
      end
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

  def get_token_price_usd(token)
    price_data = get_token_price(token)
    if price_data && price_data['price_in_usd']
      price_data['price_in_usd'].to_f
    elsif price_data && price_data['priceInUsd']
      price_data['priceInUsd'].to_f
    else
      nil
    end
  end

  def get_token_value_usd(balance, token)
    price = get_token_price_usd(token)
    if price
      balance_num = balance.to_f
      balance_num * price
    else
      nil
    end
  end

  def get_multiple_token_prices(tokens)
    prices = {}
    tokens.each_with_index do |token, index|
      # Add a small delay between requests to avoid rate limiting
      sleep(0.1) if index > 0
      prices[token] = get_token_price_usd(token)
    end
    prices
  end

  def format_price(price, currency = 'USD')
    if price.nil?
      '(price unavailable)'
    elsif price < 0.0001
      "#{sprintf('%.8f', price)} #{currency}"
    elsif price < 1
      "#{sprintf('%.6f', price)} #{currency}"
    else
      "#{sprintf('%.4f', price)} #{currency}"
    end
  end
end

if __FILE__ == $0
  token = ARGV[0] || 'trx'
  
  puts "Getting price for #{token.upcase}..."
  
  service = TokenPriceService.new
  price_data = service.get_token_price(token)
  
  if price_data
    puts "#{token.upcase} Price Information:"
    price_in_usd = price_data['price_in_usd'] || price_data['priceInUsd']
    puts "Price in USD: #{price_in_usd ? sprintf('%.4f', price_in_usd.to_f) : 'N/A'}"
    
    price_in_btc = price_data['price_btc'] || price_data['priceInBtc']
    puts "Price in BTC: #{price_in_btc ? sprintf('%.8f', price_in_btc.to_f) : 'N/A'}"
  else
    puts "Could not retrieve price for #{token}"
  end
end

# Export functions for use as a module
module TokenPriceFunctions
  def self.get_token_price(token = 'trx')
    service = TokenPriceService.new
    service.get_token_price(token)
  end

  def self.get_all_token_prices
    service = TokenPriceService.new
    service.get_all_token_prices
  end

  def self.get_token_price_usd(token)
    service = TokenPriceService.new
    service.get_token_price_usd(token)
  end

  def self.get_token_value_usd(balance, token)
    service = TokenPriceService.new
    service.get_token_value_usd(balance, token)
  end

  def self.get_multiple_token_prices(tokens)
    service = TokenPriceService.new
    service.get_multiple_token_prices(tokens)
  end

  def self.format_price(price, currency = 'USD')
    service = TokenPriceService.new
    service.format_price(price, currency)
  end
end