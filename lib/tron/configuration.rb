# lib/tron/configuration.rb
module Tron
  # Configuration class for the TRON client
  # Stores settings for API keys, network, timeouts, caching, etc.
  class Configuration
    # @return [String] TronGrid API key
    attr_accessor :api_key
    # @return [String] Tronscan API key
    attr_accessor :tronscan_api_key
    # @return [Integer] timeout for API requests in seconds
    attr_accessor :timeout
    # @return [String] base URL for TRON API
    attr_accessor :base_url
    # @return [String] base URL for Tronscan API
    attr_accessor :tronscan_base_url
    # @return [Boolean] whether strict validation is enabled
    attr_accessor :strict_mode
    # @return [Boolean] whether caching is enabled
    attr_accessor :cache_enabled
    # @return [Integer] cache TTL (time-to-live) in seconds
    attr_accessor :cache_ttl
    # @return [Integer] max stale time in seconds
    attr_accessor :cache_max_stale
    # @return [String] default address for read-only calls
    attr_accessor :default_address
    # @return [Integer] default fee limit for transactions
    attr_accessor :fee_limit
    # @return [Symbol] network (:mainnet, :shasta, :nile)
    attr_reader :network

    # Creates a new configuration instance with default values
    def initialize
      @network = :mainnet
      @timeout = 30
      @strict_mode = false
      # Cache configuration defaults
      @cache_enabled = true
      @cache_ttl = 300        # 5 minutes default TTL
      @cache_max_stale = 600  # 10 minutes max stale
      # Contract-related defaults
      @default_address = nil
      @fee_limit = 100_000_000  # 100 TRX default
      setup_urls
    end

    # Sets the network and updates the base URLs accordingly
    #
    # @param network [Symbol] the network to use (:mainnet, :shasta, :nile)
    def network=(network)
      @network = network
      setup_urls
    end

    # Sets cache configuration options
    #
    # @param options [Hash, Boolean] cache configuration or false to disable
    # @option options [Boolean] :enabled whether caching is enabled (default: true)
    # @option options [Integer] :ttl cache TTL in seconds (default: 300)
    # @option options [Integer] :max_stale max stale time in seconds (default: 600)
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

    # Sets up the base URLs based on the current network
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