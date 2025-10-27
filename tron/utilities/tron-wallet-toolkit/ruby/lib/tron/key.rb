# frozen_string_literal: true
require 'rbsecp256k1'
require 'securerandom'
require_relative 'utils/crypto'
require_relative 'utils/address'
require_relative 'signature'
require 'base58'

module Tron
  class Key
    attr_reader :private_key, :public_key

    def initialize(priv: nil)
      # Creates a new, randomized libsecp256k1 context.
      ctx = Secp256k1::Context.new(context_randomization_bytes: SecureRandom.random_bytes(32))

      key = if priv.nil?
              # Creates a new random key pair (public, private).
              ctx.generate_key_pair
            else
              # Converts hex private keys to binary strings.
              priv = Tron::Utils::Crypto.hex_to_bin(priv) if Tron::Utils::Crypto.is_hex?(priv)

              # Creates a keypair from existing private key data.
              ctx.key_pair_from_private_key(priv)
            end

      # Sets the attributes.
      @private_key = key.private_key
      @public_key = key.public_key
    end

    def private_hex
      Tron::Utils::Crypto.bin_to_hex(@private_key.data)
    end

    def private_bytes
      @private_key.data
    end

    def public_hex
      Tron::Utils::Crypto.bin_to_hex(@public_key.uncompressed)
    end

    def public_hex_compressed
      Tron::Utils::Crypto.bin_to_hex(@public_key.compressed)
    end

    def public_bytes
      @public_key.uncompressed
    end

    def public_bytes_compressed
      @public_key.compressed
    end

    def address
      # TRON address derivation algorithm:
      # 1. Take uncompressed public key (64 bytes after removing prefix 0x04)
      # 2. Hash with Keccak256
      # 3. Take last 20 bytes
      # 4. Add TRON prefix (0x41)
      # 5. Calculate checksum and encode to Base58
      
      # Get the public key without the 0x04 prefix
      public_key_bytes = @public_key.uncompressed[1..-1]
      
      # Hash the public key with Keccak256
      hash = Tron::Utils::Crypto.keccak256(public_key_bytes)
      
      # Take the last 20 bytes
      address_bytes = hash[-20..-1]
      
      # Add TRON prefix (0x41)
      prefixed_address_hex = '41' + Tron::Utils::Crypto.bin_to_hex(address_bytes)
      prefixed_address_bytes = Tron::Utils::Crypto.hex_to_bin(prefixed_address_hex)
      
      # Calculate checksum (SHA256 twice)
      double_sha256 = Tron::Utils::Crypto.sha256(Tron::Utils::Crypto.sha256(prefixed_address_bytes))
      checksum = double_sha256[0..3] # First 4 bytes
      
      # Combine prefixed address and checksum
      full_bytes = prefixed_address_bytes + checksum
      
      # Encode to Base58
      Base58.binary_to_base58(full_bytes)
    end

    def sign(blob)
      context = Secp256k1::Context.new
      compact, recovery_id = context.sign_recoverable(@private_key, blob).compact
      signature = compact.bytes
      signature << recovery_id

      Tron::Utils::Crypto.bin_to_hex(signature.pack('c*'))
    end

    def personal_sign(message)
      prefixed_message = Tron::Signature.prefix_message(message)
      hashed_message = Tron::Utils::Crypto.keccak256(prefixed_message)
      sign(hashed_message)
    end
  end
end