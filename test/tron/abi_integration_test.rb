# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../lib/tron/abi'

class AbiIntegrationTest < Minitest::Test
  def test_encode_returns_hex_string
    result = Tron::Abi.encode(['uint256'], [42])
    assert_kind_of String, result
    assert_match(/\A[0-9a-f]+\z/, result)
    assert_equal 64, result.length  # 32 bytes = 64 hex chars
  end

  def test_encode_decode_uint256_round_trip
    original = 42
    encoded = Tron::Abi.encode(['uint256'], [original])
    decoded = Tron::Abi.decode(['uint256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_multiple_uints
    original = [1, 2, 3]
    encoded = Tron::Abi.encode(['uint256', 'uint256', 'uint256'], original)
    decoded = Tron::Abi.decode(['uint256', 'uint256', 'uint256'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_bool_round_trip
    encoded_true = Tron::Abi.encode(['bool'], [true])
    decoded_true = Tron::Abi.decode(['bool'], encoded_true)
    assert_equal [true], decoded_true

    encoded_false = Tron::Abi.encode(['bool'], [false])
    decoded_false = Tron::Abi.decode(['bool'], encoded_false)
    assert_equal [false], decoded_false
  end

  def test_encode_decode_string_round_trip
    original = 'hello'
    encoded = Tron::Abi.encode(['string'], [original])
    decoded = Tron::Abi.decode(['string'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_bytes_round_trip
    original = 'test data'
    encoded = Tron::Abi.encode(['bytes'], [original])
    decoded = Tron::Abi.decode(['bytes'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_static_array_round_trip
    original = [1, 2, 3]
    encoded = Tron::Abi.encode(['uint256[3]'], [original])
    decoded = Tron::Abi.decode(['uint256[3]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_dynamic_array_round_trip
    original = [1, 2, 3, 4, 5]
    encoded = Tron::Abi.encode(['uint256[]'], [original])
    decoded = Tron::Abi.decode(['uint256[]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_mixed_static_and_dynamic
    # uint256 (static) + string (dynamic)
    original = [42, 'hello']
    encoded = Tron::Abi.encode(['uint256', 'string'], original)
    decoded = Tron::Abi.decode(['uint256', 'string'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_multiple_dynamic_types
    # Two strings (both dynamic)
    original = ['hello', 'world']
    encoded = Tron::Abi.encode(['string', 'string'], original)
    decoded = Tron::Abi.decode(['string', 'string'], encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_complex_mixed
    # uint256 + string + bool + uint256[]
    original = [42, 'hello', true, [1, 2, 3]]
    types = ['uint256', 'string', 'bool', 'uint256[]']
    encoded = Tron::Abi.encode(types, original)
    decoded = Tron::Abi.decode(types, encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_empty_string
    original = ''
    encoded = Tron::Abi.encode(['string'], [original])
    decoded = Tron::Abi.decode(['string'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_empty_array
    original = []
    encoded = Tron::Abi.encode(['uint256[]'], [original])
    decoded = Tron::Abi.decode(['uint256[]'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_zero_values
    original = [0, false, '']
    types = ['uint256', 'bool', 'string']
    encoded = Tron::Abi.encode(types, original)
    decoded = Tron::Abi.decode(types, encoded)
    assert_equal original, decoded
  end

  def test_encode_decode_max_uint256
    original = 2**256 - 1
    encoded = Tron::Abi.encode(['uint256'], [original])
    decoded = Tron::Abi.decode(['uint256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_decode_negative_int256
    original = -12345
    encoded = Tron::Abi.encode(['int256'], [original])
    decoded = Tron::Abi.decode(['int256'], encoded)
    assert_equal [original], decoded
  end

  def test_encode_known_transfer_function
    # transfer(address,uint256) with test values
    # This is a real-world scenario
    address = 'TJRyWwFs9wkrx1UN2bCJNBYFv3nD6HUGKN'
    amount = 1000000

    # Skip if address utilities not available
    skip unless defined?(Tron::Utils::Address)

    encoded = Tron::Abi.encode(['address', 'uint256'], [address, amount])
    decoded = Tron::Abi.decode(['address', 'uint256'], encoded)

    assert_equal address, decoded[0]
    assert_equal amount, decoded[1]
  end

  def test_encode_error_handling
    # Test that encoding wrong types raises errors
    assert_raises(Tron::Abi::EncodingError) do
      Tron::Abi.encode(['bool'], ['not a bool'])
    end
  end

  def test_decode_error_handling
    # Test that decoding invalid data raises errors
    assert_raises(Tron::Abi::DecodingError) do
      Tron::Abi.decode(['string'], '0000')  # Too short
    end
  end
end