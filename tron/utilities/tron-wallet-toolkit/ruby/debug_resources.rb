#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load' if File.exist?('.env')

def debug_account_resources(address)
  api_key = ENV['TRONGRID_API_KEY']
  tron_web_url = 'https://api.trongrid.io'

  # Debug getaccountresource
  puts "Testing getaccountresource API call..."
  uri = URI("#{tron_web_url}/wallet/getaccountresource")
  
  headers = {}
  headers['TRON-PRO-API-KEY'] = api_key if api_key
  headers['Content-Type'] = 'application/json'
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = { "address" => address }.to_json
  response = http.request(request)
  
  puts "Response code: #{response.code}"
  puts "Response body: #{response.body}"
  
  if response.code == '200'
    data = JSON.parse(response.body)
    puts "\nParsed data structure:"
    puts JSON.pretty_generate(data)
  end

  # Also test getaccount
  puts "\n\nTesting getaccount API call..."
  uri2 = URI("#{tron_web_url}/wallet/getaccount")
  
  headers2 = {}
  headers2['TRON-PRO-API-KEY'] = api_key if api_key
  headers2['Content-Type'] = 'application/json'
  
  http2 = Net::HTTP.new(uri2.host, uri2.port)
  http2.use_ssl = true
  
  request2 = Net::HTTP::Post.new(uri2.request_uri, headers2)
  request2.body = { "address" => address }.to_json
  response2 = http2.request(request2)
  
  puts "Response code: #{response2.code}"
  puts "Response body: #{response2.body}"
  
  if response2.code == '200'
    data2 = JSON.parse(response2.body)
    puts "\nParsed data structure:"
    puts JSON.pretty_generate(data2)
  end
end

# Get address from command line or environment
wallet_address = ENV['TRON_WALLET_ADDRESS'] || ARGV[0]

if wallet_address.nil? || wallet_address.empty?
  puts 'Error: No wallet address provided'
  puts 'Usage: ruby debug_resources.rb <TRON_WALLET_ADDRESS>'
  exit 1
end

debug_account_resources(wallet_address)