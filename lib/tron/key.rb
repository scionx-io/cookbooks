# frozen_string_literal: true
require 'rbsecp256k1'
require 'securerandom'
require_relative 'utils/crypto'
require_relative 'utils/address'
require_relative 'signature'
require 'base58-alphabets'

module Tron
  # The Key class provides utilities for key generation, signing, and address derivation
  # for TRON blockchain interactions using the secp256k1 elliptic curve cryptography.
  class Key
    # TRON address prefix (41 in hex)
    ADDRESS_PREFIX = '41'.freeze
    
    # @return [Secp256k1::PrivateKey] the private key object
    attr_reader :private_key
    # @return [Secp256k1::PublicKey] the public key object
    attr_reader :public_key

    # Creates a new key pair
    # If no private key is provided, generates a new random key pair
    #
    # @param priv [String, nil] hexadecimal private key (32 bytes) or nil to generate random key
    # @raise [ArgumentError] if the private key is invalid
    def initialize(priv: nil)
      # Creates a new, randomized libsecp256k1 context.
      ctx = Secp256k1::Context.new(context_randomization_bytes: SecureRandom.random_bytes(32))

      key = if priv.nil?
              # Creates a new random key pair (public, private).
              ctx.generate_key_pair
            else
              # Validate private key format and size
              if priv.is_a?(String) && Tron::Utils::Crypto.is_hex?(priv)
                # Convert hex private key to binary
                priv = Tron::Utils::Crypto.hex_to_bin(priv)
              elsif priv.is_a?(String) && !Tron::Utils::Crypto.is_hex?(priv)
                raise ArgumentError, "Private key must be a valid hex string"
              end
              
              # Validate private key size (must be 32 bytes)
              raise ArgumentError, "Private key must be 32 bytes" unless priv.bytesize == 32
              
              # Creates a keypair from existing private key data.
              ctx.key_pair_from_private_key(priv)
            end

      # Sets the attributes.
      @private_key = key.private_key
      @public_key = key.public_key
    end

    # Returns the private key in hexadecimal format
    #
    # @return [String] private key as hexadecimal string
    def private_hex
      Tron::Utils::Crypto.bin_to_hex(@private_key.data)
    end

    # Returns the private key in binary format
    #
    # @return [String] private key as binary string
    def private_bytes
      @private_key.data
    end

    # Returns the uncompressed public key in hexadecimal format
    #
    # @return [String] uncompressed public key as hexadecimal string
    def public_hex
      Tron::Utils::Crypto.bin_to_hex(@public_key.uncompressed)
    end

    # Returns the compressed public key in hexadecimal format
    #
    # @return [String] compressed public key as hexadecimal string
    def public_hex_compressed
      Tron::Utils::Crypto.bin_to_hex(@public_key.compressed)
    end

    # Returns the uncompressed public key in binary format
    #
    # @return [String] uncompressed public key as binary string
    def public_bytes
      @public_key.uncompressed
    end

    # Returns the compressed public key in binary format
    #
    # @return [String] compressed public key as binary string
    def public_bytes_compressed
      @public_key.compressed
    end

    # Derives the TRON address from the public key
    # Uses the TRON address derivation algorithm with Keccak256 hashing and Base58Check encoding
    #
    # @return [String] TRON address
    def address
      # TRON address derivation algorithm:
      # 1. Take uncompressed public key (64 bytes after removing prefix 0x04)
      # 2. Hash with Keccak256
      # 3. Take last 20 bytes
      # 4. Add TRON prefix (0x41)
      # 5. Calculate checksum using base58check and encode to Base58
      
      # Get the public key without the 0x04 prefix
      public_key_bytes = @public_key.uncompressed[1..-1]
      
      # Hash the public key with Keccak256
      hash = Tron::Utils::Crypto.keccak256(public_key_bytes)
      
      # Take the last 20 bytes
      address_bytes = hash[-20..-1]
      
      # Add TRON prefix (0x41)
      prefixed_address_hex = Tron::Key::ADDRESS_PREFIX + Tron::Utils::Crypto.bin_to_hex(address_bytes)
      prefixed_address_bytes = Tron::Utils::Crypto.hex_to_bin(prefixed_address_hex)
      
      # Use the base58check utility
      Tron::Utils::Crypto.base58check(prefixed_address_bytes)
    end

    # Signs a binary data blob with the private key
    #
    # @param blob [String] binary data to sign
    # @return [String] signature as hexadecimal string
    def sign(blob)
      context = Secp256k1::Context.new
      compact, recovery_id = context.sign_recoverable(@private_key, blob).compact
      signature = compact.bytes
      signature << recovery_id

      Tron::Utils::Crypto.bin_to_hex(signature.pack('c*'))
    end

    # Signs a message using the personal sign format
    # This prefixes the message with specific data before signing
    #
    # @param message [String] message to sign
    # @return [String] signature as hexadecimal string
    def personal_sign(message)
      prefixed_message = Tron::Signature.prefix_message(message)
      hashed_message = Tron::Utils::Crypto.keccak256(prefixed_message)
      sign(hashed_message)
    end

    # Verifies a signature against a data blob
    #
    # @param blob [String] the original signed data
    # @param signature [String] signature to verify
    # @param public_key_or_address [String, Secp256k1::PublicKey] public key or address to verify against
    # @return [Boolean] true if the signature is valid
    def verify_signature(blob, signature, public_key_or_address)
      # Implementation adapted from eth.rb's signature verification
      recovered_key = recover_signature(blob, signature)
      
      case public_key_or_address
      when String
        if public_key_or_address.length == 34 # TRON address length
          # Verify against TRON address
          recovered_address = public_key_to_address(recovered_key)
          return recovered_address == public_key_or_address
        elsif public_key_or_address.length == 130 # Uncompressed public key hex length (with 0x prefix)
          # Verify against full public key hex
          public_key_hex = public_key_or_address.start_with?('0x') ? public_key_or_address[2..-1] : public_key_or_address
          return recovered_key == public_key_hex
        elsif public_key_or_address.length == 128 # Uncompressed public key hex length (without 0x prefix)
          # Verify against full public key hex
          return recovered_key == public_key_or_address
        end
      when Secp256k1::PublicKey
        public_hex = Tron::Utils::Crypto.bin_to_hex(public_key_or_address.uncompressed)
        return recovered_key == public_hex
      end

      raise ArgumentError, "Invalid public key or address format"
    end

    # Verifies a personal message signature
    #
    # @param message [String] the original signed message
    # @param signature [String] signature to verify
    # @param public_key_or_address [String, Secp256k1::PublicKey] public key or address to verify against
    # @return [Boolean] true if the signature is valid
    def verify_personal_signature(message, signature, public_key_or_address)
      prefixed_message = Tron::Signature.prefix_message(message)
      hashed_message = Tron::Utils::Crypto.keccak256(prefixed_message)
      verify_signature(hashed_message, signature, public_key_or_address)
    end

    private

    # Recovers the public key from a signature and data blob
    #
    # @param blob [String] the original data that was signed
    # @param signature [String] signature to recover from
    # @return [String] recovered public key as hexadecimal string
    def recover_signature(blob, signature)
      context = Secp256k1::Context.new
      r, s, v = dissect_signature(signature)
      
      v_int = v.to_i(16)
      recovery_id = calculate_recovery_id(v_int)
      
      signature_rs = Tron::Utils::Crypto.hex_to_bin("#{r}#{s}")
      recoverable_signature = context.recoverable_signature_from_compact(signature_rs, recovery_id)
      public_key = recoverable_signature.recover_public_key(blob)
      
      Tron::Utils::Crypto.bin_to_hex(public_key.uncompressed)
    end

    # Dissects a signature into its r, s, and v components
    #
    # @param signature [String] signature to dissect
    # @return [Array<String>] array containing [r, s, v] components
    def dissect_signature(signature)
      signature_hex = signature.start_with?('0x') ? signature[2..-1] : signature
      if signature_hex.length < 128
        raise ArgumentError, "Invalid signature length: #{signature_hex.length}"
      end
      
      r = signature_hex[0, 64]
      s = signature_hex[64, 64]
      v = signature_hex[128, 2] # TRON typically uses only 1 byte for v (recovery ID)
      
      [r, s, v]
    end

    # Calculates the recovery ID from the v component
    #
    # @param v_byte [Integer] the v component of the signature as integer
    # @return [Integer] recovery ID
    def calculate_recovery_id(v_byte)
      # TRON uses different recovery ID calculation than Ethereum
      # In most TRON implementations, v is typically 27 or 28 for recovery ID 0 or 1
      if v_byte >= 27
        v_byte - 27
      else
        v_byte
      end
    end

    # Converts a public key in hexadecimal format to a TRON address
    #
    # @param public_key_hex [String] public key as hexadecimal string
    # @return [String] TRON address
    def public_key_to_address(public_key_hex)
      # Convert hex public key to bytes (remove 0x prefix if present)
      public_key_hex = public_key_hex.start_with?('0x') ? public_key_hex[2..-1] : public_key_hex
      public_key_bytes = Tron::Utils::Crypto.hex_to_bin(public_key_hex)
      
      # Remove the 0x04 prefix if present
      public_key_bytes = public_key_bytes[1..-1] if public_key_bytes[0] == "\x04".b
      
      # Hash the public key with Keccak256
      hash = Tron::Utils::Crypto.keccak256(public_key_bytes)
      
      # Take the last 20 bytes
      address_bytes = hash[-20..-1]
      
      # Add TRON prefix (0x41)
      prefixed_address_hex = Tron::Key::ADDRESS_PREFIX + Tron::Utils::Crypto.bin_to_hex(address_bytes)
      prefixed_address_bytes = Tron::Utils::Crypto.hex_to_bin(prefixed_address_hex)
      
      # Use base58check encoding
      Tron::Utils::Crypto.base58check(prefixed_address_bytes)
    end
  end
end