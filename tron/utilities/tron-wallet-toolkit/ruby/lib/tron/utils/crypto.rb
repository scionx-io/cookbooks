# frozen_string_literal: true
require 'digest/keccak'
require 'openssl'

module Tron
  module Utils
    module Crypto
      extend self

      def hex_to_bin(string)
        string = string[2..-1] if string.start_with?('0x', '0X')
        [string].pack('H*')
      end

      def bin_to_hex(bytes)
        bytes.unpack('H*').first
      end

      def keccak256(value)
        # Using keccak gem for Keccak256 hashing
        Digest::Keccak.new(256).digest(value)
      end

      def sha256(value)
        OpenSSL::Digest::SHA256.digest(value)
      end

      def is_hex?(str)
        return false unless str.is_a?(String)
        str = str[2..-1] if str.start_with?('0x', '0X')
        str.match(/\A[0-9a-fA-F]*\z/)
      end
    end
  end
end