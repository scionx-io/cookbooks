# lib/tron/services/price.rb
require_relative '../utils/http'
require_relative '../utils/cache'
require_relative '../utils/rate_limiter'

module Tron
  module Services
    class Price
      def initialize(config)
        @config = config
        @cache = Utils::Cache.new(max_age: config.cache_ttl) if config.cache_enabled
        @rate_limiter = Utils::RateLimiter.new(max_requests: 1, time_window: 1.0)
        @cache_hits = 0
        @cache_misses = 0
      end

      def get_token_price(token = 'trx')
        cache_key = cache_key_for(token)

        # Check cache first
        if @config.cache_enabled && (cached = @cache.get(cache_key))
          @cache_hits += 1
          return cached
        end

        @cache_misses += 1

        # Rate limit before API call
        @rate_limiter.execute_request

        url = "#{@config.tronscan_base_url}/api/token/price?token=#{token}"
        headers = tronscan_headers

        response = Utils::HTTP.get(url, headers)

        # Validate response structure
        unless response.is_a?(Hash)
          raise "Unexpected API response format for token price"
        end

        # Cache the successful response
        @cache.set(cache_key, response) if @config.cache_enabled

        response
      rescue => e
        # Serve stale data if available
        if @config.cache_enabled && cached
          warn "Warning: API error for #{token}, serving stale cache: #{e.message}"
          return cached
        end

        if @config.strict_mode
          raise e
        else
          warn "Warning: Could not fetch price for #{token}: #{e.message}"
          nil
        end
      end

      def get_all_prices
        url = "#{@config.tronscan_base_url}/api/getAssetWithPriceList"
        headers = tronscan_headers
        
        response = Utils::HTTP.get(url, headers)
        
        # Validate response structure
        unless response.is_a?(Hash)
          raise "Unexpected API response format for price list"
        end
        
        response
      rescue => e
        if @config.strict_mode
          raise e
        else
          warn "Warning: Could not fetch token price list: #{e.message}"
          nil
        end
      end

      def get_token_price_usd(token)
        cache_key = "#{cache_key_for(token)}:usd"

        # Check cache first for the USD price directly
        if @config.cache_enabled && (cached = @cache.get(cache_key))
          @cache_hits += 1
          return cached
        end

        @cache_misses += 1
        price_data = get_token_price(token)
        return nil unless price_data.is_a?(Hash)

        result = if price_data['price_in_usd']
          price_data['price_in_usd'].to_f
        elsif price_data['priceInUsd']
          price_data['priceInUsd'].to_f
        else
          nil
        end

        # Cache the USD price
        @cache.set(cache_key, result) if @config.cache_enabled && result

        result
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
          begin
            prices[token] = get_token_price_usd(token)
          rescue => e
            if @config.strict_mode
              raise e
            else
              warn "Warning: Could not fetch price for #{token}: #{e.message}"
              prices[token] = nil
            end
          end
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

      def cache_key_for(token)
        "price:#{token.downcase}:#{@config.network}"
      end

      def tronscan_headers
        headers = { 'accept' => 'application/json' }
        headers['TRON-PRO-API-KEY'] = @config.tronscan_api_key if @config.tronscan_api_key
        headers
      end
    end
  end
end