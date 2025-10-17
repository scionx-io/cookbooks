#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load' if File.exist?('.env')

def test_api_call_with_address(address)
  api_key = ENV['TRONGRID_API_KEY']
  tron_web_url = 'https://api.trongrid.io'

  puts "Testing getaccountresource API call with address: #{address}"
  uri = URI("#{tron_web_url}/wallet/getaccountresource")
  
  headers = {
    'Content-Type' => 'application/json',
    'Accept' => 'application/json'
  }
  
  # Add API key if available
  headers['TRON-PRO-API-KEY'] = api_key if api_key && !api_key.empty? && api_key != ''
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 30
  
  # The exact format that works with curl
  request_body = { "address" => address, "visible" => true }.to_json
  puts "Request body: #{request_body}"
  puts "Request body class: #{request_body.class}"
  puts "Request body encoding: #{request_body.encoding}"
  
  request = Net::HTTP::Post.new(uri.path, headers)  # Note: using uri.path instead of uri.request_uri
  request.body = request_body
  
  puts "\nMaking request to: #{uri}"
  puts "Headers: #{headers}"
  
  response = http.request(request)
  
  puts "\nResponse code: #{response.code}"
  puts "Response body: #{response.body}"
  
  if response.code == '200'
    begin
      data = JSON.parse(response.body)
      puts "\nParsed data:"
      puts JSON.pretty_generate(data)
      
      # Check for the error condition
      if data.key?('Error')
        puts "\nERROR DETECTED in response: #{data['Error']}"
      else
        puts "\nSUCCESS: Got account resources data"
      end
    rescue JSON::ParserError => e
      puts "Could not parse JSON response: #{e.message}"
    end
  else
    puts "\nRequest failed with status #{response.code}"
    puts "Response headers: #{response.to_hash}"
  end
end

def test_getaccount(address)
  api_key = ENV['TRONGRID_API_KEY']
  tron_web_url = 'https://api.trongrid.io'

  puts "\n\nTesting getaccount API call with address: #{address}"
  uri = URI("#{tron_web_url}/wallet/getaccount")
  
  headers = {
    'Content-Type' => 'application/json',
    'Accept' => 'application/json'
  }
  
  # Add API key if available
  headers['TRON-PRO-API-KEY'] = api_key if api_key && !api_key.empty? && api_key != ''
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 30
  
  request_body = { "address" => address, "visible" => true }.to_json
  puts "Request body: #{request_body}"
  
  request = Net::HTTP::Post.new(uri.path, headers)
  request.body = request_body
  
  response = http.request(request)
  
  puts "\nResponse code: #{response.code}"
  puts "Response body length: #{response.body.length}"
  
  if response.code == '200'
    begin
      data = JSON.parse(response.body)
      if data.key?('data') && data['data'].is_a?(Array) && data['data'][0]
        account_data = data['data'][0]
        puts "Account address: #{account_data['address']}"
        
        # Look for resource information in the account data
        if account_data.key?('account_resource')
          puts "Account has resource info: #{account_data['account_resource']}"
        end
      end
    rescue => e
      puts "Error parsing getaccount response: #{e.message}"
    end
  end
end

# Use command line argument or default to the known working address
wallet_address = ARGV[0] || "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"

test_api_call_with_address(wallet_address)
test_getaccount(wallet_address)