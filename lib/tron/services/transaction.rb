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

      # Gets detailed transaction information by transaction ID (includes error details)
      #
      # @param tx_id [String] the transaction ID (txID)
      # @return [Hash] the detailed transaction information from the blockchain
      def get_transaction_info(tx_id)
        endpoint = "#{@base_url}/wallet/gettransactioninfobyid"
        payload = { value: tx_id }

        Utils::HTTP.post(endpoint, payload)
      end

      # Waits for transaction confirmation
      #
      # @param tx_id [String] the transaction ID to wait for
      # @param max_attempts [Integer] maximum number of attempts to check (default: 15)
      # @return [Hash] the transaction information when confirmed
      # @raise [RuntimeError] if transaction is reverted or times out
      def wait_for_transaction(tx_id, max_attempts = 15)
        print "Waiting for transaction: #{tx_id}"

        max_attempts.times do |i|
          sleep 2
          print '.'

          begin
            tx_info = get_transaction(tx_id)

            if tx_info && tx_info['ret'] && tx_info['ret'][0]
              result = tx_info['ret'][0]['contractRet']

              if result == 'SUCCESS'
                puts "\n✓ Transaction confirmed"
                return tx_info
              end

              if result == 'REVERT'
                puts "\n❌ Transaction reverted"

                # Get the actual revert reason from transaction info
                error_message = extract_revert_reason(tx_id)

                # Raise with just the error message
                raise "Transaction failed: #{error_message}"
              end
            end
          rescue RuntimeError => e
            # If it's already a formatted error, re-raise it
            raise e if e.message.start_with?('Transaction failed:')
            # Transaction might not be available yet, continue waiting
            next if i < max_attempts - 1
            raise e
          rescue => e
            # Transaction might not be available yet, continue waiting
            next if i < max_attempts - 1
            raise e
          end
        end

        raise 'Transaction timeout'
      end

      private

      # Extracts the revert reason from a failed transaction
      #
      # @param tx_id [String] the transaction ID
      # @return [String] the decoded error message
      def extract_revert_reason(tx_id)
        tx_detail = get_transaction_info(tx_id)

        # Debug: Print the full transaction info
        if ENV['DEBUG']
          puts "\n🔍 DEBUG - Full transaction info:"
          puts JSON.pretty_generate(tx_detail) rescue puts(tx_detail.inspect)
        end

        # Try to get error from contractResult (this contains the ABI-encoded revert reason)
        if tx_detail && tx_detail['contractResult'] && !tx_detail['contractResult'].empty?
          contract_result = tx_detail['contractResult'][0]
          puts "🔍 DEBUG - contractResult: #{contract_result}" if ENV['DEBUG']

          # Check if this is an Error(string) revert (starts with 08c379a0)
          if contract_result && contract_result.start_with?('08c379a0')
            begin
              # ABI encoding for Error(string):
              # - 4 bytes (8 hex chars): function selector (08c379a0)
              # - 32 bytes (64 hex chars): offset to string data
              # - 32 bytes (64 hex chars): length of string
              # - N bytes: actual string data

              # Skip selector (8 chars) and offset (64 chars)
              data = contract_result[8 + 64..-1]

              # Read length (next 64 chars)
              length_hex = data[0...64]
              length = length_hex.to_i(16)
              puts "🔍 DEBUG - String length: #{length}" if ENV['DEBUG']

              # Read string data (next length * 2 hex chars)
              string_hex = data[64, length * 2]
              puts "🔍 DEBUG - String hex: #{string_hex}" if ENV['DEBUG']

              # Decode hex to UTF-8
              error_message = [string_hex].pack('H*').force_encoding('UTF-8')
              puts "🔍 DEBUG - Decoded error: #{error_message}" if ENV['DEBUG']

              return error_message unless error_message.empty?
            rescue => e
              puts "🔍 DEBUG - Error decoding contractResult: #{e.message}" if ENV['DEBUG']
              puts "🔍 DEBUG - Backtrace: #{e.backtrace.first(3).join("\n")}" if ENV['DEBUG']
              # If decoding fails, fall through
            end
          end
        end

        # Try to get error from resMessage (hex-encoded error string)
        if tx_detail && tx_detail['resMessage']
          error_hex = tx_detail['resMessage']
          puts "🔍 DEBUG - resMessage (hex): #{error_hex}" if ENV['DEBUG']

          begin
            # Decode hex to UTF-8 string
            error_message = [error_hex].pack('H*').force_encoding('UTF-8')
            # Clean up the message (remove null bytes and control characters)
            error_message = error_message.gsub(/[\x00-\x1f\x7f]/, '').strip

            puts "🔍 DEBUG - Decoded resMessage: #{error_message}" if ENV['DEBUG']
            return error_message unless error_message.empty?
          rescue => e
            puts "🔍 DEBUG - Error decoding resMessage: #{e.message}" if ENV['DEBUG']
            # If decoding fails, continue to try other methods
          end
        end

        # Default to generic revert message
        'REVERT opcode executed'
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
          error_message = response['Error'] || response['error'] || response['message'] || 'Unknown error'

          # Build detailed error message
          error_details = ["❌ Transaction broadcast failed: #{error_message}"]

          # Add code if available
          if response['code']
            error_details << "   Error code: #{response['code']}"
          end

          # Add transaction ID if available
          if response['txid'] || response['txID']
            tx_id = response['txid'] || response['txID']
            error_details << "   Transaction ID: #{tx_id}"
          end

          # Add full response for debugging
          error_details << "   Full response: #{response.inspect}"

          raise error_details.join("\n")
        end

        response
      end
    end
  end
end