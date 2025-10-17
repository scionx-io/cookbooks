#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load' if File.exist?('.env')

def test_api_response(address)
  api_key = ENV['TRONGRID_API_KEY']
  tron_web_url = 'https://api.trongrid.io'

  puts "Testing getaccountresource API call with address: #{address}"
  uri = URI("#{tron_web_url}/wallet/getaccountresource")
  
  headers = {}
  headers['TRON-PRO-API-KEY'] = api_key if api_key
  headers['Content-Type'] = 'application/json'
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = { "address" => address, "visible" => true }.to_json
  response = http.request(request)
  
  puts "Response code: #{response.code}"
  puts "Response headers: #{response.to_hash}"
  puts "Response body: #{response.body}"
  
  if response.code == '200'
    begin
      data = JSON.parse(response.body)
      puts "\nParsed data:"
      puts JSON.pretty_generate(data)
      
      # Print specific fields that might contain resource data
      puts "\nResource data fields:"
      if data['data'] && data['data'].is_a?(Array) && data['data'][0]
        resource_info = data['data'][0]
        resource_info.each { |key, value| puts "  #{key}: #{value}" }
      else
        puts "  No data field or data is not an array"
      end
    rescue JSON::ParserError
      puts "Could not parse JSON response"
    end
  else
    puts "\nRequest failed with status #{response.code}"
  end
end

# Get address from command line arguments only (bypass environment for testing)
wallet_address = ARGV[0] || "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"

test_api_response(wallet_address)