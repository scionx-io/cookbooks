# lib/tron/client.rb
require_relative 'configuration'
require_relative 'services/balance'
require_relative 'services/resources'
require_relative 'services/price'
require_relative 'services/contract'

module Tron
  class Client
    attr_reader :configuration

    def initialize(options = {})
      @configuration = Configuration.new
      
      # Apply options
      options.each do |key, value|
        if @configuration.respond_to?("#{key}=")
          @configuration.send("#{key}=", value)
        end
      end

      # Load from environment if not set in options
      @configuration.api_key ||= ENV['TRONGRID_API_KEY']
      @configuration.tronscan_api_key ||= ENV['TRONSCAN_API_KEY']
    end

    def self.configure
      yield configuration if block_given?
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def balance_service
      @balance_service ||= Services::Balance.new(@configuration)
    end

    def resources_service
      @resources_service ||= Services::Resources.new(@configuration)
    end

    def price_service
      @price_service ||= Services::Price.new(@configuration)
    end

    def contract_service
      @contract_service ||= Services::Contract.new(@configuration)
    end

    # Convenience methods that combine multiple services
    def get_wallet_balance(address, strict: false)
      validate_address!(address)
      
      {
        address: address,
        trx_balance: balance_service.get_trx(address),
        trc20_tokens: balance_service.get_trc20_tokens(address, strict: strict)
      }
    end

    def get_full_account_info(address, strict: false)
      validate_address!(address)
      
      {
        address: address,
        trx_balance: balance_service.get_trx(address),
        trc20_tokens: balance_service.get_trc20_tokens(address, strict: strict),
        resources: resources_service.get(address)
      }
    end

    def get_wallet_portfolio(address, include_zero_balances: false)
      validate_address!(address)

      # Step 1: Get all balances (TRX + TRC20)
      wallet_data = get_wallet_balance(address)

      tokens = []

      # Step 2: Process TRX (native token)
      trx_balance = wallet_data[:trx_balance].to_f
      if trx_balance > 0 || include_zero_balances
        trx_price = price_service.get_token_price_usd('trx')
        tokens << {
          symbol: 'TRX',
          name: 'Tronix',
          token_balance: trx_balance,
          decimals: 6,
          address: nil,
          price_usd: trx_price,
          usd_value: trx_price ? (trx_balance * trx_price) : nil
        }
      end

      # Step 3: Process TRC20 tokens
      wallet_data[:trc20_tokens].each do |token|
        next if token[:balance] <= 0 && !include_zero_balances

        # Get USD price for this token
        price_usd = price_service.get_token_price_usd(token[:symbol].downcase)
        usd_value = price_usd ? (token[:balance] * price_usd) : nil

        tokens << {
          symbol: token[:symbol],
          name: token[:name],
          token_balance: token[:balance],
          decimals: token[:decimals],
          address: token[:address],
          price_usd: price_usd,
          usd_value: usd_value
        }
      end

      # Step 4: Calculate total portfolio value
      total_value_usd = tokens.sum { |t| t[:usd_value] || 0 }

      # Step 5: Sort by value (highest first)
      tokens.sort_by! { |t| -(t[:usd_value] || 0) }

      {
        address: address,
        total_value_usd: total_value_usd,
        tokens: tokens
      }
    end

    def cache_enabled?
      configuration.cache_enabled
    end

    def cache_stats
      {
        price: price_service.cache_stats,
        balance: balance_service.cache_stats
      }
    end

    def clear_cache
      price_service.clear_cache
      balance_service.clear_cache
    end

    private

    def validate_address!(address)
      require_relative 'utils/address'
      raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
    end
  end
end