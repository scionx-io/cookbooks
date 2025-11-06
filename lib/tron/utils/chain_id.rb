# lib/tron/utils/chain_id.rb
module Tron
  module Utils
    module ChainId
      # Chain ID constants for different TRON networks
      MAINNET = 0x2b6653dc  # 728126428 decimal
      NILE = 0xcd8690dc     # 3448148188 decimal

      # Get the chain ID for a given network
      #
      # @param network [Symbol] the network symbol (:mainnet, :nile)
      # @return [Integer] the chain ID for the network
      # @raise [ArgumentError] if the network is unknown
      def self.for_network(network)
        case network
        when :mainnet
          MAINNET
        when :nile
          NILE
        else
          raise ArgumentError, "Unknown network: #{network}. Supported networks: :mainnet, :nile"
        end
      end

      # Get the chain ID from a client instance
      #
      # @param client [Tron::Client] the client instance
      # @return [Integer] the chain ID for the client's network
      def self.from_client(client)
        for_network(client.configuration.network)
      end
    end
  end
end
