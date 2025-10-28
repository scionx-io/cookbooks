# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi'

module Tron
  module Abi
    class EncoderTest < Minitest::Test
      def test_encode_uint256_returns_binary
        result = Encoder.type(Type.parse('uint256'), 42)
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_encode_uint8
        result = Encoder.type(Type.parse('uint8'), 255)
        assert_equal 32, result.bytesize
        assert_equal '00000000000000000000000000000000000000000000000000000000000000ff', result.unpack1('H*')
      end

      def test_encode_uint256_zero
        result = Encoder.type(Type.parse('uint256'), 0)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_encode_int256_positive
        result = Encoder.type(Type.parse('int256'), 42)
        assert_equal 32, result.bytesize
        assert_equal '000000000000000000000000000000000000000000000000000000000000002a', result.unpack1('H*')
      end

      def test_encode_int256_negative
        result = Encoder.type(Type.parse('int256'), -1)
        assert_equal 32, result.bytesize
        assert_equal 'f' * 64, result.unpack1('H*')
      end

      def test_encode_bool_true
        result = Encoder.type(Type.parse('bool'), true)
        assert_equal 32, result.bytesize
        assert_equal '0000000000000000000000000000000000000000000000000000000000000001', result.unpack1('H*')
      end

      def test_encode_bool_false
        result = Encoder.type(Type.parse('bool'), false)
        assert_equal 32, result.bytesize
        assert_equal '0' * 64, result.unpack1('H*')
      end

      def test_encode_string_returns_binary
        result = Encoder.type(Type.parse('string'), 'hello')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        # Length (32 bytes) + padded data (32 bytes) = 64 bytes
        assert_equal 64, result.bytesize

        # Check length encoding (first 32 bytes should encode 5)
        length_hex = result[0, 32].unpack1('H*')
        assert_equal '0000000000000000000000000000000000000000000000000000000000000005', length_hex

        # Check data encoding (next 32 bytes should be "hello" padded)
        data_hex = result[32, 32].unpack1('H*')
        assert_equal '68656c6c6f' + '0' * 54, data_hex
      end

      def test_encode_bytes_returns_binary
        result = Encoder.type(Type.parse('bytes'), 'test')
        assert_equal Encoding::ASCII_8BIT, result.encoding
        assert_equal 64, result.bytesize
      end

      def test_encode_bytes32_fixed
        data = 'a' * 32
        result = Encoder.type(Type.parse('bytes32'), data)
        assert_equal 32, result.bytesize
        assert_equal '61' * 32, result.unpack1('H*')
      end

      def test_encode_address_tron_format
        # Skip if address utilities not available
        skip unless defined?(Tron::Utils::Address)

        address = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD6HUGKN'
        result = Encoder.type(Type.parse('address'), address)
        assert_equal 32, result.bytesize
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_static_array
        result = Encoder.type(Type.parse('uint256[3]'), [1, 2, 3])
        assert_equal 96, result.bytesize  # 3 * 32 bytes
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_dynamic_array
        result = Encoder.type(Type.parse('uint256[]'), [1, 2, 3])
        # Length (32) + 3 values (96) = 128 bytes
        assert_equal 128, result.bytesize
        assert_equal Encoding::ASCII_8BIT, result.encoding
      end

      def test_encode_value_out_of_bounds
        assert_raises(ValueOutOfBounds) do
          Encoder.type(Type.parse('uint8'), 300)
        end
      end

      def test_encode_wrong_type
        assert_raises(EncodingError) do
          Encoder.type(Type.parse('bool'), 'not a bool')
        end
      end
    end
  end
end