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
      # Test actual transaction signing with a mock transaction
      private_key_hex = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
      key = Key.new(priv: private_key_hex)
      
      # Create a mock transaction structure similar to what TRON uses
      mock_transaction = {
        'raw_data' => {
          'ref_block_bytes' => '0x0000',
          'ref_block_num' => 12345,
          'ref_block_hash' => 'abcd1234',
          'expiration' => Time.now.to_i * 1000 + 10000,  # 10 seconds in the future
          'timestamp' => Time.now.to_i * 1000,
          'fee_limit' => 100_000_000,
          'contract' => [{
            'parameter' => {
              'value' => {
                'owner_address' => '41e46a784904aa56b8e975e901ac161e515582b02e',
                'contract_address' => '41845f0d3b41685b69c86350e206e44e639f0e0a01',
                'data' => '1234567890abcdef',
                'call_value' => 0
              },
              'type_url' => 'type.googleapis.com/protocol.TriggerSmartContract'
            },
            'type' => 'TriggerSmartContract'
          }]
        }
      }
      
      # Serialize the transaction for signing using Protocol Buffers
      serialized_data = Protobuf::TransactionSerializer.serialize_for_signing(mock_transaction)
      
      # Hash the serialized data with Keccak256
      tx_hash = Utils::Crypto.keccak256(serialized_data)
      
      # Sign the hash
      signature = key.sign(tx_hash)
      
      # Verify that signature is the correct format (130 hex chars = 65 bytes)
      assert_equal 130, signature.length, "Signature should be 130 hex characters (65 bytes)"
      
      # Check that it's valid hex
      assert signature.match(/^[0-9a-fA-F]+$/), "Signature should be valid hex"
    end
    
    def test_transaction_signing_integration
      # Integration test that verifies the entire signing flow
      private_key_hex = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
      key = Key.new(priv: private_key_hex)
      
      # Create a mock transaction
      mock_transaction = {
        'raw_data' => {
          'ref_block_bytes' => '0x0001',
          'ref_block_num' => 54321,
          'ref_block_hash' => '1234abcd',
          'expiration' => Time.now.to_i * 1000 + 20000,
          'timestamp' => Time.now.to_i * 1000,
          'fee_limit' => 200_000_000,
          'contract' => [{
            'parameter' => {
              'value' => {
                'owner_address' => '41e46a784904aa56b8e975e901ac161e515582b02e',
                'contract_address' => '41845f0d3b41685b69c86350e206e44e639f0e0a01',
                'data' => 'abcdef1234567890',
                'call_value' => 1000
              },
              'type_url' => 'type.googleapis.com/protocol.TransferContract'
            },
            'type' => 'TransferContract'
          }]
        }
      }
      
      # Test the transaction signing process step-by-step
      serialized_data = Protobuf::TransactionSerializer.serialize_for_signing(mock_transaction)
      refute_nil serialized_data
      assert serialized_data.length > 0
      
      tx_hash = Utils::Crypto.keccak256(serialized_data)
      refute_nil tx_hash
      assert_equal 32, tx_hash.length  # Keccak256 should produce 32-byte hash
      
      signature = key.sign(tx_hash)
      refute_nil signature
      assert_equal 130, signature.length  # Should be 65 bytes in hex (130 chars)
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