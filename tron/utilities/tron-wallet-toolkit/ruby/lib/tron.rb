# lib/tron.rb
require 'dotenv/load' if File.exist?('.env')

require_relative 'tron/version'
require_relative 'tron/client'
require_relative 'tron/configuration'

module Tron
  class << self
    def client
      @client ||= Client.new
    end

    def configure(&block)
      @client = nil # Reset client when configuration changes
      Client.configure(&block)
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