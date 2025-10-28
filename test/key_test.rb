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
    
    def test_transaction_signing
      # Test actual transaction signing with txID (SHA256 hash)
      # This simulates the production pattern where TronGrid API provides the txID
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)

      # Mock txID - in production this comes from TronGrid API
      # The txID is the SHA256 hash of the protobuf-serialized raw_data
      mock_txid = "88f3cf37fa1d059d1cb9da6c5c8f21fbe5e4add390b42c2d85e50f6945f7578a"

      # Convert txID to binary for signing (TRON uses SHA256, not Keccak256)
      tx_hash = Utils::Crypto.hex_to_bin(mock_txid)

      # Verify hash is 32 bytes
      assert_equal 32, tx_hash.bytesize, "SHA256 hash should be 32 bytes"

      # Sign the hash
      signature = key.sign(tx_hash)

      # Verify that signature is the correct format (130 hex chars = 65 bytes)
      assert_equal 130, signature.length, "Signature should be 130 hex characters (65 bytes)"

      # Check that it's valid hex
      assert signature.match(/^[0-9a-fA-F]+$/), "Signature should be valid hex"
    end
    
    def test_transaction_signing_integration
      # Integration test that verifies the entire signing flow with txID
      private_key_hex = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      key = Key.new(priv: private_key_hex)

      # In production, you would:
      # 1. Call TronGrid API to create transaction
      # 2. API returns transaction with txID (SHA256 hash)
      # 3. Sign the txID locally
      # 4. Broadcast the signed transaction

      # Mock txID from API (different from first test)
      mock_txid = "aac37ff8f588bd3d0cb201eb6f9d72f33e3c270a5f1fe17c3ccac59daa7eb410"

      # Convert txID to binary
      tx_hash = Utils::Crypto.hex_to_bin(mock_txid)
      refute_nil tx_hash
      assert_equal 32, tx_hash.bytesize  # SHA256 hash is 32 bytes

      # Sign the transaction hash
      signature = key.sign(tx_hash)
      refute_nil signature
      assert_equal 130, signature.length  # Should be 65 bytes in hex (130 chars)

      # Verify signature is valid hex
      assert signature.match(/^[0-9a-fA-F]+$/), "Signature must be valid hex"
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