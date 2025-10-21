# lib/tron.rb
require 'dotenv/load' if File.exist?('.env')

require_relative 'tron/version'
require_relative 'tron/client'
require_relative 'tron/configuration'
require_relative 'tron/cache'

module Tron
  class << self
    def client
      @client ||= Client.new(
        api_key: Client.configuration.api_key,
        tronscan_api_key: Client.configuration.tronscan_api_key,
        network: Client.configuration.network,
        timeout: Client.configuration.timeout
      )
    end

    def configure(&block)
      @client = nil # Reset client when configuration changes
      Client.configure(&block)
    end

    def configuration
      Client.configuration
    end

    # Delegate common methods to the default client
    def method_missing(method, *args, &block)
      if client.respond_to?(method)
        client.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      client.respond_to?(method) || super
    end
  end
end