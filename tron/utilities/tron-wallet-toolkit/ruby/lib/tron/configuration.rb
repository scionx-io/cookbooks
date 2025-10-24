# lib/tron/configuration.rb
module Tron
  class Configuration
    attr_accessor :api_key, :tronscan_api_key, :timeout, :base_url, :tronscan_base_url, :strict_mode
    attr_accessor :cache_enabled, :cache_ttl, :cache_max_stale
    attr_reader :network

    def initialize
      @network = :mainnet
      @timeout = 30
      @strict_mode = false
      # Cache configuration defaults
      @cache_enabled = true
      @cache_ttl = 300        # 5 minutes default TTL
      @cache_max_stale = 600  # 10 minutes max stale
      setup_urls
    end

    def network=(network)
      @network = network
      setup_urls
    end

    def cache=(options)
      if options.is_a?(Hash)
        @cache_enabled = options.fetch(:enabled, true)
        @cache_ttl = options.fetch(:ttl, 300)
        @cache_max_stale = options.fetch(:max_stale, 600)
      elsif options == false
        @cache_enabled = false
      end
    end

    private

    def setup_urls
      case @network
      when :mainnet
        @base_url = 'https://api.trongrid.io'
        @tronscan_base_url = 'https://apilist.tronscanapi.com'
      when :shasta
        @base_url = 'https://api.shasta.trongrid.io'
        @tronscan_base_url = 'https://shasta.tronscan.org'
      when :nile
        @base_url = 'https://nile.trongrid.io'
        @tronscan_base_url = 'https://nileapi.tronscan.org'
      else
        @base_url = 'https://api.trongrid.io'
        @tronscan_base_url = 'https://apilist.tronscanapi.com'
      end
    end
  end
end