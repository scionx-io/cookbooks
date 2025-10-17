# lib/tron/utils/address.rb
require 'base58'

module Tron
  module Utils
    class Address
      def self.validate(address)
        return false unless address && address.length == 34 && address.start_with?('T')
        
        begin
          base58_part = address[1..-1]
          Base58.decode(base58_part)
          true
        rescue
          false
        end
      end

      def self.to_hex(address)
        return address if address.start_with?('41') && address.length == 42 # Already hex format

        base58_part = address.start_with?('T') ? address[1..-1] : address
        decoded = Base58.decode(base58_part)
        '41' + decoded.unpack('H*').first
      end

      def self.to_base58(hex_address)
        return hex_address if hex_address.start_with?('T') && hex_address.length == 34 # Already base58 format

        hex_without_prefix = hex_address.start_with?('41') ? hex_address[2..-1] : hex_address
        address_bytes = [hex_without_prefix].pack('H*')
        
        require 'digest'
        checksum = Digest::SHA256.digest(Digest::SHA256.digest(address_bytes))[0...4]
        Base58.binary_to_base58(address_bytes + checksum)
      end
    end
  end
end