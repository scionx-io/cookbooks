# frozen_string_literal: true
require 'digest/keccak'
require 'openssl'
require 'base58-alphabets'

module Tron
  module Utils
    # Crypto utilities for various cryptographic operations needed in TRON blockchain
    module Crypto
      extend self

      # Converts a hexadecimal string to binary data
      #
      # @param string [String] the hex string to convert (with or without 0x prefix)
      # @return [String] the binary representation
      def hex_to_bin(string)
        string = string[2..-1] if string.start_with?('0x', '0X')
        [string].pack('H*')
      end

      # Converts binary data to a hexadecimal string
      #
      # @param bytes [String] the binary data to convert
      # @return [String] the hexadecimal representation
      def bin_to_hex(bytes)
        bytes.unpack('H*').first
      end

      # Computes the Keccak256 hash of the given value
      #
      # @param value [String] the value to hash
      # @return [String] the Keccak256 hash
      def keccak256(value)
        # Using keccak gem for Keccak256 hashing
        Digest::Keccak.digest(value, 256)
      end

      # Computes the SHA256 hash of the given value
      #
      # @param value [String] the value to hash
      # @return [String] the SHA256 hash
      def sha256(value)
        OpenSSL::Digest::SHA256.digest(value)
      end

      # Checks if a string is a valid hexadecimal string
      #
      # @param str [String] the string to check
      # @return [Boolean] true if the string is valid hex, false otherwise
      def is_hex?(str)
        return false unless str.is_a?(String)
        str = str[2..-1] if str.start_with?('0x', '0X')
        str.match(/\A[0-9a-fA-F]*\z/)
      end
      
      # Applies Base58Check encoding to the given data
      # This creates a checksum and encodes the data with the checksum
      #
      # @param data [String] the data to encode
      # @return [String] the Base58Check encoded string
      def base58check(data)
        checksum = sha256(sha256(data))[0..3]
        Base58.encode_bin(data + checksum)
      end
    end
  end
end