# lib/tron/client.rb
require_relative 'configuration'
require_relative 'services/balance'
require_relative 'services/resources'
require_relative 'services/price'
require_relative 'services/contract'
require_relative 'services/transaction'

module Tron
  # The main client class for interacting with the TRON blockchain
  # Provides methods for checking balances, resources, prices, and contract interactions
  class Client
    attr_reader :configuration

    # Creates a new client instance with the given options
    #
    # @param options [Hash] configuration options
    # @option options [String] :api_key TronGrid API key
    # @option options [String] :tronscan_api_key Tronscan API key
    # @option options [Symbol] :network network to use (:mainnet, :shasta, :nile)
    # @option options [Integer] :timeout timeout for API requests
    # @option options [Boolean] :cache_enabled whether caching is enabled
    # @option options [Integer] :cache_ttl cache TTL in seconds
    # @option options [Integer] :cache_max_stale max stale time in seconds
    # @option options [String] :default_address default address for read-only calls
    # @option options [Integer] :fee_limit default fee limit for transactions
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

    # Configures the default client
    #
    # @yield [config] block to configure the client
    # @yieldparam [Tron::Configuration] config the configuration object
    def self.configure
      yield configuration if block_given?
    end

    # Returns the default configuration
    #
    # @return [Tron::Configuration] the configuration object
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Returns the balance service instance
    #
    # @return [Tron::Services::Balance] the balance service
    def balance_service
      @balance_service ||= Services::Balance.new(@configuration)
    end

    # Returns the resources service instance
    #
    # @return [Tron::Services::Resources] the resources service
    def resources_service
      @resources_service ||= Services::Resources.new(@configuration)
    end

    # Returns the price service instance
    #
    # @return [Tron::Services::Price] the price service
    def price_service
      @price_service ||= Services::Price.new(@configuration)
    end

    # Returns the contract service instance
    #
    # @return [Tron::Services::Contract] the contract service
    def contract_service
      @contract_service ||= Services::Contract.new(@configuration)
    end

    # Returns the transaction service instance
    #
    # @return [Tron::Services::Transaction] the transaction service
    def transaction_service
      @transaction_service ||= Services::Transaction.new(@configuration)
    end

    # Get wallet balance information including TRX and TRC20 tokens
    #
    # @param address [String] TRON address to check
    # @param strict [Boolean] whether to enable strict validation
    # @return [Hash] balance information hash
    def get_wallet_balance(address, strict: false)
      validate_address!(address)
      
      {
        address: address,
        trx_balance: balance_service.get_trx(address),
        trc20_tokens: balance_service.get_trc20_tokens(address, strict: strict)
      }
    end

    # Get complete account information including balances and resources
    #
    # @param address [String] TRON address to check
    # @param strict [Boolean] whether to enable strict validation
    # @return [Hash] full account information hash
    def get_full_account_info(address, strict: false)
      validate_address!(address)
      
      {
        address: address,
        trx_balance: balance_service.get_trx(address),
        trc20_tokens: balance_service.get_trc20_tokens(address, strict: strict),
        resources: resources_service.get(address)
      }
    end

    # Get wallet portfolio including balances converted to USD values
    #
    # @param address [String] TRON address to check
    # @param include_zero_balances [Boolean] whether to include tokens with zero balance
    # @return [Hash] portfolio information with USD values
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

    # Check if caching is enabled
    #
    # @return [Boolean] true if caching is enabled
    def cache_enabled?
      configuration.cache_enabled
    end

    # Get cache statistics
    #
    # @return [Hash] cache statistics for different services
    def cache_stats
      {
        price: price_service.cache_stats,
        balance: balance_service.cache_stats
      }
    end

    # Clear all caches
    def clear_cache
      price_service.clear_cache
      balance_service.clear_cache
    end

    private

    # Validates a TRON address
    #
    # @param address [String] TRON address to validate
    # @raise [ArgumentError] if the address is invalid
    def validate_address!(address)
      require_relative 'utils/address'
      raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
    end
  end
end