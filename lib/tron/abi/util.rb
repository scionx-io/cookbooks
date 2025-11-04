# frozen_string_literal: true

module Tron
  module Abi
    # Provides utility functions for ABI encoding/decoding
    module Util
      extend self

      # Maximum uint value
      UINT_MAX = (2 ** 256) - 1

      # Minimum uint value
      UINT_MIN = 0

      # Maximum int value
      INT_MAX = (2 ** 255) - 1

      # Minimum int value
      INT_MIN = -(2 ** 255)

      # Pads a length to a multiple of 32 bytes
      #
      # @param x [Integer] the length to pad
      # @return [Integer] the padded length
      def ceil32(x)
        ((x + 31) / 32).floor * 32
      end

      # Pads an integer to a specified number of bytes in binary format
      #
      # @param x [Integer] the integer to pad
      # @param len [Integer] the number of bytes to pad to (default: 32)
      # @return [String] the padded integer as a binary string
      def zpad_int(x, len = 32)
        # Ensure x is positive for modulo operation
        x = x % (2 ** (8 * len)) if x >= 2 ** (8 * len) || x < 0
        [x.to_s(16).rjust(len * 2, '0')].pack('H*')
      end

      # Pads a string to a specified length with null bytes
      #
      # @param s [String] the string to pad
      # @param length [Integer] the target length
      # @return [String] the padded string
      def zpad(s, length)
        s + "\x00" * (length - s.length)
      end

      # Pads a hex string to 32 bytes (64 hex characters), returning binary
      #
      # @param s [String] the hex string to pad
      # @return [String] the padded hex as a binary string
      def zpad_hex(s)
        s = s[2..-1] if s.start_with?('0x', '0X')
        [s.rjust(64, '0')].pack('H*')
      end

      # Checks if a string is prefixed with 0x
      #
      # @param s [String] the string to check
      # @return [Boolean] true if prefixed with 0x or 0X
      def prefixed?(s)
        s.start_with?('0x', '0X')
      end

      # Checks if a string is a valid hex string
      #
      # @param s [String] the string to check
      # @return [Boolean] true if it's a valid hex string
      def hex?(s)
        s = s[2..-1] if s.start_with?('0x', '0X')
        s.match(/\A[0-9a-fA-F]*\z/)
      end

      # Convert hex string to binary
      #
      # @param s [String] the hex string to convert
      # @return [String] the binary representation
      def hex_to_bin(s)
        s = s[2..-1] if s.start_with?('0x', '0X')
        [s].pack('H*')
      end

      # Convert binary to hex string
      #
      # @param b [String] the binary to convert
      # @return [String] the hexadecimal representation
      def bin_to_hex(b)
        b.unpack('H*').first
      end

      # Deserialize big endian integer from binary data
      #
      # @param data [String] the binary data to deserialize
      # @return [Integer] the deserialized integer
      def deserialize_big_endian_to_int(data)
        data.unpack1('H*').to_i(16)
      end
    end
  end
end