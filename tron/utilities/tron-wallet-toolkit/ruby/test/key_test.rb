require 'minitest/autorun'
require_relative '../lib/tron'

module Tron
  class TestKey < Minitest::Test
    def test_key_generation
      key = Key.new
      refute_nil key.private_key
      refute_nil key.public_key
      refute_nil key.private_hex
      refute_nil key.public_hex
    end

    def test_key_from_private_key
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)
      
      assert_equal private_key_hex, key.private_hex
    end

    def test_address_derivation
      # Use a known private key to verify address derivation
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)
      
      address = key.address
      # TRON addresses are 34 characters long
      assert_equal 34, address.length
      # Address should be a non-empty string
      assert !address.empty?
    end

    def test_signing
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)
      
      data_to_sign = "Hello, TRON!"
      hash_to_sign = Utils::Crypto.keccak256(data_to_sign)
      
      signature = key.sign(hash_to_sign)
      
      refute_nil signature
      assert signature.length > 0
    end

    def test_personal_sign
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)
      
      message = "Hello, TRON!"
      signature = key.personal_sign(message)
      
      refute_nil signature
      assert signature.length > 0
    end
  end

  class TestCryptoUtils < Minitest::Test
    def test_hex_to_bin
      hex = "68656c6c6f"  # "hello" in hex
      expected_bin = "hello"
      
      result = Utils::Crypto.hex_to_bin(hex)
      assert_equal expected_bin, result
    end

    def test_bin_to_hex
      bin = "hello"
      expected_hex = "68656c6c6f"
      
      result = Utils::Crypto.bin_to_hex(bin)
      assert_equal expected_hex, result
    end

    def test_keccak256
      data = "hello"
      
      result = Utils::Crypto.keccak256(data)
      assert_equal 32, result.length  # Keccak256 produces 32-byte hash
    end

    def test_is_hex
      assert Utils::Crypto.is_hex?("68656c6c6f")
      assert Utils::Crypto.is_hex?("0x68656c6c6f")
      refute Utils::Crypto.is_hex?("0x68656c6c6fX")
      refute Utils::Crypto.is_hex?("hello")
    end
  end
end