# lib/tron/configuration.rb
module Tron
  class Configuration
    attr_accessor :api_key, :tronscan_api_key, :network, :timeout, :base_url, :tronscan_base_url, :strict_mode

    def initialize
      @network = :mainnet
      @timeout = 30
      @strict_mode = false
      setup_urls
    end

    def network=(network)
      @network = network
      setup_urls
    end

    private

    def setup_urls
      case @network
      when :mainnet
        @base_url = 'https://api.trongrid.io'
        @tronscan_base_url = 'https://apilist.tronscanapi.com'
      when :shasta
        @base_url = 'https://api.shasta.trongrid.io'
        @tronscan_base_url = 'https://api.shasta.tronscanapi.com'
      when :nile
        @base_url = 'https://nile.trongrid.io'
        @tronscan_base_url = 'https://api.nileex.net'
      else
        @base_url = 'https://api.trongrid.io'
        @tronscan_base_url = 'https://apilist.tronscanapi.com'
      end
    end
  end
end