# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi/util'

module Tron
  module Abi
    class UtilTest < Minitest::Test
      def test_zpad_int_returns_binary
        result = Util.zpad_int(42)
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_int_with_zero
        result = Util.zpad_int(0)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_zpad_int_with_large_number
        result = Util.zpad_int(2**256 - 1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_zpad_int_with_negative
        result = Util.zpad_int(-1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_zpad_hex_returns_binary
        result = Util.zpad_hex('2a')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_hex_with_0x_prefix
        result = Util.zpad_hex('0x2a')
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_zpad_hex_already_64_chars
        long_hex = 'a' * 64
        result = Util.zpad_hex(long_hex)
        assert_equal 32, result.bytesize
        assert_equal long_hex, result.unpack1('H*')
      end

      def test_deserialize_big_endian_to_int_from_binary
        binary = [42].pack('C*').rjust(32, "\x00")
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 42, result
      end

      def test_deserialize_big_endian_to_int_zero
        binary = "\x00" * 32
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 0, result
      end

      def test_deserialize_big_endian_to_int_max_value
        binary = "\xff" * 32
        result = Util.deserialize_big_endian_to_int(binary)
        assert_equal 2**256 - 1, result
      end

      def test_ceil32
        assert_equal 0, Util.ceil32(0)
        assert_equal 32, Util.ceil32(1)
        assert_equal 32, Util.ceil32(32)
        assert_equal 64, Util.ceil32(33)
        assert_equal 64, Util.ceil32(64)
        assert_equal 96, Util.ceil32(65)
      end

      def test_bin_to_hex
        binary = "\x00\x2a"
        assert_equal '002a', Util.bin_to_hex(binary)
      end

      def test_hex_to_bin
        hex = '002a'
        binary = Util.hex_to_bin(hex)
        assert_equal Encoding::ASCII_8BIT, binary.encoding
        assert_equal "\x00\x2a", binary
      end

      def test_hex_to_bin_with_0x_prefix
        hex = '0x002a'
        binary = Util.hex_to_bin(hex)
        assert_equal "\x00\x2a", binary
      end

      def test_prefixed
        assert Util.prefixed?('0x123')
        assert Util.prefixed?('0X123')
        refute Util.prefixed?('123')
      end

      def test_hex
        assert Util.hex?('0x123abc')
        assert Util.hex?('123ABC')
        refute Util.hex?('0xzzz')
        refute Util.hex?('hello')
      end
    end
  end
end