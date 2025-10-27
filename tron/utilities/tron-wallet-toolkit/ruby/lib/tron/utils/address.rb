# lib/tron/utils/address.rb
require 'base58-alphabets'

module Tron
  module Utils
    # TRON address utilities for validation, conversion, and formatting
    class Address
      # TRON address prefix in hex (41 corresponds to 'T' in Base58)
      ADDRESS_PREFIX = '41'.freeze
      
      # Validates a TRON address
      #
      # @param address [String] the TRON address to validate
      # @return [Boolean] true if the address is valid, false otherwise
      def self.validate(address)
        return false unless address && address.length == 34 && address.start_with?('T')
        
        begin
          # Decode the entire Base58 address to get the raw bytes
          decoded_bytes = Base58.decode_bin(address)
          # Should have 21 bytes (1 byte prefix + 20 address bytes) + 4 bytes checksum = 25 bytes total
          return false unless decoded_bytes.length == 25
          
          # Split into address part (21 bytes) and checksum (4 bytes)
          addr_part = decoded_bytes[0...21]
          checksum = decoded_bytes[21..-1]
          
          # Verify the checksum by double-SHA256 of the address part
          require 'digest'
          expected_checksum = Digest::SHA256.digest(Digest::SHA256.digest(addr_part))[0...4]
          
          # Check if the address prefix is correct (should be 0x41 which is decimal 65)
          return (checksum == expected_checksum) && (addr_part[0].ord == 65) # 0x41 = 65 in decimal
        rescue
          false
        end
      end

      # Converts a Base58 TRON address to hex format
      #
      # @param address [String] the Base58 TRON address to convert
      # @return [String] the address in hex format
      # @raise [ArgumentError] if the address is invalid
      def self.to_hex(address)
        return address if address.start_with?(ADDRESS_PREFIX) && address.length == 42 # Already hex format

        # Decode the full Base58 address to get the raw bytes
        decoded_bytes = Base58.decode_bin(address)
        # Should have 21 bytes (1 byte prefix + 20 address bytes) + 4 bytes checksum = 25 bytes total
        raise ArgumentError, "Invalid TRON address format: #{address}" unless decoded_bytes.length == 25

        # Take only the first 21 bytes (address part with prefix)
        addr_part = decoded_bytes[0...21]

        # Convert to hex string
        addr_part.unpack1('H*')
      end

      # Converts a hex address to Base58 format
      #
      # @param hex_address [String] the hex address to convert
      # @return [String] the address in Base58 format
      def self.to_base58(hex_address)
        return hex_address if hex_address.start_with?('T') && hex_address.length == 34 # Already base58 format

        hex_without_prefix = hex_address.start_with?(ADDRESS_PREFIX) ? hex_address[2..-1] : hex_address
        address_bytes = [hex_without_prefix].pack('H*')
        
        # Verify the address part is correct length (21 bytes after including prefix)
        if address_bytes.length != 21
          # Add the prefix byte 0x41 (decimal 65) if not present
          address_bytes = [65].pack('C') + address_bytes if address_bytes.length == 20
        end
        
        require 'digest'
        checksum = Digest::SHA256.digest(Digest::SHA256.digest(address_bytes))[0...4]
        full_bytes = address_bytes + checksum

        # Encode to Base58
        Base58.encode_bin(full_bytes)
      end
    end
  end
end