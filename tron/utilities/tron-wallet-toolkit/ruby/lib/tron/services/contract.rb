require_relative '../utils/http'
require_relative '../utils/abi'
require_relative '../utils/address'
require_relative 'transaction'

module Tron
  module Services
    class Contract
      def initialize(configuration)
        @configuration = configuration
        @base_url = configuration.base_url
        @transaction_service = Transaction.new(configuration)
      end

      # Trigger smart contract (state-changing operation)
      # Returns transaction result
      def trigger_contract(
        contract_address:,
        function:,
        parameters: [],
        private_key:,
        fee_limit: 100_000_000,
        call_value: 0,
        owner_address: nil
      )
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

      # Call smart contract (read-only operation)
      # Returns the result without creating a transaction
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
        function_selector = Utils::ABI.encode_function_call(function, parameters)

        payload = {
          contract_address: Utils::Address.to_hex(contract_address),
          function_selector: function_selector,
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

      # Check if payment is processed (example helper)
      def payment_processed?(contract_address, operator_address, payment_id)
        result = call_contract(
          contract_address: contract_address,
          function: 'isPaymentProcessed(address,bytes16)',
          parameters: [operator_address, payment_id]
        )

        Utils::ABI.decode_output('bool', result)
      end

      # Get fee destination (example helper)
      def get_fee_destination(contract_address, operator_address)
        result = call_contract(
          contract_address: contract_address,
          function: 'getFeeDestination(address)',
          parameters: [operator_address]
        )

        Utils::ABI.decode_output('address', result)
      end

      # Check if operator is registered (example helper)
      def operator_registered?(contract_address, operator_address)
        result = call_contract(
          contract_address: contract_address,
          function: 'isOperatorRegistered(address)',
          parameters: [operator_address]
        )

        Utils::ABI.decode_output('bool', result)
      end

      private

      def build_trigger_transaction(
        contract_address:,
        function:,
        parameters:,
        owner_address:,
        fee_limit:,
        call_value:
      )
        endpoint = "#{@base_url}/wallet/triggersmartcontract"

        # Encode function call
        function_selector = Utils::ABI.encode_function_call(function, parameters)

        payload = {
          contract_address: Utils::Address.to_hex(contract_address),
          function_selector: function_selector,
          fee_limit: fee_limit,
          call_value: call_value,
          owner_address: Utils::Address.to_hex(owner_address)
        }

        # Get transaction from API
        response = Utils::HTTP.post(endpoint, payload)

        raise "Failed to create transaction: #{response}" unless response['result']

        response['transaction']
      end

      def parse_constant_result(response)
        return nil unless response['result']

        # Extract constant result (hex string)
        constant_result = response['constant_result']
        return nil if constant_result.nil? || constant_result.empty?

        constant_result.first
      end

      def validate_address!(address)
        require_relative '../utils/address'
        raise ArgumentError, "Invalid TRON address: #{address}" unless Utils::Address.validate(address)
      end

      def derive_address_from_private_key(private_key)
        # This requires cryptographic operations
        # Placeholder - implement using TronWeb or similar
        # For now, require owner_address to be passed explicitly
        raise ArgumentError, "Owner address derivation not implemented. Please provide owner_address parameter."
      end
    end
  end
end