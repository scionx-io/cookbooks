# lib/tron/services/price.rb
require_relative '../utils/http'

module Tron
  module Services
    class Price
      def initialize(config)
        @config = config
      end

      def get_token_price(token = 'trx')
        url = "#{@config.tronscan_base_url}/api/token/price?token=#{token}"
        headers = tronscan_headers
        
        response = Utils::HTTP.get(url, headers)
        
        # Validate response structure
        unless response.is_a?(Hash)
          raise "Unexpected API response format for token price"
        end
        
        response
      rescue => e
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
        price_data = get_token_price(token)
        return nil unless price_data.is_a?(Hash)
        
        if price_data['price_in_usd']
          price_data['price_in_usd'].to_f
        elsif price_data['priceInUsd']
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

      private

      def tronscan_headers
        headers = { 'accept' => 'application/json' }
        headers['TRON-PRO-API-KEY'] = @config.tronscan_api_key if @config.tronscan_api_key
        headers
      end
    end
  end
end