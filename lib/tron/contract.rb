# frozen_string_literal: true
require_relative 'abi'

module Tron
  # The Contract class provides utilities for interacting with TRON smart contracts
  # including calling read-only functions and executing state-changing functions
  class Contract
    # @return [String] the contract address
    attr_reader :address
    # @return [Array<Hash>] the contract ABI (Application Binary Interface)
    attr_reader :abi

    # Creates a new contract instance
    #
    # @param address [String] the contract address
    # @param abi_json [Array<Hash>] the contract ABI as a JSON array
    # @param configuration [Tron::Configuration] the configuration to use
    def initialize(address, abi_json, configuration)
      @address = address
      @abi = abi_json
      @configuration = configuration
      @client = Client.new(@configuration)
      
      # Parse ABI and create method wrappers
      @functions = {}
      parse_abi
    end

    # Create a contract instance from ABI JSON
    #
    # @param abi [Array<Hash>] the contract ABI
    # @param address [String] the contract address
    # @param configuration [Tron::Configuration] the configuration to use (optional)
    # @return [Tron::Contract] a new contract instance
    def self.from_abi(abi:, address:, configuration: nil)
      config = configuration || Client.configuration
      new(address, abi, config)
    end

    # Call a read-only function on the contract
    # This method does not change the blockchain state and doesn't require signing
    #
    # @param function_name [String] name of the function to call
    # @param args [Array] arguments to pass to the function
    # @param key [String] optional parameter (not used in current implementation)
    # @return the decoded result from the contract function
    def call_function(function_name, *args, key: nil)
      function_abi = @functions[function_name]
      raise "Function #{function_name} not found in ABI" unless function_abi

      # Encode the function call
      encoded_data = encode_function_call(function_abi, args)

      # Call the contract
      result = @client.contract_service.call_contract(
        contract_address: @address,
        function: encoded_data,
        parameters: []
      )

      # Decode the result
      decode_function_output(function_abi, result)
    end

    # Execute a state-changing function on the contract
    # This method changes the blockchain state and requires a private key for signing
    #
    # @param function_name [String] name of the function to execute
    # @param args [Array] arguments to pass to the function
    # @param private_key [String] private key to sign the transaction
    # @param fee_limit [Integer] maximum energy fee to pay (default: 100_000_000)
    # @param call_value [Integer] amount of TRX to send with the call (default: 0)
    # @return the transaction result
    def execute_function(function_name, *args, private_key:, fee_limit: 100_000_000, call_value: 0)
      function_abi = @functions[function_name]
      raise "Function #{function_name} not found in ABI" unless function_abi

      # Encode the function call
      encoded_data = encode_function_call(function_abi, args)

      # Trigger the contract
      @client.contract_service.trigger_contract(
        contract_address: @address,
        function: encoded_data,
        parameters: [],
        private_key: private_key,
        fee_limit: fee_limit,
        call_value: call_value
      )
    end

    private

    # Parses the ABI to extract available functions
    def parse_abi
      @abi.each do |item|
        next unless item['type'] == 'function'

        name = item['name']
        @functions[name] = item
      end
    end

    # Encodes a function call with the given arguments
    #
    # @param function_abi [Hash] the ABI definition for the function
    # @param args [Array] arguments to encode
    # @return [String] the encoded function call
    def encode_function_call(function_abi, args)
      # Get function signature
      input_types = function_abi['inputs'].map { |input| input['type'] }
      
      # Parse types using the new ABI system
      parsed_types = input_types.map { |type_str| Abi::Type.parse(type_str) }
      
      # Encode arguments
      encoded_args = []
      args.each_with_index do |arg, idx|
        encoded_args << Abi::Encoder.type(parsed_types[idx], arg)
      end
      
      # Create function selector (first 4 bytes of keccak hash of function signature)
      signature_parts = function_abi['inputs'].map { |input| "#{input['type']} #{input['name']}" }
      signature = "#{function_abi['name']}(#{function_abi['inputs'].map { |input| input['type'] }.join(',')})"
      
      # Calculate function selector using keccak256
      function_selector = calculate_function_selector(signature)
      
      # Combine selector and encoded args
      function_selector + encoded_args.join
    end

    # Calculates the function selector from the function signature
    #
    # @param signature [String] the function signature
    # @return [String] the function selector (first 4 bytes of keccak hash)
    def calculate_function_selector(signature)
      # Use keccak256 to calculate the function selector (first 4 bytes)
      hash = Utils::Crypto.keccak256(signature)
      # Take only first 4 bytes (8 hex chars)
      Utils::Crypto.bin_to_hex(hash[0, 4])
    end

    # Decodes the output of a function call
    #
    # @param function_abi [Hash] the ABI definition for the function
    # @param output_data [String] the raw output data to decode
    # @return the decoded output
    def decode_function_output(function_abi, output_data)
      # Parse output types
      output_types = function_abi['outputs'].map { |output| Abi::Type.parse(output['type']) }
      
      # Decode the output
      Abi::Decoder.type(output_types.first, output_data)  # Simplified for single output
    end
  end
end