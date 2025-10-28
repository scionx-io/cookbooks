# lib/tron.rb
require 'dotenv/load' if File.exist?('.env')

require_relative 'tron/version'
require_relative 'tron/client'
require_relative 'tron/configuration'
require_relative 'tron/cache'
require_relative 'tron/key'
require_relative 'tron/signature'
require_relative 'tron/abi'
require_relative 'tron/contract'
require_relative 'tron/protobuf'

# The main module for the Tron Ruby Client
# This module provides a simplified interface to interact with the TRON blockchain
module Tron
  class << self
    # Returns the default client instance
    # Creates a new instance if one doesn't exist
    #
    # @return [Tron::Client] the client instance
    def client
      @client ||= Client.new(
        api_key: Client.configuration.api_key,
        tronscan_api_key: Client.configuration.tronscan_api_key,
        network: Client.configuration.network,
        timeout: Client.configuration.timeout
      )
    end

    # Configures the default client
    # Resets the client when configuration changes
    #
    # @yield [config] block to configure the client
    # @yieldparam [Tron::Configuration] config the configuration object
    def configure(&block)
      @client = nil # Reset client when configuration changes
      Client.configure(&block)
    end

    # Returns the current configuration
    #
    # @return [Tron::Configuration] the configuration object
    def configuration
      Client.configuration
    end

    # Delegates common methods to the default client
    #
    # @param method [Symbol] the method to call
    # @param args [Array] arguments to pass to the method
    # @param block [Proc] block to pass to the method
    # @return the result of the method call
    def method_missing(method, *args, &block)
      if client.respond_to?(method)
        client.send(method, *args, &block)
      else
        super
      end
    end

    # Checks if the module responds to a method
    #
    # @param method [Symbol] the method to check
    # @param include_private [Boolean] whether to include private methods
    # @return [Boolean] true if the module responds to the method
    def respond_to_missing?(method, include_private = false)
      client.respond_to?(method) || super
    end
  end
end