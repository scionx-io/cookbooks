require_relative '../utils/http'
require_relative '../key'
require 'json'

module Tron
  module Services
    class Transaction
      def initialize(configuration)
        @configuration = configuration
        @base_url = configuration.base_url
      end

      # Sign and broadcast transaction
      def sign_and_broadcast(transaction, private_key, local_signing: true)
        if local_signing
          signed_tx = sign_transaction_locally(transaction, private_key)
        else
          signed_tx = sign_transaction_via_api(transaction, private_key)
        end

        broadcast_transaction(signed_tx)
      end

      private

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

      def sign_transaction_via_api(transaction, private_key)
        # Legacy API-based signing
        endpoint = "#{@base_url}/wallet/gettransactionsign"
        payload = {
          transaction: transaction,
          private_key: private_key
        }

        Utils::HTTP.post(endpoint, payload)
      end

      def prepare_transaction_for_signing(transaction)
        # Extract the raw transaction data for signing
        # TRON transactions need to be properly serialized before signing
        
        # According to TRON protocol, the raw transaction needs to be serialized
        # using Protocol Buffers before signing
        
        # For now, we'll use a simplified approach - in real implementation,
        # we'd serialize the transaction according to TRON's protocol buffer format
        serialized_data = serialize_transaction(transaction)
        
        serialized_data
      end
      
      def serialize_transaction(transaction)
        # This is a simplified implementation
        # In a real-world scenario, this needs to properly serialize
        # the transaction according to TRON's protocol buffer specification
        JSON.generate(transaction['raw_data'])
      end

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