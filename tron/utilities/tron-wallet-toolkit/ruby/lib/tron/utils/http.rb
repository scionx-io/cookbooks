# lib/tron/utils/http.rb
require 'net/http'
require 'uri'
require 'json'
require 'digest'

module Tron
  module Utils
    class HTTP
      # TTL values for different endpoint types (in seconds)
      # These are optimized based on data volatility
      ENDPOINT_TTL = {
        # Balance endpoints - moderate volatility (5 minutes)
        balance: { ttl: 300, max_stale: 600 },

        # Token info endpoints - low volatility (15 minutes)
        token_info: { ttl: 900, max_stale: 1800 },

        # Price endpoints - high volatility (1 minute)
        price: { ttl: 60, max_stale: 120 },

        # Account resources - moderate volatility (5 minutes)
        resources: { ttl: 300, max_stale: 600 },

        # Default for unclassified endpoints
        default: { ttl: 300, max_stale: 600 }
      }.freeze

      # GET request with optional caching
      # @param url [String] the URL to request
      # @param headers [Hash] request headers
      # @param cache_options [Hash] optional cache configuration
      # @option cache_options [Boolean] :enabled override global cache setting
      # @option cache_options [Integer] :ttl custom TTL in seconds
      # @option cache_options [Integer] :max_stale custom max_stale in seconds
      # @option cache_options [Symbol] :endpoint_type endpoint type for TTL lookup
      def self.get(url, headers = {}, cache_options = {})
        if should_use_cache?(cache_options)
          cache_key = generate_cache_key('GET', url, headers)
          ttl_config = get_ttl_config(cache_options)

          Tron::Cache.fetch(cache_key, ttl: ttl_config[:ttl], max_stale: ttl_config[:max_stale]) do
            make_request(Net::HTTP::Get, url, nil, headers)
          end
        else
          make_request(Net::HTTP::Get, url, nil, headers)
        end
      end

      # POST request (no caching for mutations)
      def self.post(url, body = nil, headers = {})
        make_request(Net::HTTP::Post, url, body, headers)
      end

      # Clear cache for a specific endpoint
      # @param url [String] the URL to clear from cache
      # @param headers [Hash] request headers used in the original request
      def self.clear_cache(url, headers = {})
        cache_key = generate_cache_key('GET', url, headers)
        Tron::Cache.delete(cache_key)
      end

      # Get cache statistics for an endpoint
      # @param url [String] the URL to get stats for
      # @param headers [Hash] request headers used in the original request
      def self.cache_stats(url, headers = {})
        cache_key = generate_cache_key('GET', url, headers)
        Tron::Cache.stats(cache_key)
      end

      private

      # Determine if caching should be used for this request
      def self.should_use_cache?(cache_options)
        # Check if caching is explicitly disabled for this request
        return false if cache_options[:enabled] == false

        # Otherwise, use global configuration
        Tron.configuration.cache_enabled
      end

      # Get TTL configuration for the request
      def self.get_ttl_config(cache_options)
        # If custom TTL provided, use it
        if cache_options[:ttl] && cache_options[:max_stale]
          return { ttl: cache_options[:ttl], max_stale: cache_options[:max_stale] }
        end

        # If endpoint type specified, use its TTL
        if cache_options[:endpoint_type] && ENDPOINT_TTL[cache_options[:endpoint_type]]
          return ENDPOINT_TTL[cache_options[:endpoint_type]]
        end

        # Use global configuration if set
        if Tron.configuration.cache_ttl && Tron.configuration.cache_max_stale
          return {
            ttl: Tron.configuration.cache_ttl,
            max_stale: Tron.configuration.cache_max_stale
          }
        end

        # Fall back to default
        ENDPOINT_TTL[:default]
      end

      # Generate a unique cache key based on request parameters
      def self.generate_cache_key(method, url, headers)
        # Include method, URL, and relevant headers in the cache key
        # Exclude headers that don't affect the response (like User-Agent)
        relevant_headers = headers.reject { |k, _| k.to_s.downcase == 'user-agent' }
        key_parts = [method, url, relevant_headers.sort.to_h]
        Digest::SHA256.hexdigest(key_parts.to_json)
      end

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