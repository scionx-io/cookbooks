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

      private

      # Signs a transaction locally using the private key
      #
      # @param transaction [Hash] the transaction to sign
      # @param private_key [String] the private key in hex format
      # @return [Hash] the signed transaction
      def sign_transaction_locally(transaction, private_key)
        # Create a key instance with the provided private key
        key = Key.new(priv: private_key)
        
        # Get raw data for transaction hashing
        raw_data = prepare_transaction_for_signing(transaction)
        
        # Hash the transaction data
        tx_hash = Tron::Utils::Crypto.keccak256(raw_data)
        
        # Sign the transaction hash
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

      # Prepares a transaction for signing by serializing it properly
      #
      # @param transaction [Hash] the transaction to prepare
      # @return [String] the serialized transaction data
      def prepare_transaction_for_signing(transaction)
        # Extract the raw transaction data for signing
        # TRON transactions need to be properly serialized using Protocol Buffers before signing
        serialized_data = Tron::Protobuf::TransactionSerializer.serialize_for_signing(transaction)
        
        serialized_data
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