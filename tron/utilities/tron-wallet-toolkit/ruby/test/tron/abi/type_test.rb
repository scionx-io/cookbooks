# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'
require_relative '../../../lib/tron/abi/type'
require_relative '../../../lib/tron/abi/util'

class TypeTest < Minitest::Test
  def test_parse_uint256
    type = Tron::Abi::Type.parse("uint256")
    assert_equal "uint", type.base_type
    assert_equal "256", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_int128
    type = Tron::Abi::Type.parse("int128")
    assert_equal "int", type.base_type
    assert_equal "128", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_address
    type = Tron::Abi::Type.parse("address")
    assert_equal "address", type.base_type
    assert_equal "", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_bool
    type = Tron::Abi::Type.parse("bool")
    assert_equal "bool", type.base_type
    assert_equal "", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_string
    type = Tron::Abi::Type.parse("string")
    assert_equal "string", type.base_type
    assert_equal "", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_bytes
    type = Tron::Abi::Type.parse("bytes")
    assert_equal "bytes", type.base_type
    assert_equal "", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_fixed_bytes
    type = Tron::Abi::Type.parse("bytes32")
    assert_equal "bytes", type.base_type
    assert_equal "32", type.sub_type
    assert_equal [], type.dimensions
  end

  def test_parse_static_array
    type = Tron::Abi::Type.parse("uint256[10]")
    assert_equal "uint", type.base_type
    assert_equal "256", type.sub_type
    assert_equal [10], type.dimensions
  end

  def test_parse_dynamic_array
    type = Tron::Abi::Type.parse("uint256[]")
    assert_equal "uint", type.base_type
    assert_equal "256", type.sub_type
    assert_equal [0], type.dimensions  # 0 represents dynamic array
  end

  def test_parse_multidim_array
    type = Tron::Abi::Type.parse("uint256[2][3]")
    assert_equal "uint", type.base_type
    assert_equal "256", type.sub_type
    assert_equal [2, 3], type.dimensions
  end

  def test_parse_tuple
    type = Tron::Abi::Type.parse("(uint256,address)")
    assert_equal "tuple", type.base_type
    assert_equal "", type.sub_type
    assert_equal [], type.dimensions
    assert_equal 2, type.components.length
    assert_equal "uint", type.components[0].base_type
    assert_equal "256", type.components[0].sub_type
    assert_equal "address", type.components[1].base_type
  end

  def test_parse_nested_tuple
    type = Tron::Abi::Type.parse("((uint256,address),bool)")
    assert_equal "tuple", type.base_type
    assert_equal [], type.dimensions
    assert_equal 2, type.components.length
    assert_equal "tuple", type.components[0].base_type
    assert_equal "bool", type.components[1].base_type
  end

  def test_dynamic_detection
    # Static types
    refute Tron::Abi::Type.parse("uint256").dynamic?
    refute Tron::Abi::Type.parse("address").dynamic?
    refute Tron::Abi::Type.parse("uint256[5]").dynamic?

    # Dynamic types
    assert Tron::Abi::Type.parse("string").dynamic?
    assert Tron::Abi::Type.parse("bytes").dynamic?
    assert Tron::Abi::Type.parse("uint256[]").dynamic?
    assert Tron::Abi::Type.parse("(uint256,string)").dynamic?
  end

  def test_size_calculation
    # Static types should have fixed sizes
    assert_equal 32, Tron::Abi::Type.parse("uint256").size
    assert_equal 32, Tron::Abi::Type.parse("address").size
    assert_equal 32, Tron::Abi::Type.parse("bool").size
    assert_equal 32 * 5, Tron::Abi::Type.parse("uint256[5]").size

    # Dynamic types should have nil size
    assert_nil Tron::Abi::Type.parse("string").size
    assert_nil Tron::Abi::Type.parse("bytes[]").size
    assert_nil Tron::Abi::Type.parse("(uint256,string)").size
  end

  def test_validation_errors
    assert_raises(Tron::Abi::Type::ParseError) { Tron::Abi::Type.parse("invalid_type") }
    assert_raises(Tron::Abi::Type::ParseError) { Tron::Abi::Type.parse("uint12") }  # Invalid int size
    assert_raises(Tron::Abi::Type::ParseError) { Tron::Abi::Type.parse("bytes33") } # Too many bytes
  end
end