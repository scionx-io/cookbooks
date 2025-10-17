# lib/tron/utils/http.rb
require 'net/http'
require 'uri'
require 'json'

module Tron
  module Utils
    class HTTP
      def self.get(url, headers = {})
        make_request(Net::HTTP::Get, url, nil, headers)
      end

      def self.post(url, body = nil, headers = {})
        make_request(Net::HTTP::Post, url, body, headers)
      end

      private

      def self.make_request(method_class, url, body, headers)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.read_timeout = Tron.configuration.timeout

        request = method_class.new(uri.request_uri, headers)
        request.body = body if body

        response = http.request(request)
        
        case response
        when Net::HTTPSuccess
          json_response = JSON.parse(response.body)
          # Validate that the response is actually a hash/array before returning
          unless json_response.is_a?(Hash) || json_response.is_a?(Array)
            raise "Invalid response format: expected JSON object or array"
          end
          json_response
        else
          raise "API Error: #{response.code} - #{response.body}"
        end
      rescue JSON::ParserError
        raise "Invalid JSON response: #{response.body}"
      rescue => e
        raise "HTTP Error: #{e.message}"
      end
    end
  end
end