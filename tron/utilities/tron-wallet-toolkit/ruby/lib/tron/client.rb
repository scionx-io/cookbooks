# lib/tron/client.rb
require_relative 'configuration'
require_relative 'services/balance'
require_relative 'services/resources'
require_relative 'services/price'

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

    private

    def validate_address!(address)
      require_relative 'utils/address'
      raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
    end
  end
end