require_relative '../utils/http'
require_relative '../key'
require 'json'

module Tron
  module Services
    # The Transaction service handles signing and broadcasting of TRON transactions
    class Transaction
      # Creates a new instance of the Transaction service
      #
      # @param configuration [Tron::Configuration] the configuration object
      def initialize(configuration)
        @configuration = configuration
        @base_url = configuration.base_url
      end

      # Signs and broadcasts a transaction
      #
      # @param transaction [Hash] the transaction to sign and broadcast
      # @param private_key [String] the private key to sign the transaction with
      # @param local_signing [Boolean] whether to sign locally (default: true)
      # @return [Hash] the response from the broadcast
      def sign_and_broadcast(transaction, private_key, local_signing: true)
        if local_signing
          signed_tx = sign_transaction_locally(transaction, private_key)
        else
          signed_tx = sign_transaction_via_api(transaction, private_key)
        end

        broadcast_transaction(signed_tx)
      end

      # Gets transaction information by transaction ID
      #
      # @param tx_id [String] the transaction ID (txID)
      # @return [Hash] the transaction information from the blockchain
      def get_transaction(tx_id)
        endpoint = "#{@base_url}/wallet/gettransactionbyid"
        payload = { value: tx_id }

        Utils::HTTP.post(endpoint, payload)
      end

      private

      # Signs a transaction locally using the private key
      #
      # IMPORTANT: TRON uses SHA256 for transaction hashing, NOT Keccak256
      # The txID provided by TronGrid API is already the correct SHA256 hash
      # of the properly protobuf-serialized raw_data
      #
      # @param transaction [Hash] the transaction to sign (must have 'txID' field)
      # @param private_key [String] the private key in hex format
      # @return [Hash] the signed transaction
      # @raise [ArgumentError] if transaction doesn't have txID field
      def sign_transaction_locally(transaction, private_key)
        # Create a key instance with the provided private key
        key = Key.new(priv: private_key)

        # Ensure transaction has txID from TronGrid API
        unless transaction['txID']
          raise ArgumentError, "Transaction must have 'txID' field. Create transaction via TronGrid API first."
        end

        # The txID is the SHA256 hash of the protobuf-serialized raw_data
        # Convert from hex string to binary for signing
        tx_hash = Tron::Utils::Crypto.hex_to_bin(transaction['txID'])

        # Sign the transaction hash locally
        # SECURITY: Private key never leaves this machine!
        signature = key.sign(tx_hash)

        # Add the signature to the transaction
        transaction['signature'] = [signature]

        transaction
      end

      # Signs a transaction via the API (legacy method)
      #
      # @param transaction [Hash] the transaction to sign
      # @param private_key [String] the private key in hex format
      # @return [Hash] the signed transaction from the API
      def sign_transaction_via_api(transaction, private_key)
        # Legacy API-based signing
        endpoint = "#{@base_url}/wallet/gettransactionsign"
        payload = {
          transaction: transaction,
          private_key: private_key
        }

        Utils::HTTP.post(endpoint, payload)
      end

      # Broadcasts a signed transaction to the TRON network
      #
      # @param signed_transaction [Hash] the signed transaction to broadcast
      # @return [Hash] the response from the broadcast
      # @raise [RuntimeError] if the transaction fails to broadcast
      def broadcast_transaction(signed_transaction)
        endpoint = "#{@base_url}/wallet/broadcasttransaction"

        response = Utils::HTTP.post(endpoint, signed_transaction)

        # Check if the transaction was successful
        unless response['result']
          error = response['Error'] || response['error'] || 'Unknown error'
          raise "Transaction failed: #{error}"
        end

        response
      end
    end
  end
end