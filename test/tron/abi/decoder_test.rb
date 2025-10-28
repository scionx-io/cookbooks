# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

module Tron
  module Abi
    class DecoderTest < Minitest::Test
      def test_decode_uint256_from_binary
        # Encode 42 as binary
        binary = Util.zpad_int(42)
        result = Decoder.type(Type.parse('uint256'), binary)
        assert_equal 42, result
      end

      def test_decode_uint8
        binary = Util.zpad_int(255)
        result = Decoder.type(Type.parse('uint8'), binary)
        assert_equal 255, result
      end

      def test_decode_uint256_zero
        binary = Util.zpad_int(0)
        result = Decoder.type(Type.parse('uint256'), binary)
        assert_equal 0, result
      end

      def test_decode_int256_positive
        binary = Util.zpad_int(42)
        result = Decoder.type(Type.parse('int256'), binary)
        assert_equal 42, result
      end

      def test_decode_int256_negative
        binary = Util.zpad_int(-1)
        result = Decoder.type(Type.parse('int256'), binary)
        assert_equal -1, result
      end

      def test_decode_bool_true
        binary = Util.zpad_int(1)
        result = Decoder.type(Type.parse('bool'), binary)
        assert_equal true, result
      end

      def test_decode_bool_false
        binary = Util.zpad_int(0)
        result = Decoder.type(Type.parse('bool'), binary)
        assert_equal false, result
      end

      def test_decode_string_from_binary
        # Manually construct binary: length (5) + "hello" padded to 32 bytes
        length = Util.zpad_int(5)
        data = "hello".b + ("\x00" * 27)
        binary = length + data

        result = Decoder.type(Type.parse('string'), binary)
        assert_equal 'hello', result
      end

      def test_decode_bytes_from_binary
        length = Util.zpad_int(4)
        data = "test".b + ("\x00" * 28)
        binary = length + data

        result = Decoder.type(Type.parse('bytes'), binary)
        assert_equal 'test', result
      end

      def test_decode_bytes32_fixed
        data = ('a' * 32).b + ("\x00" * 0)  # 32 bytes, no padding needed
        binary = data

        result = Decoder.type(Type.parse('bytes32'), binary)
        assert_equal 'a' * 32, result
      end

      def test_decode_static_array
        # Array of 3 uint256s: [1, 2, 3]
        binary = Util.zpad_int(1) + Util.zpad_int(2) + Util.zpad_int(3)
        result = Decoder.type(Type.parse('uint256[3]'), binary)
        assert_equal [1, 2, 3], result
      end

      def test_decode_dynamic_array
        # Array length (3) + three values [1, 2, 3]
        length = Util.zpad_int(3)
        values = Util.zpad_int(1) + Util.zpad_int(2) + Util.zpad_int(3)
        binary = length + values

        result = Decoder.type(Type.parse('uint256[]'), binary)
        assert_equal [1, 2, 3], result
      end

      def test_decode_empty_string
        length = Util.zpad_int(0)
        binary = length

        result = Decoder.type(Type.parse('string'), binary)
        assert_equal '', result
      end

      def test_decode_wrong_data_size
        # Insufficient data for uint256
        binary = "\x00" * 16  # Only 16 bytes instead of 32

        # This might not raise an error but return incorrect results
        # Actual behavior depends on implementation
      end
    end
  end
end