require_relative '../utils/http'
require_relative '../utils/address'
require_relative '../abi'
require_relative 'transaction'

module Tron
  module Services
    # The Contract service handles interactions with TRON smart contracts
    # including both read-only calls and state-changing transactions
    class Contract
      # Creates a new instance of the Contract service
      #
      # @param configuration [Tron::Configuration] the configuration object
      def initialize(configuration)
        @configuration = configuration
        @base_url = configuration.base_url
        @transaction_service = Transaction.new(configuration)
      end

      # Triggers a smart contract (state-changing operation)
      # This creates and broadcasts a transaction to the blockchain
      #
      # @param contract_address [String] the contract address to interact with
      # @param function [String] the function to call on the contract
      # @param parameters [Array] the parameters to pass to the function
      # @param private_key [String] the private key to sign the transaction
      # @param fee_limit [Integer] the maximum energy fee to pay (default: configuration default)
      # @param call_value [Integer] the amount of TRX to send with the call (default: 0)
      # @param owner_address [String] the address of the transaction originator (default: derived from private key)
      # @return [Hash] the transaction result
      def trigger_contract(
        contract_address:,
        function:,
        parameters: [],
        private_key:,
        fee_limit: nil,
        call_value: 0,
        owner_address: nil
      )
        # Use configuration default if fee_limit not provided
        fee_limit ||= @configuration.fee_limit

        # Derive owner address from private key if not provided
        owner_address ||= derive_address_from_private_key(private_key)

        # Validate addresses
        validate_address!(contract_address)
        validate_address!(owner_address)

        # Build transaction
        transaction = build_trigger_transaction(
          contract_address: contract_address,
          function: function,
          parameters: parameters,
          owner_address: owner_address,
          fee_limit: fee_limit,
          call_value: call_value
        )

        # Sign and broadcast
        @transaction_service.sign_and_broadcast(transaction, private_key)
      end

      # Calls a smart contract (read-only operation)
      # This does not create a transaction and doesn't change blockchain state
      #
      # @param contract_address [String] the contract address to interact with
      # @param function [String] the function to call on the contract
      # @param parameters [Array] the parameters to pass to the function
      # @param owner_address [String] the address of the caller (default: configuration default)
      # @return [Hash] the result of the function call
      def call_contract(
        contract_address:,
        function:,
        parameters: [],
        owner_address: nil
      )
        # Use a default address if not provided
        owner_address ||= @configuration.default_address || 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb'

        # Validate address
        validate_address!(contract_address)

        # Build request
        endpoint = "#{@base_url}/wallet/triggerconstantcontract"

        # Encode function call
        encoded_data = Abi.encode_function_call(function, parameters)

        # Use 'data' field instead of 'function_selector' (same as trigger_contract)
        payload = {
          contract_address: Utils::Address.to_hex(contract_address),
          data: encoded_data,
          owner_address: Utils::Address.to_hex(owner_address)
        }

        # Make API call
        response = Utils::HTTP.post(endpoint, payload, {
          endpoint_type: :contract_call,
          ttl: 60  # Cache for 1 minute
        })

        # Parse response
        parse_constant_result(response)
      end

      # Checks if a payment has been processed (example helper)
      #
      # @param contract_address [String] the contract address
      # @param operator_address [String] the operator's address
      # @param payment_id [String] the payment ID
      # @return [Boolean] true if the payment is processed, false otherwise
      def payment_processed?(contract_address, operator_address, payment_id)
        result = call_contract(
          contract_address: contract_address,
          function: 'isPaymentProcessed(address,bytes16)',
          parameters: [operator_address, payment_id]
        )

        Abi.decode_output('bool', result)
      end

      # Gets the fee destination (example helper)
      #
      # @param contract_address [String] the contract address
      # @param operator_address [String] the operator's address
      # @return [String] the fee destination address
      def get_fee_destination(contract_address, operator_address)
        result = call_contract(
          contract_address: contract_address,
          function: 'getFeeDestination(address)',
          parameters: [operator_address]
        )

        Abi.decode_output('address', result)
      end

      # Checks if an operator is registered (example helper)
      #
      # @param contract_address [String] the contract address
      # @param operator_address [String] the operator's address
      # @return [Boolean] true if the operator is registered, false otherwise
      def operator_registered?(contract_address, operator_address)
        result = call_contract(
          contract_address: contract_address,
          function: 'isOperatorRegistered(address)',
          parameters: [operator_address]
        )

        Abi.decode_output('bool', result)
      end

      private

      # Builds a trigger transaction for a smart contract call
      #
      # @param contract_address [String] the contract address
      # @param function [String] the function to call
      # @param parameters [Array] the parameters to pass
      # @param owner_address [String] the address of the transaction owner
      # @param fee_limit [Integer] the maximum energy fee
      # @param call_value [Integer] the value to send with the call
      # @return [Hash] the transaction object
      def build_trigger_transaction(
        contract_address:,
        function:,
        parameters:,
        owner_address:,
        fee_limit:,
        call_value:
      )
        endpoint = "#{@base_url}/wallet/triggersmartcontract"

        # Encode function call (selector + parameters)
        encoded_data = Abi.encode_function_call(function, parameters)

        # IMPORTANT: Use 'data' field, not 'function_selector'
        # When function_selector is provided, the API expects it to be the signature string
        # with parameters in a separate 'parameter' field.
        # Using 'data' allows us to send the complete encoded call data.
        payload = {
          contract_address: Utils::Address.to_hex(contract_address),
          data: encoded_data,
          fee_limit: fee_limit,
          call_value: call_value,
          owner_address: Utils::Address.to_hex(owner_address)
        }

        # Get transaction from API
        response = Utils::HTTP.post(endpoint, payload)

        raise "Failed to create transaction: #{response}" unless response['result']

        response['transaction']
      end

      # Parses the result of a constant function call
      #
      # @param response [Hash] the API response
      # @return [String] the parsed result
      def parse_constant_result(response)
        return nil unless response['result']

        # Extract constant result (hex string)
        constant_result = response['constant_result']
        return nil if constant_result.nil? || constant_result.empty?

        constant_result.first
      end

      # Validates a TRON address
      #
      # @param address [String] the address to validate
      # @raise [ArgumentError] if the address is invalid
      def validate_address!(address)
        require_relative '../utils/address'
        raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
      end

      # Derives a TRON address from a private key
      #
      # @param private_key [String] the private key in hex format
      # @return [String] the derived address
      def derive_address_from_private_key(private_key)
        # Use the Key class to derive address from private key
        key = Tron::Key.new(priv: private_key)
        key.address
      end
    end
  end
end