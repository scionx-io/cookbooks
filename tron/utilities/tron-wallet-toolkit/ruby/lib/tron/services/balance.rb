# lib/tron/services/balance.rb
require_relative '../utils/http'
require_relative '../utils/address'
require_relative '../utils/cache'
require_relative '../utils/rate_limiter'

module Tron
  module Services
    class Balance
      def initialize(config)
        @config = config
        @cache = Utils::Cache.new(max_age: config.cache_ttl) if config.cache_enabled
        @rate_limiter = Utils::RateLimiter.new(max_requests: 1, time_window: 1.0)
        @cache_hits = 0
        @cache_misses = 0
      end

      def get_trx(address)
        validate_address!(address)

        cache_key = "balance:trx:#{address}:#{@config.network}"

        # Check cache first
        if @config.cache_enabled && (cached = @cache.get(cache_key))
          @cache_hits += 1
          return cached
        end

        @cache_misses += 1

        # Rate limit before API call
        @rate_limiter.execute_request

        url = "#{@config.base_url}/v1/accounts/#{address}"
        headers = api_headers

        response = Utils::HTTP.get(url, headers)

        # Validate response structure
        raise "Unexpected API response format" unless response.is_a?(Hash)
        raise "Missing 'data' field in response" unless response.key?('data')
        raise "Invalid 'data' format in response" unless response['data'].is_a?(Array)
        raise "Empty account data in response" if response['data'].empty?

        account_data = response['data'].first
        raise "Invalid account data format" unless account_data.is_a?(Hash)

        # The balance field is only present when > 0; defaults to 0 for new/empty accounts
        raw_balance = account_data.fetch('balance', 0)
        result = format_balance(raw_balance, 6)

        # Cache the result
        @cache.set(cache_key, result) if @config.cache_enabled

        result
      end

      def get_trc20_tokens(address, strict: false)
        validate_address!(address)

        cache_key = "balance:trc20:#{address}:#{@config.network}"

        # Check cache first
        if @config.cache_enabled && (cached = @cache.get(cache_key))
          @cache_hits += 1
          return cached
        end

        @cache_misses += 1

        # Rate limit before API call
        @rate_limiter.execute_request

        url = "#{@config.tronscan_base_url}/api/account/wallet?address=#{address}&asset_type=1"
        headers = tronscan_headers

        response = Utils::HTTP.get(url, headers)

        # Validate response structure
        raise "Unexpected API response format for TRC20 tokens" unless response.is_a?(Hash)
        raise "Missing 'data' field in TRC20 response" unless response.key?('data')
        raise "Invalid 'data' format in TRC20 response" unless response['data'].is_a?(Array)

        result = response['data'].select { |token| token['token_type'] == 20 && token['balance'].to_f > 0 }
          .map do |token|
            validate_token_data!(token)
            {
              symbol: token['token_abbr'] || token['token_name'],
              name: token['token_name'],
              balance: token['balance'].to_f,
              decimals: (token['token_decimal'] || 6).to_i,
              address: token['token_id']
            }
          end

        # Cache the result
        @cache.set(cache_key, result) if @config.cache_enabled

        result
      end

      def cache_stats
        total = @cache_hits + @cache_misses
        {
          hits: @cache_hits,
          misses: @cache_misses,
          total: total,
          hit_rate: total > 0 ? (@cache_hits.to_f / total * 100).round(2) : 0.0
        }
      end

      def clear_cache
        @cache&.clear
        @cache_hits = 0
        @cache_misses = 0
      end

      private

      def validate_token_data!(token)
        unless token.is_a?(Hash)
          raise "Invalid token data format: expected hash"
        end
        
        # Check required fields exist
        ['token_type', 'balance'].each do |field|
          unless token.key?(field)
            raise "Missing required field '#{field}' in token data: #{token}"
          end
        end
      end

      def get_all(address, strict: false)
        validate_address!(address)
        
        {
          address: address,
          trx_balance: get_trx(address),
          trc20_tokens: get_trc20_tokens(address, strict: strict)
        }
      end

      private

      def validate_address!(address)
        raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
      end

      def format_balance(raw_balance, decimals)
        balance = raw_balance.to_i
        divisor = 10 ** decimals
        whole = balance / divisor
        fraction = balance % divisor
        "#{whole}.#{fraction.to_s.rjust(decimals, '0')}"
      end

      def api_headers
        headers = { 'accept' => 'application/json' }
        headers['TRON-PRO-API-KEY'] = @config.api_key if @config.api_key
        headers
      end

      def tronscan_headers
        headers = { 'accept' => 'application/json' }
        headers['TRON-PRO-API-KEY'] = @config.tronscan_api_key if @config.tronscan_api_key
        headers
      end
    end
  end
end